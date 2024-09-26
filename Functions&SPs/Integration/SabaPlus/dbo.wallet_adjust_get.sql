/*
	Louisa: get running ticket after X minutes
	2024-09-23
*/

-- DROP PROCEDURE dbo.wallet_sabaplus_adjust_get
CREATE OR REPLACE FUNCTION dbo.wallet_sabaplus_adjust_get
(
	  IN ticketno		character varying
	  ,IN groupaction	character varying
	  ,IN actualstake	numeric DEFAULT 0.0
	  ,IN payout		numeric DEFAULT 0.0
)
/*
	Param's explaination: 
		doing: settle ( for action won/lose/draw)
				void ( for action void/refund/reject)
*/
RETURNS numeric 
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _old_actual_stake	numeric(20,6);
			_old_payout			numeric(20,6);
			_old_status			character varying(10);
			_adjust				numeric(18,6);
BEGIN
	---need to add case send running

	WITH cte_ticketinfo AS
	(	SELECT b.ticketno, b.actualstake , b.payout
			, CASE WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 'settle'
					WHEN b.ticketstatus = 'running' THEN b.ticketstatus
					WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 'void'
					ELSE NULL END status  --unknow
			,RANK() OVER( ORDER BY  CASE WHEN b.ticketstatus IN ('refund','reject', 'void') THEN 1
											 WHEN b.ticketstatus IN ( 'won','lose','draw') THEN 2
											 WHEN b.ticketstatus = 'running' THEN 3
											 ELSE 99 --unknow
											 END 
									, CASE WHEN b.ticketstatus in ('won','lose','draw','refund','reject', 'void') then sq else 0 END desc ) as rn
		FROM dbo.bettrans_sabaplus_bet b
		WHERE b.ticketno = wallet_sabaplus_adjust_get.ticketno
	)

	SELECT SUM(b.actualstake)	 
			, SUM(b.payout)		 
			,b.status			
	INTO _old_actual_stake,  _old_payout, _old_status
	FROM cte_ticketinfo b
	WHERE b.rn = 1
	GROUP BY b.ticketno, b.rn, b.status;
	
	IF groupaction = 'settle' THEN
		IF _old_status = 'settle' THEN	_adjust := (- _old_payout  + payout) + ( _old_actual_stake - actualstake) ;	END IF;	 ---resettle
		IF _old_status = 'running' THEN _adjust := (_old_actual_stake - actualstake ) + payout;	END IF;	--settle
	END IF;

	IF groupaction = 'void' THEN
		IF _old_status = 'settle' THEN	_adjust := -(_old_payout - _old_actual_stake)  ; END IF;	---void/refund/reject settle
		IF _old_status = 'running' THEN _adjust :=  _old_actual_stake;	END IF; ---	---void/refund/reject  running
	END IF;
	
	RETURN CASE WHEN _adjust IS NULL THEN 0 ELSE _adjust END ;

END;
$BODY$;

/*
 select   dbo.wallet_sabaplus_adjust_get
(
		ticketno		 => 'Louisa_5402|$|4uo2mwf6dow8_test|$|5402_30429807'
	  , doing			 =>	 'settle'
	  , stake			 => 2.0
	  , actualstake		 => 2.0
	  , netstake		 => 2.0
	  , payout			 => 26.0
)
*/
