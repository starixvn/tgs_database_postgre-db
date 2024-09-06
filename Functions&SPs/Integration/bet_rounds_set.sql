-- PROCEDURE: bet.bet_rounds_set(uuid, timestamp with time zone, character varying, uuid, text, integer, character varying, smallint, uuid, uuid, timestamp with time zone, timestamp with time zone, uuid, timestamp with time zone, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, numeric, smallint, numeric, timestamp with time zone, numeric, numeric, numeric, numeric, bigint, character varying, integer, text)

-- DROP PROCEDURE IF EXISTS bet.bet_rounds_set(uuid, timestamp with time zone, character varying, uuid, text, integer, character varying, smallint, uuid, uuid, timestamp with time zone, timestamp with time zone, uuid, timestamp with time zone, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, numeric, smallint, numeric, timestamp with time zone, numeric, numeric, numeric, numeric, bigint, character varying, integer, text);

CREATE OR REPLACE PROCEDURE bet.bet_rounds_set(
	IN id uuid DEFAULT NULL::uuid,
	IN created_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
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
	IN tie_bet_adjustment numeric DEFAULT NULL::numeric,
	IN client_status smallint DEFAULT NULL::smallint,
	IN reopen_turnover_adjustment numeric DEFAULT NULL::numeric,
	IN reopened_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN effective_betting_percentage numeric DEFAULT NULL::numeric,
	IN actual_bet_amount numeric DEFAULT 0,
	IN payout numeric DEFAULT 0,
	IN bet_type numeric DEFAULT NULL::numeric,
	IN licenseetxid bigint DEFAULT NULL::bigint,
	IN actiontype character varying DEFAULT NULL::character varying,
	INOUT errcode integer DEFAULT 0,
	INOUT errmsg text DEFAULT ''::text)
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE p_bet_amount numeric;
			p_actual_bet_amount numeric;
			p_round_exist boolean;
			p_round_exist_and_open boolean;
			p_round_update boolean;
			p_status smallint;
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
	) THEN 
			errcode := 101;
			errmsg := 'Duplicate Transaction';
			RETURN;
		ELSE
			SELECT b.betamount
			INTO p_bet_amount
			FROM dbo.bettrans_sbsw_bet b
			WHERE b.licenseeTxid = bet_rounds_set.licenseeTxid AND b.txid = bet_rounds_set.external_round_id::bigint;
			
			INSERT INTO bet.rounds (
			id,
			created_on,
			external_round_id ,
			game_provider_id ,
			player_code ,
			game_id ,
			currency_code ,
			status ,
			game_provider_configuration_id ,
			wallet_id ,
			closed_on ,
			updated_on ,
			brand_id ,
			external_created_on,
			external_closed_on ,
			bet_amount ,
			valid_bet_amount ,
			settle_amount ,
			commission	,
			turnover,
			win_loss,
			tie_bet_adjustment,
			client_status,
			reopen_turnover_adjustment,
			reopened_on	,
			effective_betting_percentage,
			actual_bet_amount,
			bet_type
			)
			VALUES (
				id,
				created_on,
				external_round_id ,
				game_provider_id ,
				player_code ,
				game_id ,
				currency_code ,
				status ,
				game_provider_configuration_id ,
				wallet_id ,
				closed_on ,
				updated_on ,
				brand_id ,
				external_created_on,
				external_closed_on ,
				p_bet_amount ,
				valid_bet_amount ,
				settle_amount ,
				commission	,
				turnover,
				payout,
				tie_bet_adjustment,
				client_status,
				reopen_turnover_adjustment,
				reopened_on	,
				effective_betting_percentage,
				actual_bet_amount,
				bet_type
			);
		END IF;
	ELSIF actiontype IN ('Settle', 'Unsettle', 'Resettle') THEN 
		IF NOT EXISTS (SELECT 1 FROM bet.rounds br WHERE br.id = bet_rounds_set.id) THEN
			errcode := 102;
			errmsg := 'No Data';
			RETURN;
		ELSE
			SELECT br.bet_amount, 
					br.actual_bet_amount,
					CASE WHEN br.id IS NOT NULL 
						THEN true 
						ELSE false 
					END AS round_exist,
					CASE WHEN br.id IS NOT NULL AND br.status = 1 --Open
						THEN true
						ELSE false
					END AS round_exist_and_open,
					CASE WHEN bet_rounds_set.bet_amount != br.bet_amount 
							OR  bet_rounds_set.valid_bet_amount != br.valid_bet_amount 
							OR  bet_rounds_set.settle_amount != br.settle_amount
							OR  bet_rounds_set.commission != br.commission 
							OR  bet_rounds_set.turnover != br.turnover  
							OR bet_rounds_set.payout !=  br.win_loss   
							OR bet_rounds_set.client_status != br.client_status 
						THEN true
						ELSE false
					END AS round_update,
					br.status
			INTO p_bet_amount, 
				p_actual_bet_amount,
				p_round_exist,
				p_round_exist_and_open,
				p_round_update,
				p_status
			FROM bet.rounds br
			WHERE br.id = bet_rounds_set.id;

			IF p_round_exist = true AND p_status = 1 AND bet_rounds_set.status != p_status
			THEN 
				UPDATE bet.rounds br
				SET closed_on = current_timestamp --UTCNow
				WHERE br.id = bet_rounds_set.id;
			END IF;

			IF p_round_update = true AND p_round_exist = true AND p_status = 2 AND bet_rounds_set.status = p_status
			THEN
				UPDATE bet.rounds br
				SET tie_bet_adjustment = 0,
					reopen_turnover_adjustment = COALESCE(br.turnover, 0),
					reopened_on = current_timestamp
				WHERE br.id = bet_rounds_set.id;
			END IF;

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
ALTER PROCEDURE bet.bet_rounds_set(uuid, timestamp with time zone, character varying, uuid, text, integer, character varying, smallint, uuid, uuid, timestamp with time zone, timestamp with time zone, uuid, timestamp with time zone, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, numeric, smallint, numeric, timestamp with time zone, numeric, numeric, numeric, numeric, bigint, character varying, integer, text)
    OWNER TO postgres;
