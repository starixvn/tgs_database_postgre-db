-- PROCEDURE: dbo.bet_bettrans_sbsw_get_ticketinfo(character varying, character varying, character varying, numeric, numeric)

-- DROP PROCEDURE IF EXISTS dbo.bet_bettrans_sbsw_get_ticketinfo(character varying, character varying, character varying, numeric, numeric);

CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_get_ticketinfo(
	IN userid character varying DEFAULT NULL::character varying,
	IN refid character varying DEFAULT NULL::character varying,
	INOUT ticketstatus character varying DEFAULT NULL::character varying,
	INOUT actualstake numeric DEFAULT NULL::numeric,
	INOUT winlostamount numeric DEFAULT NULL::numeric)
LANGUAGE 'plpgsql'
AS $BODY$
begin
	select betAmount
		,actualAmount
		,case action when 'PlaceBet' then 'waiting'
					when 'ConfirmBet' then 'running'
					when 'CancelBet' then 'cancelled' 
					else '' end as ticketstatus
	into actualstake, winlostamount, ticketstatus
	from dbo.bettrans_sbsw_bet as sbsw
	where sbsw.userid = Bet_Bettrans_SBSW_Get_TicketInfo.userid and sbsw.refid =  Bet_Bettrans_SBSW_Get_TicketInfo.refid;

	if exists (
		select 1 from dbo.bettrans_sbsw_settle as sbsw 
		where sbsw.userid = Bet_Bettrans_SBSW_Get_TicketInfo.userid and sbsw.refid = Bet_Bettrans_SBSW_Get_TicketInfo.refid
	) then
		select sbsw.status
		into ticketstatus
		from dbo.bettrans_sbsw_settle as sbsw
		where sbsw.userid = Bet_Bettrans_SBSW_Get_TicketInfo.userid and sbsw.refid = Bet_Bettrans_SBSW_Get_TicketInfo.refid
		order by updatetime desc
		limit 1;
	end if;
end;
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_get_ticketinfo(character varying, character varying, character varying, numeric, numeric)
    OWNER TO postgres;
