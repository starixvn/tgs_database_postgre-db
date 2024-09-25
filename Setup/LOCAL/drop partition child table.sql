
do 
$$
	declare r record;
begin
	for r in 
	select schemaname, tablename
	from pg_tables
	where tablename like '%_p202%'
		and schemaname not in ('information_schema', 'pg_catalog')

	loop 
		raise notice 'dropping table: %.%', r.schemaname, r.tablename;
		execute format('DROP TABLE %I.%I;',r.schemaname, r.tablename);
	end loop;
end;
$$

