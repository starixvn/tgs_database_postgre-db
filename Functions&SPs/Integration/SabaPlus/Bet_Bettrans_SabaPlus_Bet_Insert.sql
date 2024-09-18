/*
	Louisa: insert data into dbo.Bettrans_sabaplus_Bet/Settle
	2024-09-05
*/
 
CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sabaplus_bet(
	IN seq character varying,
	IN operatorcustid character varying,
	IN ticketno character varying,
	IN action character varying,
	IN gameprovidercode character varying,
	IN gametype character varying DEFAULT NULL::character varying,
	IN externalgameid character varying DEFAULT NULL::character varying,
	IN gameroundid character varying DEFAULT NULL::character varying,
	IN ipaddress character varying DEFAULT NULL::character varying,
	IN transdate timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN settledate timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN transactionid character varying DEFAULT NULL::character varying,
	IN stake numeric DEFAULT 0.0,
	IN actualstake numeric DEFAULT 0.0,
	IN netstake numeric DEFAULT 0.0,
	IN payout numeric DEFAULT 0.0,
	IN odds numeric DEFAULT 0.0,
	IN betchoice character varying DEFAULT NULL::character varying,
	IN tablecode character varying DEFAULT NULL::character varying,
	IN currencyiso character varying DEFAULT NULL::character varying,
	IN extrainfo character varying DEFAULT NULL::character varying,
	IN bonusid character varying DEFAULT '0'::character varying,
	IN bonusname character varying DEFAULT NULL::character varying,
	IN prizename character varying DEFAULT NULL::character varying,
	IN providerticketstatus character varying DEFAULT NULL::character varying,
	IN gameresult character varying DEFAULT NULL::character varying,
	IN resultid character varying DEFAULT NULL::character varying,
	IN gameproviderid uuid DEFAULT NULL::uuid,
	INOUT refno bigint DEFAULT 0,
	INOUT statuscode character varying DEFAULT '0'::character varying,
	INOUT errmsg text DEFAULT ''::text)
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
			_gameid	int;
			
BEGIN

---- get TicketStatus from API
	IF Action IN ( 'VoidGame', 'BetResultCheck') THEN
		SELECT ProviderTicketStatus INTO TicketStatus;
	END IF;

	SELECT g.id into _gameid::int  FROM dbo.Games g 
	WHERE g.external_id = bet_bettrans_sabaplus_bet.externalgameid 
		AND  g.game_provider_id = bet_bettrans_sabaplus_bet.gameproviderid;
	
---- check API VoidGame dplicate request duplicate
	IF EXISTS ( SELECT 1 FROM dbo.Bettrans_sabaplus_Settle s WHERE s.ticketNo = bet_bettrans_sabaplus_bet.ticketno AND s.Action = 'VoidGame') THEN
        StatusCode := '101';
		ErrMsg := 'Duplicate Transaction';
        
		RETURN;
    END IF;

	IF Action = 'Bonus' THEN
		SELECT 'WON' INTO TicketStatus;
	
	ELSIF Action = 'PlaceBet' THEN
		SELECT 'running' INTO TicketStatus;	
	
	ELSEIF Action IN ('EndGame', 'PlaceBetAndSettle', 'FreeSpin') THEN
		SELECT CASE WHEN payout = 0 THEN 'Lose' 
					WHEN payout = actualstake THEN 'Draw'
					WHEN payout > 0 THEN 'Won'
					ELSE '' --unknow case or bug;
				END INTO TicketStatus;
	END IF;

