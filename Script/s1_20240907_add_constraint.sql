ALTER TABLE IF EXISTS dbo.game_providers
    ADD CONSTRAINT ux_game_providers_code UNIQUE (code);