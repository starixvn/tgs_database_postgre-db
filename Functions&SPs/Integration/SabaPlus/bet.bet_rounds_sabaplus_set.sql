
-- DROP PROCEDURE IF EXISTS bet.bet_rounds_sabaplus_set(character varying, uuid, text, integer, character varying, character varying, uuid, bigint, uuid, character varying, uuid, timestamp with time zone, timestamp with time zone, numeric, character varying, boolean, character varying, uuid, character varying, text);

CREATE OR REPLACE PROCEDURE bet.bet_rounds_sabaplus_set(
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
	INOUT id uuid DEFAULT gen_random_uuid(),
	INOUT statuscode character varying DEFAULT '0'::character varying,
	INOUT errmsg text DEFAULT ''::text)
LANGUAGE 'plpgsql'
/*
	Param's explaination: 
		external_round_id: dbo.bettrans_sabaplus_bet.TicketNo
		extrastatus: PlaceBet
					 EndGame
		licenseetxid: column sq in table dbo.bettrans_sabaplus_bet
		actiontype:	ConfirmBet
					Settle


*/
AS $BODY$
	DECLARE b_bet_amount	numeric; --stake
		 	b_valid_bet_amount numeric;
		 	b_bet_type		integer;
			p_status		smallint;
			b_client_status smallint;
			b_is_existing	BIT :=0;
			b_is_raise_bet	BIT :=0;
			b_external_closed_on timestamp with time zone;
			b_closed_on timestamp with time zone;
			b_settle_amount	numeric(20,6);
			b_turnover		numeric(20,6);
			b_win_loss		numeric(18,6);
			b_ticketstatus	character varying(100);	

			r_bet_amount	numeric; --stake

			---For keep track in local
				_start TIMESTAMP := current_timestamp;
				_end TIMESTAMP;
				_text character varying(500) :='external_round_id:' || external_round_id || ', external_created_on:' || external_created_on || ', actiontype:' || actiontype;
				_action character varying(100);
			---/end

