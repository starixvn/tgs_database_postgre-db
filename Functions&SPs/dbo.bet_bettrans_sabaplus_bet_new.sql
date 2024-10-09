/*
	Louisa: insert data into dbo.Bettrans_sabaplus_Bet/Settle
	2024-09-05
*/
 
CREATE OR REPLACE PROCEDURE dbo.Louisa_bet_bettrans_sabaplus_bet(
	IN seq				character varying,
	IN operatorcustid	character varying,
	IN ticketno			character varying,
	IN action			character varying, --''
	IN gameprovidercode character varying,
	IN gametype			character varying DEFAULT NULL::character varying,
	IN externalgameid	character varying DEFAULT NULL::character varying,
	IN gameroundid		character varying DEFAULT NULL::character varying,
	IN ipaddress		character varying DEFAULT NULL::character varying,
	IN transdate		timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN settledate		timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN transactionid	character varying DEFAULT NULL::character varying,
	IN stake			numeric DEFAULT 0.0,
	IN actualstake		numeric DEFAULT 0.0,
	IN netstake			numeric DEFAULT 0.0,
	IN payout			numeric DEFAULT 0.0,
	IN odds				numeric DEFAULT 0.0,
	IN betchoice		character varying DEFAULT NULL::character varying,
	IN tablecode		character varying DEFAULT NULL::character varying,
	IN currencyiso		character varying DEFAULT NULL::character varying,
	IN extrainfo		character varying DEFAULT NULL::character varying,
	IN bonusid			character varying DEFAULT '0'::character varying,
	IN bonusname		character varying DEFAULT NULL::character varying,
	IN prizename		character varying DEFAULT NULL::character varying,
	IN providerticketstatus int DEFAULT NULL::int,
	IN gameresult			character varying DEFAULT NULL::character varying,
	IN resultid				character varying DEFAULT NULL::character varying,
	IN gameproviderid		uuid DEFAULT NULL::uuid,
	IN playercode			character varying DEFAULT NULL::character varying,

	INOUT refno				bigint DEFAULT 0,
	INOUT balanceadjust		numeric DEFAULT 0,
	INOUT statuscode		character varying DEFAULT '0'::character varying,
	INOUT errmsg			text DEFAULT ''::text)
LANGUAGE 'plpgsql'
/*
	Param's explaination: 
		TicketStatusId from Saba+: 0-Running		 
									1-Won			 
									2-Lose 		 
									3-Draw 		 
									4-Void		 
									5-Reject		 
									6-Refund
		action: API Name (PlaceBet, EndGame, PlaceBetAndSettle...)
*/
AS $BODY$
	DECLARE TicketStatus 	character varying(100) := 'running';
			
			_old_actual_stake	numeric(20,6);
			_old_payout			numeric(20,6);
			_old_status			character varying(10);
			_adjust				numeric(18,6);
			_cnt				int;
			
