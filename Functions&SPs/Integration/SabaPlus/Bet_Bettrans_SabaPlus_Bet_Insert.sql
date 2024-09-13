/*
	Louisa: insert data into dbo.Bettrans_Bet
	2024-09-05
*/
 
-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_bet_insert(character varying, character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, bigint, character varying, text);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_bet_insert(
	IN seq 				character varying,
	IN operatorcustid 	character varying,
	IN ticketno 		character varying,
	IN Action			character varying(100),	
	IN GameProviderCode	character varying(16),
	IN gametype 		character varying DEFAULT NULL::character varying,
	IN ExternalGameId	integer DEFAULT 0,
	IN gameroundid 		character varying DEFAULT NULL::character varying,
	IN gameid 			character varying DEFAULT NULL::character varying,
	IN ipaddress 		character varying DEFAULT NULL::character varying,
	IN transdate 		timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN settledate 		timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN transactionid 	character varying DEFAULT NULL::character varying,
	IN stake 			numeric DEFAULT 0.0,
	IN actualstake 		numeric DEFAULT 0.0,
	IN netstake 		numeric DEFAULT 0.0,
	IN payout 			numeric DEFAULT 0.0,
	IN odds 			numeric DEFAULT 0.0,
	IN betchoice 		character varying DEFAULT NULL::character varying,
	IN tablecode 		character varying DEFAULT NULL::character varying,
	IN currencyiso 		character varying DEFAULT NULL::character varying,
	IN extrainfo 		character varying DEFAULT NULL::character varying,
	IN bonusid 			character varying DEFAULT '0'::character varying,
	IN bonusname 		character varying DEFAULT NULL::character varying,
	IN prizename 		character varying DEFAULT NULL::character varying,
	IN ProviderTicketStatus character varying DEFAULT NULL::character varying,
	INOUT refno 		bigint DEFAULT 0,
	INOUT statuscode 	character varying DEFAULT '0'::character varying,
	INOUT errmsg 		text DEFAULT ''::text
)
LANGUAGE 'plpgsql'
/*
	Param's explaination: 
		Action	: API Name --PlaceBet
		ProviderTicketStatus: ticket status from Provider -- API BetResultCheck and VoidGame may have this value --now is attribute status
		refno		: output ID from S1 to Saba+
*/
AS $BODY$
	DECLARE TicketStatus 	character varying(100) := 'running';
			IsResettle		bit;
			TicketStatusId	smallint;
BEGIN

---- get TicketStatus from API
	IF Action IN ( 'VoidGame', 'BetResultCheck') THEN
		SELECT ProviderTicketStatus INTO TicketStatus;

		/* --check API VoidGame dplicate request duplicate
			IF EXISTS SELECT TOP 1 1 FROM dbo.Bettrans_Settle WHERE ticketNo = TicketNo THEN 
                StatusCode := '101';
				ErrMsg := 'Duplicate Transaction';
                RETURN;
            END IF;
		*/
	ELSIF Action = 'Bonus' THEN
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

----Set TicketStatusID base on TicketStatus
	SELECT CASE WHEN TicketStatus = 'running'  THEN 0
				WHEN TicketStatus =	 'Won'		THEN 1
				WHEN TicketStatus =	 'Lose'		THEN 2
				WHEN TicketStatus =	 'Draw'		THEN 3
				WHEN TicketStatus =	 'Void'		THEN 4
				WHEN TicketStatus =	 'Reject'	THEN 5
				WHEN TicketStatus =	 'Refund' 	THEN 6
				ELSE NULL 
			END
	INTO TicketStatusId;

	IF Action IN ('EndGame', 'VoidGame', 'BetResultCheck') THEN
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
			,TicketStatusId
		)
		VALUES
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
			,CURRENT_TIMESTAMP	
			,CURRENT_TIMESTAMP 
			,Action --- '' + API Name
			,TicketStatus
			,TicketStatusId
		);

	ELSIF Action IN ( 'PlaceBet', 'PlaceBetAndSettle', 'FreeSpin', 'Bonus' ) THEN
		INSERT INTO dbo.bettrans_SabaPlus_Bet 
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
			,Action --- '' + API Name
			,TicketStatus
			,TicketStatusId
		)
		VALUES
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
			,CURRENT_TIMESTAMP	
			,CURRENT_TIMESTAMP
			,Action
			,TicketStatus
			,TicketStatusId
		);
	END IF;
	
	SELECT LASTVAL() INTO Refno;---OUTPUT inserted ID to API

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

-----------------------------------------------------------------------------
ALTER PROCEDURE dbo.bet_bettrans_bet_insert(character varying, character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying, character varying, character varying, character varying,character varying, bigint, character varying, text)
    OWNER TO postgres;


--------- SAMPLE ------------------------------------------------------------
----Place bet
--- select * from dbo.players limit 10
	
	CALL dbo.bet_bettrans_bet_insert(
		seq => 'NGBF2390-AE14-435F-BD14-0D513ED25890'
		,operatorcustid => '4uo0gcqkvze1'
		,ticketno	=> '12345654324'	
		,Action	=> 'PlaceBet'
		,gametype	=>'MaxGame'	
		,ExternalGameId	=> 5401 	
		,gameroundid =>'1234567'	
		,gameid		=>'5300014'	
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
	
	select * from dbo.bettrans_SabaPlus_Bet  where seq =  '3781D88A-9180-443F-B405-E660878D0770'
	----truncate table  dbo.bettrans_Bet RESTART IDENTITY

----EndGame
	CALL dbo.bet_bettrans_bet_insert(
		seq 			=> 'bF3B7850-F49A-41BD-A2FE-EA62BD7DDACC'
		,operatorcustid =>'4uo0gcqkvze1'
		,ticketno		=>'12345654323'	
		,Action		=> 'EndGame'
		,gametype	=>'MaxGame'	
		,ExternalGameId	=> 5401 
		,gameroundid =>'1234567'	
		,gameid		=>'5300014'		
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
	----truncate table  dbo.bettrans_Settle
	
----Place bet and Settle /FreeSpin/ Bonus
	CALL dbo.bet_bettrans_bet_insert(
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
	----truncate table  dbo.bettrans_Bet RESTART IDENTITY
	
----VoidGame
	CALL dbo.bet_bettrans_bet_insert(
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
	
	select * from dbo.bettrans_bet where seq = 'hj98s34j-h4gh-4jh1-23ee'
	----truncate table  dbo.bettrans_bet
