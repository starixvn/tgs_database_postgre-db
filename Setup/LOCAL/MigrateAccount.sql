CREATE ROLE app_reader_writer WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
  CONNECTION LIMIT 1000
  PASSWORD '@1234aA@';

GRANT CONNECT ON DATABASE tgs_staging TO app_reader_writer;

GRANT pg_read_all_data TO app_reader_writer;
GRANT pg_write_all_data TO app_reader_writer;

CREATE ROLE app_reader WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
  CONNECTION LIMIT 1000
  PASSWORD '@1234aA@';

GRANT CONNECT ON DATABASE tgs_staging TO app_reader;

GRANT pg_read_all_data TO app_reader;

CREATE ROLE app_bet_service WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
  CONNECTION LIMIT 1000
  PASSWORD '@1234aA@';

GRANT CONNECT ON DATABASE tgs_staging TO app_bet_service;

GRANT USAGE ON SCHEMA bet, dbo TO app_bet_service;

REASSIGN OWNED BY tgs_app TO postgres;

REASSIGN OWNED BY tgs_migration TO postgres;

REASSIGN OWNED BY tgs_reader TO postgres;

REASSIGN OWNED BY tgs_devops TO postgres;

REASSIGN OWNED BY tgsstagingsuprtadmin TO postgres;

-- Disable unused accounts
ALTER ROLE tgs_app WITH NOLOGIN;
ALTER ROLE tgs_devops WITH NOLOGIN;
ALTER ROLE tgs_migration WITH NOLOGIN;
ALTER ROLE tgs_reader WITH NOLOGIN;
ALTER ROLE tgsstagingsuprtadmin WITH NOLOGIN;


-- Revoke all table privileges
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE tableowner != 'tgs_reader' 
    LOOP
        EXECUTE format('REVOKE ALL PRIVILEGES ON TABLE %I.%I FROM tgs_reader;', r.schemaname, r.tablename);
    END LOOP;
END $$;

-- Revoke all view privileges
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT schemaname, viewname
        FROM pg_views 
        WHERE viewowner != 'tgs_reader' 
    LOOP
        EXECUTE format('REVOKE ALL PRIVILEGES ON %I.%I FROM tgs_reader;', r.schemaname, r.viewname);
    END LOOP;
END $$;

-- Revoke all sequence privileges
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT schemaname, sequencename 
        FROM pg_sequences 
        WHERE sequenceowner != 'tgs_reader' 
    LOOP
        EXECUTE format('REVOKE ALL PRIVILEGES ON SEQUENCE %I.%I FROM tgs_reader;', r.schemaname, r.sequencename);
    END LOOP;
END $$;

-- Revoke usage on all schemas
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT nspname 
        FROM pg_namespace 
        WHERE nspname NOT IN ('pg_catalog', 'information_schema') 
    LOOP
        EXECUTE format('REVOKE USAGE ON SCHEMA %I FROM tgs_reader;', r.nspname);
    END LOOP;
END $$;

REVOKE EXECUTE ON FUNCTION public.subpath(ltree, integer) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.subpath(ltree, integer, integer) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree, ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree, ltree, ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree, ltree, ltree, ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree, ltree, ltree, ltree, ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree, ltree, ltree, ltree, ltree, ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree, ltree, ltree, ltree, ltree, ltree, ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.lca(ltree[]) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION backup.move_round_data_to_backup() FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION backup.move_round_data_to_backup(start_date date, end_date date) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION backup.move_game_actions_tables_to_backup() FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION backup.move_game_actions_tables_to_backup(start_date date, end_date date) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.index(ltree, ltree) FROM tgs_reader;
REVOKE EXECUTE ON FUNCTION public.index(ltree, ltree, integer) FROM tgs_reader;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
		SELECT n.nspname, p.proname, pg_get_function_result(p.oid) AS result
		FROM pg_proc p
		JOIN pg_namespace n ON n.oid = p.pronamespace
		LEFT JOIN information_schema.routines ri ON ri.routine_schema = n.nspname AND ri.routine_name = p.proname
		WHERE has_function_privilege('tgs_reader', p.oid, 'EXECUTE')
			AND ri.routine_type = 'FUNCTION'
			AND n.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %I.%I FROM tgs_reader;', r.nspname, r.proname);
    END LOOP;
END $$;



-- Revoke privileges on the database
REVOKE ALL PRIVILEGES ON DATABASE tgs_staging FROM tgs_reader;
-- Finally, drop the user
REVOKE USAGE ON SCHEMA backup, bet, dbo, log, report FROM tgs_reader;
REVOKE CREATE ON SCHEMA backup, bet, dbo, log, report FROM tgs_reader;

DROP ROLE tgs_reader;
