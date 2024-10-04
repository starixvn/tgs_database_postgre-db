/*
	Louisa: get running ticket after X minutes
	2024-09-07
*/

-- DROP FUNCTION dbo.bet_bettrans_sabaplus_running_get

CREATE OR REPLACE FUNCTION dbo.bet_bettrans_sabaplus_running_get
(
	 IN diff integer 
	 ,IN istest bit DEFAULT 0::BIT
)
returns table 
(   
	ticketno			character varying(200)
	,gameprovidercode	character varying(16)
	,externalgameid		character varying(50)
	,playercode			text
) 
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _start timestamp with time zone :=  CURRENT_TIMESTAMP - ( Diff *  INTERVAL  '24 hour' )  ;
			_end timestamp with time zone := CURRENT_TIMESTAMP - (Diff * INTERVAL '1 min')  ;
		
BEGIN
	RETURN QUERY
	 
	 SELECT DISTINCT r.External_round_id AS ticketno
			,b.gameprovidercode
			,b.externalgameid
			,r.player_code AS playercode
	FROM bet.rounds r
		JOIN dbo.bettrans_sabaplus_bet b
		ON r.external_round_id = b.TicketNo
		AND r.player_code = b.playercode
		AND b.ticketstatus = 'running' 
	WHERE r.external_created_on BETWEEN _start  AND _end
		AND r.client_status = 1
		AND ( istest = 0::BIT
				OR ( istest  = 1::BIT AND LOWER(b.gametype) = 'simulator' AND LOWER(b.ticketno) LIKE '%simulator%' )
			);

END;
$BODY$;

-- select dbo.bet_bettrans_sabaplus_running_get(2, 0::bit )




