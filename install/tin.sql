--
-- This SHOULD create a database that is ready to go for tin.  
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE admin;
ALTER ROLE admin WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57037abb4885de0d3521db711dc634826';
CREATE ROLE adminprivate;
ALTER ROLE adminprivate WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md53daafadd61518998cfcfce69e1ae1267';
CREATE ROLE btzuser;
ALTER ROLE btzuser WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md5138ad172f74f342ffb524cdf491ec8af';
CREATE ROLE chembl;
ALTER ROLE chembl WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
-- CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;
CREATE ROLE root;
ALTER ROLE root WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE test;
ALTER ROLE test WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE tinuser;
ALTER ROLE tinuser WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md516a847029f27f45ebc318a781bc3df5a';
CREATE ROLE zinc21;
ALTER ROLE zinc21 WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md50893f3c540509e267e4b24cef189e262';
CREATE ROLE zincfree;
ALTER ROLE zincfree WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md52a08c13b63d4e1257e7cea48d468a5de';
CREATE ROLE zincread;
ALTER ROLE zincread WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57d8bffd68d271c7d10510986e086ce65';
CREATE ROLE zincwrite;
ALTER ROLE zincwrite WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57c0a812310ac0a935e992599d5df7e0a';






--
-- PostgreSQL database cluster dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


--
-- -- Name: rdkit; Type: EXTENSION; Schema: -; Owner: -
-- --

-- CREATE EXTENSION IF NOT EXISTS rdkit WITH SCHEMA public;


-- --
-- -- Name: EXTENSION rdkit; Type: COMMENT; Schema: -; Owner: 
-- --

-- COMMENT ON EXTENSION rdkit IS 'Cheminformatics functionality for PostgreSQL.';


SET default_tablespace = '';

SET default_table_access_method = heap;

create table public.meta (varname text, svalue text, ivalue bigint);
insert into public.meta (values ('n_partitions', 'n_partitions', 128));
insert into public.meta(varname, ivalue) values ('version', 0);

create or replace procedure public.create_table_partitions (tabname text, tmp text) language plpgsql AS $$
    declare
        n_partitions int;
        i int;
    begin
        select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
        for i in 0..(n_partitions-1) loop
            execute(format('create %s table %s_p%s partition of %s for values with (modulus %s, remainder %s)', tmp, tabname, i, tabname, n_partitions, i));
        end loop;
    end;
$$;

-- create logg function on public schema
create or replace function public.logg(t text) returns int as $$
begin
	        raise info '[%]: %', clock_timestamp(), t;
		        return 0;
end;
$$ language plpgsql;


-- START SEQUENCES
CREATE SEQUENCE public.cat_content_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.catalog_cat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.sub_id_seq
    AS bigint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE public.cat_sub_itm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

create SEQUENCE public.tranche_id 
    START WITH 1
    INCREMENT BY 1 
    NO MINVALUE 
    NO MAXVALUE 
    CACHE 1;

