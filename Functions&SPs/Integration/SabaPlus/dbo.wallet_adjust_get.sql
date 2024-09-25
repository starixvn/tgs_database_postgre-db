/*
	Louisa: get running ticket after X minutes
	2024-09-23
*/

-- DROP PROCEDURE dbo.wallet_adjust_get
CREATE OR REPLACE FUNCTION dbo.wallet_adjust_get
(
	  IN ticketno		character varying
	  ,IN external_status int
	  ,IN stake			numeric DEFAULT 0.0
	  ,IN actualstake	numeric DEFAULT 0.0
	  ,IN netstake		numeric DEFAULT 0.0
	  ,IN payout		numeric DEFAULT 0.0
)
/*
	Param's explaination: 

*/
RETURNS numeric 
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _old_actual_stake	numeric(20,6);
			_old_payout			numeric(20,6);
			_old_status			character varying(10);
			_adjust				numeric(18,6); 	
			_doing				character varying(10) :=  CASE WHEN external_status =  0 THEN 'placebet'
																WHEN external_status IN ( 1,2,3) THEN 'settle'
																WHEN external_status IN (4,5,7) THEN  'void'
																ELSE 'unknow'
																END;
BEGIN
	---need to add case send running

	WITH cte_ticketinfo AS
	(	SELECT b.ticketno, b.actualstake , b.payout
			, CASE WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 'settle'
					WHEN b.ticketstatus = 'running' THEN 'placebet'
					WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 'void'
					ELSE NULL END status
			,RANK() OVER( ORDER BY  CASE WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 1
											 WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 2
											 WHEN b.ticketstatus = 'running' THEN 3
											 ELSE 99 --unknow
											 END 
									, CASE WHEN b.ticketstatus in ('won','lose','draw','refund','reject', 'void') then sq else 0 END desc ) as rn
		FROM dbo.bettrans_sabaplus_bet b
		WHERE b.ticketno = wallet_adjust_get.ticketno
	)

	SELECT SUM(b.actualstake)	 
			, SUM(b.payout)		 
			,b.status			
	INTO _old_actual_stake,  _old_payout, _old_status
	FROM cte_ticketinfo b
	WHERE b.rn = 1
	GROUP BY b.ticketno, b.rn, b.status;
	
	IF _doing = 'settle' THEN
		IF _old_status = 'settle' THEN	_adjust := _old_payout + payout;	END IF;	
		IF _old_status = 'running' THEN _adjust :=  _old_actual_stake - actualstake + payout;	END IF;	
	END IF;

	IF _doing = 'void' THEN
		IF _old_status = 'settle' THEN	_adjust := -(_old_payout - _old_actual_stake) ; END IF;	
		IF _old_status = 'running' THEN _adjust :=  -(_old_actual_stake);	END IF;
	END IF;
	
	RETURN _adjust;

END;
$BODY$;
