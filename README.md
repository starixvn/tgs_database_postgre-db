# postgre-db
## dbo.bet_bettrans_sbsw_settle_xtest
## remove param: sporttype
## Settle/Unsettle/Resettle call with all param

## bet.bet_rounds_set_xtest
## remove param: 
created_on, closed_on, updated_on, bet_amount, valid_bet_amount, settle_amount, commission, turnover, win_loss, 
tie_bet_adjustment, client_status, reopen_turnover_adjustment, reopened_on, effective_betting_percentage, bet_type
## add param: extrastatus [character varying], isOnlyWinlostDateChanged [boolean]
## change param: status [smallint -> character varying], player_code [character varying -> text]
## Settle call with these param:
id
extrastatus
external_round_id 
brand_id 
game_id
external_closed_on --winlostdate
status
payout
actiontype

## Unsettle call with these param:
id
extrastatus
external_round_id 
brand_id 
game_id
status
actiontype

## Resettle call with these param:
id
extrastatus
external_round_id 
brand_id 
game_id
isOnlyWinlostDateChanged
external_closed_on --winlostdate
status
payout
actiontype