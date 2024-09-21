DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
	SELECT table_schema AS schema_name,
			table_name AS view_name
	FROM information_schema.tables 
	WHERE table_type = 'VIEW'
		AND table_schema NOT IN ('pg_catalog', 'information_schema')
		AND (
			table_name ILIKE '%xtest%' 
			OR table_name ILIKE '%xpre%' 
			OR table_name ILIKE '%louisa%' 
			OR table_name ILIKE '%dominic%' 
			OR table_name ILIKE '%luke%'
		)
	LOOP
		RAISE NOTICE 'DROPPING VIEW: %.%', r.schema_name, r.view_name;
        EXECUTE format('DROP VIEW %I.%I;', r.schema_name, r.view_name);
    END LOOP;
END $$;