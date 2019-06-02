* random_check

odbc load, exec(" SELECT A.cluster, B.name FROM rdp_cluster AS A JOIN gcro_publichousing AS B ON A.cluster=B.OGC_FID;") clear dsn(gauteng) 

set seed 2

sample 20, count

