DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
	SELECT specific_schema AS schema_name,
			routine_name AS function_name
	FROM information_schema.routines
	WHERE routine_type = 'FUNCTION'
		AND specific_schema NOT IN ('pg_catalog', 'information_schema')
		AND (
			routine_name ILIKE '%xtest%' 
			OR routine_name ILIKE '%xpre%' 
			OR routine_name ILIKE '%louisa%' 
			OR routine_name ILIKE '%dominic%' 
			OR routine_name ILIKE '%luke%'
		)
	LOOP
		RAISE NOTICE 'DROPPING FUNCTION: %.%', r.schema_name, r.function_name;
        EXECUTE format('DROP FUNCTION %I.%I;', r.schema_name, r.function_name);
    END LOOP;
END $$;