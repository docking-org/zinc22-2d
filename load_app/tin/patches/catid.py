from load_app.common.consts import *
from load_app.common.patch import StagedPatch, Patch
from load_app.common.database import Database
class CatIdPartitionPatch(StagedPatch):

    def __init__(self):
        
        super().__init__('catid', BINDIR + '/psql/tin/patches/catid_partitioned')
        
        self.patch_stages.append(('code', {}))
        self.patch_stages.append(('apply', {}))
        self.patch_stages.append(('test', {}))

        if Database.instance.select("select count(*) from substance").first()[0] == 0:
            print("No data in the table, skipping partitioning for now")
            return True

        if Patch.get_patch_attribute('catid'):
            self.set_patched(True, suffix='apply')
            Database.instance.call("delete from patches where patchname = 'catid'")
