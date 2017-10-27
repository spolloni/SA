#select RDP trasactions w/cluster ID:
SELECT A.transaction_id, B.geometry, C.cluster 
FROM transactions AS A
JOIN erven AS B ON A.property_id = B.property_id
JOIN rdp_clusters_ls AS C ON A.transaction_id = C.transaction_id

SELECT A.transaction_id, st_buffer(B.geometry,600) as buffers , C.cluster 
FROM transactions AS A
JOIN erven AS B ON A.property_id = B.property_id
JOIN rdp_clusters_ls AS C ON A.transaction_id = C.transaction_id
WHERE A.suburb_id = 507 AND  C.cluster !=0

SELECT A.transaction_id, st_union(st_buffer(B.geometry,600)) as buffers , C.cluster 
FROM transactions AS A
JOIN erven AS B ON A.property_id = B.property_id
JOIN rdp_clusters_ls AS C ON A.transaction_id = C.transaction_id
WHERE A.suburb_id = 507 AND  C.cluster !=0
GROUP BY C.cluster 

SELECT A.transaction_id as id, B.geometry as points, C.cluster as cluster
FROM transactions AS A
JOIN erven AS B ON A.property_id = B.property_id
LEFT JOIN rdp_clusters_ls AS C ON A.transaction_id = C.transaction_id
WHERE A.suburb_id = 507 AND  ( C.cluster !=0 OR C.cluster IS NULL)

SELECT A.transaction_id as transaction_id, B.geometry, st_distance(B.geometry,C.geometry)
FROM transactions AS A, (

SELECT D.geometry
FROM transactions AS E
JOIN erven AS D ON E.property_id = D.property_id
JOIN rdp_clusters_ls AS F ON E.transaction_id = F.transaction_id
WHERE E.suburb_id = 507 AND  F.cluster !=0 

) as C
JOIN erven AS B ON A.property_id = B.property_id
WHERE A.suburb_id = 507 




SELECT A.transaction_id as transaction_id, B.geometry, C.rdp_ls
FROM transactions AS A
JOIN erven AS B ON A.property_id = B.property_id
JOIN rdp    AS C ON A.transaction_id= C.transaction_id
WHERE A.suburb_id = 507  AND C.rdp_ls = 0 