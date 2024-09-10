/*
	Louisa: create new structure to received data from API
	2024-09-05
*/


----------------------------------------------------
--1. TABLE dbo.bettrans_SabaPlus_Bet;
----------------------------------------------------

---drop table if exists dbo.bettrans_SabaPlus_Bet;

CREATE SEQUENCE IF NOT EXISTS dbo.bettrans_SabaPlus_Bet_sq_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE dbo.bettrans_SabaPlus_Bet_sq_seq
    OWNER TO postgres;
	
CREATE TABLE dbo.bettrans_SabaPlus_Bet 
(
	 SQ				bigint NOT NULL DEFAULT  nextval('dbo.bettrans_SabaPlus_Bet_sq_seq'::regclass) 
	,Seq			character varying(36) 
	,OperatorCustId	character varying(32)	NOT NULL
	,GameType		character varying(50)	NOT NULL
	,Bettype		integer									
	,GameRoundId	character varying(100)
	,GameId			character varying(50)	NOT NULL	
	,IpAddress		character varying(25)	
	,TransDate		timestamp with time zone	NOT NULL	
	,SettleDate		timestamp with time zone
	,TicketNo		character varying(200)		NOT NULL
	,TransactionId	character varying(100)	
	,Stake			numeric(20,6)	NOT NULL DEFAULT 0.0
	,ActualStake	numeric(20,6)	NOT NULL DEFAULT 0.0
	,NetStake		numeric(20,6)	DEFAULT 0.0	
	,Payout			numeric(20,6)	DEFAULT 0.0
	,Odds			numeric(20,2)	NOT NULL 
	,BetChoice		character varying(100)
	,TableCode		character varying(100)	
	,CurrencyISO	character varying(10)	
	,BonusId		character varying(100) NOT NULL DEFAULT '0'	
	,BonusName		character varying(500)	
	,PrizeName		character varying(500)	
	,CreateTime		timestamp with time zone NOT NULL
	,UpdateTime		timestamp with time zone NOT NULL
	,ExtraInfo		character varying(500)		
	,SourceName		character varying(100) NOT NULL
	,TicketStatus	character varying(100) NOT NULL
);

--Primary key
ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet 
DROP CONSTRAINT IF EXISTS pk_bettrans_SabaPlus_Bet;

ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet
    ADD CONSTRAINT pk_bettrans_SabaPlus_Bet PRIMARY KEY (sq);

--Unique key
ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet 
DROP CONSTRAINT IF EXISTS uk_bettrans_SabaPlus_Bet_Seq_TicketNo;

ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet
    ADD CONSTRAINT uk_bettrans_SabaPlus_Bet_Seq_TicketNo UNIQUE (Seq,TicketNo);

ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_bet
    OWNER to postgres;

ALTER SEQUENCE dbo.bettrans_SabaPlus_Bet_sq_seq
    OWNED BY dbo.bettrans_SabaPlus_Bet.sq;

----------------------------------------------------
--2. TABLE dbo.bettrans_SabaPlus_Settle;
----------------------------------------------------
	
---drop table if exists dbo.bettrans_SabaPlus_Settle;
CREATE SEQUENCE IF NOT EXISTS dbo.bettrans_SabaPlus_Settle_sq_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE dbo.bettrans_SabaPlus_Settle_sq_seq
    OWNER TO postgres;

CREATE TABLE dbo.bettrans_SabaPlus_Settle 
(
	 SQ				bigint					NOT NULL DEFAULT nextval('dbo.bettrans_SabaPlus_Settle_sq_seq'::regclass) 
	,Seq			character varying(36)	NOT NULL	
	,OperatorCustId	character varying(32)	NOT NULL			
	,Bettype		integer					 
	,GameRoundId	character varying(100)
	,GameId			character varying(50)	NOT NULL	
	,TicketStatus	smallint							
	,SettleFlag		smallint	
	,SettleDate		timestamp with time zone NOT NULL
	,TicketNo		character varying(200)	 NOT NULL
	,TransactionId	character varying(100)	
	,Stake			decimal(20,6)	NOT NULL DEFAULT 0.0
	,ActualStake	decimal(20,6)	NOT NULL DEFAULT 0.0	
	,NetStake		decimal(20,6)	NOT NULL DEFAULT 0.0
	,Payout			decimal(20,6)	NOT NULL DEFAULT 0.0
	,Odds			decimal(20,2)	NOT NULL	
	,CurrencyISO	character varying(10)	
	,BonusId		character varying(100)	NOT NULL DEFAULT '0'
	,BonusName		character varying(500)	
	,PrizeName		character varying(500)	
	,CreateTime		timestamp with time zone	NOT NULL
	,UpdateTime		timestamp with time zone	NOT NULL
	,SourceName		character varying(100) NOT NULL
	,TicketStatus	character varying(100) NOT NULL
);

--Primary key
ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Settle 
DROP CONSTRAINT IF EXISTS pk_bettrans_SabaPlus_Settle;

ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Settle
    ADD CONSTRAINT pk_bettrans_SabaPlus_Settle PRIMARY KEY (sq);


ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Settle
    OWNER to postgres;

ALTER SEQUENCE dbo.bettrans_SabaPlus_Settle_sq_seq
    OWNED BY dbo.bettrans_SabaPlus_Settle.sq;

----------------------------------------------------
--3. TABLE dbo.SystemSetting;
----------------------------------------------------

--DROP TABLE IF EXISTS dbo.SystemSetting 

CREATE TABLE dbo.SystemSetting 
(
	 KeyName		character varying(200) NOT NULL
	,KeyValue	character varying(500) NOT NULL
)

ALTER TABLE IF EXISTS dbo.SystemSetting 
DROP CONSTRAINT IF EXISTS pk_SystemSetting ;

ALTER TABLE IF EXISTS  dbo.SystemSetting 
    ADD CONSTRAINT pk_SystemSetting PRIMARY KEY (KeyName);





	