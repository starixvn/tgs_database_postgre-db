CREATE TABLE IF NOT EXISTS dbo.bettrans_sbsw_adjust
(
    sq bigserial NOT NULL ,
    action character varying(20) COLLATE pg_catalog."default",
    "time" timestamp with time zone,
    userid character varying(30) COLLATE pg_catalog."default",
    currency integer,
    txid bigint,
    refid character varying(100) COLLATE pg_catalog."default",
    operationid character varying(30) COLLATE pg_catalog."default",
    bettype integer,
    bettypename character varying(30) COLLATE pg_catalog."default",
    winlostdate date,
    creditamount numeric(18,2),
    debitamount numeric(18,2),
    createtime timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updatetime timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bettrans_sbsw_adjust PRIMARY KEY (sq),
    CONSTRAINT uk_bettrans_sbsw_adjust_operationid_refid UNIQUE (operationid, refid)
)
