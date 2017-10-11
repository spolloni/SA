'''
main.py

    created by: sp, oct 9 2017
    
    - import lighstone data into SQLite DB

'''

from pysqlite2 import dbapi2 as sql
from pycode.lightstone2sql import add_trans, add_erven, add_bonds
import os 

# switchboard
IMPORT = 1

# set directories 
project = os.getcwd()[:os.getcwd().rfind('Code')]
rawdata = project + 'Raw/DEEDS/'
gendata = project + 'Generated/LIGHTSTONE/'
if not os.path.exists(gendata):
    os.makedirs(gendata)

# import txt files into SQL tables
if IMPORT ==1:
    add_trans(rawdata+'TRAN_DATA_1205.txt',gendata+'lighstone.db')
    add_erven(rawdata+'TRAN_DATA_1205.txt',gendata+'lighstone.db')
    add_bonds(rawdata+'TRAN_DATA_1205.txt',gendata+'lighstone.db')


