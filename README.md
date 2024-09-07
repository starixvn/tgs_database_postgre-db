# postgre-db
## dbo.bet_bettrans_sbsw_settle_xtest
## remove param: tickettype, SPResult
## add param: game_provider_id [uuid], game_id [integer], StatusCode [character varying], ErrMsg [TEXT]
## Settle/Unsettle/Resettle call with all param

###########################

## dbo.bet_bettrans_sbsw_bet_xtest
## remove param: tickettype, SPResult
## add param: game_provider_id [uuid], game_id [integer], StatusCode [character varying], ErrMsg [TEXT]
## PlaceBet/PlaceBetParlay call with all param

###########################

## bet.bet_rounds_set_xtest
## remove param: actual_bet_amount
## add param: win_loss [numeric], licenseetxid [bigint], StatusCode [character varying]
## change param: bet_type [numeric -> integer]
## ConfirmBet/ ConfirmBetParlay call with these param:
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

## dbo.bet_bettrans_sbsw_get_ticketinfo_xtest
## add param: StatusCode [character varying], Errmsg [text]
## GetTicketInfo call with all params

## dbo.bet_bettrans_sbsw_confirmbet_xtest
## remove param: sporttype, SPResult
## add param: StatusCode [character varying], ErrMsg [TEXT]
## change param: add default value null for all param
## ConfirmBet/ ConfirmBetParlay call with all param

## bet.bet_round_details_set_xtest
## add param: StatusCode [character varying], Errmsg [text]
## ConfirmBet/ ConfirmBetParlay call with all param

## dbo.bet_bettrans_sbsw_cancelbet_xtest
## remove param: spresult, sporttype
## add param: StatusCode [character varying], ErrMsg [TEXT] 
## CancelBet call with all param