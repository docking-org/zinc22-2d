LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to LOG;

begin;

	create or replace procedure create_table_partitions (tabname text, tmp text) language plpgsql AS $$

		declare
			n_partitions int;
			i int;
		begin
			select ivalue from tin_meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop

				execute(format('create %s table %s_p%s partition of %s for values with (modulus %s, remainder %s)', tmp, tabname, i, tabname, n_partitions, i));

			end loop;

		end;

	$$;

	create or replace procedure export_ids_from_catalog_content () language plpgsql as $$

		declare
			n_partitions int;
			i int;
		begin
			select ivalue from tin_meta where svalue = 'n_partitions' limit 1 into n_partitions;

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
			execute(format('select smiles from catalog_content_p%s where cat_content_id = %s', part_id, cat_content_id_q)) into code;
			return code;
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

			select ivalue from tin_meta where svalue = 'n_partitions' limit 1 into n_partitions;
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
                        select ivalue from tin_meta where svalue = 'n_partitions' limit 1 into n_partitions;
                        for i in 0..(n_partitions-1) loop
                                execute(format('alter table if exists catalog_content_tp%s rename to catalog_content_p%s', i, i));
				execute(format('alter table if exists catalog_content_t_p%s rename to catalog_content_p%s', i, i));
                        end loop;
                end;
        $$ language plpgsql;

commit;
