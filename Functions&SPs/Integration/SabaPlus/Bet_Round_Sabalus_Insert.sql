/*
	Louisa: insert data into bet.round
	2024-09-11
*/

---- DROP PROCEDURE IF EXISTS 

CREATE OR REPLACE PROCEDURE bet.Bet_Round_Sabalus_Insert
(
     IN external_round_id				character varying(255)	
	,IN game_provider_id				uuid					
	,IN player_code					text					
	,IN game_id						integer					
	,IN currency_code					character varying(10)	
	,IN status							smallint				
	,IN game_provider_configuration_id uuid					
	,IN wallet_id						uuid					
	,IN brand_id						uuid					
	,IN client_status					smallint				
	,IN closed_on						timestamp with time zone DEFAULT NULL::timestamp with time zone
	,IN external_created_on			timestamp with time zone DEFAULT NULL::timestamp with time zone
	,IN external_closed_on				timestamp with time zone DEFAULT NULL::timestamp with time zone
	,IN bet_amount						numeric(18,6)			 DEFAULT 0.0
	,IN settle_amount					numeric					 DEFAULT 0.0
	,IN win_loss						numeric(18,6)			 DEFAULT 0.0
	,IN bet_type						integer					 DEFAULT 0.0
	,INOUT statuscode 	character varying DEFAULT '0'::character varying
	,INOUT errmsg 		text DEFAULT ''::text
)
LANGUAGE 'plpgsql'
/*
	Param's explaination: 
		TicketStatusId: 0-Running		 
						1-Won			 
						2-Lose 		 
						3-Draw 		 
						4-Void		 
						5-Reject		 
						6-Refund 
*/
AS $BODY$
	DECLARE valid_bet_amount numeric(18,6);
			turnover		 numeric;
BEGIN

--------Validate -----------------------
	IF EXISTS(	SELECT 1 FROM bet.Round br	
				WHERE br.TicketNo =  Bet_Round_Sabalus_Insert.TicketNo 
					AND br.game_provider_id = Bet_Round_Sabalus_Insert.game_provider_id
					AND ( 
							Bet_Round_Sabalus_Insert.client_status IN ( 0,4,5) --not allow place bet/void/reject duplicate
							OR (br.external_closed_on = Bet_Round_Sabalus_Insert.external_closed_on AND Bet_Round_Sabalus_Insert.client_status IN (1,2,3,4) ) --not allow duplicate settle
						)
					
			) THEN
		
		SELECT 'duplicate ticket OR duplicate action' INTO errmsg;
		SELECT '101' INTO statuscode;
		
		RETURN;
	END IF;
-----/End validate

	SELECT CASE WHEN client_status IN (4,5,6) THEN 0
				ELSE bet_amount 
			END
	INTO valid_bet_amount;

	SELECT CASE WHEN client_status IN (0,4,5,6) THEN 0
				ELSE bet_amount 
			END
	INTO turnover;


	IF NOT EXISTS ( SELECT 1 FROM bet.Round r 
					WHERE r.TicketNo =  Bet_Round_Sabalus_Insert.TicketNo 
						AND r.game_provider_id = Bet_Round_Sabalus_Insert.game_provider_id
					) THEN
	BEGIN
		INSERT INTO bet.Round
		(	 id							
			,external_round_id			
			,game_provider_id			
			,player_code				
			,game_id					
			,currency_code				
			,status						
			,game_provider_configuration_id
			,wallet_id					
			,created_on					
			,updated_on					
			,brand_id					
			,client_status				
			,closed_on					
			,external_created_on		
			,external_closed_on			
			,bet_amount					
			,valid_bet_amount			
			,settle_amount				
			,turnover					
			,win_loss					
			,bet_type					
		)
		VALUES 
		(	 gen_random_uuid()							
			,external_round_id				
			,game_provider_id				
			,player_code					
			,game_id						
			,currency_code					
			,status							
			,game_provider_configuration_id 
			,wallet_id						
			,CURRENT_TIMESTAMP	--created_on						
			,CURRENT_TIMESTAMP	--updated_on					
			,brand_id						
			,client_status					
			,closed_on						
			,external_created_on			
			,external_closed_on				
			,bet_amount						
			,valid_bet_amount
			,settle_amount					
			,turnover						
			,win_loss						
			,bet_type						
		);
	END;
	ELSE
	BEGIN
		UPDATE  bet.Round br
		SET  status				= Bet_Round_Sabalus_Insert.status						
			,updated_on			= CURRENT_TIMESTAMP				
			,client_status		= Bet_Round_Sabalus_Insert.client_status				
			,closed_on			= Bet_Round_Sabalus_Insert.closed_on					
			,external_closed_on	= Bet_Round_Sabalus_Insert.external_closed_on			
			,bet_amount			= Bet_Round_Sabalus_Insert.bet_amount					
			,valid_bet_amount	= valid_bet_amount			
			,settle_amount		= Bet_Round_Sabalus_Insert.settle_amount				
			,turnover			= turnover					
			,win_loss			= Bet_Round_Sabalus_Insert.win_loss					
			,bet_type			= Bet_Round_Sabalus_Insert.bet_type					
		WHERE br.TicketNo	= Bet_Round_Sabalus_Insert.TicketNo			
			AND br.game_provider_id = Bet_Round_Sabalus_Insert.game_provider_id;
	END;
	END IF;

END;
$BODY$;

-----------------------------------------------
ALTER PROCEDURE bet.Bet_Round_Sabalus_Insert(character varying 	
,uuid					
,text					
,integer				
,character varying 
,smallint				
,uuid					
,uuid					
,uuid					
,smallint				
,timestamp with time zone
,timestamp with time zone
,timestamp with time zone
,numeric 			  
,numeric				
,numeric 			  
,integer				
,character varying  
,text 
)OWNER TO postgres;

-----------------------------------------------
