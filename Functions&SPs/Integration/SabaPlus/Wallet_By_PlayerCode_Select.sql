-- PROCEDURE: dbo.cashservice_exchange_wallet(character varying, character varying, character varying, integer, numeric, numeric, character varying, character varying, character varying, boolean, character varying, character varying, character varying, numeric, numeric, character varying)

-- DROP PROCEDURE IF EXISTS dbo.cashservice_exchange_wallet(character varying, character varying, character varying, integer, numeric, numeric, character varying, character varying, character varying, boolean, character varying, character varying, character varying, numeric, numeric, character varying);

CREATE OR REPLACE PROCEDURE dbo.Wallet_By_PlayerCode_Select(
	operatorcustid 	character varying
	,TicketNo		character varying 	DEFAULT NULL::character varying,
	,Seq			character varying 	DEFAULT NULL::character varying
	,Payout			numeric 			DEFAULT 0.0,
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
	bal decimal;
begin

	IF TicketNo IS NOT NULL
	(
		SELECT  CASE WHEN MAX(s.Sq) IS NULL THEN MAX(b.sq) END
		FROM dbo.Bettrans_SabaPlus_Bet AS b
		FULL JOIN dbo.Bettrans_SabaPlus_Settle AS s
			ON b.TicketNo = s.TicketNo
		WHERE b.TicketNo = TicketNo
	)
	select w.balance into bal
	from dbo.wallets w
	where w.id = $1;

	return bal;
select *   from dbo.wallets w
END;
$BODY$;
LANGUAGE 'plpgsql'
AS $BODY$
	DECLARE _walletId text;
			_playerCode text;
			_brandId text;
			_balance numeric = 0;
			_lockedBalance numeric = 0;
			_recordOn timestamp = CURRENT_TIMESTAMP;
BEGIN    
        SELECT w.id, w.player_code, w.brand_id, w.balance, w.locked_balance
        INTO _walletId, _playerCode, _brandId, _balance, _lockedBalance
        FROM dbo.wallets as w
		WHERE w.id::text = walletid OR w.player_code = playercode
		LIMIT 1;

        /* ErrorCodes
			Success = 0,
			NotFoundWallet = '203',
			InsufficientFunds = '205'
		*/
		IF (_walletId is null) THEN
				cashservice_exchange_wallet.errorcode := '203';
			RETURN;
		END IF;

		IF (_lockedBalance + lockamount < 0 OR (isallownegative = false AND _balance + amount < 0)) THEN
			cashservice_exchange_wallet.errorcode := '205';
		ELSE
			INSERT INTO dbo.transactions
			(
				id, 
				player_code, 
				wallet_id, 
				brand_id, 
				external_transaction_id, 
				amount, 
				balance, 
				description, 
				type, 
				recorded_on, 
				sent_on, 
				created_by_user_id, 
				locked_balance, 
				lock_amount,
				provider_code,
				operation_id,
				action
			)
			VALUES 
			(
				transactionid::uuid, 
				_playerCode, 
				_walletId::uuid, 
				_brandId::uuid, 
				externalid, 
				amount, 
				_balance + amount, 
				description, 
				transactiontype, 
				_recordOn, 
				null, 
				createdbyuserid::uuid, 
				_lockedBalance + lockamount, 
				lockamount,
				providercode,
				operationid,
				action
			);
			
			UPDATE dbo.wallets
			SET
				balance = _balance + amount,
				locked_balance = _lockedBalance + lockamount,
				snapshot_id = transactionid::uuid,
				updated_on = _recordOn
			WHERE id::text = _walletId;
			
			cashservice_exchange_wallet.errorcode := '0';
			cashservice_exchange_wallet.balance := _balance + amount;
			cashservice_exchange_wallet.lockedbalance := _lockedBalance + lockamount;
		END IF;
END ; 
$BODY$;
ALTER PROCEDURE dbo.cashservice_exchange_wallet(character varying, character varying, character varying, integer, numeric, numeric, character varying, character varying, character varying, boolean, character varying, character varying, character varying, numeric, numeric, character varying)
    OWNER TO postgres;
