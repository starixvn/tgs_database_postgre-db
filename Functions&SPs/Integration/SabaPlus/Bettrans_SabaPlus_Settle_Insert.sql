/*
	Louisa: insert data into dbo.Bettrans_SabaPlus_Settle
	2024-09-05
*/
 DROP PROCEDURE IF EXISTS dbo.Bettrans_SabaPlus_Settle_Insert (
	 character varying(64)
	,character varying(32)	
	,character varying(200)
	,character varying(200)
	,timestamp with time zone	
	,integer					
	,character varying(100)		
	,character varying(50)		
	,smallint					
	,smallint					
	,character varying(100)		
	,numeric(20,6)				
	,numeric(20,6)				
	,numeric(20,6)				
	,numeric(20,6)				
	,decimal(20,2)				
	,character varying(10)		
	,character varying(100)		
	,character varying(500)		
	,character varying(500)		
);
CREATE OR REPLACE PROCEDURE dbo.Bettrans_SabaPlus_Settle_Insert
(
	 IN Seq				character varying(64)
	,IN OperatorCustId	character varying(32)	
	,IN TicketNo		character varying(200)	
	,IN Action			character varying(200)
	,IN SettleDate		timestamp with time zone	
	,IN Bettype			integer DEFAULT 0
	,IN GameRoundId		character varying(100) DEFAULT NULL::character varying
	,IN GameId			character varying(50)  DEFAULT NULL::character varying	
	,IN TicketStatus	smallint	DEFAULT 0				
	,IN SettleFlag		smallint	DEFAULT 0	
	,IN TransactionId	character varying(100) DEFAULT NULL::character varying
	,IN Stake			numeric(20,6) DEFAULT 0
	,IN ActualStake		numeric(20,6) DEFAULT 0
	,IN NetStake		numeric(20,6) DEFAULT 0
	,IN Payout			numeric(20,6) DEFAULT 0
	,IN Odds			decimal(20,2) DEFAULT 0		
	,IN CurrencyISO		character varying(10)	DEFAULT NULL::character varying	
	,IN BonusId			character varying(100)	DEFAULT '0'
	,IN BonusName		character varying(500)	DEFAULT NULL::character varying
	,IN PrizeName		character varying(500)	DEFAULT NULL::character varying
)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	INSERT INTO dbo.Bettrans_SabaPlus_Settle 
	(	 Seq			
		,OperatorCustId	
		,TicketNo	
		,Action
		,Bettype		
		,SettleDate		
		,GameRoundId	
		,GameId			
		,TicketStatus	
		,SettleFlag		
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
	)
	VALUES
	(	 Seq			
		,OperatorCustId	
		,TicketNo	
		,Action
		,Bettype		
		,SettleDate		
		,GameRoundId	
		,GameId			
		,TicketStatus	
		,SettleFlag		
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
	);
END;
$BODY$;
-----------------------------------------------------------------------------
ALTER PROCEDURE dbo.Bettrans_SabaPlus_Settle_Insert
(
	 character varying(64)
	,character varying(32)	
	,character varying(200)
	,character varying(32)
	,timestamp with time zone	
	,integer					
	,character varying(100)		
	,character varying(50)		
	,smallint					
	,smallint					
	,character varying(100)		
	,numeric(20,6)				
	,numeric(20,6)				
	,numeric(20,6)				
	,numeric(20,6)				
	,decimal(20,2)				
	,character varying(10)		
	,character varying(100)		
	,character varying(500)		
	,character varying(500)		
)
 OWNER TO postgres;

 
--------- SAMPLE ------------------------------------------------------------

CALL dbo.Bettrans_SabaPlus_Settle_Insert
(
	 seq 			=> 'v45tgf78-d4dg-sad1-jh7u'
	,operatorcustid =>'4uo0gcqkvze1'
	,ticketno		=>  '12345654323'
	,Action			=> 'SBL_EndGame'
	,SettleDate		=> '2024-09-06 15:18:22+00'	
	,bettype		=> 5401
	,gameroundid 	=>'1234567'	
	,gameid			=>'5300014'		
	,transactionid  =>'6dd529awqf71'
	,stake			=> 100.0		
	,actualstake 	=> 100.0	
	,NetStake 		=> 95.0
	,odds			=> 0.2	
	,Payout			=> 114.0
)

select * from dbo.Bettrans_SabaPlus_Settle where ticketno = '12345654323'
----truncate table  dbo.Bettrans_SabaPlus_Settle
----RESTART IDENTITY;
