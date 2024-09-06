/*
	Louisa: insert data into dbo.Bettrans_SPSW_Bet
	2024-09-05
*/
 
 DROP PROCEDURE IF EXISTS dbo.Bettrans_SPSW_Bet_Insert (
	character varying 
	,character varying 
	,character varying  
	,character varying 
	,integer
	,character varying    
	,character varying 	 
	,character varying 	 
	,timestamp with time zone  
	,character varying 
	,numeric 
	,numeric 
	,numeric  
	,character varying 
	,character varying 
	,character varying 
	,character varying
	,smallint 
	,character varying 
	,character varying 
	,character varying 
	,BIGINT
);
CREATE OR REPLACE PROCEDURE dbo.Bettrans_SPSW_Bet_Insert
(
	IN Seq		character varying(64)
	,IN OperatorCustId character varying(32)
	,IN TicketNo	character varying(200)
	,IN GameType	character varying(50) DEFAULT NULL::character varying
	,IN Bettype		integer DEFAULT 0
	,IN GameRoundId character varying(100) DEFAULT NULL::character varying
	,IN GameId		character varying(50)  DEFAULT NULL::character varying
	,IN IpAddress	character varying(25) DEFAULT NULL::character varying
	,IN TransDate	timestamp with time zone DEFAULT NULL::timestamp with time zone
	,IN TransactionId character varying(100) DEFAULT NULL::character varying
	,IN Stake		numeric(20,6) DEFAULT 0
	,IN ActualStake numeric(20,6) DEFAULT 0
	,IN Odds		numeric(20,2) DEFAULT 0
	,IN BetChoice	character varying(100) DEFAULT NULL::character varying
	,IN TableCode	character varying(100) DEFAULT NULL::character varying
	,IN CurrencyISO	character varying(10)  DEFAULT NULL::character varying
	,IN ExtraInfo	character varying(500) DEFAULT NULL::character varying
	,IN ActionID	smallint DEFAULT 0	---parse from TicketStatus in BetResultCheck
	,IN BonusId		character varying(100)	DEFAULT '0'
	,IN BonusName	character varying(500)	DEFAULT NULL::character varying
	,IN PrizeName	character varying(500)	DEFAULT NULL::character varying
	,INOUT	Refno	BIGINT DEFAULT 0
)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	INSERT INTO dbo.bettrans_SPSW_Bet 
	(	Seq
		,OperatorCustId	
		,GameType		
		,Bettype		
		,GameRoundId	
		,GameId			
		,IpAddress		
		,TransDate				
		,TicketNo		
		,TransactionId	
		,Stake			
		,ActualStake 		
		,Odds			
		,BetChoice		
		,TableCode		
		,CurrencyISO	
		,BonusId			
		,BonusName		
		,PrizeName	
		,ExtraInfo		
		,ActionID		
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
		,TicketNo		
		,TransactionId	
		,Stake			
		,ActualStake	 	
		,Odds			
		,BetChoice		
		,TableCode	
		,CurrencyISO
		,BonusId			
		,BonusName	
		,PrizeName		
		,ExtraInfo		
		,ActionID		
		,CURRENT_TIMESTAMP	
		,CURRENT_TIMESTAMP 
	);
	SELECT LASTVAL() INTO Refno;	
END;
$BODY$;
-----------------------------------------------------------------------------
ALTER PROCEDURE dbo.Bettrans_SPSW_Bet_Insert
(
	character varying 
	,character varying  
	,character varying 
	,character varying 
	,integer
	,character varying    
	,character varying 	 
	,character varying 	 
	,timestamp with time zone  
	,character varying 
	,numeric 
	,numeric 
	,numeric  
	,character varying 
	,character varying 
	,character varying 
	,character varying
	,smallint 
	,character varying 
	,character varying 
	,character varying 
	,BIGINT
)
 OWNER TO postgres;

 
--------- SAMPLE ------------------------------------------------------------

CALL dbo.bettrans_spsw_bet_insert(
	seq => '42e460f1-e36f-4ad1-86da'
	,operatorcustid =>'4unukou84t6h'
	,gametype	=>'MaxGame'	
	,bettype	=>'5401'	
	,gameroundid =>'1234567'	
	,gameid		=>'5300014'	
	,ipaddress	=>''	
	,transdate	=> '2024-09-06 15:00:22+00'	
	,ticketno	=> '12345654321'	
	,transactionid  =>'6dd529awqf71'
	,stake	=> 100.0		
	,actualstake => 100.0	
	,odds		=> 0.2			
	,refno	=>null	
)

select * from dbo.bettrans_spsw_bet where seq =  '42e460f1-e36f-4ad1-86da'
truncate table  dbo.bettrans_spsw_bet