--
-- Name: catalog; Type: TABLE; Schema: public; Owner: root
--
-- START TABLES
CREATE TABLE public.catalog (
    cat_id integer default nextval('public.catalog_cat_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    version character varying,
    short_name character varying NOT NULL,
    free boolean DEFAULT true NOT NULL,
    purchasable integer DEFAULT 0 NOT NULL,
    updated date NOT NULL,
    website character varying,
    email character varying,
    phone character varying,
    fax character varying,
    item_template character varying,
    pubchem boolean DEFAULT true NOT NULL,
    integration integer DEFAULT 0 NOT NULL,
    bb boolean DEFAULT false NOT NULL,
    np integer DEFAULT 0 NOT NULL,
    drug integer DEFAULT 0 NOT NULL,
    original_size integer DEFAULT 0,
    num_filtered integer DEFAULT 0,
    num_unique integer DEFAULT 0,
    num_substances integer DEFAULT 0,
    num_items integer DEFAULT 0,
    num_biogenic integer,
    num_endogenous integer,
    num_inman integer,
    num_world integer
);

CREATE TABLE public.catalog_content (
    cat_content_id bigint DEFAULT nextval('public.cat_content_id_seq'::regclass),
    cat_id_fk integer NOT NULL,
    supplier_code text UNIQUE NOT NULL,
    depleted boolean,
    tranche_id smallint default 0 not null
) PARTITION BY hash(supplier_code);

CREATE TABLE public.catalog_id (
	cat_content_id bigint NOT NULL,
	cat_partition_fk smallint 
) partition by hash(cat_content_id);

CREATE TABLE public.catalog_substance (
    cat_content_fk bigint NOT NULL,
    sub_id_fk bigint NOT NULL,
    grp_id bigint,
    PRIMARY KEY (sub_id_fk, cat_content_fk)
) PARTITION BY hash(sub_id_fk);

CREATE TABLE public.catalog_substance_cat (
    sub_id_fk bigint NOT NULL,
    cat_content_fk bigint NOT NULL,
    grp_id bigint,
    PRIMARY KEY (cat_content_fk, sub_id_fk)
) PARTITION BY hash(cat_content_fk);

CREATE TABLE public.catalog_substance_grp (
    sub_id_fk bigint NOT NULL,
    cat_content_fk bigint NOT NULL,
    grp_id bigint NOT NULL,
    PRIMARY KEY (grp_id, sub_id_fk, cat_content_fk)
) PARTITION BY hash(grp_id);

CREATE TABLE public.substance (
    sub_id bigint NOT NULL,
    smiles character varying NOT NULL,
    purchasable smallint,
    date_updated date DEFAULT now() NOT NULL,
    inchikey character(27),
    tranche_id smallint default 0 not null
) PARTITION BY hash(smiles);

CREATE TABLE public.zinc_3d_map (
    sub_id bigint,
    tranche_id smallint,
    tarball_id int,
    grp_id int
) PARTITION BY hash(sub_id);

CREATE TABLE public.substance_id (
    sub_id bigint NOT NULL,
    sub_partition_fk smallint
) PARTITION BY hash(sub_id);

alter table public.substance_id add primary key (sub_id);
create index substance_id_partition_fk_idx on public.substance_id (sub_partition_fk);

CREATE TABLE public.zinc_tarballs (
    tartball_path text,
    tarball_id int
);

CREATE TABLE public.tranches (
    tranche_id smallint default nextval('public.tranche_id'::regclass) NOT NULL,
    tranche_name varchar
);

CREATE TABLE public.patches (
	patchname varchar,
    patched boolean
);


create table public.sub_dups_corrections (
    sub_id_wrong bigint,
    sub_id_right bigint
);

create table public.tranche_id_corrections (
    sub_id bigint,
    tranche_id_wrong smallint
);

create table public.cat_dups_corrections (
    code_id_wrong bigint,
    code_id_right bigint
);

create table public.catsub_dups_corrections (
    cat_sub_itm_id bigint
);


SELECT pg_catalog.setval('public.catalog_cat_id_seq', 1, false);

SELECT pg_catalog.setval('public.cat_content_id_seq', 1, true);

SELECT pg_catalog.setval('public.cat_sub_itm_id_seq', 11, true);

SELECT pg_catalog.setval('public.sub_id_seq', 11, true);

INSERT INTO public.patches VALUES ('postgres', true), ('escape', true), ('substanceopt', true), ('normalize_p1', true), ('normalize_p2', true);

-- CREATE INDEX catalog_substance_sub_id_fk_idx ON public.catalog_substance USING btree (sub_id_fk, tranche_id);

-- CREATE INDEX catalog_substance_cat_id_fk_idx ON public.catalog_substance USING btree (cat_content_fk);

CREATE INDEX catalog_content_supplier_code_idx ON public.catalog_content USING hash (supplier_code);

GRANT ALL ON TABLE public.catalog TO test;
GRANT SELECT ON TABLE public.catalog TO zincread;
GRANT SELECT ON TABLE public.catalog TO zincfree;
GRANT ALL ON TABLE public.catalog TO adminprivate;
GRANT ALL ON TABLE public.catalog TO admin;

GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO adminprivate;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO tinuser;

GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO adminprivate;
GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO tinuser;

GRANT ALL ON TABLE public.catalog_content TO test;
GRANT SELECT ON TABLE public.catalog_content TO zincread;
GRANT SELECT ON TABLE public.catalog_content TO zincfree;
GRANT ALL ON TABLE public.catalog_content TO adminprivate;
GRANT ALL ON TABLE public.catalog_content TO admin;

GRANT ALL ON TABLE public.catalog_substance TO test;
GRANT SELECT ON TABLE public.catalog_substance TO zincread;
GRANT SELECT ON TABLE public.catalog_substance TO zincfree;
GRANT ALL ON TABLE public.catalog_substance TO adminprivate;
GRANT ALL ON TABLE public.catalog_substance TO admin;

GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO adminprivate;
GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO tinuser;

GRANT SELECT ON TABLE public.substance TO zincread;
GRANT SELECT ON TABLE public.substance TO zincfree;
GRANT ALL ON TABLE public.substance TO test;
GRANT ALL ON TABLE public.substance TO adminprivate;
GRANT ALL ON TABLE public.substance TO admin;

GRANT SELECT,USAGE ON SEQUENCE public.sub_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.sub_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.sub_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.sub_id_seq TO adminprivate;

-- ALTER TABLE public.catalog_content OWNER TO root;
-- ALTER TABLE public.catalog_cat_id_seq OWNER TO root;
ALTER SEQUENCE public.catalog_cat_id_seq OWNED BY public.catalog.cat_id;

-- ALTER TABLE public.catalog_substance OWNER TO tinuser;
-- ALTER TABLE public.cat_sub_itm_id_seq OWNER TO tinuser;
-- ALTER SEQUENCE public.cat_sub_itm_id_seq OWNED BY public.catalog_substance.cat_sub_itm_id;

-- ALTER TABLE public.substance OWNER TO tinuser;
-- ALTER TABLE public.sub_id_seq OWNER TO tinuser;
ALTER SEQUENCE public.sub_id_seq OWNED BY public.substance.sub_id;

ALTER TABLE public.cat_content_id_seq OWNER TO tinuser;

call public.create_table_partitions('public.catalog_content', '');
call public.create_table_partitions('public.catalog_id', '');
call public.create_table_partitions('public.catalog_substance', '');
call public.create_table_partitions('public.catalog_substance_cat', '');
call public.create_table_partitions('public.catalog_substance_grp', '');
call public.create_table_partitions('public.substance', '');
call public.create_table_partitions('public.zinc_3d_map', '');
call public.create_table_partitions('public.substance_id', '');

SET SEARCH_PATH = 'public';

--BEGIN ZINC_ID_PARTITIONED_PATCH

create or replace procedure export_ids_from_substance () language plpgsql as $$

    declare
        n_partitions int;
        i int;
    begin
        select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;

        for i in 0..(n_partitions-1) loop

            execute(format('insert into substance_id (sub_id, sub_partition_fk) (select sub_id, %s from substance_p%s)', i, i));

        end loop;

    end;

$$;

-- function to look up just one substance by sub_id. faster for small batches
create or replace function get_substance_by_id (sub_id_q bigint) returns text as $$

    declare
        part_id int;
        sub text;
    begin
        select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
        if part_id is null then
            raise info '%', sub_id_q;
            select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
            select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
            raise info '% %', sub_id_q, part_id;
        end if;
        execute(format('select smiles from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
        return sub;
    end;

$$ language plpgsql;

create or replace function get_substance_by_id_pfk (sub_id_q bigint, part_id smallint) returns text as $$
    declare 
        sub text;
    begin
        execute(format('select smiles from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
        return sub;
    end;

$$ language plpgsql;

-- like get_many_substance_by_id, but chilling out with the temporary tables
-- for a lookup in the range of 10s of Ks it will be much simpler to ORDER BY on the partition key and let the cache handle things
create or replace procedure get_some_substances_by_id (sub_id_input_tabname text, substance_output_tabname text) as $$
declare
    extrafields text[];
    extrafields_decl_it text;
    extrafields_decl text;
    subquery_1 text;
    subquery_2 text;
    query text;
begin
    extrafields := get_shared_columns(sub_id_input_tabname, substance_output_tabname, 'sub_id', '{}');

    if array_length(extrafields, 1) > 0 then
        extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
        extrafields_decl := ',' || cols_declare(extrafields, '');
    else
        extrafields_decl := '';
        extrafields_decl_it := '';
    end if;

    subquery_1 := format('select sid.sub_id, sid.sub_partition_fk %1$s from %2$s it left join substance_id sid on it.sub_id = sid.sub_id order by sub_partition_fk', extrafields_decl_it, sub_id_input_tabname);

    subquery_2 := format('select case when not sub_id is null then get_substance_by_id_pfk(sub_id, sub_partition_fk) else null end, sub_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

    query := format('insert into %3$s (smiles, sub_id %1$s) (%2$s)', extrafields_decl, subquery_2, substance_output_tabname);

    execute(query);
end;
$$ language plpgsql;

-- procedure to force data locality for large lookups by sub_id
-- turns out I can use compiiler hints like /* USE_HASH(a) */ to force hash joins
-- wish I had known that before I ripped the whole system up
-- still, there are advantages to this partitioning strategy. For one, it allows incremental progress on the upload, and easier maintenance of indexes etc.
create or replace procedure get_many_substances_by_id (sub_id_input_tabname text, substance_output_tabname text, extra_field text) as $$

    declare 
        retval text[];
        n_partitions int;
        i int;
        t_start timestamptz;
    begin
        t_start := clock_timestamp();

        if not extra_field is null then
            execute(format('create temporary table subids_by_subid (sub_id bigint, %s %s) partition by hash(sub_id)', sc_colname(extra_field), sc_coltype(extra_field)));
        else
            create temporary table subids_by_subid (
                sub_id bigint
            ) partition by hash(sub_id);
        end if;

        call create_table_partitions('subids_by_subid'::text, 'temporary'::text);

        if not extra_field is null then
            execute(format('create temporary table subids_by_pfk (sub_id bigint, sub_partition_fk smallint, %s %s) partition by list(sub_partition_fk)', sc_colname(extra_field), sc_coltype(extra_field)));
        else
            create temporary table subids_by_pfk (
                sub_id bigint,
                sub_partition_fk smallint
            ) partition by list(sub_partition_fk);
        end if;

        select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
        for i in 0..(n_partitions-1) loop
            execute(format('create temporary table subids_by_pfk_p%s partition of subids_by_pfk for values in (%s)', i, i));
        end loop;

        create temporary table subids_by_pfk_pn partition of subids_by_pfk for values in (null);

        execute(format('insert into subids_by_subid (select sub_id%s from %s)', sub_id_input_tabname));

        for i in 0..(n_partitions-1) loop
            execute(format('insert into subids_by_pfk (select ss.sub_id, sbid.sub_partition_fk from subids_by_subid_p%s ss left join substance_id_p%s sbid on ss.sub_id = sbid.sub_id)', i, i));
        end loop;

        for i in 0..(n_partitions-1) loop
            execute(format('insert into %s (sub_id, smiles, tranche_id) (select sp.sub_id, sb.smiles, sb.tranche_id from subids_by_pfk_p%s sp left join substance_p%s sb on sp.sub_id = sb.sub_id)', substance_output_tabname, i, i));
        end loop;

        execute(format('insert into %s (sub_id) (select sub_id from subids_by_pfk_pn)', substance_output_tabname));

        drop table subids_by_subid;
        drop table subids_by_pfk;

        raise notice 'time spent=%s', clock_timestamp() - t_start;
    end;

$$ language plpgsql;

do $$
    declare
        i int;
        n_partitions int;
    begin
        select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
        for i in 0..(n_partitions-1) loop
            execute(format('alter table if exists substance_tp%s rename to substance_p%s', i, i));
            execute(format('alter table if exists substance_t_p%s rename to substance_p%s', i, i));
        end loop;
    end;
$$ language plpgsql;

-- END ZINC_ID_PARTITIONED_PATCH

-- BEGIN CAT_ID_PARTITIONED_PATCH
create or replace procedure export_ids_from_catalog_content () language plpgsql as $$
    declare
        n_partitions int;
        i int;
    begin
        select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
        for i in 0..(n_partitions-1) loop
            execute(format('insert into catalog_id (cat_content_id, cat_partition_fk) (select cat_content_id, %s from catalog_content_p%s)', i, i));
        end loop;
    end;
$$;

-- function to look up just one substance by cat_content_id. faster for small batches
create or replace function get_code_by_id (cc_id_q bigint) returns text as $$
    declare
        part_id int;
        code text;
    begin
        select cat_partition_fk from catalog_id ccid where ccid.cat_content_id = cc_id_q into part_id;
        execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', part_id, cc_id_q)) into code;
        return code;
    end;

$$ language plpgsql;

create or replace function get_code_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns text as $$
    declare
        code text;
    begin	
        execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into code;
        return code;
    end;
$$ language plpgsql;

create or replace function get_cat_id_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns smallint as $$
    declare
        cat_id smallint;
    begin
        execute(format('select cat_id_fk from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into cat_id;
        return cat_id;
    end;
$$ language plpgsql;

-- like get_many_substance_by_id, but chilling out with the temporary tables
    -- for a lookup in the range of 10s of Ks it will be much simpler to ORDER BY on the partition key and let the cache handle things
    create or replace procedure get_some_codes_by_id (code_id_input_tabname text, code_output_tabname text) as $$
            declare
                    extrafields text[];
                    extrafields_decl_it text;
                    extrafields_decl text;
                    subquery_1 text;
                    subquery_2 text;
                    query text;
            begin
                    extrafields := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

                    if array_length(extrafields, 1) > 0 then
                            extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
                            extrafields_decl := ',' || cols_declare(extrafields, '');
                    else
                            extrafields_decl := '';
                            extrafields_decl_it := '';
                    end if;

                    subquery_1 := format('select cid.cat_content_id, cid.cat_partition_fk %1$s from %2$s it left join catalog_id cid on it.cat_content_id = cid.cat_content_id order by cat_partition_fk', extrafields_decl_it, code_id_input_tabname);

                    subquery_2 := format('select get_code_by_id_pfk(cat_content_id, cat_partition_fk) supplier_code, cat_content_id, get_cat_id_by_id_pfk(cat_content_id, cat_partition_fk) cat_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

                    query := format('insert into %3$s (supplier_code, cat_content_id, cat_id_fk %1$s) (%2$s)', extrafields_decl, subquery_2, code_output_tabname);

                    execute(query);
            end;
    $$ language plpgsql;	

-- procedure to force data locality for large lookups by cat_content_id
create or replace procedure get_many_codes_by_id (code_id_input_tabname text, code_output_tabname text, outputnull boolean) as $$

    declare 
        retval text[];
        n_partitions int;
        i int;
        t_start timestamptz;
    begin
        t_start := clock_timestamp();
        create temporary table catids_by_catid (
            cat_content_id bigint
        ) partition by hash(cat_content_id);

        call create_table_partitions('catids_by_catid'::text, 'temporary'::text);

        create temporary table catids_by_pfk (
            cat_content_id bigint,
            cat_partition_fk smallint
        ) partition by list(cat_partition_fk);

        select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
        for i in 0..(n_partitions-1) loop
            execute(format('create temporary table catids_by_pfk_p%s partition of catids_by_pfk for values in (%s)', i, i));
        end loop;

        create temporary table catids_by_pfk_pn partition of catids_by_pfk for values in (null);

        execute(format('insert into catids_by_catid (select cat_content_id from %s)', code_id_input_tabname));

        for i in 0..(n_partitions-1) loop
            execute(format('insert into catids_by_pfk (select cc.cat_content_id, ccid.cat_partition_fk from catids_by_catid_p%s cc left join catalog_id_p%s ccid on cc.cat_content_id = ccid.cat_content_id)', i, i));
        end loop;

        for i in 0..(n_partitions-1) loop
            execute(format('insert into %s (cat_content_id, supplier_code, cat_id_fk) (select cp.cat_content_id, cc.supplier_code, cc.cat_id_fk from catids_by_pfk_p%s cp left join catalog_content_p%s cc on cp.cat_content_id = cc.cat_content_id)', code_output_tabname, i, i));
        end loop;

        if outputnull then
            execute(format('insert into %s (cat_content_id) (select cat_content_id from catids_by_pfk_pn)', code_output_tabname));
        end if;

        drop table catids_by_catid;
        drop table catids_by_pfk;

        raise notice 'time spent=%s', clock_timestamp() - t_start;
    end;

$$ language plpgsql;

-- fix catalog_content table name if applicable
do $$
        declare
                i int;
                n_partitions int;
        begin
                select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
                for i in 0..(n_partitions-1) loop
                        execute(format('alter table if exists catalog_content_tp%s rename to catalog_content_p%s', i, i));
        execute(format('alter table if exists catalog_content_t_p%s rename to catalog_content_p%s', i, i));
                end loop;
        end;
$$ language plpgsql;

-- END CAT_ID_PARTITIONED_PATCH

-- BEGIN EXPORT PATCH
CREATE OR REPLACE FUNCTION cols_declare_type (cols text[])
        RETURNS text
        AS $$
DECLARE
        coldecl text[];
BEGIN
        SELECT
                INTO coldecl array_agg(replace(t.col, ':', ' '))
        FROM
                unnest(cols) as t (col);
        RETURN array_to_string(coldecl, ', ');
END;
$$
LANGUAGE plpgsql;

create or replace procedure rename_table_partitions (tabname text, desiredname text)
language plpgsql
as $$
declare
        n_partitions int;
        i int;
begin
        select
                ivalue
        from
                meta
        where
                svalue = 'n_partitions'
        limit 1 into n_partitions;
        for i in 0.. (n_partitions - 1)
        loop
                execute (format('alter table if exists %s_p%s rename to %s_p%s', tabname, i, desiredname, i));
		execute (format('alter table if exists %1$sp%2$s rename to %s_p%s', tabname, i, desiredname, i));
        end loop;
end;
$$;

create or replace procedure get_many_codes_by_id_ (code_id_input_tabname text, code_output_tabname text, input_pre_partitioned boolean) as $$

    declare
        retval text[];
        n_partitions int;
        i int;
        t_start timestamptz;
        extra_columns text[];
        extra_cols_decl_type text;
        extra_cols_decl text;
        extra_cols_decl_cc text;
        extra_cols_decl_cp text;
    begin
    set enable_partitionwise_join = ON;

    extra_columns := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

    if array_length(extra_columns, 1) > 0 then
        extra_cols_decl_type := ',' || cols_declare_type(extra_columns);
        extra_cols_decl := ',' || cols_declare(extra_columns, '');
        extra_cols_decl_cc := ',' || cols_declare(extra_columns, 'cc.');
        extra_cols_decl_cp := ',' || cols_declare(extra_columns, 'cp.');
    else
        extra_cols_decl := '';
        extra_cols_decl_cc := '';
        extra_cols_decl_cp := '';
    end if;

                t_start := clock_timestamp();
    if input_pre_partitioned then
        execute(format('alter table %s rename to catids_by_catid', code_id_input_tabname));
        call rename_table_partitions(code_id_input_tabname, 'catids_by_catid');
    else
        execute(format('create temporary table catids_by_catid (cat_content_id bigint %1$s) partition by hash(cat_content_id)', extra_cols_decl_type));
/*                      create temporary table catids_by_catid (
                        cat_content_id bigint
                ) partition by hash(cat_content_id);*/

                    call create_table_partitions('catids_by_catid'::text, 'temporary'::text);
        execute(format('insert into catids_by_catid (select cat_content_id %s from %s)', extra_cols_decl, code_id_input_tabname));
    end if;

    execute(format('create temporary table catids_by_pfk (cat_content_id bigint, cat_partition_fk smallint %1$s) partition by list(cat_partition_fk)', extra_cols_decl_type));
/*                      create temporary table catids_by_pfk (
                        cat_content_id bigint,
                        cat_partition_fk smallint
                ) partition by list(cat_partition_fk);*/

                select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
                for i in 0..(n_partitions-1) loop
                        execute(format('create temporary table catids_by_pfk_p%s partition of catids_by_pfk for values in (%s)', i, i));
                end loop;

                create temporary table catids_by_pfk_pn partition of catids_by_pfk for values in (null);

                for i in 0..(n_partitions-1) loop
                        execute(format('insert into catids_by_pfk(cat_content_id, cat_partition_fk %3$s) (select cc.cat_content_id, ccid.cat_partition_fk %4$s from catids_by_catid_p%1$s cc left join catalog_id_p%1$s ccid on cc.cat_content_id = ccid.cat_content_id)', i, i, extra_cols_decl, extra_cols_decl_cc));
                end loop;

                for i in REVERSE (n_partitions-1)..0 loop
                        execute(format('insert into %1$s (cat_content_id, supplier_code, cat_id_fk %4$s) (select cp.cat_content_id, cc.supplier_code, cc.cat_id_fk %5$s from catids_by_pfk_p%2$s cp left join catalog_content_p%2$s cc on cp.cat_content_id = cc.cat_content_id)', code_output_tabname, i, i, extra_cols_decl, extra_cols_decl_cp));
                end loop;

                execute(format('insert into %1$s (cat_content_id %2$s) (select cat_content_id %2$s from catids_by_pfk_pn)', code_output_tabname, extra_cols_decl));

    if input_pre_partitioned then
        execute(format('alter table catids_by_catid rename to %s', code_id_input_tabname));
        call rename_table_partitions('catids_by_catid', code_id_input_tabname);
    else
                    drop table catids_by_catid;
    end if;
                drop table catids_by_pfk;

                raise notice 'time spent=%s', clock_timestamp() - t_start;
        end;

$$ language plpgsql;

create or replace procedure get_many_codes_by_id(code_id_input_tabname text, code_output_tabname text) as $$
		begin
			call get_many_codes_by_id_(code_id_input_tabname, code_output_tabname, false);
		end;
$$ language plpgsql;

create or replace procedure get_many_substances_by_id_ (sub_id_input_tabname text, substance_output_tabname text, input_pre_partitioned boolean) as $$

                declare
                        retval text[];
                        n_partitions int;
                        i int;
                        t_start timestamptz;
			extra_cols text[];
			extra_cols_decl text;
			extra_cols_decl_type text;
			extra_cols_decl_ss text;
			extra_cols_decl_sp text;
                begin
                        t_start := clock_timestamp();

			extra_cols := get_shared_columns(sub_id_input_tabname, substance_output_tabname, '', '{{"tranche_id"},{"smiles"},{"sub_id"}}');

			if array_length(extra_cols, 1) > 0 then
				extra_cols_decl_type := ',' || cols_declare_type(extra_cols);
				extra_cols_decl := ',' || cols_declare(extra_cols, '');
				extra_cols_decl_ss := ',' || cols_declare(extra_cols, 'ss.');
				extra_cols_decl_sp := ',' || cols_declare(extra_cols, 'sp.');
			else
				extra_cols_decl := '';
				extra_cols_decl_type := '';
				extra_cols_decl_ss := '';
				extra_cols_decl_sp := '';
			end if;

			if input_pre_partitioned then
				execute(format('alter table %s rename to subids_by_subid', sub_id_input_tabname));
				call rename_table_partitions(sub_id_input_tabname, 'subids_by_subid');
			else
				execute(format('create temporary table subids_by_subid (sub_id bigint %1$s) partition by hash(sub_id)', extra_cols_decl_type));
/*			create temporary table subids_by_subid (
				sub_id bigint
			) partition by hash(sub_id);*/

	                        call create_table_partitions('subids_by_subid'::text, 'temporary'::text);
				execute(format('insert into subids_by_subid (select sub_id %s from %s)', extra_cols_decl, sub_id_input_tabname));
			end if;

			execute(format('create temporary table subids_by_pfk (sub_id bigint, sub_partition_fk smallint %1$s) partition by list(sub_partition_fk)', extra_cols_decl_type));
/*			create temporary table subids_by_pfk (
				sub_id bigint,
				sub_partition_fk smallint
			) partition by list(sub_partition_fk);*/

                        select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;
                        for i in 0..(n_partitions-1) loop
                                execute(format('create temporary table subids_by_pfk_p%s partition of subids_by_pfk for values in (%s)', i, i));
                        end loop;

                        create temporary table subids_by_pfk_pn partition of subids_by_pfk for values in (null);

                        for i in 0..(n_partitions-1) loop
                                execute(format('insert into subids_by_pfk (select ss.sub_id, sbid.sub_partition_fk %3$s from subids_by_subid_p%1$s ss left join substance_id_p%1$s sbid on ss.sub_id = sbid.sub_id)', i, i, extra_cols_decl_ss));
				if not input_pre_partitioned then
					execute(format('drop table subids_by_subid_p%s', i));
				end if;
                        end loop;


			-- I theorize that going in reverse on the next iteration will improve cache access
			-- partition populated more recently == more likely in cache
                        for i in REVERSE (n_partitions-1)..0 loop
                                execute(format('insert into %1$s (sub_id, smiles, tranche_id %5$s) (select sp.sub_id, sb.smiles, sb.tranche_id %4$s from subids_by_pfk_p%2$s sp left join substance_p%2$s sb on sp.sub_id = sb.sub_id)', substance_output_tabname, i, i, extra_cols_decl_sp, extra_cols_decl));
				execute(format('drop table subids_by_pfk_p%s', i));
                        end loop;

                        execute(format('insert into %1$s (sub_id, smiles, tranche_id %2$s) (select sub_id, get_substance_by_id(sub_id) as smiles, get_tranche_by_id(sub_id) as tranche_id %2$s from subids_by_pfk_pn)', substance_output_tabname, extra_cols_decl));

			if input_pre_partitioned then
				execute(format('alter table subids_by_subid rename to %s', sub_id_input_tabname));
				call rename_table_partitions('subids_by_subid', sub_id_input_tabname);
			else
                        	drop table subids_by_subid;
			end if;
                        drop table subids_by_pfk;

                        raise notice 'time spent=%s', clock_timestamp() - t_start;
                end;

$$ language plpgsql;

create or replace procedure get_many_substances_by_id(sub_id_input_tabname text, substance_output_tabname text) as $$
	begin
		call get_many_substances_by_id_(sub_id_input_tabname, substance_output_tabname, false);
	end;
$$ language plpgsql;

create or replace procedure get_many_pairs_by_id_(pair_ids_input_tabname text, pairs_output_tabname text, input_pre_partitioned boolean) as $$
	declare msg text;
	begin
		/* (sub_id bigint, cat_content_id bigint) -> (smiles text, code text, sub_id bigint, tranche_id smallint, cat_id_fk smallint) */
		create temporary table pairs_tempload (smiles text, sub_id bigint, cat_content_id bigint, tranche_id smallint) partition by hash(cat_content_id);
		call create_table_partitions('pairs_tempload', 'temporary');

		call get_many_substances_by_id_(pair_ids_input_tabname, 'pairs_tempload', input_pre_partitioned);

		call get_many_codes_by_id_('pairs_tempload', pairs_output_tabname, true);

		drop table pairs_tempload;

	end;
$$ language plpgsql;

create or replace procedure get_many_pairs_by_id(pair_ids_input_tabname text, pairs_output_tabname text) as $$
	begin
		call get_many_pairs_by_id_(pair_ids_input_tabname, pairs_output_tabname, false);
	end;
$$ language plpgsql;

create or replace procedure get_some_pairs_by_sub_id(sub_ids_input_tabname text, pairs_output_tabname text) as $$
	declare cols text[];
	begin
		create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint, tranche_id smallint);
		create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

		execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id, tranche_id) (select sub_id_fk, cat_content_fk, tranche_id from %s i left join catalog_substance cs on i.sub_id = cs.sub_id_fk)', sub_ids_input_tabname));

		call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

		call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
	end;
$$ language plpgsql;

-- END EXPORT PATCH

-- BEGIN JUNE3 PATCH
---------------------------------------------------------------------------------------------
-- function to look up just one substance by cat_content_id. faster for small batches
create or replace function get_code_by_id (cc_id_q bigint) returns text as $$

declare
	part_id int;
	code text;
begin
	if cc_id_q is null then
		return null;
	end if;
	select cat_partition_fk from catalog_id ccid where ccid.cat_content_id = cc_id_q into part_id;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', part_id, cc_id_q)) into code;
	return code;
end;

$$ language plpgsql;

create or replace function get_code_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns text as $$
declare
	code text;
begin
	if cat_partition_fk is null then
		return null;
	end if;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into code;
	return code;
end;
$$ language plpgsql;

create or replace function get_cat_id_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns smallint as $$
declare
	cat_id smallint;
begin
	if cat_partition_fk is null then
		return null;
	end if;
	execute(format('select cat_id_fk from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into cat_id;
	return cat_id;
end;
$$ language plpgsql;

-- like get_many_substance_by_id, but chilling out with the temporary tables
-- for a lookup in the range of 10s of Ks it will be much simpler to ORDER BY on the partition key and let the cache handle things
create or replace procedure get_some_codes_by_id (code_id_input_tabname text, code_output_tabname text) as $$
declare
	extrafields text[];
	extrafields_decl_it text;
	extrafields_decl text;
	subquery_1 text;
	subquery_2 text;
	query text;
begin
	extrafields := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select cid.cat_content_id, cid.cat_partition_fk %1$s from %2$s it left join catalog_id cid on it.cat_content_id = cid.cat_content_id order by cat_partition_fk', extrafields_decl_it, code_id_input_tabname);

	subquery_2 := format('select get_code_by_id_pfk(cat_content_id, cat_partition_fk) supplier_code, cat_content_id, get_cat_id_by_id_pfk(cat_content_id, cat_partition_fk) cat_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (supplier_code, cat_content_id, cat_id_fk %1$s) (%2$s)', extrafields_decl, subquery_2, code_output_tabname);

	execute(query);
end;
$$ language plpgsql;

-----------------------------------------------------------------------------------------------

drop function if exists get_substance_by_id;
-- function to look up just one substance by sub_id. faster for small batches
create or replace function get_substance_by_id (sub_id_q bigint) returns text as $$
declare
	part_id int;
	sub text;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	end if;
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$ language plpgsql;

drop function if exists get_substance_by_id_pfk;
create or replace function get_substance_by_id_pfk (sub_id_q bigint, part_id smallint) returns text as $$
declare
	sub text;
begin
	if part_id is null then
		return get_substance_by_id(sub_id_q);
	end if;
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$ language plpgsql;

create or replace function get_tranche_by_id (sub_id_q bigint) returns smallint as $$
declare
	tranche_id smallint;
	part_id smallint;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
end;
$$ language plpgsql;

create or replace function get_tranche_by_id_pfk (sub_id_q bigint, part_id smallint) returns smallint as $$
declare
	tranche_id smallint;
begin
	if part_id is null then
		return get_tranche_by_id(sub_id_q);
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
end;
$$ language plpgsql;

create or replace procedure get_some_substances_by_id (sub_id_input_tabname text, substance_output_tabname text) as $$
declare
	extrafields text[];
	extrafields_decl_it text;
	extrafields_decl text;
	subquery_1 text;
	subquery_2 text;
	query text;
begin
	extrafields := get_shared_columns(sub_id_input_tabname, substance_output_tabname, 'sub_id', '{{"tranche_id:smallint"}}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select it.sub_id, sid.sub_partition_fk %1$s from %2$s it left join substance_id sid on it.sub_id = sid.sub_id order by sub_partition_fk', extrafields_decl_it, sub_id_input_tabname);

	subquery_2 := format('select get_substance_by_id_pfk(sub_id, sub_partition_fk) as smiles, get_tranche_by_id_pfk(sub_id, sub_partition_fk) tranche_id, sub_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (smiles, tranche_id, sub_id %1$s) (%2$s)', extrafields_decl, subquery_2, substance_output_tabname);
	execute(query);
end;
$$ language plpgsql;

---------------------------------------------------------------------------------------------

create or replace procedure get_some_pairs_by_code_id(code_ids_input_tabname text, pairs_output_tabname text) as $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint, tranche_id smallint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id, tranche_id) (select sub_id_fk, cat_content_fk, tranche_id from %s i left join catalog_substance_cat cs on i.cat_content_id = cs.cat_content_fk)', code_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$ language plpgsql;

create or replace procedure get_some_pairs_by_sub_id(sub_ids_input_tabname text, pairs_output_tabname text) as $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id) (select i.sub_id, cat_content_fk from %s i left join catalog_substance cs on i.sub_id = cs.sub_id_fk)', sub_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$ language plpgsql;


-- END JUNE3 PATCH

-- BEGIN JUNE10 PATCH
---------------------------------------------------------------------------------------------
-- function to look up just one substance by cat_content_id. faster for small batches
create or replace function get_code_by_id (cc_id_q bigint) returns text as $$

declare
	part_id int;
	code text;
begin
	if cc_id_q is null then
		return null;
	end if;
	select cat_partition_fk from catalog_id ccid where ccid.cat_content_id = cc_id_q into part_id;
	if not cat_partition_fk is null then
		execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', part_id, cc_id_q)) into code;
	end if;
	-- only try again once
	if code is null then
		select cat_id_right from cat_dups_corrections into cc_id_q;
		if cc_id_q is null then
			return null;
		end if;
		select cat_partition_fk from catalog_id ccid where ccid.cat_content_id = cc_id_q into part_id;
		if cat_partition_fk is null then
			return null;
		end if;
		execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', part_id, cc_id_q)) into code;
	end if;
	return code;
end;

$$ language plpgsql;

create or replace function get_code_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns text as $$
declare
	code text;
begin
	if cat_partition_fk is null then
		return null;
	end if;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into code;
	return code;
end;
$$ language plpgsql;

create or replace function get_cat_id_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns smallint as $$
declare
	cat_id smallint;
begin
	if cat_partition_fk is null then
		return null;
	end if;
	execute(format('select cat_id_fk from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into cat_id;
	return cat_id;
end;
$$ language plpgsql;

-- like get_many_substance_by_id, but chilling out with the temporary tables
-- for a lookup in the range of 10s of Ks it will be much simpler to ORDER BY on the partition key and let the cache handle things
create or replace procedure get_some_codes_by_id (code_id_input_tabname text, code_output_tabname text) as $$
declare
	extrafields text[];
	extrafields_decl_it text;
	extrafields_decl text;
	subquery_1 text;
	subquery_2 text;
	query text;
begin
	extrafields := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select cid.cat_content_id, cid.cat_partition_fk %1$s from %2$s it left join catalog_id cid on it.cat_content_id = cid.cat_content_id order by cat_partition_fk', extrafields_decl_it, code_id_input_tabname);

	subquery_2 := format('select get_code_by_id_pfk(cat_content_id, cat_partition_fk) supplier_code, cat_content_id, get_cat_id_by_id_pfk(cat_content_id, cat_partition_fk) cat_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (supplier_code, cat_content_id, cat_id_fk %1$s) (%2$s)', extrafields_decl, subquery_2, code_output_tabname);

	execute(query);
end;
$$ language plpgsql;

-----------------------------------------------------------------------------------------------

drop function if exists get_substance_by_id;
-- function to look up just one substance by sub_id. faster for small batches
create or replace function get_substance_by_id (sub_id_q bigint) returns text as $$
declare
	part_id int;
	sub text;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	end if;
	if part_id is null then
		return null;
	end if;
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$ language plpgsql;

drop function if exists get_substance_by_id_pfk;
create or replace function get_substance_by_id_pfk (sub_id_q bigint, part_id smallint) returns text as $$
declare
	sub text;
begin
	if part_id is null then
		return get_substance_by_id(sub_id_q);
	end if;
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$ language plpgsql;

create or replace function get_tranche_by_id (sub_id_q bigint) returns smallint as $$
declare
	tranche_id smallint;
	part_id smallint;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		-- this actually implies limit 1, for some reason when you use a values statement instead of a table, it gives an error
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	end if;
	if part_id is null then
		return null;
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
end;
$$ language plpgsql;

create or replace function get_tranche_by_id_pfk (sub_id_q bigint, part_id smallint) returns smallint as $$
declare
	tranche_id smallint;
begin
	if part_id is null then
		return get_tranche_by_id(sub_id_q);
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
end;
$$ language plpgsql;

create or replace procedure get_some_substances_by_id (sub_id_input_tabname text, substance_output_tabname text) as $$
declare
	extrafields text[];
	extrafields_decl_it text;
	extrafields_decl text;
	subquery_1 text;
	subquery_2 text;
	query text;
begin
	extrafields := get_shared_columns(sub_id_input_tabname, substance_output_tabname, 'sub_id', '{{"tranche_id:smallint"}}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select it.sub_id, sid.sub_partition_fk %1$s from %2$s it left join substance_id sid on it.sub_id = sid.sub_id order by sub_partition_fk', extrafields_decl_it, sub_id_input_tabname);

	subquery_2 := format('select get_substance_by_id_pfk(sub_id, sub_partition_fk) as smiles, get_tranche_by_id_pfk(sub_id, sub_partition_fk) tranche_id, sub_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (smiles, tranche_id, sub_id %1$s) (%2$s)', extrafields_decl, subquery_2, substance_output_tabname);
	execute(query);
end;
$$ language plpgsql;

---------------------------------------------------------------------------------------------

-- expects tables "vendor_input" and "pairs_output" to have been created
-- cb_vendor_input (supplier_code text);
-- cb_pairs_output (smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_id_fk smallint);
-- antimony stores cat_content_id of stored supplier codes, but we don't use that here on the off chance that cat_content_id is/becomes unstable
-- more reliable to directly look up by code value
create or replace procedure cb_get_some_pairs_by_vendor() as $$
begin
	create temporary table pairs_tempload_p1(supplier_code text, sub_id bigint, cat_id smallint);
	--create temporary table pairs_tempload_p2(smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_id_fk smallint);

	insert into pairs_tempload_p1 (select i.supplier_code, cs.sub_id_fk, cc.cat_id_fk from cb_vendor_input i left join catalog_content cc on i.supplier_code = cc.supplier_code left join catalog_substance_cat cs on cs.cat_content_fk = cc.cat_content_id);

	call get_some_substances_by_id('pairs_tempload_p1', 'cb_pairs_output');

	drop table pairs_tempload_p1;
end;
$$ language plpgsql;

-- expects tables "q_sub_id_input" and "pairs_output" to have been created - just so we don't need to use ugly "execute" statements for certain logic
-- cb_sub_id_input (sub_id bigint, tranche_id_orig smallint)
-- cb_pairs_output (smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_id smallint, tranche_id_orig smallint)
-- need to keep track of the original tranche provided by the searched zinc id, is useful in case id does not look up or there is a mismatch
create or replace procedure cb_get_some_pairs_by_sub_id() as $$
begin
	create temporary table pairs_tempload_p1(smiles text, sub_id bigint, tranche_id smallint, tranche_id_orig smallint);
	create temporary table pairs_tempload_p2(smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint, tranche_id_orig smallint);

	call get_some_substances_by_id('cb_sub_id_input', 'pairs_tempload_p1');

	insert into pairs_tempload_p2 (select p1.smiles, p1.sub_id, p1.tranche_id, cs.cat_content_fk, p1.tranche_id_orig from pairs_tempload_p1 p1 left join catalog_substance cs on cs.sub_id_fk = p1.sub_id);

	call get_some_codes_by_id('pairs_tempload_p2', 'cb_pairs_output');

	drop table pairs_tempload_p1;
	drop table pairs_tempload_p2;
end;
$$ language plpgsql;
-- by the way- "cb" stands for "cartblanche" the name of the frontend site, given that these functions are used by the frontend

create or replace procedure get_some_pairs_by_code_id(code_ids_input_tabname text, pairs_output_tabname text) as $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint, tranche_id smallint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id, tranche_id) (select sub_id_fk, cat_content_fk, tranche_id from %s i left join catalog_substance_cat cs on i.cat_content_id = cs.cat_content_fk)', code_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$ language plpgsql;

create or replace procedure get_some_pairs_by_sub_id(sub_ids_input_tabname text, pairs_output_tabname text) as $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id) (select i.sub_id, cat_content_fk from %s i left join catalog_substance cs on i.sub_id = cs.sub_id_fk)', sub_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$ language plpgsql;
-- END JUNE10 PATCH

-- START COMMON UPLOAD PATCH
CREATE OR REPLACE FUNCTION get_shared_columns (tab1 text, tab2 text, excl1 text, excl2 text[])
	RETURNS text[]
	AS $$
DECLARE
	shared_cols text[];
BEGIN
	RAISE info '%', excl2;
	RAISE info '%', 'a' = ANY (excl2);
	SELECT INTO shared_cols 
		array_agg(concat(t1.col, ':', t1.dtype))
	FROM (
		SELECT
			attname::text AS col,
			case when atttypmod != -1 then concat(atttypid::regtype::text, '(' || atttypmod || ')') else atttypid::regtype::text end as dtype
		FROM
			pg_attribute
		WHERE
			attrelid = tab1::regclass
			AND attnum > 0) t1
	INNER JOIN (
		SELECT
			attname::text AS col,
			case when atttypmod != -1 then concat(atttypid::regtype::text, '(' || atttypmod || ')') else atttypid::regtype::text end as dtype
		FROM
			pg_attribute
		WHERE
			attrelid = tab2::regclass
			AND attnum > 0) t2 
	ON t1.col = t2.col
	WHERE
		t1.col != sc_colname(excl1)
		AND NOT t1.col = ANY (excl2);
	RAISE info '%', shared_cols;
	RAISE info '%', excl1;

	RETURN shared_cols;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sc_colname (scol text)
	RETURNS text
	AS $$
BEGIN
	RETURN SPLIT_PART(scol, ':', 1);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sc_coltype (scol text)
	RETURNS text
	AS $$
BEGIN
	RETURN SPLIT_PART(scol, ':', 2);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cols_declare (cols text[], tabprefix text)
	RETURNS text
	AS $$
DECLARE
	colnames text[];
BEGIN
	SELECT
		INTO colnames array_agg(sc_colname (t.col))
	FROM
		unnest(cols) AS t (col);
	IF NOT tabprefix IS NULL THEN
		RETURN tabprefix || array_to_string(colnames, ', ' || tabprefix);
	ELSE
		RETURN array_to_string(colnames, ', ');
	END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cols_declare_type (cols text[])
	RETURNS text
	AS $$
DECLARE
	coldecl text[];
BEGIN
	SELECT
		INTO coldecl array_agg(replace(t.col, ':', ' '))
	FROM
		unnest(cols) as t (col);
	RETURN array_to_string(coldecl, ', ');
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cols_declare_join (cols text[], t1 text, t2 text)
	RETURNS text
	AS $$
DECLARE
	colnames text[];
	equ_stmts text[];
BEGIN
	SELECT
		INTO colnames array_agg(sc_colname (t.col))
	FROM
		unnest(cols) AS t (col);
	SELECT
		array_agg(format('%2$s.%1$s = %3$s.%1$s', col, t1, t2))
	FROM
		unnest(colnames) AS t (col) INTO equ_stmts;
	RETURN array_to_string(equ_stmts, ' and ');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upload_bypart (PARTITION int, loadtable text, desttable text, nexttable text, keyfields text[], idfield text, destseq text, filediff text)
	RETURNS int
	AS $$
DECLARE
	destcolumns text[];
	loadcolumns text[];
	nextcolumns text[];
	keyfield_colnames text[];
	desttable_p text;
	loadtable_p text;
	query text;
	col text;
	nnew int;
BEGIN
	IF PARTITION <> - 1 THEN
		desttable_p := format('%s_p%s', desttable, PARTITION);
		loadtable_p := format('%s_p%s', loadtable, PARTITION);
	ELSE
		desttable_p := desttable;
		loadtable_p := loadtable;
	END IF;
	SELECT
		array_agg(sc_colname (t.col))
	FROM
		unnest(keyfields) AS t (col) INTO keyfield_colnames;
	-- columns shared between load table and dest table, keyfields are assumed to be shared (thus will not be included in list of shared columns)
	destcolumns := get_shared_columns (loadtable_p, desttable_p, idfield, keyfield_colnames);
	-- columns of the load table (minus keyfields + idfield)
	loadcolumns := get_shared_columns (loadtable_p, loadtable_p, idfield, keyfield_colnames);
	-- columns shared between the load table and the next stage table (what data do we pass on to the next stage, idfield is assumed to be passed, but not keyfields)
	nextcolumns := get_shared_columns (loadtable_p, nexttable, idfield, '{}');
	RAISE info '%', format('shared cols : dest <> load : %s', array_to_string(destcolumns, ','));
	RAISE info '%', format('shared cols : load <> load : %s', array_to_string(loadcolumns, ','));
	RAISE info '%', format('shared cols : load <> next : %s', array_to_string(nextcolumns, ','));
	-- allocate temporary table for calculations
	CREATE TEMPORARY SEQUENCE temp_seq;
	CREATE TEMPORARY TABLE temp_table_load (
		temp_id int DEFAULT nextval('temp_seq' )
	);
	EXECUTE (format('alter table temp_table_load add column %s %s', sc_colname (idfield), sc_coltype (idfield)));
	foreach col IN ARRAY keyfields LOOP
		EXECUTE (format('alter table temp_table_load add column %s %s', sc_colname (col), sc_coltype (col)));
	END LOOP;
	foreach col IN ARRAY loadcolumns LOOP
		EXECUTE (format('alter table temp_table_load add column %s %s', sc_colname (col), sc_coltype (col)));
	END LOOP;
	-- join input table to destination table on keyfields and store result in temporary table
	EXECUTE (format('insert into temp_table_load(%1$s, %2$s, %3$s) (select s.%1$s, %4$s, %5$s from %6$s t left join %7$s s on %8$s)', sc_colname (idfield), cols_declare (keyfield_colnames, ''), cols_declare(loadcolumns, ''), cols_declare (keyfield_colnames, 't.'), cols_declare (loadcolumns, 't.'), loadtable_p, desttable_p, cols_declare_join (keyfields, 't', 's')));
	-- create second temporary table to store just entries new to the destination table
	EXECUTE (format('create temporary table new_entries (%1$s %2$s, temp_id int, rn int)', sc_colname (idfield), sc_coltype (idfield)));
	foreach col IN ARRAY keyfields LOOP
		EXECUTE (format('alter table new_entries add column %s %s', sc_colname (col), sc_coltype (col)));
	END LOOP;
	-- locate all entries new to destination table and assign them a new sequential ID, storing in the temporary table we just created
	EXECUTE (format('insert into new_entries(%1$s, %2$s, rn, temp_id) (select %1$s, min(%2$s) over w as %2$s, ROW_NUMBER() over w as rn, temp_id from (select %3$s, case when ROW_NUMBER() over w = 1 then nextval(''%4$s'') else null end as %2$s, t.temp_id from temp_table_load t where t.%2$s is null window w as (partition by %3$s)) t window w as (partition by %3$s))', cols_declare (keyfields, ''), sc_colname (idfield), cols_declare (keyfields, 't.'), destseq));
	-- finally, insert new entries to destination table
	query := format('insert into %1$s (%2$s, %3$s, %4$s) (select %5$s, n.%3$s, %6$s from new_entries n left join temp_table_load t on n.temp_id = t.temp_id where n.rn = 1)', desttable_p, cols_declare (keyfields, ''), sc_colname(idfield), cols_declare(destcolumns, ''), cols_declare (keyfields, 'n.'), cols_declare (destcolumns, 't.'));
	select count(*) from new_entries where rn = 1 into nnew;
	-- save the diff to an external file (if specified)
	IF NOT filediff IS NULL THEN
		query := 'copy (' || query || ' returning *) to ''' || filediff || '''';
	END IF;
	EXECUTE (query);
	-- move data to next stage (if applicable)
	IF NOT nexttable IS NULL THEN
		query := format('insert into %1$s (%2$s, %3$s) (select %2$s, case when t.%3$s is null then n.%3$s else t.%3$s end from temp_table_load t left join new_entries n on t.temp_id = n.temp_id)', nexttable, cols_declare (nextcolumns, ''), sc_colname (idfield));
		EXECUTE (query);
	END IF;
	-- clean up!
	DROP TABLE temp_table_load;
	DROP SEQUENCE temp_seq;
	DROP TABLE new_entries;
	RETURN nnew;

	/* END GENERALIZATION REWRITE */
END
$$
LANGUAGE plpgsql;

