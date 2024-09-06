CREATE TABLE IF NOT EXISTS dbo.bettrans_sbsw_settle
(
    sq bigserial,
    action character varying(20) COLLATE pg_catalog."default",
    operationid character varying(30) COLLATE pg_catalog."default",
    userid character varying(30) COLLATE pg_catalog."default",
    refid character varying(100) COLLATE pg_catalog."default",
    txid bigint DEFAULT '0'::bigint,
    updatetime timestamp with time zone,
    winlostdate date,
    status character varying(30) COLLATE pg_catalog."default",
    payout numeric(18,2),
    creditamount numeric(18,2),
    debitamount numeric(18,2),
    extrastatus character varying(100) COLLATE pg_catalog."default" DEFAULT ''::character varying,
    tickettype integer DEFAULT 0,
    createtime timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    systemupdatetime timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bettrans_sbsw_settle PRIMARY KEY (sq),
    CONSTRAINT uk_bettrans_sbsw_settle_operationid_refid UNIQUE (operationid, refid)
)
