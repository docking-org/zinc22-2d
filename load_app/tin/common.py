import sys, os
import subprocess
import tarfile
import shutil
import gzip

from load_app.common.consts import *
from load_app.common.database import Database

def get_tin_machines():
    for host, port in Database.get_config_instance().select('select host, port from database_partitions order by host, port').data:
        yield host, port

def get_tranche_id(tranchename):
    data = Database.instance.select("select tranche_id from tranches where tranche_name = '{}'".format(tranchename)).first()[0]
    return int(data)

# deprecated
def get_db_path(db_port):
    srcdir = "/local2/load"
    db_path = None
    for partition in os.listdir(srcdir):
        if not len(partition) == 15 or not partition[0] == "H":
            continue
        ppath = "/".join([srcdir, partition])
        if os.path.isfile(ppath + "/.port"):
            with open(ppath + "/.port") as portf:
                thisport = int(portf.read())
                if thisport == db_port:
                    if db_path:
                        print("multiple databases are hosted on this port!")
                        print(db_path, ppath, "are both on port {}".format(db_port))
                        sys.exit(1)
                    db_path = ppath
    return db_path

def get_or_set_catid(cat_shortname):
    data_catid = Database.instance.select("select cat_id from catalog where short_name = '{}'".format(cat_shortname))
    if data_catid.empty():
        data_catid = Database.instance.select("insert into catalog(name, short_name, updated) values ('{}','{}', 'now()') returning cat_id".format(cat_shortname, cat_shortname))
    cat_id = data_catid.first()[0]
    return cat_id

digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
digits_map = {d:i for i, d in enumerate(digits)}
def base62_rev_zincid(n):
    tot = 0
    # manually unrolling this loop to optimize for decoding zinc ids
    tot += digits_map[n[9]]
    tot += digits_map[n[8]] * 62
    tot += digits_map[n[7]] * 3844
    tot += digits_map[n[6]] * 238328
    tot += digits_map[n[5]] * 14776336
    tot += digits_map[n[4]] * 916132832
    tot += digits_map[n[3]] * 56800235584
    tot += digits_map[n[2]] * 3521614606208
    tot += digits_map[n[1]] * 218340105584896
    tot += digits_map[n[0]] * 13537086546263552
    #for i, d in enumerate(reversed(n)):
    #    tot += digits_map[d] * 62**i
    return tot

logp_range="M500 M400 M300 M200 M100 M000 P000 P010 P020 P030 P040 P050 P060 P070 P080 P090 P100 P110 P120 P130 P140 P150 P160 P170 P180 P190 P200 P210 P220 P230 P240 P250 P260 P270 P280 P290 P300 P310 P320 P330 P340 P350 P360 P370 P380 P390 P400 P410 P420 P430 P440 P450 P460 P470 P480 P490 P500 P600 P700 P800 P900".split(" ")
def base62(n):
    b62_str=""
    while n >= 62:
        n, r = divmod(n, 62)
        b62_str += digits[r]
    b62_str += digits[n]
    return ''.join(reversed(b62_str))

def get_tranches():
    host = Database.instance.host
    port = Database.instance.port
    data = Database.get_config_instance().select("select tranche from tranche_mappings where host = '{}' and port = {}".format(host, port)).all()
    
    return [d[0] for d in data]
    # data = Database.instance.select("select tranche_name from tranches").all()
    # return [d[0] for d in data]


def zincid_to_subid_opt(infile, outfile, tranche_id, only_output_zincid=False, writemode='w'):
    if infile.endswith('.gz'):
        src = gzip.open(infile, 'rb')
    else:
        src = open(infile, 'rb')
    total = 0
    with open(outfile, writemode) as out:
        fails = 0
        first = False
        zincid_pos = -1
        smiles_pos = -1
        with src:
            def writeout(tokens):
                nonlocal fails
                zincid = tokens[zincid_pos]
                try:
                    sub_id = base62_rev_zincid(zincid[6:])
                except:
                    print("failed to parse: ", tokens)
                    fails += 1
                    if (fails/total) > 0.25:
                        raise Exception("too many parsing failures!")
                    return
                if not only_output_zincid:
                    out.write(" ".join([str(sub_id), str(tranche_id)] + [tokens[smiles_pos]]) + "\n")
                else:
                    out.write(" ".join([str(sub_id), str(tranche_id)]) + "\n")
            total=0
            firstline = src.readline().decode('utf-8')
            tokens = firstline.strip().split()
            if len(tokens) == 0:
                return
            # zincid is supposed to be in the first column, but this is not always the case
            # to avoid annoying manual specification of the column every time, automatically detect it here
            for i, tok in enumerate(tokens):
                if tok.startswith("ZINC") and len(tok) == 16:
                    if len(tokens) == 2: # we also need to figure out where smiles are- sigh
                        smiles_pos = abs(i-1) # usually we are reading in a file with two columns- zinc id + smiles. if we aren't, rewrite this code some more
                    zincid_pos = i
                    break
            writeout(tokens)
            if zincid_pos == -1:
                raise Exception("couldn't find a zinc id in the first line of this file! exiting!")
            else:
                print("found zincid pos: {}".format(zincid_pos))
            for line in src:
                line = line.decode('utf-8')
                total += 1
                tokens = line.strip().split()
                if len(tokens) < 2:
                    continue
                writeout(tokens)
    print("total mols={}".format(total))

def subid_to_zincid_opt(infile, outfile, tranche_name, subid_pos):
    idstart = "ZINC" + digits[int(tranche_name[1:3])] + digits[logp_range.index(tranche_name[3:])]
    with open(infile, 'r') as inf:
        with open(outfile, 'w') as otf:
            for line in inf:
                 tokens = line.strip().split()
                 sub_id = int(tokens[subid_pos-1])
                 zincid = idstart + base62(sub_id).zfill(10)
                 otf.write("\t".join(tokens[:subid_pos-1] + [zincid] + tokens[subid_pos:]) + "\n")

