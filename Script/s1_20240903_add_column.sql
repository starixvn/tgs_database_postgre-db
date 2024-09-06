alter table dbo.game_bets add actual_bet numeric(18,6);
alter table bet.rounds add actual_bet_amount numeric(18,6);
alter table bet.rounds add bet_type integer;