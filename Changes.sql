--Change 01
CREATE OR REPLACE PROCEDURE bet.bet_rounds_set_xtest(
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
			WHERE br.external_created_on = bet_rounds_set_xtest.external_created_on
				AND br.external_round_id = bet_rounds_set_xtest.external_round_id
				AND br.game_provider_id = bet_rounds_set_xtest.game_provider_id
				AND br.game_id = bet_rounds_set_xtest.game_id
	) THEN 
			errcode := 101;
			errmsg := 'Duplicate Transaction';
			RETURN;
		ELSE
			SELECT b.betamount
			INTO p_bet_amount
			FROM dbo.bettrans_sbsw_bet b
			WHERE b.licenseeTxid = bet_rounds_set_xtest.licenseeTxid AND b.txid = bet_rounds_set_xtest.external_round_id::bigint;
			
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
				p_bet_amount,
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
		IF NOT EXISTS (SELECT 1 FROM bet.rounds br WHERE br.id = bet_rounds_set_xtest.id) THEN
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
					CASE WHEN bet_rounds_set_xtest.bet_amount != br.bet_amount 
							OR  bet_rounds_set_xtest.valid_bet_amount != br.valid_bet_amount 
							OR  bet_rounds_set_xtest.settle_amount != br.settle_amount
							OR  bet_rounds_set_xtest.commission != br.commission 
							OR  bet_rounds_set_xtest.turnover != br.turnover  
							OR bet_rounds_set_xtest.payout !=  br.win_loss   
							OR bet_rounds_set_xtest.client_status != br.client_status 
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
			WHERE br.id = bet_rounds_set_xtest.id;

			IF p_round_exist = true AND p_status = 1 AND bet_rounds_set_xtest.status != p_status
			THEN 
				UPDATE bet.rounds br
				SET closed_on = current_timestamp --UTCNow
				WHERE br.id = bet_rounds_set_xtest.id;
			END IF;

			IF p_round_update = true AND p_round_exist = true AND p_status = 2 AND bet_rounds_set_xtest.status = p_status
			THEN
				UPDATE bet.rounds br
				SET tie_bet_adjustment = 0,
					reopen_turnover_adjustment = COALESCE(br.turnover, 0),
					reopened_on = current_timestamp
				WHERE br.id = bet_rounds_set_xtest.id;
			END IF;

			UPDATE bet.rounds br
			SET status = bet_rounds_set_xtest.status,
				external_closed_on = bet_rounds_set_xtest.external_closed_on,
				settle_amount = p_bet_amount + (bet_rounds_set_xtest.payout - p_actual_bet_amount),
				win_loss = -(bet_rounds_set_xtest.payout - p_actual_bet_amount),
				client_status = bet_rounds_set_xtest.client_status,
				closed_on = bet_rounds_set_xtest.closed_on
			WHERE br.id = bet_rounds_set_xtest.id;
		END IF;
	END IF;
END;
$BODY$;
ALTER PROCEDURE bet.bet_rounds_set_xtest(uuid, timestamp with time zone, character varying, uuid, text, integer, character varying, smallint, uuid, uuid, timestamp with time zone, timestamp with time zone, uuid, timestamp with time zone, timestamp with time zone, numeric, numeric, numeric, numeric, numeric, numeric, smallint, numeric, timestamp with time zone, numeric, numeric, numeric, numeric, bigint, character varying, integer, text)
    OWNER TO postgres;

