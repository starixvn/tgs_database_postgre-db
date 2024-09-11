/*
	Louisa: get running ticket after X minutes
	2024-09-07
*/

-- DROP FUNCTION dbo.bet_bettrans_running_select

CREATE OR REPLACE FUNCTION dbo.bet_bettrans_running_select
(
	 Diff integer
)
returns table 
(   sq bigint
	,gametype character varying 	
	,operatorcustid character varying
	,ticketno character varying
	,AgentId uuid
	,AgentKey character varying
	,AgentCode character varying
	,ExtraInfo  character varying
) 
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	RETURN QUERY
		SELECT  b.sq  
			,b.GameType 
			,b.OperatorCustId 
			,b.TicketNo 
			,pl.Agent_Id AS AgentId
			,''::character varying AS AgentKey
			,''::character varying AS AgentCode
			,b.ExtraInfo
	FROM dbo.Bettrans_SabaPlus_Bet AS b
	INNER JOIN dbo.Players AS pl
		ON b.operatorcustid = pl.player_code
	LEFT JOIN dbo.Bettrans_SabaPlus_Settle 
		ON b.TicketNo = Bettrans_SabaPlus_Settle.TicketNo
	WHERE b.SourceName = 'SabaPlus_PlaceBet'
	--	AND Bettrans_SabaPlus_Settle.TicketNo IS NULL
		AND  (select extract(min from CURRENT_TIMESTAMP  - b.CreateTime::timestamp) )>= Diff;

END;
$BODY$;

ALTER FUNCTION dbo.bet_bettrans_running_select(integer)
 OWNER TO postgres;
 
SELECT * FROM dbo.bet_bettrans_running_select(1);