BEGIN


		---IF not exists (place running bet or place settled bet or missing data): insert
		-- IF existing: update
		-- IF raise bet( extra bet ):  raise stake/actualstake, update odds..
		SELECT 1::BIT 
			, CASE WHEN br.client_status = 1 AND bet_rounds_sabaplus_set.actiontype = 'ConfirmBet' THEN 1::BIT ELSE 0::BIT END 
			, br.bet_amount
		INTO b_is_existing  
			, b_is_raise_bet 
			, r_bet_amount
		FROM bet.Rounds br	
		WHERE br.external_round_id =  bet_rounds_sabaplus_set.external_round_id 
			AND br.brand_id = bet_rounds_sabaplus_set.brand_id
			AND br.game_id = bet_rounds_sabaplus_set.game_id;				

		IF COALESCE(b_is_existing,0::BIT) = 0::BIT AND (extrastatus ILIKE  '%EndGame%' OR extrastatus ILIKE '%VoidGame%') THEN
			statuscode := '102';
			errmsg := 'No Data';
			RETURN;
		END IF;

		--value for update/insert
		SELECT CASE WHEN bet_rounds_sabaplus_set.actiontype = 'ConfirmBet' OR bet_rounds_sabaplus_set.extrastatus IN ('PlaceBetAndSettle', 'FreeSpin') THEN b.Stake
					ELSE r_bet_amount END  --b_bet_amount	
				,b.ExternalGameID::integer  --b_bet_type
				,CASE WHEN TicketStatus IN ('void','reject','refund') THEN 0
					  ELSE b.NetStake
					  END --b_valid_bet_amount
				,CASE WHEN LOWER(b.TicketStatus) = 'running'	THEN 1
					  WHEN LOWER(b.TicketStatus) IN ('void', 'refund','reject')	THEN 2
					  WHEN LOWER(b.TicketStatus) = 'won'	THEN 3
					  WHEN LOWER(b.TicketStatus) = 'lose'	THEN 4
					  WHEN LOWER(b.TicketStatus) = 'draw'	THEN 5
					  ELSE NULL ---bug or unknow case =))
					  END   --b_client_status
				,CASE WHEN LOWER(b.TicketStatus) = 'running' THEN 1 ELSE 2 END  --p_status
				,CASE WHEN LOWER(b.ticketstatus) = 'running' THEN NULL ELSE external_closed_on END  --b_external_closed_on
				,CASE WHEN LOWER(b.ticketstatus) = 'running' THEN NULL ELSE current_timestamp END --b_closed_on
				,CASE WHEN LOWER(b.ticketstatus) IN ('void','reject','refund','running' ) THEN 0 
					  WHEN bet_rounds_sabaplus_set.extrastatus = 'EndGame' THEN r_bet_amount
					  ELSE b.stake 
					  END --b_turnover
				,CASE WHEN LOWER(b.TicketStatus) IN ('running','void', 'refund','reject') THEN 0 ELSE bet_rounds_sabaplus_set.payout - b.ActualStake END--b_win_loss	
				,bet_rounds_sabaplus_set.payout --b_settle_amount
				,b.ticketstatus
				INTO b_bet_amount ,  b_bet_type , b_valid_bet_amount ,  b_client_status, p_status, b_external_closed_on, b_closed_on, b_turnover, b_win_loss, b_settle_amount, b_ticketstatus
			FROM dbo.bettrans_sabaplus_bet b
			WHERE ( b.TicketNo = bet_rounds_sabaplus_set.external_round_id 
						AND bet_rounds_sabaplus_set.actiontype <> 'ConfirmBet' 
						AND b.Action = bet_rounds_sabaplus_set.extrastatus
					)
				OR (	b.sq = licenseetxid 
						AND bet_rounds_sabaplus_set.actiontype = 'ConfirmBet'
					) ;

		IF COALESCE(b_is_existing,0::BIT) = 0::BIT THEN
			INSERT INTO bet.Rounds
			(	 id,
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
			VALUES 
			(	 id,
				current_timestamp, 
				external_round_id, 
				game_provider_id, 
				player_code, 
				game_id, 
				currency_code, 
				p_status,
				game_provider_configuration_id,	
				wallet_id,
				b_closed_on,
				current_timestamp,				--updated_on
				brand_id,
				external_created_on,
				b_external_closed_on,
				b_bet_amount, 
				b_valid_bet_amount,	 
				b_settle_amount, 
				NULL,							--commission
				b_turnover,	
				b_win_loss,		
				NULL,							--tie_bet_adjustment
				b_client_status,
				NULL,							--reopen_turnover_adjustment
				NULL,							--reopened_on
				NULL,							--effective_betting_percentage		
				b_bet_type
			);
		ELSE
			UPDATE bet.rounds br
					SET status				= p_status
						,closed_on			= b_closed_on
						,updated_on			= current_timestamp
						,external_closed_on = b_external_closed_on
						,settle_amount		= b_settle_amount
						,win_loss			=  CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN win_loss + b_win_loss
													ELSE b_win_loss
													END
						,client_status		= b_client_status
						,bet_amount			= CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN bet_amount + b_bet_amount
													ELSE b_bet_amount
													END
						,valid_bet_amount	= CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN valid_bet_amount + b_valid_bet_amount
													ELSE b_valid_bet_amount
													END
						,turnover			= CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN turnover + b_turnover
													ELSE b_turnover
													END
					WHERE br.external_round_id = bet_rounds_sabaplus_set.external_round_id 
						AND br.brand_id = bet_rounds_sabaplus_set.brand_id
						AND br.game_id = bet_rounds_sabaplus_set.game_id;	
		END IF;

		---for keep track in local
			_end := current_timestamp;
			IF COALESCE(b_is_existing,0::BIT) = 0::BIT THEN  _action := 'insert' ;
				ELSE  _action := 'update';
			END IF;
			
			INSERT INTO log.DBA_Log ( uid ,action , object_name	 ,start_time	 ,end_time	 ,text	)	
			SELECT id, _action
					, 'bet_rounds_sabaplus_set', _start, _end, _text;
					
		---/end

		EXCEPTION 
		WHEN unique_violation THEN 
			SELECT  'duplicate ticket' INTO errmsg;
			SELECT '101' INTO statuscode;
		WHEN Others THEN
			 get stacked diagnostics
        		statuscode   = returned_sqlstate,
        		errmsg     = message_text;


END;
$BODY$;
 


/*
	CALL  bet.bet_rounds_sabaplus_set(
		external_round_id				=>'5446|$|4unxqj93ywp8|$|5446_29950432'	
		,game_provider_id				=>'40e6215d-b5c6-4896-987c-f30f3678f608'							
		,player_code					=>'4unxqj93ywp8'						
		,game_id						=>5446								
		,currency_code					=>'CNY'								
		,game_provider_configuration_id=>'6ecd8c99-4036-403d-bf84-cf8400f67836'							
		,licenseetxid					=> 96::bigint									
		,wallet_id 						=>'6ecd8c99-4036-403d-bf84-cf8400f67836'
		,refid							=> '1111111'							
		,brand_id 						=>'8acacf5a-d808-4a55-8302-d832ee3da6dc'
		,external_created_on			=>'2024-09-06 15:00:22+00'				
		,external_closed_on				=>'2024-09-06 15:00:22+00'				
		,payout							=> 0.0										
		,extrastatus					=>'PlaceBet'										
		,actiontype						=>'ConfirmBet'															
		,statuscode						=>NULL									
		,errmsg							=>NULL
	
		,Louisaahihi	=> NULL
	)

	*/
 