BEGIN

	---not allow add bet after EndGame, cash service should refund stake if already deducted
	IF Action = 'PlaceBet' AND EXISTS (	SELECT 1 FROM  dbo.bettrans_sabaplus_bet b
										WHERE b.ticketno = Louisa_bet_bettrans_sabaplus_bet.ticketno AND b.Action=  'EndGame'
										) THEN
			statuscode := '104';
			errmsg := 'Ticket already settle, cannot add bet';
			RETURN;
	END IF;

	--------------------------------------------------------
	IF Action = 'PlaceBet' THEN
		PERFORM pg_advisory_xact_lock_shared (hashtext('dbo.Louisa_bet_bettrans_sabaplus_bet')::bigint  #hashtext(ticketno)::bigint);
	ELSEIF Action IN ('EndGame', 'VoidGame', 'BetResultCheck') THEN
		PERFORM pg_advisory_xact_lock		 (hashtext('dbo.Louisa_bet_bettrans_sabaplus_bet')::bigint #hashtext(ticketno)::bigint);
	END IF;

	----------TicketStatus---------------------------------------
	IF Action IN ( 'VoidGame', 'BetResultCheck') THEN
		SELECT CASE providerticketstatus WHEN 0 THEN 'running'		 
										 WHEN 1 THEN 'won'			 
										 WHEN 2 THEN 'lose' 		 
										 WHEN 3 THEN 'draw' 		 
										 WHEN 4 THEN 'void'		 
										 WHEN 5 THEN 'reject'		 
										 WHEN 6 THEN 'refund'
				END
		INTO TicketStatus;

	ELSEIF Action = 'Bonus' THEN
		SELECT 'won' INTO TicketStatus;
	
	ELSIF Action = 'PlaceBet' THEN
		SELECT 'running' INTO TicketStatus;	
	
	ELSEIF Action IN ('EndGame', 'PlaceBetAndSettle', 'FreeSpin') THEN
		SELECT CASE WHEN payout = actualstake THEN 'draw'
					WHEN payout < actualstake THEN 'lose' 
					WHEN payout > actualstake THEN 'won'
					ELSE '' --unknow case or bug;
				END INTO TicketStatus;
	END IF;
----------------------------------------------------------------

	INSERT INTO dbo.bettrans_sabaplus_bet 
	(	OperatorCustId	
		,GameType		
		,ExternalGameId		
		,GameRoundId	
		,GameId
		,GameProviderCode
		,IpAddress		
		,TransDate
		,SettleDate
		,TicketNo		
		,TransactionId	
		,Stake			
		,ActualStake 	
		,NetStake
		,Payout
		,Odds			
		,BetChoice		
		,TableCode		
		,CurrencyISO	
		,BonusId			
		,BonusName		
		,PrizeName	
		,ExtraInfo	
		,CreateTime		
		,UpdateTime
		,Action ---   API Name
		,TicketStatus
		,Seq
		,playercode
	)
	VALUES 
	(	OperatorCustId	
		,GameType		
		,ExternalGameId		
		,GameRoundId	
		,0 -- _gameid	
		,GameProviderCode
		,IpAddress		
		,TransDate
		,SettleDate
		,TicketNo		
		,TransactionId	
		,Stake			
		,ActualStake
		,NetStake
		,Payout
		,Odds			
		,BetChoice		
		,TableCode	
		,CurrencyISO
		,BonusId			
		,BonusName	
		,PrizeName		
		,ExtraInfo		
		,CURRENT_TIMESTAMP	
		,CURRENT_TIMESTAMP
		,Action
		,TicketStatus
		,Seq
		,playercode
	);

	---OUTPUT inserted ID to API
	SELECT LASTVAL() INTO Refno;

	---Return Balance to API
	IF Action IN ('EndGame', 'VoidGame', 'BetResultCheck') THEN
		DROP TABLE IF EXISTS ticketinfo;

		CREATE TEMPORARY TABLE ticketinfo ( operatorcustid character varying(32), ticketno character varying(200), gametype  character varying(50)
											, actualstake numeric(20,6), payout numeric(20,6), status character varying(20), rn int
											);

		INSERT INTO  ticketinfo ( operatorcustid, ticketno, gametype, actualstake , payout, status, rn )
		SELECT b.operatorcustid, b.ticketno, b.gametype, b.actualstake , b.payout
				, CASE WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 'settle'
						WHEN b.ticketstatus = 'running' THEN b.ticketstatus
						WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 'void'
						ELSE NULL END status  --unknow
				,RANK() OVER( ORDER BY  CASE --WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 1
												 WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 2
												 WHEN b.ticketstatus = 'running' THEN 3
												 ELSE 99 --unknow
												 END 
										, CASE WHEN b.ticketstatus in ('won','lose','draw') then sq else 0 END desc ) as rn
			FROM dbo.bettrans_sabaplus_bet b
			WHERE b.ticketno = Louisa_bet_bettrans_sabaplus_bet.ticketno
				AND b.sq <> Refno;

		SELECT SUM(b.actualstake)	 
			, SUM(b.payout)		 
			,b.status			
		INTO _old_actual_stake,  _old_payout, _old_status
		FROM ticketinfo b
		WHERE b.rn = 1
			AND b.status <> 'void'
		GROUP BY b.ticketno, b.rn, b.status;
	
		IF groupaction = 'settle' THEN
			IF _old_status = 'settle' THEN	balanceadjust := (- _old_payout  + payout) + ( _old_actual_stake - actualstake) ;	END IF;	 ---resettle
			IF _old_status = 'running' THEN balanceadjust := (_old_actual_stake - actualstake ) + payout;	END IF;	--settle
		END IF;

		IF groupaction = 'void' THEN
			IF _old_status = 'settle' THEN	balanceadjust := -(_old_payout - _old_actual_stake)  ; END IF;	---void/refund/reject settle
			IF _old_status = 'running' THEN balanceadjust :=  _old_actual_stake;	END IF; ---	---void/refund/reject  running
		END IF;

		DROP TABLE ticketinfo; 
	END IF;

	EXCEPTION 
		WHEN unique_violation THEN 
			SELECT  'duplicate ticket' INTO errmsg;
			SELECT '101' INTO statuscode;
		WHEN Others THEN
			 get stacked diagnostics
        		statuscode   = returned_sqlstate,
        		errmsg     = message_text;

END;
$BODY$; 
 
--------- SAMPLE ------------------------------------------------------------
----Place bet 
 
 /*
	CALL dbo.bet_bettrans_sabaplus_bet(
		seq => 'E6EA2761-46AC-42AF-9DD3-B65E2F763A8E'
		,operatorcustid => '4uo0gcqkvze1'
		,ticketno	=> '12345654406'	
		,Action	=> 'PlaceBet'
		,gametype	=>'MaxGame'	
		,ExternalGameId	=> '5401'	
		,gameroundid =>'1234567'
		,GameProviderCode => 'MAXPLAY'
		,ipaddress	=>''	
		,transdate	=> '2024-09-06 15:00:22+00'	
		,transactionid  =>'6dd529awqf71'
		,stake	=> 100.0		
		,actualstake => 100.0	
		,odds		=> 0.2		
		
		,refno		=> null	
		,statuscode => ''
		,errmsg 	=> ''
	)
	
	select * from dbo.bettrans_sabaplus_bet where seq = 'hj98s34j-h4gh-4jh1-23ee'
	---- truncate table  dbo.bettrans_sabaplus_bet restart identity

*/