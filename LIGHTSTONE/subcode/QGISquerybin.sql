#select RDP trasactions w/cluster ID:
SELECT A.transaction_id, B.geometry, C.cluster 
FROM transactions AS A
JOIN erven AS B ON A.property_id = B.property_id
JOIN rdp_clusters AS C ON A.transaction_id = C.transaction_id