-- PROCEDURE: dbo.bet_bettrans_sbsw_adjust_sabasw(character varying, timestamp with time zone, character varying, integer, bigint, character varying, character varying, integer, character varying, date, numeric, numeric, integer, bigint)

-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sbsw_adjust_sabasw(character varying, timestamp with time zone, character varying, integer, bigint, character varying, character varying, integer, character varying, date, numeric, numeric, integer, bigint);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_adjust_sabasw(
	IN action character varying,
	IN "time" timestamp with time zone,
	IN userid character varying,
	IN currency integer,
	IN txid bigint,
	IN refid character varying,
	IN operationid character varying,
	IN bettype integer,
	IN bettypename character varying,
	IN winlostdate date,
	IN creditamount numeric,
	IN debitamount numeric,
	INOUT spresult integer DEFAULT 0,
	INOUT licenseetxid bigint DEFAULT NULL::bigint)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN  
        IF EXISTS(SELECT 1
        FROM dbo.Bettrans_SBSW_Adjust AS SBSW 
        WHERE  SBSW.refId = bet_bettrans_sbsw_adjust_sabasw.refid AND SBSW.operationId = bet_bettrans_sbsw_adjust_sabasw.operationId) THEN
            SELECT -4 INTO SPResult;
                        RETURN;
        END IF;
        INSERT INTO dbo.Bettrans_SBSW_Adjust
          (
            action,
            "time",
            userId,
            currency,
            txId,
            refId,
            operationId,
            betType,
            betTypeName,
            winlostDate,
            creditAmount,
            debitAmount
          )
        VALUES 
          (
            action,
            "time",
            userId,
            currency,
            txId,
            refId,
            operationId,
            betType,
            betTypeName,
            winlostDate,
            creditAmount,
            debitAmount
          );
       SELECT LASTVAL() INTO licenseetxid; 
END ;
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_adjust_sabasw(character varying, timestamp with time zone, character varying, integer, bigint, character varying, character varying, integer, character varying, date, numeric, numeric, integer, bigint)
    OWNER TO postgres;
