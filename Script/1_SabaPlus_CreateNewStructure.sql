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
	
CREATE TABLE dbo.bettrans_sabaplus_bet 
(
	 SQ					bigint NOT NULL DEFAULT  nextval('dbo.bettrans_SabaPlus_Bet_sq_seq'::regclass)
	,Seq				character varying(64)	NOT NULL
	,OperatorCustId		character varying(32)	NOT NULL
	,GameType			character varying(50)	NOT NULL
	,ExternalGameId		character varying(50)	NULL									
	,GameRoundId		character varying(100)
	,GameId				integer					NULL
	,GameProviderCode	character varying(16)	NULL
	,IpAddress			character varying(25)	
	,TransDate			timestamp with time zone		
	,SettleDate			timestamp with time zone
	,TicketNo			character varying(200)		NOT NULL
	,TransactionId		character varying(100)	
	,Stake				numeric(20,6)	DEFAULT 0.0
	,ActualStake		numeric(20,6)	DEFAULT 0.0
	,NetStake			numeric(20,6)	DEFAULT 0.0	
	,Payout				numeric(20,6)	DEFAULT 0.0
	,Odds				numeric(20,2)	NOT NULL 
	,BetChoice			character varying(100)
	,TableCode			character varying(100)	
	,CurrencyISO		character varying(10)	
	,BonusId			character varying(100)
	,BonusName			character varying(500)	
	,PrizeName			character varying(500)	
	,CreateTime			timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP	
	,UpdateTime			timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP	
	,ExtraInfo			character varying(500)		
	,Action				character varying(100)	NOT NULL ---API Name
	,TicketStatus		character varying(100)	NOT NULL
	,GameResult			character varying(2000)
	,ResultId			character varying(500)
	,playercode			character varying(16)
);
-----------------------------------------------

-- DROP INDEX IF EXISTS dbo.PK_bettrans_sabaplus_bet_sq;
CREATE INDEX IF NOT EXISTS PK_bettrans_sabaplus_bet_sq
    ON dbo.bettrans_sabaplus_bet USING btree
    (sq ASC NULLS LAST)
    WITH (deduplicate_items=False)
    TABLESPACE pg_default;

-- DROP INDEX IF EXISTS dbo.IDX_bettrans_sabaplus_transdate
CREATE INDEX IDX_bettrans_sabaplus_transdate
	ON dbo.bettrans_sabaplus_bet USING btree
	(transdate ASC NULLS LAST)
	WITH (deduplicate_items=True)
	TABLESPACE pg_default;

-- DROP INDEX IF EXISTS dbo.IDX_bettrans_sabaplus_bet_ticketno
CREATE INDEX IDX_bettrans_sabaplus_bet_ticketno
    ON dbo.bettrans_sabaplus_bet USING btree
    (ticketno ASC NULLS LAST)
    WITH (deduplicate_items=True)
;

----------------------------------------------


--Primary key
ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet 
DROP CONSTRAINT IF EXISTS pk_bettrans_SabaPlus_Bet;

ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet
    ADD CONSTRAINT pk_bettrans_SabaPlus_Bet PRIMARY KEY (sq);

--Unique key TicketNo, Seq
ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet 
DROP CONSTRAINT IF EXISTS uk_bettrans_SabaPlus_Bet_TicketNo_Seq;

ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Bet
    ADD CONSTRAINT uk_bettrans_SabaPlus_Bet_TicketNo_Seq UNIQUE (TicketNo, Seq);

--grant
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
	 SQ				BIGINT					NOT NULL DEFAULT nextval('dbo.bettrans_SabaPlus_Settle_sq_seq'::regclass) 
	,Seq				character varying(64)	NOT NULL
	,OperatorCustId	CHARACTER VARYING(32)	NOT NULL			
	,ExternalGameId	character varying(50)	NULL
	,GameRoundId	CHARACTER VARYING(100)
	,GameId			INT						NULL	
	,GameProviderCode	character varying(16)	NOT NULL
	,SettleDate		TIMESTAMP WITH TIME ZONE
	,TicketNo		CHARACTER VARYING(200)		NOT NULL
	,TransactionId	CHARACTER VARYING(100)	
	,Stake			DECIMAL(20,6)	 DEFAULT 0.0
	,ActualStake	DECIMAL(20,6)	DEFAULT 0.0	
	,NetStake		DECIMAL(20,6)	DEFAULT 0.0
	,Payout			DECIMAL(20,6)	 DEFAULT 0.0
	,Odds			DECIMAL(20,2)	NOT NULL	
	,CurrencyISO	CHARACTER VARYING(10)	
	,BonusId		CHARACTER VARYING(100)
	,BonusName		CHARACTER VARYING(500)	
	,PrizeName		CHARACTER VARYING(500)	
	,CreateTime		TIMESTAMP WITH TIME ZONE	NOT NULL
	,UpdateTime		TIMESTAMP WITH TIME ZONE	NOT NULL
	,Action			CHARACTER VARYING(100)		NOT NULL
	,TicketStatus	CHARACTER VARYING(100)		NOT NULL
	,GameResult			character varying(2000)
	,ResultId			character varying(500)
);

--Primary key
ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Settle 
DROP CONSTRAINT IF EXISTS pk_bettrans_SabaPlus_Settle;

ALTER TABLE IF EXISTS dbo.bettrans_SabaPlus_Settle
    ADD CONSTRAINT pk_bettrans_SabaPlus_Settle PRIMARY KEY (sq);

---grant
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

----------------------------------------------------
--4. TABLE log.DBALog
----------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS log.DBA_Log_sq_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE log.DBA_Log_sq_seq
    OWNER TO postgres;

CREATE TABLE log.DBA_Log 
(
	 sq BIGINT NOT NULL DEFAULT nextval('log.DBA_Log_sq_seq'::regclass)
	 ,sessionid		character varying(200)
	 ,uid			uuid
	 ,userid		oid
	 ,action		character varying(50)
	 ,object_type	character varying(50)
	 ,schema		 character varying(50)	 
	 ,object_name	character varying(200)
	 ,start_time	timestamp
	 ,end_time		timestamp
	 ,text			character varying(1000)
)




	