--Change 02:
CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_bet_xtest(
	IN action character varying,
	IN operationid character varying,
	IN userid character varying,
	IN currency integer,
	IN matchid integer,
	IN homeid integer,
	IN awayid integer,
	IN homename character varying,
	IN awayname character varying,
	IN kickofftime timestamp with time zone,
	IN bettime timestamp with time zone,
	IN betamount numeric,
	IN actualamount numeric,
	IN sporttype integer,
	IN sporttypename character varying,
	IN bettype integer,
	IN bettypename character varying,
	IN oddstype integer,
	IN oddsid bigint,
	IN odds numeric,
	IN betchoice character varying,
	IN betchoice_en character varying,
	IN updatetime timestamp with time zone,
	IN transactiontime timestamp with time zone,
	IN leagueid integer,
	IN leaguename character varying,
	IN leaguename_en character varying,
	IN sporttypename_en character varying,
	IN bettypename_en character varying,
	IN homename_en character varying,
	IN awayname_en character varying,
	IN ip character varying,
	IN islive boolean,
	IN txid bigint,
	IN tsid character varying,
	IN point character varying,
	IN point2 character varying,
	IN betteam character varying,
	IN homescore integer,
	IN awayscore integer,
	IN bastatus boolean,
	IN excluding character varying,
	IN betfrom character varying,
	IN creditamount numeric,
	IN debitamount numeric,
	IN oddsinfo character varying,
	IN matchdatetime timestamp with time zone,
	IN isoddschanged boolean,
	IN winlostdate date,
	IN productid integer,
	IN gameid integer,
	IN productname_en character varying,
	IN gamename_en character varying,
	IN roundid character varying,
	IN extra jsonb,
	IN parlaytype character varying,
	IN detail jsonb,
	IN refid character varying,
	IN game_provider_id uuid,
	IN game_id integer,
	INOUT licenseetxid bigint DEFAULT NULL::bigint,
	INOUT spresult integer DEFAULT 0)
LANGUAGE 'plpgsql'
AS $BODY$
        DECLARE _sq bigint ;
        BEGIN
        IF bet_bettrans_sbsw_bet_xtest.action != 'PlaceBetEnt' THEN 
            SELECT NULL INTO _sq; 
            SELECT SBSW.SQ
            INTO _sq
            FROM dbo.Bettrans_SBSW_Bet AS SBSW 
            WHERE  SBSW.refId = bet_bettrans_sbsw_bet_xtest.refId AND SBSW.operationId = bet_bettrans_sbsw_bet_xtest.operationId;
        
            IF _sq IS NOT NULL THEN 
                SELECT -4 INTO SPResult;
                RETURN;
            END IF;
        END IF;
        
        INSERT INTO dbo.Bettrans_SBSW_Bet
        (
            action,
            operationId,
            userId,
            currency,
            matchId,
            homeId,
            awayId,
            homeName,
            awayName,
            kickOffTime,
            betTime,
            betAmount,
            actualAmount,
            sportType,
            sportTypeName,
            betType,
            betTypeName,
            oddsType,
            oddsId,
            odds,
            betChoice,
            betChoice_en,
            updateTime,
            transactionTime,
            leagueId,
            leagueName,
            leagueName_en,
            sportTypeName_en,
            betTypeName_en,
            homeName_en,
            awayName_en,
            IP,
            isLive,
            refId,
            txId,
            licenseeTxId,
            tsId,
            point,
            point2,
            betTeam,
            homeScore,
            awayScore,
            baStatus,
            excluding,
            betFrom,
            creditAmount,
            debitAmount,
            oddsInfo,
            matchDateTime,
            isOddsChanged,
            winlostDate,
            productId,
            gameId,
            productName_en,
            gameName_en,
            roundId,
            extra,
            parlayType,
            detail,
            game_provider_id,
			game_id
        )
        VALUES
        (
            action,
            operationId,
            userId,
            currency,
            matchId,
            homeId,
            awayId,
            homeName,
            awayName,
            kickOffTime,
            betTime,
            betAmount,
            actualAmount,
            sportType,
            sportTypeName,
            betType,
            betTypeName,
            oddsType,
            oddsId,
            odds,
            betChoice,
            betChoice_en,
            updateTime,
            transactionTime,
            leagueId,
            leagueName,
            leagueName_en,
            sportTypeName_en,
            betTypeName_en,
            homeName_en,
            awayName_en,
            IP,
            isLive,
            refId,
            txId,
            licenseeTxId,
            tsId,
            point,
            point2,
            betTeam,
            homeScore,
            awayScore,
            baStatus,
            excluding,
            betFrom,
            creditAmount,
            debitAmount,
            oddsInfo,
            matchDateTime,
            isOddsChanged,
            winlostDate,
            productId,
            gameId,
            productName_en,
            gameName_en,
            roundId,
            extra,
            parlayType,
            detail,
            game_provider_id,
			game_id
        );
        SELECT LASTVAL() INTO licenseeTxId;
