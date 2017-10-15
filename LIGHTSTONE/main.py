'''
main.py

    created by: sp, oct 9 2017
    
    - step 1. import lighstone data into SQLite DB
    - step 2. select sample and flag RDP.
    - step 3. assign to spatial cluster.

'''

from pysqlite2 import dbapi2 as sql
from subcode.lightstone2sql import add_trans, add_erven, add_bonds
from subcode.spaclust import spatial_cluster
import os, subprocess

#############################################
# switchboard                               #
_1_IMPORT  = 0                              #
_2_FLAGRDP = 0                              #
_3_CLUSTER = 1                              #
    algo = 1    # 1=dbscan, 2=hdbscan       #
    par1 = 1                                #
    par2 = 2                                #
#############################################

# set directories 
project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdata = project + 'Raw/DEEDS/'
gendata = project + 'Generated/LIGHTSTONE/'
if not os.path.exists(gendata):
    os.makedirs(gendata)

#############################################
# STEP 1:  import txt files into SQL tables #
#############################################
if _1_IMPORT ==1:

    print '\n'," Importing Lighstone TXTs into SQL... ",'\n'

    if os.path.exists(gendata+'lightstone.db'):
        os.remove(gendata+'lightstone.db')

    add_trans(rawdata+'TRAN_DATA_1205.txt',gendata+'lightstone.db')
    print '\n'," - Transactions table: done! "'\n'

    add_erven(rawdata+'ERF_DATA_1205.txt',gendata+'lightstone.db')
    print '\n'," - Erven table: done! "'\n'

    add_bonds(rawdata+'BOND_DATA_1205.txt',gendata+'lightstone.db')
    print '\n'," - Bond table: done! "'\n'

#############################################
# STEP 2:  RDP properties flagging          #
#############################################
if _2_FLAGRDP ==1:

    print '\n'," Identifying sample and RDP properties... ",'\n'

    con = sql.connect(gendata+'lightstone.db')
    cur = con.cursor()
    cur.execute(''' DROP TABLE IF EXISTS rdp;''')
    con.commit()
    con.close()
    dofile = "subcode/rdp_flag.do"
    cmd = ["stata-mp", "do", dofile]
    subprocess.call(cmd)

#############################################
# STEP 3:  Cluster RDP properties           #
#############################################
if _3_CLUSTER ==1:

    print '\n'," Clustering RDP properties... ",'\n'

    qry = '''
        SELECT A.transaction_id, C.latitude, C.longitude
            FROM transactions AS A
                JOIN rdp      AS B ON A.transaction_id = B.transaction_id
                JOIN erven    AS C ON A.property_id = C.property_id
        WHERE B.rdp_ls=1;
        '''

    spatial_cluster(qry,algo,par1,par2)











