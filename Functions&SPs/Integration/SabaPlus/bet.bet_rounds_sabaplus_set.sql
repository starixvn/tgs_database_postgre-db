 

CREATE OR REPLACE PROCEDURE bet.bet_rounds_sabaplus_set(
	IN external_round_id				character varying	DEFAULT NULL::character varying
	,IN game_provider_id				uuid				DEFAULT NULL::uuid
	,IN player_code						text				DEFAULT NULL::text
	,IN game_id							integer				DEFAULT NULL::integer
	,IN currency_code					character varying	DEFAULT NULL::character varying
	,IN status							character varying	DEFAULT NULL::character varying
	,IN game_provider_configuration_id	uuid				DEFAULT NULL::uuid
	,IN licenseetxid					bigint				DEFAULT NULL::bigint
	,IN wallet_id						uuid				DEFAULT NULL::uuid
	,IN refid							character varying	DEFAULT NULL::character varying
	,IN brand_id						uuid				DEFAULT NULL::uuid
	,IN external_created_on				timestamp with time zone DEFAULT NULL::timestamp with time zone
	,IN external_closed_on				timestamp with time zone DEFAULT NULL::timestamp with time zone
	,IN payout							numeric DEFAULT 0
	,IN extrastatus						character varying	DEFAULT NULL::character varying
	,IN isonlywinlostdatechanged		boolean				DEFAULT NULL::boolean
	,IN actiontype						character varying	DEFAULT NULL::character varying
	,INOUT id							uuid				DEFAULT gen_random_uuid()
	,INOUT statuscode					character varying	DEFAULT '0'::character varying
	,INOUT errmsg						text				DEFAULT ''::text
	)
LANGUAGE 'plpgsql'
/*
	Param's explaination: 
		external_round_id: dbo.bettrans_sabaplus_bet.TicketNo
		extrastatus: PlaceBet
					 EndGame
		licenseetxid: column sq in table dbo.bettrans_sabaplus_bet.
		actiontype:	ConfirmBet
					Settle


*/
AS $BODY$
	DECLARE p_bet_amount	numeric;
		 	p_valid_bet_amount numeric;
		 	p_bet_type		integer;
			p_status		smallint;
			p_client_status smallint;
			p_is_existing	BIT :=0;
			p_is_raise_bet	BIT;
			p_external_closed_on timestamp with time zone;
			p_closed_on timestamp with time zone;
			p_settle_amount	numeric(20,6);
			p_turnover		numeric(20,6);
			p_win_loss		numeric(18,6);
BEGIN

		SELECT 1  , CASE WHEN br.client_status = 1 THEN 1 ELSE 0 END  INTO p_is_existing  ,  p_is_raise_bet::BIT
		FROM bet.Rounds br	
		WHERE br.external_round_id =  bet_rounds_sabaplus_set.external_round_id 
			AND br.brand_id = bet_rounds_sabaplus_set.brand_id
			AND br.game_id = bet_rounds_sabaplus_set.game_id;				

		IF  p_is_existing = 0::BIT AND (extrastatus LIKE '%EndGame%' OR extrastatus LIKE '%VoidGame%') THEN
			statuscode := '102';
			errmsg := 'No Data';
			RETURN;
		END IF;

		SELECT b.Stake 	
			,b.ExternalGameID::integer 
			,CASE WHEN TicketStatus IN ('void','reject','refund') THEN 0
					ELSE  CASE WHEN b.NetStake = 0 THEN b.Stake ELSE  b.NetStake END 
					END 
			,CASE b.TicketStatus WHEN 'running'	THEN 1
								WHEN 'void'		THEN 2
								WHEN 'refund'	THEN 3
								WHEN 'reject'	THEN 4
								WHEN 'lose'		THEN 5
								WHEN 'won'		THEN 6
								WHEN 'draw'		THEN 7
								ELSE NULL ---bug or unknow case =))
								END  
			,CASE WHEN b.TicketStatus = 'running' THEN 1 ELSE 2 END  
			,CASE WHEN b.ticketstatus = 'running' THEN NULL ELSE external_closed_on END  
			,CASE WHEN b.ticketstatus = 'running' THEN NULL ELSE current_timestamp END 
			,CASE WHEN b.ticketstatus = 'running' THEN 0 ELSE bet_rounds_sabaplus_set.payout END 
			,CASE WHEN b.ticketstatus IN ('void','reject','refund','running' ) THEN 0 ELSE b.stake END		
			,bet_rounds_sabaplus_set.payout - CASE WHEN b.NetStake = 0 THEN b.ActualStake ELSE b.NetStake END 
			INTO p_bet_amount ,  p_bet_type , p_valid_bet_amount ,  p_client_status, p_status, p_external_closed_on, p_closed_on, p_turnover, p_win_loss
		FROM dbo.bettrans_sabaplus_bet b
		WHERE b.sq = licenseetxid;

		IF p_is_existing = 0::BIT THEN
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
				p_closed_on,
				current_timestamp,				--updated_on
				brand_id,
				external_created_on,
				p_external_closed_on,
				p_bet_amount, 
				p_valid_bet_amount,	 
				p_settle_amount, 
				NULL,							--commission
				p_turnover,	
				p_win_loss,		
				NULL,							--tie_bet_adjustment
				p_client_status,
				NULL,							--reopen_turnover_adjustment
				NULL,							--reopened_on
				NULL							--effective_betting_percentage		
				
			);
		ELSE
			UPDATE bet.rounds br
					SET status				= p_status
						,closed_on			= p_closed_on
						,updated_on			= current_timestamp
						,external_closed_on = p_external_closed_on
						,settle_amount		= p_settle_amount
						,win_loss			= p_win_loss
						,client_status		= p_client_status
						,bet_amount			= bet_amount + CASE WHEN p_is_raise_bet = 1::BIT THEN p_bet_amount ELSE 0 END
						,valid_bet_amount	= valid_bet_amount + CASE WHEN p_is_raise_bet = 1::BIT THEN p_valid_bet_amount ELSE 0 END
						,turnover			= turnover + CASE WHEN p_is_raise_bet = 1::BIT THEN p_turnover ELSE 0 END
					WHERE br.external_round_id = bet_rounds_sabaplus_set.external_round_id 
						AND br.brand_id = bet_rounds_sabaplus_set.brand_id
						AND br.game_id = bet_rounds_sabaplus_set.game_id;		
		END IF;


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
 