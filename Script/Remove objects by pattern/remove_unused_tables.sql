DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
	SELECT table_schema AS schema_name,
			table_name AS table_name
	FROM information_schema.tables 
	WHERE table_type = 'BASE TABLE'
		AND table_schema NOT IN ('pg_catalog', 'information_schema')
		AND (
			table_name ILIKE '%xtest%' 
			OR table_name ILIKE '%xpre%' 
			OR table_name ILIKE '%louisa%' 
			OR table_name ILIKE '%dominic%' 
			OR table_name ILIKE '%luke%'
		)
	LOOP
		RAISE NOTICE 'DROPPING TABLE: %.%', r.schema_name, r.table_name;
        EXECUTE format('DROP TABLE %I.%I;', r.schema_name, r.table_name);
    END LOOP;
END $$;