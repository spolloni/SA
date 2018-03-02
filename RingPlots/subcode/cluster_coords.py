
# cluster_coords.py
# 07/2017

# 1. take TRANS_in.csv as input
# 2. extract rdp obs. and cluster
# 3. output as TRANS_out.csv 

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import sklearn.cluster as cluster
import time, csv, hdbscan, sys, time

############### FILES #######################
file_in  = sys.argv[1]
file_out = sys.argv[2]
#############################################

#_take_input 
algo = int(sys.argv[3])
par1 = float(sys.argv[4])
par2 = float(sys.argv[5])

#_empty_lists
new_csv = []
rdps = []

#_plot_params
plot_kwds = {'alpha' : 0.35, 's' : 25, 'linewidths':0}

#_unload_csv
print "cluster_coords: unloading csv data... "
with open(file_in) as f:

    reader = csv.reader(f)
    header = next(reader)
    header.append('cluster')
    new_csv.append(header)

    rdp = int(header.index('rdp'))
    lat = int(header.index('latitude'))
    lon = int(header.index('longitude'))
    lid = int(header.index('local_id'))

    for line in reader:

        #_stock_non-RDP
        if line[rdp] == '0':
            line.append("-1")
            new_csv.append(line)

        #_separate_RDP
        if line[rdp] == '1':
            rdps.append(line)

#_load_RDP_to_numpy_array
mat = np.array([[line[lid],line[lat],line[lon]] 
        for line in rdps])

#_spatial_clustering
print "cluster_coords: spatial clustering... "
if algo ==1:
    algoname = "DBSCAN"
    labels = cluster.DBSCAN(eps=par1,min_samples=par2).fit_predict(mat[:,1:])
if algo ==2:
    algoname = "HDBSCAN"
    labels = hdbscan.HDBSCAN(min_cluster_size=int(par1),min_samples=int(par2)).fit_predict(mat[:,1:])
labels = labels +1 

#_make_plots_and_save
print "cluster_coords: saving plots... "
palette = sns.color_palette('Paired', np.unique(labels).max()+1)
colors = [palette[x] if x > 0 else (0.0, 0.0, 0.0) for x in labels]
plt.scatter(mat.T[2], mat.T[1], c=colors, **plot_kwds)
frame = plt.gca()
frame.axes.get_xaxis().set_visible(False)
frame.axes.get_yaxis().set_visible(False)
#plt.axis([27.12,29.12,-27.1,-25.1])
plt.savefig('tex/plot.pdf',bbox_inches='tight', dpi=30) 
plt.axis([27.8,28,-26.3,-26.205])
plt.savefig('tex/plotzoom.pdf',bbox_inches='tight', dpi=30) 

#_convert_to_python_list_and_add_to_data
labels = labels.tolist()
rdps = [ rdps[i] + [str(labels[i])] for i in range(0,len(rdps))]
new_csv.extend(rdps)

#_write_data_to_csv
print "cluster_coords: writing to output... "
with open(file_out, "wb") as f:
    writer = csv.writer(f)
    writer.writerows(new_csv)
