-- PROCEDURE: dbo.game_bets_set(uuid, integer, uuid, character varying, timestamp with time zone, uuid, uuid, uuid, uuid, uuid, text, character varying, character varying, timestamp with time zone, timestamp with time zone, timestamp with time zone, integer, integer, integer, integer, integer, integer, integer, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, timestamp with time zone, timestamp with time zone, timestamp with time zone, integer, timestamp with time zone, jsonb, numeric, character varying)

-- DROP PROCEDURE IF EXISTS dbo.game_bets_set(uuid, integer, uuid, character varying, timestamp with time zone, uuid, uuid, uuid, uuid, uuid, text, character varying, character varying, timestamp with time zone, timestamp with time zone, timestamp with time zone, integer, integer, integer, integer, integer, integer, integer, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, timestamp with time zone, timestamp with time zone, timestamp with time zone, integer, timestamp with time zone, jsonb, numeric, character varying);

CREATE OR REPLACE PROCEDURE dbo.game_bets_set(
	IN game_provider_id uuid DEFAULT NULL::uuid,
	IN game_id integer DEFAULT NULL::integer,
	IN wallet_id uuid DEFAULT NULL::uuid,
	IN external_bet_id character varying DEFAULT NULL::character varying,
	IN external_created_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN id uuid DEFAULT NULL::uuid,
	IN game_provider_configuration_id uuid DEFAULT NULL::uuid,
	IN reseller_id uuid DEFAULT NULL::uuid,
	IN licensee_id uuid DEFAULT NULL::uuid,
	IN brand_id uuid DEFAULT NULL::uuid,
	IN player_code text DEFAULT NULL::text,
	IN currency_code character varying DEFAULT NULL::character varying,
	IN external_round_id character varying DEFAULT NULL::character varying,
	IN external_closed_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN external_payoff_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN external_resettle_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN bet_state integer DEFAULT NULL::integer,
	IN bet_type integer DEFAULT NULL::integer,
	IN free_game_state integer DEFAULT NULL::integer,
	IN gamble_state integer DEFAULT NULL::integer,
	IN cashout_state integer DEFAULT NULL::integer,
	IN resettle_state integer DEFAULT NULL::integer,
	IN jackpot_state integer DEFAULT NULL::integer,
	IN currency_ratio numeric DEFAULT NULL::numeric,
	IN bet numeric DEFAULT NULL::numeric,
	IN valid_bet numeric DEFAULT NULL::numeric,
	IN settle numeric DEFAULT NULL::numeric,
	IN commission numeric DEFAULT NULL::numeric,
	IN turnover numeric DEFAULT NULL::numeric,
	IN payout numeric DEFAULT NULL::numeric,
	IN jackpot numeric DEFAULT NULL::numeric,
	IN created_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN closed_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN updated_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN reset_state integer DEFAULT NULL::integer,
	IN reset_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN additional_data jsonb DEFAULT '{}'::jsonb,
	IN actual_bet numeric DEFAULT 0,
	IN actiontype character varying DEFAULT NULL::character varying)
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE p_bet numeric;
			p_actual_bet numeric;
BEGIN
	IF actiontype IN ('ConfirmBet', 'ConfirmBetParlay') THEN 
		INSERT INTO dbo.game_bets(
			game_provider_id,
			game_id,
			wallet_id,
			external_bet_id,
			external_created_on,
			id,
			game_provider_configuration_id,
			reseller_id,
			licensee_id,
			brand_id,
			player_code,
			currency_code,
			external_round_id,
			external_closed_on,
			external_payoff_on,
			external_resettle_on,
			bet_state,
			bet_type,
			free_game_state	,
			gamble_state,
			cashout_state,
			resettle_state,
			jackpot_state,
			currency_ratio,
			bet,
			valid_bet,
			settle,
			commission,
			turnover,
			win_loss,
			jackpot,
			created_on,
			closed_on,
			updated_on,
			reset_state,
			reset_on,
			additional_data,
			actual_bet
		)
	VALUES
	(
			game_provider_id,
			game_id,
			wallet_id,
			external_bet_id,
			external_created_on,
			id,
			game_provider_configuration_id,
			reseller_id,
			licensee_id,
			brand_id,
			player_code,
			currency_code,
			external_round_id,
			external_closed_on,
			external_payoff_on,
			external_resettle_on,
			bet_state,
			bet_type,
			free_game_state	,
			gamble_state,
			cashout_state,
			resettle_state,
			jackpot_state,
			currency_ratio,
			bet,
			valid_bet,
			settle,
			commission,
			turnover,
			payout,
			jackpot,
			created_on,
			closed_on,
			updated_on,
			reset_state,
			reset_on,
			additional_data,
			actual_bet
	);
	ELSIF ActionType IN ('Settle', 'Unsettle', 'Resettle') THEN
		SELECT gb.bet, gb.actual_bet
		INTO p_bet, p_actual_bet
		FROM dbo.game_bets gb
		WHERE gb.game_provider_id = game_bets_set.game_provider_id
			AND	gb.game_id = game_bets_set.game_id
			AND	gb.wallet_id = game_bets_set.wallet_id
			AND	gb.external_bet_id = game_bets_set.external_bet_id;
		
		UPDATE dbo.game_bets gb
		SET external_closed_on = game_bets_set.external_closed_on,
			external_payoff_on = game_bets_set.external_payoff_on,
			bet_state = game_bets_set.bet_state,
			cashout_state = game_bets_set.cashout_state,
			settle = p_bet + (game_bets_set.payout - p_actual_bet),
			win_loss = -(game_bets_set.payout - p_actual_bet)
		WHERE gb.game_provider_id = game_bets_set.game_provider_id
			AND	gb.game_id = game_bets_set.game_id
			AND	gb.wallet_id = game_bets_set.wallet_id
			AND	gb.external_bet_id = game_bets_set.external_bet_id;
	END IF;
END;
$BODY$;
ALTER PROCEDURE dbo.game_bets_set(uuid, integer, uuid, character varying, timestamp with time zone, uuid, uuid, uuid, uuid, uuid, text, character varying, character varying, timestamp with time zone, timestamp with time zone, timestamp with time zone, integer, integer, integer, integer, integer, integer, integer, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, timestamp with time zone, timestamp with time zone, timestamp with time zone, integer, timestamp with time zone, jsonb, numeric, character varying)
    OWNER TO postgres;
