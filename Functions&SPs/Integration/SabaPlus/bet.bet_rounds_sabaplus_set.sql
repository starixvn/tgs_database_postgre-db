
-- DROP PROCEDURE IF EXISTS bet.bet_rounds_sabaplus_set(character varying, uuid, text, integer, character varying, character varying, uuid, bigint, uuid, character varying, uuid, timestamp with time zone, timestamp with time zone, numeric, character varying, boolean, character varying, uuid, character varying, text);

CREATE OR REPLACE PROCEDURE bet.bet_rounds_sabaplus_set(
	IN external_round_id character varying DEFAULT NULL::character varying,
	IN game_provider_id uuid DEFAULT NULL::uuid,
	IN player_code text DEFAULT NULL::text,
	IN game_id integer DEFAULT NULL::integer,
	IN currency_code character varying DEFAULT NULL::character varying,
	IN status character varying DEFAULT NULL::character varying,
	IN game_provider_configuration_id uuid DEFAULT NULL::uuid,
	IN licenseetxid bigint DEFAULT NULL::bigint, ---bet_rounds_sabaplus.sq
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
	DECLARE b_stake			numeric; --stake
			b_actual_stake	numeric; --actual stake
		 	b_netstake		numeric;
		 	b_bet_type			integer;
			p_new_status		smallint;
			b_new_client_status	smallint;
			b_is_existing		BIT :=0;
			b_is_raise_bet		BIT :=0;
			b_win_loss			numeric(18,6);
			b_ticketstatus		character varying(100);	
			b_sq bigint := CAST( COALESCE(refid,'0') AS INT); ---column bettrans_sabaplus_bet.sq
			b_is_resettle		BIT :=0;			
			b_external_gameround_id character varying(100);

			r_old_status		smallint;
			
			---For keep track in local
				_start TIMESTAMP :=  clock_timestamp();
				_end TIMESTAMP;
				_action character varying(100);
			---/end

BEGIN
		PERFORM pg_advisory_xact_lock(hashtext('bet.bet_rounds_sabaplus_set')::bigint #hashtext(	external_round_id)::bigint);

		---IF not exists (place running bet or place settled bet or missing data): insert
		-- IF existing: update
		-- IF raise bet( extra bet ):  raise stake/actualstake, update odds..
		SELECT 1::BIT 
			, CASE WHEN br.client_status = 1 AND bet_rounds_sabaplus_set.actiontype = 'ConfirmBet' THEN 1::BIT ELSE 0::BIT END
			, br.status
		INTO b_is_existing  
			, b_is_raise_bet 
			, r_old_status
		FROM bet.Rounds br	
		WHERE br.external_round_id =  bet_rounds_sabaplus_set.external_round_id 
			AND br.brand_id = bet_rounds_sabaplus_set.brand_id
			AND br.game_id = bet_rounds_sabaplus_set.game_id;				

		---prevent case service runs parallel, command is not ran sequence, suggest web delay 200ms and retry 3 times
		IF COALESCE(b_is_existing,0::BIT) = 0::BIT AND (extrastatus LIKE  '%EndGame%' OR extrastatus LIKE '%VoidGame%' OR extrastatus LIKE 'BetResultCheck')  THEN
			statuscode := '102';
			errmsg := 'No Data';
			_end :=   clock_timestamp ;
			INSERT INTO log.DBA_Log ( uid ,action , object_name	 ,start_time	 ,end_time	 ,text	)	
			SELECT id, _action, 'bet_rounds_sabaplus_set', _start, _end, errmsg || ',external_round_id =>'	|| COALESCE(CAST( external_round_id	 AS CHARACTER VARYING),'') || ',refid =>'|| COALESCE(refid	,'');

			RETURN;
		END IF;

		--- ticket runing come to system after settle
		IF COALESCE(r_old_status,1) > 1 AND bet_rounds_sabaplus_set.actiontype = 'ConfirmBet' THEN
			statuscode := '104';
			errmsg := 'Ticket already settle, cannot add bet';
			_end :=   clock_timestamp ;
			INSERT INTO log.DBA_Log ( uid ,action , object_name	 ,start_time	 ,end_time	 ,text	)	
			SELECT id, _action, 'bet_rounds_sabaplus_set',  _start, _end, errmsg || ',external_round_id =>'	|| COALESCE(CAST( external_round_id	 AS CHARACTER VARYING),'') || ',refid =>'|| COALESCE(refid	,'');

			RETURN;
		END IF;

		----bettrans_sabaplus_bet
		SELECT b.Stake
				,b.ExternalGameID::integer
				,b.NetStake
				,CASE WHEN LOWER(b.TicketStatus) = 'running'	THEN 1
					  WHEN LOWER(b.TicketStatus) IN ('void', 'refund','reject')	THEN 2
					  WHEN LOWER(b.TicketStatus) = 'won'	THEN 3
					  WHEN LOWER(b.TicketStatus) = 'lose'	THEN 4
					  WHEN LOWER(b.TicketStatus) = 'draw'	THEN 5
					  ELSE NULL ---bug or unknow case =))
					  END   --b_new_client_status
				,CASE WHEN LOWER(b.TicketStatus) = 'running' THEN 1 ELSE 2 END  --p_new_status
				,CASE WHEN LOWER(b.TicketStatus) IN ('running','void', 'refund','reject') THEN 0 
						ELSE bet_rounds_sabaplus_set.payout - b.ActualStake 
						END--b_win_loss
				,b.ticketstatus
				,b.actualstake
				,CASE WHEN b.ExtraInfo LIKE '%{"IsResettle":"True"}%' THEN 1::BIT ELSE 0::BIT END
				,b.GameRoundId
			INTO b_stake,  b_bet_type, b_netstake
					, b_new_client_status, p_new_status
					, b_win_loss, b_ticketstatus, b_actual_stake
					, b_is_resettle
					, b_external_gameround_id
			FROM dbo.bettrans_sabaplus_bet b
			WHERE ( b.TicketNo = bet_rounds_sabaplus_set.external_round_id ---ticketNo
						AND bet_rounds_sabaplus_set.actiontype <> 'ConfirmBet' 
						AND b.sq = b_sq
					)
				OR (	b.sq = licenseetxid 
						AND bet_rounds_sabaplus_set.actiontype = 'ConfirmBet'
					);
		
		----API PlaceBet/FreeSPin/Bonus 
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
				bet_type,
				actual_bet_amount,
				adjustment_actual_bet_amount,
				external_gameround_id
			)
			SELECT 
			 	 id,
				current_timestamp, 
				external_round_id, 
				game_provider_id, 
				player_code, 
				game_id, 
				currency_code, 
				p_new_status, --status
				game_provider_configuration_id,	
				wallet_id,
				CASE WHEN bet_rounds_sabaplus_set.actiontype = 'ConfirmBet' THEN NULL
					ELSE current_timestamp
					END, --closed_on
				current_timestamp,	--updated_on
				brand_id,
				bet_rounds_sabaplus_set.external_created_on,
				bet_rounds_sabaplus_set.external_closed_on,
				b_stake,  --bet_amount
				b_netstake,	 --valid_bet_amount
				bet_rounds_sabaplus_set.payout, --settle_amount
				NULL,							--commission
				CASE WHEN  b_ticketstatus  =  'running'  THEN 0
					  ELSE b_netstake
					  END, --b_turnover,	
				b_win_loss,		
				NULL,		--tie_bet_adjustment
				b_new_client_status,
				NULL,							--reopen_turnover_adjustment
				NULL,							--reopened_on
				NULL,							--effective_betting_percentage		
				b_bet_type,		
				b_actual_stake,
				0,
				b_external_gameround_id;
		ELSE
			---RaiseBet, API EndGame/VoidGame/BetResultCheck
			UPDATE bet.rounds br
					SET status				= p_new_status
						,closed_on			= CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT  --raise bet
														OR ( b_ticketstatus  IN ('void', 'refund','reject') AND br.status = 2 ) 
														OR b_is_resettle = 1::BIT
														THEN br.closed_on -- void/refund/reject ticket settle
													ELSE current_timestamp
													END
						,updated_on			= current_timestamp
						,external_closed_on = CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT  --raise bet
														OR ( b_ticketstatus  IN ('void', 'refund','reject') AND br.status = 2 ) THEN br.external_closed_on  -- void/refund/reject ticket settle
													ELSE bet_rounds_sabaplus_set.external_closed_on
													END
						,settle_amount		=  CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN 0
													WHEN b_ticketstatus  IN ('won','lose','draw') THEN bet_rounds_sabaplus_set.payout
													WHEN b_ticketstatus  IN ('void', 'refund','reject') THEN br.actual_bet_amount
													END
						,win_loss			=  CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN win_loss + b_win_loss
													ELSE b_win_loss
													END
						,client_status		= b_new_client_status
						,bet_amount			= CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN bet_amount + b_stake
													ELSE br.bet_amount --API Void/EndGame/BetResultCheck: Not Update
													END
						,actual_bet_amount = CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN actual_bet_amount + b_actual_stake
													WHEN b_ticketstatus IN ('void', 'refund','reject') THEN actual_bet_amount
													ELSE b_actual_stake
													END
						,adjustment_actual_bet_amount = CASE WHEN b_ticketstatus  IN ('won','lose','draw') AND b_actual_stake <> actual_bet_amount THEN actual_bet_amount - b_actual_stake
															ELSE adjustment_actual_bet_amount
															END
						,valid_bet_amount	= CASE WHEN COALESCE(b_is_raise_bet,0::BIT) = 1::BIT THEN valid_bet_amount + b_netstake
													WHEN b_ticketstatus IN ('void','reject','refund') THEN 0
													ELSE b_netstake
													END
						,turnover			= CASE WHEN b_ticketstatus IN ('void','reject','refund','running' ) THEN 0 
													WHEN b_ticketstatus  IN ('won','lose','draw') THEN b_netstake
													ELSE NULL ---bug
													END
					WHERE br.external_round_id = bet_rounds_sabaplus_set.external_round_id 
						AND br.brand_id = bet_rounds_sabaplus_set.brand_id
						AND br.game_id = bet_rounds_sabaplus_set.game_id;
		END IF;

		---for keep track in local
			_end := CAST( clock_timestamp() as timestamp);
			IF COALESCE(b_is_existing,0::BIT) = 0::BIT THEN  _action := 'insert' ;
				ELSE  _action := 'update';
			END IF;
			
			INSERT INTO log.DBA_Log ( uid ,action , object_name	 ,start_time	 ,end_time	 ,text	)	
			SELECT id, _action, 'bet_rounds_sabaplus_set',  _start, _end
					, 'external_round_id =>'					|| COALESCE(CAST( external_round_id				 AS CHARACTER VARYING),'')
						|| ',game_provider_id=>'				|| COALESCE(CAST( game_provider_id				 AS CHARACTER VARYING),'')
						|| ',player_code =>'					|| COALESCE(CAST( player_code					 AS CHARACTER VARYING),'')
						|| ',game_id =>'						|| COALESCE(CAST( game_id						 AS CHARACTER VARYING),'')
						|| ',currency_code =>'					|| COALESCE(CAST( currency_code					 AS CHARACTER VARYING),'')
						|| ',status  =>' 						|| COALESCE(CAST( status						 AS CHARACTER VARYING),'')
						|| ',game_provider_configuration_id =>'	|| COALESCE(CAST( game_provider_configuration_id AS CHARACTER VARYING),'')
						|| ',licenseetxid =>'					|| COALESCE(CAST( licenseetxid					 AS CHARACTER VARYING),'')
						|| ',wallet_id =>'						|| COALESCE(CAST( wallet_id						 AS CHARACTER VARYING),'')
						|| ',brand_id =>'						|| COALESCE(CAST( brand_id						 AS CHARACTER VARYING),'')
						|| ',external_created_on =>' 			|| COALESCE(CAST( external_created_on			 AS CHARACTER VARYING),'')
						|| ',external_closed_on =>'				|| COALESCE(CAST( external_closed_on			 AS CHARACTER VARYING),'')
						|| ',payout =>'							|| COALESCE(CAST( payout						 AS CHARACTER VARYING),'')
						|| ',extrastatus =>' 					|| COALESCE(CAST( extrastatus					 AS CHARACTER VARYING),'')
						|| ',actiontype =>'						|| COALESCE(CAST( actiontype					 AS CHARACTER VARYING),'')
						|| ',refid =>'							|| COALESCE(refid		,'')						
					;
					
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
	)

	
--	select * from log.dba_log;

--	truncate table log.dba_log
	---restart indentity


	*/
 