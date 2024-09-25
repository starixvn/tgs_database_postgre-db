/*
	Louisa: get running ticket after X minutes
	2024-09-07
*/

-- DROP FUNCTION dbo.bet_bettrans_sabaplus_running_get

CREATE OR REPLACE FUNCTION dbo.bet_bettrans_sabaplus_running_get
(
	 Diff integer 
)
returns table 
(   
	ticketno			character varying(200)
	,gameprovidercode	character varying(16)
	,externalgameid		character varying(50)
	,playercode			character varying(16)
) 
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _start timestamp with time zone :=  CURRENT_TIMESTAMP - ( Diff *  INTERVAL  '24 hour' )  ;
			_end timestamp with time zone := CURRENT_TIMESTAMP - (Diff * INTERVAL '1 min')  ;
		
BEGIN
	RETURN QUERY
	 
	WITH cte_running AS
	(	SELECT b2.TicketNo
			,b.gameprovidercode
			,b.externalgameid
			,b.playercode
	FROM dbo.bettrans_sabaplus_bet b
		JOIN (	SELECT b2.TicketNo , MAX(b2.CreateTime) AS mx_CreateTime 
				FROM dbo.bettrans_sabaplus_bet b2 
				GROUP BY b2.TicketNo 
				) b2
		ON b.TicketNo = b2.TicketNo		
		AND b.CreateTime = mx_CreateTime
	WHERE b.transdate BETWEEN _start AND _end
		AND b.ticketno NOT LIKE '%simulator_%'
		AND b.ticketstatus = 'running'
	)

	SELECT b.ticketno
			,b.gameprovidercode
			,b.externalgameid
			,b.playercode
	FROM cte_running b;

END;
$BODY$;

ALTER FUNCTION dbo.bet_bettrans_sabaplus_running_get(integer)
 OWNER TO postgres;
  