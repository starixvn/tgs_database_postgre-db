/*
	Louisa: insert data into dbo.Bettrans_SabaPlus_Bet
	2024-09-05
*/
 
-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sabaplus_bet_insert(character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying, character varying, character varying, character varying, bigint);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sabaplus_bet_insert(
	IN seq character varying,
	IN operatorcustid character varying,
	IN ticketno character varying,
	IN action character varying,
	IN gametype character varying DEFAULT NULL::character varying,
	IN bettype integer DEFAULT 0,
	IN gameroundid character varying DEFAULT NULL::character varying,
	IN gameid character varying DEFAULT NULL::character varying,
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
	INOUT refno bigint DEFAULT 0)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	INSERT INTO dbo.bet_bettrans_SabaPlus_Bet 
	(	Seq
		,OperatorCustId	
		,GameType		
		,Bettype		
		,GameRoundId	
		,GameId			
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
		,Action	
		,CreateTime		
		,UpdateTime	
	)
	VALUES
	(	Seq
		,OperatorCustId	
		,GameType		
		,Bettype		
		,GameRoundId	
		,GameId			
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
		,Action		
		,CURRENT_TIMESTAMP	
		,CURRENT_TIMESTAMP 
	);
	SELECT LASTVAL() INTO Refno;	
END;
$BODY$;
-----------------------------------------------------------------------------
ALTER PROCEDURE dbo.bet_bettrans_sabaplus_bet_insert(character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying, character varying, character varying, character varying, bigint)
    OWNER TO postgres;
-----------------------------------------------------------------------------
ALTER PROCEDURE dbo.bet_bettrans_sabaplus_bet_insert(character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying, character varying, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, numeric, numeric, character varying, character varying, character varying, character varying, character varying, character varying, character varying, bigint)
 OWNER TO postgres;


--------- SAMPLE ------------------------------------------------------------
----Place bet
--- select   * from dbo.players limit 10
	
	CALL dbo.bet_bettrans_sabaplus_bet_insert(
		seq => '56gh60f1-e36f-4ad1-86ff'
		,operatorcustid =>'4uo0gcqkvze1'
		,ticketno	=> '12345654323'	
		,action		=> 'SBL_PlaceBet'
		,gametype	=>'MaxGame'	
		,bettype	=> 5401 	
		,gameroundid =>'1234567'	
		,gameid		=>'5300014'	
		,ipaddress	=>''	
		,transdate	=> '2024-09-06 15:00:22+00'	
		,transactionid  =>'6dd529awqf71'
		,stake	=> 100.0		
		,actualstake => 100.0	
		,odds		=> 0.2			
		,refno	=>null	
	)
	
	select * from dbo.bettrans_sabaplus_bet where seq =  '56gh60f1-e36f-4ad1-86ff'
	----truncate table  dbo.bettrans_spsw_bet
	----RESTART IDENTITY;

----Place bet and Settle
	CALL dbo.bet_bettrans_sabaplus_bet_insert(
		seq => 'hj98s34j-h4gh-4jh1-23ee'
		,operatorcustid =>'4uo0gcqkvze1'
		,ticketno	=> '12345654324'	
		,action		=> 'SBL_PlaceBetAndSettle'
		,gametype	=>'SlotGame'	
		,bettype	=> 1011 	
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
	)

	select * from dbo.bettrans_sabaplus_bet where seq = 'hj98s34j-h4gh-4jh1-23ee'
	----truncate table  dbo.bettrans_spsw_bet
	---RESTART IDENTITY;
