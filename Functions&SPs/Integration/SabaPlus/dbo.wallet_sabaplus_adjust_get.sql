/*
	Louisa: get running ticket after X minutes
	2024-09-23
*/

-- DROP PROCEDURE dbo.wallet_sabaplus_adjust_get
CREATE OR REPLACE PROCEDURE dbo.wallet_sabaplus_adjust_get
(
	  IN ticketno		character varying
	 ,IN groupaction	character varying
	 ,IN operatorcustid	character varying
	 ,IN gametype		character varying DEFAULT NULL::character varying
	 ,IN actualstake	numeric DEFAULT 0.0
	 ,IN payout			numeric DEFAULT 0.0
	 ,refno				bigint	DEFAULT 0::bigint ---dbo.bettrans_sabaplus_bet.sq

	 ,INOUT balanceadjust numeric DEFAULT 0
	 ,INOUT statuscode		character varying DEFAULT '0'::character varying
	 ,INOUT errmsg			text DEFAULT ''::text
	 
)
/*
	Param's explaination: 
		groupaction: settle ( for BetResultCheck(won/lose/draw) | EndGame)
					 void ( for  BetResultCheck(void/refund/reject) , VoidGame  )
*/
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _old_actual_stake	numeric(20,6);
			_old_payout			numeric(20,6);
			_old_status			character varying(10);
			_adjust				numeric(18,6);

BEGIN
	---need to add case send running

	DROP TABLE IF EXISTS ticketinfo;

	CREATE TEMPORARY TABLE ticketinfo ( operatorcustid character varying(32), ticketno character varying(200), gametype  character varying(50)
										, actualstake numeric(20,6), payout numeric(20,6), status character varying(20), rn int
										);

	INSERT INTO  ticketinfo ( operatorcustid, ticketno, gametype, actualstake , payout, status, rn )
	SELECT b.operatorcustid, b.ticketno, b.gametype, b.actualstake , b.payout
			, CASE WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 'settle'
					WHEN b.ticketstatus = 'running' THEN b.ticketstatus
					WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 'void'
					ELSE NULL END status  --unknow
			,RANK() OVER( ORDER BY  CASE --WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 1
											 WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 2
											 WHEN b.ticketstatus = 'running' THEN 3
											 ELSE 99 --unknow
											 END 
									, CASE WHEN b.ticketstatus in ('won','lose','draw') then sq else 0 END desc ) as rn
		FROM dbo.bettrans_sabaplus_bet b
		WHERE b.ticketno = wallet_sabaplus_adjust_get.ticketno
			AND b.sq <> wallet_sabaplus_adjust_get.refno;

	SELECT SUM(b.actualstake)	 
			, SUM(b.payout)		 
			,b.status			
	INTO _old_actual_stake,  _old_payout, _old_status
	FROM ticketinfo b
	WHERE b.rn = 1
		AND b.status <> 'void'
	GROUP BY b.ticketno, b.rn, b.status;
	
	IF groupaction = 'settle' THEN
		IF _old_status = 'settle' THEN	balanceadjust := (- _old_payout  + payout) + ( _old_actual_stake - actualstake) ;	END IF;	 ---resettle
		IF _old_status = 'running' THEN balanceadjust := (_old_actual_stake - actualstake ) + payout;	END IF;	--settle
	END IF;

	IF groupaction = 'void' THEN
		IF _old_status = 'settle' THEN	balanceadjust := -(_old_payout - _old_actual_stake)  ; END IF;	---void/refund/reject settle
		IF _old_status = 'running' THEN balanceadjust :=  _old_actual_stake;	END IF; ---	---void/refund/reject  running
	END IF;

	DROP TABLE ticketinfo; 

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

/*
call   dbo.wallet_sabaplus_adjust_get
(
		ticketno		 => 'Louisa_5402|$|4uo2mwf6dow8_test|$|5402_30429807'
		,gametype => 'fff'
	  , groupaction			=>	 'settle'
	  , actualstake		 => 2.0
	  , payout			 => 26.0
	  , operatorcustid		 => '4uo2mwf6dow8_test'
	  ,refno	=> 19923
)

 
call   dbo.wallet_sabaplus_adjust_get
(
		ticketno		 => '11314|$|4uo2mwf6dow8_test|$|66f51c802ffa022cbfa6783bdw2' 
	  , groupaction			=>	 'settle'
	  , actualstake		 => 2.0
	  , payout			 => 26.0
	  , operatorcustid		 => '4uo2mwf6dow8_test'
	  ,refno	=> 19923
)
*/
