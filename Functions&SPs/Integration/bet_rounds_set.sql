-- PROCEDURE: bet.bet_rounds_set(uuid, timestamp with time zone, character varying, uuid, text, integer, character varying, smallint, uuid, uuid, timestamp with time zone, timestamp with time zone, uuid, timestamp with time zone, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, numeric, smallint, numeric, timestamp with time zone, numeric, numeric, numeric, numeric, bigint, character varying, integer, text)

-- DROP PROCEDURE IF EXISTS bet.bet_rounds_set(uuid, timestamp with time zone, character varying, uuid, text, integer, character varying, smallint, uuid, uuid, timestamp with time zone, timestamp with time zone, uuid, timestamp with time zone, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, numeric, smallint, numeric, timestamp with time zone, numeric, numeric, numeric, numeric, bigint, character varying, integer, text);

CREATE OR REPLACE PROCEDURE bet.bet_rounds_set(
	IN id uuid DEFAULT NULL::uuid,
	IN created_on timestamp with time zone DEFAULT NULL,
	IN external_round_id character varying DEFAULT NULL::character varying,
	IN game_provider_id uuid DEFAULT NULL::uuid,
	IN player_code text DEFAULT NULL::text,
	IN game_id integer DEFAULT NULL::integer,
	IN currency_code character varying DEFAULT NULL::character varying,
	IN status smallint DEFAULT NULL::smallint,
	IN game_provider_configuration_id uuid DEFAULT NULL::uuid,
	IN wallet_id uuid DEFAULT NULL::uuid,
	IN closed_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN updated_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN brand_id uuid DEFAULT NULL::uuid,
	IN external_created_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN external_closed_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN bet_amount numeric DEFAULT NULL::numeric,
	IN valid_bet_amount numeric DEFAULT NULL::numeric,
	IN settle_amount numeric DEFAULT NULL::numeric,
	IN commission numeric DEFAULT NULL::numeric,
	IN turnover numeric DEFAULT NULL::numeric,
	IN win_loss numeric DEFAULT 0,
	IN tie_bet_adjustment numeric DEFAULT NULL::numeric,
	IN client_status smallint DEFAULT NULL::smallint,
	IN reopen_turnover_adjustment numeric DEFAULT NULL::numeric,
	IN reopened_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN effective_betting_percentage numeric DEFAULT NULL::numeric,
	IN payout numeric DEFAULT 0,
	IN bet_type integer DEFAULT NULL::integer,
	IN licenseetxid bigint DEFAULT NULL::bigint,
	IN actiontype character varying DEFAULT NULL::character varying,
	INOUT StatusCode character varying DEFAULT '0'::character varying,
	INOUT errmsg text DEFAULT ''::text)
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE p_bet_amount numeric;
			p_valid_bet_amount numeric;
			p_actual_bet_amount numeric;
			p_bet_type integer;
BEGIN
	IF actiontype IN ('ConfirmBet', 'ConfirmBetParlay')
	THEN
		IF EXISTS (
			SELECT 1 
			FROM bet.rounds br 
			WHERE br.external_created_on = bet_rounds_set.external_created_on
				AND br.external_round_id = bet_rounds_set.external_round_id
				AND br.game_provider_id = bet_rounds_set.game_provider_id
				AND br.game_id = bet_rounds_set.game_id
		) 
		THEN 
			statuscode := '101';
			errmsg := 'Duplicate Transaction';
			RETURN;
		ELSE
			SELECT b.betamount, b.betamount, b.bettype
			INTO p_bet_amount, p_valid_bet_amount, p_bet_type
			FROM dbo.bettrans_sbsw_bet b
			WHERE b.licenseeTxid = bet_rounds_set.licenseeTxid AND b.txid = CAST(bet_rounds_set.external_round_id AS BIGINT);
			
			INSERT INTO bet.rounds (
			id,
			created_on,
			external_round_id,
			game_provider_id,
			player_code,
			game_id,
			currency_code,
			status,
			game_provider_configuration_id,
			wallet_id,
			closed_on,
			updated_on,
			brand_id,
			external_created_on,
			external_closed_on,
			bet_amount,
			valid_bet_amount,
			settle_amount,
			commission,
			turnover,
			win_loss,
			tie_bet_adjustment,
			client_status,
			reopen_turnover_adjustment,
			reopened_on,
			effective_betting_percentage,
			bet_type
			)
			VALUES (
				id,
				current_timestamp ,
				external_round_id ,
				game_provider_id,
				player_code,
				game_id,
				currency_code,
				1 , --Open
				game_provider_configuration_id,
				wallet_id,
				NULL ,
				current_timestamp,
				brand_id,
				external_created_on,
				NULL ,
				p_bet_amount ,
				p_valid_bet_amount ,
				0 ,
				0 ,
				0 ,
				0 ,
				NULL,
				0 ,
				0 ,
				NULL ,
				NULL ,
				p_bet_type 
			);
		END IF;
	ELSIF actiontype IN ('Settle', 'Unsettle', 'Resettle') THEN 
		IF NOT EXISTS (SELECT 1 FROM bet.rounds br WHERE br.id = bet_rounds_set.id) THEN
			statuscode := '102';
			errmsg := 'No Data';
			RETURN;
		ELSE
			SELECT br.bet_amount, br.actual_bet_amount
			INTO p_bet_amount, p_actual_bet_amount
			FROM bet.rounds br
			WHERE br.id = bet_rounds_set.id;
			
			UPDATE bet.rounds br
			SET status = bet_rounds_set.status,
				external_closed_on = bet_rounds_set.external_closed_on,
				settle_amount = p_bet_amount + (bet_rounds_set.payout - p_actual_bet_amount),
				win_loss = -(bet_rounds_set.payout - p_actual_bet_amount),
				client_status = bet_rounds_set.client_status,
				closed_on = bet_rounds_set.closed_on
			WHERE br.id = bet_rounds_set.id;
		END IF;
	END IF;
END;
$BODY$;