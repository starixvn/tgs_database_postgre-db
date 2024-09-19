-- PROCEDURE: dbo.cashservice_exchange_wallet(character varying, character varying, character varying, integer, numeric, numeric, character varying, character varying, character varying, boolean, character varying, character varying, character varying, numeric, numeric, character varying)

-- DROP PROCEDURE IF EXISTS dbo.cashservice_exchange_wallet(character varying, character varying, character varying, integer, numeric, numeric, character varying, character varying, character varying, boolean, character varying, character varying, character varying, numeric, numeric, character varying);

CREATE OR REPLACE PROCEDURE dbo.cashservice_exchange_wallet(
	INOUT transactionid character varying,
	IN walletid character varying,
	IN playercode character varying,
	IN transactiontype integer,
	IN amount numeric,
	IN lockamount numeric,
	IN description character varying,
	IN externalid character varying,
	IN createdbyuserid character varying,
	IN isallownegative boolean DEFAULT true,
	IN providercode character varying DEFAULT NULL::character varying,
	IN operationid character varying DEFAULT NULL::character varying,
	IN action character varying DEFAULT NULL::character varying,
	INOUT balance numeric DEFAULT 0,
	INOUT lockedbalance numeric DEFAULT 0,
	INOUT errorcode character varying DEFAULT '0'::character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE _walletId text;
		_playerCode text;
		_brandId text;
		_balance numeric = 0;
		_lockedBalance numeric = 0;
		_recordOn timestamp = CURRENT_TIMESTAMP;
		_updated_balance numeric = 0;
		_updated_locked_balance numeric = 0;
		_existing_transaction_count integer;
BEGIN    
    -- Retrieve wallet info
    SELECT w.id, w.player_code, w.brand_id, w.balance, w.locked_balance
    INTO _walletId, _playerCode, _brandId, _balance, _lockedBalance
    FROM dbo.wallets as w
    WHERE w.id::text = walletid OR w.player_code = playercode
	FOR UPDATE
    LIMIT 1;

    -- ErrorCodes:
    -- Success = '0'
    -- NotFoundWallet = '203'
    -- InsufficientFunds = '205'
    -- DuplicateTransaction = '202'

    -- Check if wallet exists
    IF (_walletId is null) THEN
        cashservice_exchange_wallet.errorcode := '203';
        RETURN;
    END IF;

    -- Check if transaction with the same _playerCode, externalid, providercode, operationid, action exists
    SELECT COUNT(*)
    INTO _existing_transaction_count
    FROM dbo.transactions tn
    WHERE tn.player_code = _playerCode
      AND tn.external_transaction_id = cashservice_exchange_wallet.externalid
      AND tn.provider_code = cashservice_exchange_wallet.providercode
      AND tn.operation_id = cashservice_exchange_wallet.operationid
      AND tn.action = cashservice_exchange_wallet.action;

    IF _existing_transaction_count > 0 THEN
        -- Return error code if a duplicate transaction is found
        cashservice_exchange_wallet.errorcode := '202';
        RETURN;
    END IF;

    -- Check for sufficient funds (if applicable)
    IF (_lockedBalance + lockamount < 0 OR (isallownegative = false AND _balance + amount < 0)) THEN
        cashservice_exchange_wallet.errorcode := '205';
		RETURN;
    ELSE
        -- Insert transaction if no duplicates found
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

        -- Update the wallet balance and locked balance
        UPDATE dbo.wallets w
        SET
            balance = w.balance + amount,
            locked_balance = w.locked_balance + lockamount,
            snapshot_id = transactionid::uuid,
            updated_on = _recordOn
        WHERE id::text = _walletId;

        cashservice_exchange_wallet.errorcode := '0';
        cashservice_exchange_wallet.balance := _balance + amount;
        cashservice_exchange_wallet.lockedbalance := _lockedBalance + lockamount;

    END IF;
END;
$BODY$;