END ; 
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_bet_xtest(character varying, character varying, character varying, integer, integer, integer, integer, character varying, character varying, timestamp with time zone, timestamp with time zone, numeric, numeric, integer, character varying, integer, character varying, integer, bigint, numeric, character varying, character varying, timestamp with time zone, timestamp with time zone, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, boolean, bigint, character varying, character varying, character varying, character varying, integer, integer, boolean, character varying, character varying, numeric, numeric, character varying, timestamp with time zone, boolean, date, integer, integer, character varying, character varying, character varying, jsonb, character varying, jsonb, integer, character varying, bigint, integer)
    OWNER TO postgres;

--Change 03:
CREATE OR REPLACE PROCEDURE dbo.bet_bettrans_sbsw_settle_xtest(
	IN action character varying DEFAULT NULL::character varying,
	IN operationid character varying DEFAULT NULL::character varying,
	IN userid character varying DEFAULT NULL::character varying,
	IN refid character varying DEFAULT NULL::character varying,
	IN txid bigint DEFAULT NULL::bigint,
	IN updatetime timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN winlostdate timestamp with time zone DEFAULT NULL::timestamp with time zone,
	IN status character varying DEFAULT NULL::character varying,
	IN payout numeric DEFAULT NULL::numeric,
	IN creditamount numeric DEFAULT NULL::numeric,
	IN debitamount numeric DEFAULT NULL::numeric,
	IN extrastatus character varying DEFAULT NULL::character varying,
	IN game_provider_id uuid DEFAULT NULL,
	IN game_id integer DEFAULT NULL,
	INOUT spresult integer DEFAULT 0,
	INOUT sporttype integer DEFAULT NULL::integer)
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _sq BIGINT;
			_rc BIGINT;
	BEGIN
        IF action != 'SettleEnt' THEN 
            SELECT null INTO _sq;
            SELECT SBSW.SQ
            INTO _sq
            FROM dbo.Bettrans_SBSW_Settle AS SBSW 
            WHERE  SBSW.refId = bet_bettrans_sbsw_settle_xtest.refId AND SBSW.operationId = bet_bettrans_sbsw_settle_xtest.operationId;
        
            IF _sq IS NOT NULL THEN --已完成此交易
                SELECT -4 INTO SPResult;
                RETURN;
            END IF;
        END IF;

        INSERT INTO dbo.Bettrans_SBSW_Settle
        (
            action,
            operationId,
            userId,
            refId,
            txId,
            updateTime,
            winlostDate,
            status,
            payout,
            creditAmount,
            debitAmount,
            extraStatus,
            game_provider_id,
			game_id
        )
        VALUES
        (
            action,
            operationId,
            userId,
            refId,
            txId,
            updateTime,
            winlostDate,
            status,
            payout,
            creditAmount,
            debitAmount,
            extraStatus,
            game_provider_id,
			game_id
        );
	GET DIAGNOSTICS _rc = ROW_COUNT;
    IF _rc > 0 THEN
        PERFORM 1
        FROM dbo.Bettrans_SBSW_Bet AS SBSW  
		WHERE SBSW.refId = bet_bettrans_sbsw_settle_xtest.refId;
		get diagnostics SPResult = row_count;

		select sbsw.sporttype 
		into bet_bettrans_sbsw_settle_xtest.sporttype
		from dbo.Bettrans_SBSW_Bet AS SBSW  
		WHERE SBSW.refId = bet_bettrans_sbsw_settle_xtest.refId;
    END IF;
END ;
$BODY$;
ALTER PROCEDURE dbo.bet_bettrans_sbsw_settle_xtest(character varying, character varying, character varying, character varying, bigint, timestamp with time zone, timestamp with time zone, character varying, numeric, numeric, numeric, character varying, integer, integer, integer)
    OWNER TO postgres;
