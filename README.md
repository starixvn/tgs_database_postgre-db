# postgre-db
## dbo.bet_bettrans_sbsw_settle_xtest
## remove param: sporttype
## Settle/Unsettle/Resettle call with all param

## bet.bet_rounds_set_xtest
## remove param:
## add param: extrastatus [character varying], isOnlyWinlostDateChanged [boolean]
## change param: status [smallint -> character varying], player_code [character varying -> text]
## Settle call with these param:
id 
extrastatus
external_round_id 
licenseetxid
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
licenseetxid
brand_id 
game_id
status
actiontype

## Resettle call with these param:
id 
extrastatus
external_round_id 
licenseetxid
brand_id 
game_id
isOnlyWinlostDateChanged
external_closed_on --winlostdate
status
payout
actiontype