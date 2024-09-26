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

GRANT CONNECT ON DATABASE TSDB TO app_reader_writer;


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

GRANT CONNECT ON DATABASE TSDB TO app_reader;


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

GRANT CONNECT ON DATABASE TSDB TO app_bet_service;


CREATE ROLE app_cash_service WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  NOBYPASSRLS
  CONNECTION LIMIT 1000
  PASSWORD '@1234aA@';

GRANT CONNECT ON DATABASE TSDB TO app_cash_service;

--Run after restore DB 
GRANT USAGE ON SCHEMA dbo TO app_reader_writer;
GRANT USAGE ON SCHEMA backup TO app_reader_writer;
GRANT USAGE ON SCHEMA bet TO app_reader_writer;
GRANT USAGE ON SCHEMA log TO app_reader_writer;
GRANT USAGE ON SCHEMA partman TO app_reader_writer;
GRANT USAGE ON SCHEMA public TO app_reader_writer;
GRANT USAGE ON SCHEMA report TO app_reader_writer;
GRANT USAGE ON SCHEMA information_schema TO app_reader_writer;
GRANT USAGE ON SCHEMA pg_catalog TO app_reader_writer;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dbo TO app_reader_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA backup TO app_reader_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bet TO app_reader_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA log TO app_reader_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA partman TO app_reader_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_reader_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA report TO app_reader_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO app_reader_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO app_reader_writer;

GRANT USAGE ON SCHEMA dbo TO app_reader;
GRANT USAGE ON SCHEMA backup TO app_reader;
GRANT USAGE ON SCHEMA bet TO app_reader;
GRANT USAGE ON SCHEMA log TO app_reader;
GRANT USAGE ON SCHEMA partman TO app_reader;
GRANT USAGE ON SCHEMA public TO app_reader;
GRANT USAGE ON SCHEMA report TO app_reader;
GRANT USAGE ON SCHEMA information_schema TO app_reader;
GRANT USAGE ON SCHEMA pg_catalog TO app_reader;

GRANT SELECT ON ALL TABLES IN SCHEMA dbo TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA backup TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA bet TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA log TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA partman TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA report TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO app_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO app_reader;

GRANT USAGE ON SCHEMA dbo TO app_bet_service;
GRANT USAGE ON SCHEMA backup TO app_bet_service;
GRANT USAGE ON SCHEMA bet TO app_bet_service;
GRANT USAGE ON SCHEMA log TO app_bet_service;
GRANT USAGE ON SCHEMA partman TO app_bet_service;
GRANT USAGE ON SCHEMA public TO app_bet_service;
GRANT USAGE ON SCHEMA report TO app_bet_service;
GRANT USAGE ON SCHEMA information_schema TO app_bet_service;
GRANT USAGE ON SCHEMA pg_catalog TO app_bet_service;

GRANT USAGE ON SCHEMA dbo TO app_cash_service;
GRANT USAGE ON SCHEMA backup TO app_cash_service;
GRANT USAGE ON SCHEMA bet TO app_cash_service;
GRANT USAGE ON SCHEMA log TO app_cash_service;
GRANT USAGE ON SCHEMA partman TO app_cash_service;
GRANT USAGE ON SCHEMA public TO app_cash_service;
GRANT USAGE ON SCHEMA report TO app_cash_service;
GRANT USAGE ON SCHEMA information_schema TO app_cash_service;
GRANT USAGE ON SCHEMA pg_catalog TO app_cash_service;

REVOKE INSERT, DELETE, UPDATE ON dbo.transactions FROM app_reader_writer;
REVOKE INSERT, DELETE, UPDATE ON dbo.wallets FROM app_reader_writer;