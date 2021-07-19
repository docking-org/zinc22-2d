begin;
create table catalog_content_t (like catalog_content including defaults);
insert into catalog_content_t (select * from catalog_content);
-- main block for updating catalog_content

create temporary table to_deplete(supplier_code varchar);
copy to_deplete(supplier_code) from :'source_f';

update catalog_content_t set depleted = :depleted_bool where supplier_code in (select supplier_code from to_deplete);

-- end main block
alter table catalog_content_t add primary key (cat_content_id, tranche_id);
create index catalog_content_supplier_code_idx_t on catalog_content(supplier_code);

alter table catalog_content_t add constraint "catalog_content_cat_id_fk_fkey_t" foreign key (cat_id_fk) references catalog(cat_id);
alter table catalog_substance drop constraint "catalog_substance_cat_itm_fk_fkey";

alter table catalog_substance add constraint "catalog_substance_cat_itm_fk_fkey" foreign key (cat_content_fk, tranche_id) references catalog_content_t(cat_content_id, tranche_id);

alter table catalog_content rename to catalog_content_trash;
drop table catalog_content_trash cascade;

alter table catalog_content_t rename to catalog_content;
alter table catalog_content rename constraint "catalog_content_cat_id_fk_fkey_t" to "catalog_content_cat_id_fk_fkey";
alter table catalog_content rename constraint "catalog_content_t_pkey" to "catalog_content_pkey";

commit;