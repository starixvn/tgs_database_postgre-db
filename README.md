# postgre-db
## dbo.bet_bettrans_sbsw_settle_xtest
## remove param: sporttype
## Settle/Unsettle/Resettle call with all param

## bet.bet_rounds_set_xtest
## remove param: actual_bet_amount
## add param: extrastatus [character varying], isOnlyWinlostDateChanged [boolean]
## change param: status [smallint -> character varying], player_code [character varying -> text]
## Settle/Unsettle call with these param:
id 
external_round_id 
game_provider_id 
player_code
game_id
currency_code 
game_provider_configuration_id
wallet_id 
brand_id 
external_created_on
licenseetxid
actiontype 
status
external_closed_on --winlostdate
payout
extrastatus

## Resettle call with these param:
id 
external_round_id 
game_provider_id 
player_code
game_id
currency_code 
game_provider_configuration_id
wallet_id 
brand_id 
external_created_on
licenseetxid
actiontype 
status
external_closed_on --winlostdate
payout
extrastatus
isOnlyWinlostDateChanged


## dbo.bet_bettrans_sbsw_cancelbet_xtest
## remove param: spresult, sporttype
## add param: StatusCode [character varying], ErrMsg [TEXT] 
## CancelBet call with all param