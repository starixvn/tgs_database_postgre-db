/*
	Louisa: insert data into bet.round
	2024-09-11
*/

---- DROP PROCEDURE IF EXISTS 

CREATE OR REPLACE PROCEDURE bet.Bet_Round_Sabalus_Insert
(
     external_round_id				character varying(255)	
	,game_provider_id				uuid					
	,player_code					text					
	,game_id						integer					
	,currency_code					character varying(10)	
	,status							smallint				
	,game_provider_configuration_id uuid					
	,wallet_id						uuid					
	,brand_id						uuid					
	,client_status					smallint				
	,TicketStatusId					smallint				
	,closed_on						timestamp with time zone DEFAULT::NULL timestamp with time zone
	,external_created_on			timestamp with time zone DEFAULT::NULL timestamp with time zone
	,external_closed_on				timestamp with time zone DEFAULT::NULL timestamp with time zone 
	,bet_amount						numeric(18,6)			 DEFAULT = 0
	,settle_amount					numeric					 DEFAULT = 0
	,turnover						numeric					 DEFAULT = 0
	,win_loss						numeric(18,6)			 DEFAULT = 0
	,bet_type						integer					 DEFAULT = 0
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
	DECLARE valid_bet_amount numeric(18,6)
BEGIN

--------Validate -----------------------
	IF EXISTS(	SELECT 1 FROM bet.Round br	
				WHERE br.TicketNo =  TicketNo 
					AND br.game_provider_id = game_provider_id
					AND ( 
							TicketStatusId IN ( 0,4,5) --not allow place bet/void/reject duplicate
							OR (external_closed_on = external_closed_on AND TicketStatusId IN (1,2,3,4) ) --not allow duplicate settle
						)
					
			) THEN
		
		SELECT 'duplicate ticket OR duplicate action' INTO errmsg;
		SELECT '101' INTO statuscode;
		
		RETURN;
	END IF;
-----/End validate

	IF NOT EXISTS ( SELECT 1 FROM bet.Round r WHERE r.TicketNo =  TicketNo AND r.game_provider_id = game_provider_id) THEN
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
		(	 id								
			,external_round_id				
			,game_provider_id				
			,player_code					
			,game_id						
			,currency_code					
			,status							
			,game_provider_configuration_id 
			,wallet_id						
			,CURRENT_TIMESTAMP	 AS created_on						
			,CURRENT_TIMESTAMP	 AS updated_on						
			,brand_id						
			,client_status					
			,closed_on						
			,external_created_on			
			,external_closed_on				
			,bet_amount						
			,valid_bet_amount	---		IF ticket Void/Reject/Refund: 0 ELSE: Stake	
			,settle_amount					
			,turnover						
			,win_loss						
			,bet_type						
		)
	ELSE
	BEGIN
		UPDATE  bet.Round
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
	END IF

END;
$BODY$;

-----------------------------------------------
ALTER PROCEDURE dbo.bet_bettrans_sabaplus_bet_insert(uuid,character varying,uuid,text,integer,character varying,smallint,uuid,uuid,uuid,smallint,timestamp with time zone ,timestamp with time zone,timestamp with time zone ,numeric,numeric,numeric,numeric,integer)
    OWNER TO postgres;

-----------------------------------------------
