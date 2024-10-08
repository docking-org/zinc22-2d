import sys, os
import subprocess
import tarfile
import shutil

from load_app.common.consts import *
from load_app.tin.common import *
from load_app.common.upload import make_hash_partitions, get_partitions_count, create_transaction_record_table, check_transaction_record, check_transaction_started, increment_version

def find_source_file(source_dir, tranche, ext='.smi'):
    hac = tranche[0:3]
    p1 = os.path.join(source_dir, hac, tranche + ext)
    p2 = os.path.join(source_dir, hac, tranche)
    p3 = os.path.join(source_dir, tranche + ext)
    p4 = os.path.join(source_dir, tranche)
    for p in [p1, p2, p3, p4] + [_p+'.gz' for _p in [p1, p2, p3, p4]]:
        if os.path.isfile(p):
            return p
    return None


def create_source_file(source_dirs, cat_shortnames):

    database_port = Database.instance.port
    source_f = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_upload.txt"

    #if os.path.exists(source_f):
    #    return source_f

    psql_source_f = open(source_f, 'w')

    print("processing file for postgres...")
    for source_dir, cat_shortname in zip(source_dirs, cat_shortnames):
        cat_id = get_or_set_catid(cat_shortname)
        for tranche in get_tranches():
            print("processing", tranche)
            tranche_id = get_tranche_id(tranche)

            srcf = find_source_file(source_dir, tranche)

            with open(srcf, 'r') as tf:
                for line in tf:
                    # we do a more sophisticated escape sequence using sed below
                    # this strategy could potentially add extra escape characters when they are not needed
                    #escaped_line = line.replace('\\', '\\\\').strip()
                    tokens = line.split()
                    if len(tokens) == 2: # filter out lines that will cause an error to be thrown
                        psql_source_f.write(' '.join(tokens + [str(cat_id), str(tranche_id)]) + "\n")

    psql_source_f.close() 
    subprocess.call(["chmod", "777", source_f])
    psql_source_f_t = open(source_f + '.t', 'w')
    subprocess.call(["sed", "-E", "s/\\\\/\\\\\\\\/g", psql_source_f.name], stdout=psql_source_f_t)
    #subprocess.call(["sed", "-E", "s/([^\\\\]+|^)(\\\\){1}([^\\\\]+|$)/\\1\\2\\2\\3/g", psql_source_f.name], stdout=psql_source_f_t)
    psql_source_f_t.close()
    os.rename(psql_source_f_t.name, psql_source_f.name)
    return source_f

def undeplete_codes(args):

    source_dirs = args.source_dirs.split(',')
    cat_shortnames = args.transaction_id.split('.')
    diff_destination = args.diff_destination

    transaction_identifier = "_".join(cat_shortnames + (["update"] if args.just_update_info else []))
    diff_destination = diff_destination + "/{}/{}".format(transaction_identifier, args.host+':'+str(args.port))
    diff_buckets = ["/sup_update_depleted"]
    diff_locations =  [diff_destination + diff_bucket for diff_bucket in diff_buckets]
    if args.fake_upload:
        increment_version(transaction_identifier)
        return True

    subprocess.call(["mkdir", "-p"] + diff_locations)
    subprocess.call(["chmod", "777"] + diff_locations)
    
    n_partitions = get_partitions_count()

    if args.just_update_info:
        source_f = create_source_file(args.source_dirs, args.catalogs)
        code = Database.instance.call_file(BINDIR + '/psql/tin/update_depleted.pgsql', vars={"source_f":source_f, "diff_destination":diff_destination})
        if code == 0:
            increment_version(transaction_identifier)
        return True