IF Action IN ('PlaceBet', 'PlaceBetAndSettle', 'FreeSpin', 'Bonus') THEN
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
		)
		VALUES 
		(	OperatorCustId	
			,GameType		
			,ExternalGameId		
			,GameRoundId	
			,_gameid	
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
		);
	END IF;

	SELECT LASTVAL() INTO Refno;---OUTPUT inserted ID to API
		
	IF Action  <>  'PlaceBet' THEN
		INSERT INTO dbo.Bettrans_SabaPlus_Settle 
		(	OperatorCustId	
			,TicketNo	
			,ExternalGameId		
			,SettleDate		
			,GameRoundId	
			,GameId		
			,GameProviderCode
			,TransactionId	
			,Stake		
			,ActualStake	
			,NetStake		
			,Payout			
			,Odds			
			,CurrencyISO	
			,BonusId		
			,BonusName		
			,PrizeName			
			,CreateTime		
			,UpdateTime	
			,Action --- '' + API Name
			,TicketStatus
			,Seq
		)
		VALUES
		(	OperatorCustId	
			,TicketNo	
			,ExternalGameId		
			,SettleDate		
			,GameRoundId	
			,_gameid	
			,GameProviderCode
			,TransactionId	
			,Stake			
			,ActualStake	
			,NetStake		
			,Payout			
			,Odds			
			,CurrencyISO	
			,BonusId		
			,BonusName		
			,PrizeName	
			,CURRENT_TIMESTAMP	
			,CURRENT_TIMESTAMP 
			,Action ---   API Name
			,TicketStatus
			,Seq
		);
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

 

----EndGame
	CALL dbo.bet_bettrans_sabaplus_bet(
		seq 			=> 'E6EA2761-46AC-42AF-9DD3-B65E2F763A8E'
		,operatorcustid =>'4uo0gcqkvze1'
		,ticketno		=>'12345654406'
		,Action		=> 'EndGame'
		,gametype	=>'MaxGame'	
		,ExternalGameId	=> '5401' 
		,gameroundid =>'1234567'	
		,GameProviderCode => 'MAXPLAY'
		,settledate	=> '2024-09-07 10:02:22+00'	
		,transactionid  =>'4678gfqf71'
		,stake		=> 100.0	
		,netstake	=> 100.0
		,actualstake => 100.0	
		,odds		=> 0.2
		,payout		=> 140.0
		
		,refno		=>null	
		,statuscode => ''
		,errmsg 	=> ''
	)
	select * from dbo.bettrans_Settle   
	----truncate table  dbo.bettrans_sabaplus_Settle
	
----Place bet and Settle /FreeSpin/ Bonus
	CALL dbo.bet_bettrans_sabaplus_bet_insert(
		seq => '18A74C4F-C96A-4678-948B-AC3955632E52'
		,operatorcustid =>'4uo0gcqkvze1'
		,ticketno	=> '12345654325'	
		,Action		=> 'PlaceBetAndSettle'
		,gametype	=>'SlotGame'	
		,ExternalGameId	=> 1011 	
		,gameid		=>'200006'	
		,ipaddress	=>''	
		,transdate	=> '2024-09-07 10:00:22+00'	
		,settledate	=> '2024-09-07 10:00:22+00'	
		,transactionid  =>'4678gfqf71'
		,stake		=> 100.0	
		,netstake	=> 100.0
		,actualstake => 100.0	
		,odds		=> 0.2
		,payout		=> 120.0
		,refno		=>null	
		,statuscode => ''
		,errmsg 	=> ''
	)
	select * from dbo.bettrans_Bet   
	----truncate table  dbo.bettrans_sabaplus_Bet RESTART IDENTITY
	
----VoidGame
	CALL dbo.bet_bettrans_sabaplus_bet_insert(
		seq => 'hj98s34j-h4gh-4jh1-23ee'
		,operatorcustid =>'4uo0gcqkvze1'
		,ticketno	=> '12345654324'	
		,Action		=> 'VoidGame'
		,gametype	=>'SlotGame'	
		,gameid		=>'200006'
		,GameRoundId=>'5402_29835804'
		,ipaddress	=>''	
		,transactionid  =>'4678gfqf71'
		,ProviderTicketStatus = 'Reject'
		,statuscode => ''
		,errmsg 	=> ''
	)
	
	select * from dbo.bettrans_sabaplus_bet where seq = 'hj98s34j-h4gh-4jh1-23ee'
	---- truncate table  dbo.bettrans_sabaplus_bet restart identity

*/