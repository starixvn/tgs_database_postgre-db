-- PROCEDURE: bet.bet_rounds_set(uuid, character varying, uuid, text, integer, character varying, character varying, uuid, bigint, uuid, character varying, uuid, timestamp with time zone, timestamp with time zone, numeric, character varying, boolean, character varying, character varying, text)

-- DROP PROCEDURE IF EXISTS bet.bet_rounds_set(uuid, character varying, uuid, text, integer, character varying, character varying, uuid, bigint, uuid, character varying, uuid, timestamp with time zone, timestamp with time zone, numeric, character varying, boolean, character varying, character varying, text);

CREATE OR REPLACE PROCEDURE bet.bet_rounds_set(
	IN id uuid DEFAULT NULL::uuid,
	IN external_round_id character varying DEFAULT NULL::character varying,
	IN game_provider_id uuid DEFAULT NULL::uuid,
	IN player_code text DEFAULT NULL::text,
	IN game_id integer DEFAULT NULL::integer,
	IN currency_code character varying DEFAULT NULL::character varying,
	IN status character varying DEFAULT NULL::character varying,
	IN game_provider_configuration_id uuid DEFAULT NULL::uuid,
	IN licenseetxid bigint DEFAULT NULL::bigint,
	IN wallet_id uuid DEFAULT NULL::uuid,
	IN refid character varying DEFAULT NULL::character varying,
	IN brand_id uuid DEFAULT NULL::uuid,
	IN external_created_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN external_closed_on timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN payout numeric DEFAULT 0,
	IN extrastatus character varying DEFAULT NULL::character varying,
	IN isonlywinlostdatechanged boolean DEFAULT NULL::boolean,
	IN actiontype character varying DEFAULT NULL::character varying,
	INOUT statuscode character varying DEFAULT '0'::character varying,
	INOUT errmsg text DEFAULT ''::text)
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE p_bet_amount numeric;
			p_valid_bet_amount numeric;
			p_actual_bet_amount numeric;
			p_bet_type integer;
			p_is_cash_out boolean; 
			p_effective_betting_percentage numeric;
			p_client_status smallint;
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
			WHERE b.licenseeTxid = bet_rounds_set.licenseeTxid AND CAST(b.txid AS character varying) = bet_rounds_set.external_round_id;
			
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
	ELSIF actiontype = 'Settle' THEN 
		IF NOT EXISTS (SELECT 1 
						FROM bet.rounds br 
						WHERE br.external_round_id = bet_rounds_set.external_round_id 
							AND br.brand_id = bet_rounds_set.brand_id
							AND br.game_id = bet_rounds_set.game_id
							AND br.status = 1) 
		THEN
			statuscode := '102';
			errmsg := 'No Data';
			RETURN;
		ELSE
			SELECT CASE 
					WHEN COALESCE(extrastatus, '') = '' OR extrastatus ilike 'void cashout' THEN false ELSE true 
				END
			INTO p_is_cash_out;
		
			SELECT b.betamount, b.actualamount
			INTO p_bet_amount, p_actual_bet_amount
			FROM dbo.Bettrans_SBSW_Bet b
			WHERE b.refid = bet_rounds_set.refid AND CAST(b.txid AS character varying) = bet_rounds_set.external_round_id;
			
			SELECT bg.effective_betting_percentage
			INTO p_effective_betting_percentage
			FROM dbo.brand_games bg
			WHERE bg.brand_id = bet_rounds_set.brand_id AND bg.game_id = bet_rounds_set.game_id;
			
			UPDATE bet.rounds br
			SET status = 2,
				closed_on = current_timestamp,
				updated_on = current_timestamp,
				external_closed_on = bet_rounds_set.external_closed_on,
				valid_bet_amount = CASE 
										WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') OR p_is_cash_out = true THEN 0
										ELSE p_bet_amount
									END,
				settle_amount = bet_rounds_set.payout,
				turnover = CASE 
								WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') OR p_is_cash_out = true THEN 0
								ELSE p_bet_amount
							END,
				win_loss = bet_rounds_set.payout - p_actual_bet_amount,
				client_status = CASE 
									WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') THEN 2
									WHEN bet_rounds_set.status IN ('won', 'half won') THEN 3
									WHEN bet_rounds_set.status IN ('lose', 'half lose') THEN 4
									WHEN bet_rounds_set.status IN ('draw') THEN 5
									ELSE br.client_status END,
				effective_betting_percentage = p_effective_betting_percentage 	
			WHERE br.external_round_id = bet_rounds_set.external_round_id 
				AND br.brand_id = bet_rounds_set.brand_id
				AND br.game_id = bet_rounds_set.game_id;
		END IF;
	ELSIF actiontype = 'Resettle' THEN 
		IF NOT EXISTS (SELECT 1 
						FROM bet.rounds br 
						WHERE br.external_round_id = bet_rounds_set.external_round_id 
							AND br.brand_id = bet_rounds_set.brand_id
							AND br.game_id = bet_rounds_set.game_id 
							AND br.status = 2) 
		THEN
			statuscode := '102';
			errmsg := 'No Data';
			RETURN;
		ELSE
			SELECT CASE 
					WHEN COALESCE(extrastatus, '') = '' OR extrastatus ilike 'void cashout' THEN false ELSE true 
				END,
				CASE 
					WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') THEN 2
					WHEN bet_rounds_set.status IN ('won', 'half won') THEN 3
					WHEN bet_rounds_set.status IN ('lose', 'half lose') THEN 4
					WHEN bet_rounds_set.status IN ('draw') THEN 5
				END
			INTO p_is_cash_out, p_client_status;
		
			SELECT b.betamount, b.actualamount
			INTO p_bet_amount, p_actual_bet_amount
			FROM dbo.Bettrans_SBSW_Bet b
			WHERE b.refid = bet_rounds_set.refid AND CAST(b.txid AS character varying) = bet_rounds_set.external_round_id;
			
			SELECT bg.effective_betting_percentage
			INTO p_effective_betting_percentage
			FROM dbo.brand_games bg
			WHERE bg.brand_id = bet_rounds_set.brand_id AND bg.game_id = bet_rounds_set.game_id;
			
			UPDATE bet.rounds br
			SET status = CASE 
							WHEN isOnlyWinlostDateChanged = true THEN br.status
							ELSE 2
						END,
				updated_on = current_timestamp,
				external_closed_on = bet_rounds_set.external_closed_on,
				valid_bet_amount = CASE 
										WHEN isOnlyWinlostDateChanged = true THEN br.valid_bet_amount
										WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') OR p_is_cash_out = true THEN 0
										ELSE p_bet_amount
									END,
				settle_amount = CASE 
									WHEN isOnlyWinlostDateChanged = true THEN br.settle_amount
									ELSE bet_rounds_set.payout
								END,
				turnover = CASE 
								WHEN isOnlyWinlostDateChanged = true THEN br.turnover
								WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') OR p_is_cash_out = true THEN 0
								ELSE p_bet_amount
							END,
				win_loss = CASE 
								WHEN isOnlyWinlostDateChanged = true THEN br.win_loss
								ELSE bet_rounds_set.payout - p_actual_bet_amount
							END,
				client_status = CASE 
									WHEN isOnlyWinlostDateChanged = true THEN br.client_status
									WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') THEN 2
									WHEN bet_rounds_set.status IN ('won', 'half won') THEN 3
									WHEN bet_rounds_set.status IN ('lose', 'half lose') THEN 4
									WHEN bet_rounds_set.status IN ('draw') THEN 5
									ELSE br.client_status 
								END,
				reopen_turnover_adjustment = CASE 
												WHEN isOnlyWinlostDateChanged = true THEN br.reopen_turnover_adjustment
												WHEN br.settle_amount != bet_rounds_set.payout OR br.client_status != p_client_status THEN br.turnover
												ELSE br.reopen_turnover_adjustment
											END,
				reopened_on = CASE 
								WHEN isOnlyWinlostDateChanged = true THEN br.reopened_on
								WHEN br.settle_amount != bet_rounds_set.payout OR br.client_status != p_client_status THEN current_timestamp
								ELSE br.reopened_on
							END,
				effective_betting_percentage = CASE 
													WHEN isOnlyWinlostDateChanged = true THEN br.effective_betting_percentage
													ELSE p_effective_betting_percentage
												END
			WHERE br.external_round_id = bet_rounds_set.external_round_id 
				AND br.brand_id = bet_rounds_set.brand_id
				AND br.game_id = bet_rounds_set.game_id;	
		END IF;
	ELSIF actiontype = 'Unsettle' THEN 
		IF NOT EXISTS (SELECT 1 
						FROM bet.rounds br 
						WHERE br.external_round_id = bet_rounds_set.external_round_id 
							AND br.brand_id = bet_rounds_set.brand_id
							AND br.game_id = bet_rounds_set.game_id 
							AND br.status = 2) 
		THEN
			statuscode := '102';
			errmsg := 'No Data';
			RETURN;
		ELSE
			SELECT CASE 
					WHEN COALESCE(extrastatus, '') = '' OR extrastatus ilike 'void cashout' THEN false ELSE true 
				END
			INTO p_is_cash_out;
			
			SELECT b.betamount, b.actualamount
			INTO p_bet_amount, p_actual_bet_amount
			FROM dbo.Bettrans_SBSW_Bet b
			WHERE b.refid = bet_rounds_set.refid AND CAST(b.txid AS character varying) = bet_rounds_set.external_round_id;
			
			SELECT bg.effective_betting_percentage
			INTO p_effective_betting_percentage
			FROM dbo.brand_games bg
			WHERE bg.brand_id = bet_rounds_set.brand_id AND bg.game_id = bet_rounds_set.game_id;	
			
			UPDATE bet.rounds br
			SET status = 1,
				updated_on = current_timestamp,
				valid_bet_amount = CASE 
										WHEN bet_rounds_set.status IN ('void', 'reject', 'refund') OR p_is_cash_out = true THEN 0
										ELSE p_bet_amount
									END,
				settle_amount = 0,
				turnover = 0,
				win_loss = 0,
				client_status = 0,
				effective_betting_percentage = null
			WHERE br.external_round_id = bet_rounds_set.external_round_id 
				AND br.brand_id = bet_rounds_set.brand_id
				AND br.game_id = bet_rounds_set.game_id;
		END IF;
	END IF;
END;
$BODY$;
ALTER PROCEDURE bet.bet_rounds_set(uuid, character varying, uuid, text, integer, character varying, character varying, uuid, bigint, uuid, character varying, uuid, timestamp with time zone, timestamp with time zone, numeric, character varying, boolean, character varying, character varying, text)
    OWNER TO postgres;
