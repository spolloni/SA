 -- AREA
 select avg(sqkm) from
(select st_area(GEOMETRY)/1000000 as sqkm , rdp from projects
where st_area(GEOMETRY)/1000000 < 100) as area
group by rdp 

-- RDP HOUSES PER PROJECT
select count(property_id) as count,  betterberdp from
(
	select rdp.property_id, rdp.rdp_all, rdp.rdp_notownship, projects.cluster, projects.rdp as betterberdp  from rdp
	join erven on rdp.property_id = erven.property_id
	join projects on st_intersects(projects.GEOMETRY, erven.GEOMETRY)
	where rdp_notownship =1
)
where betterberdp =1
GROUP BY cluster


-- DISTANCE TO CBD
select avg(distance), rdp from 
(
	select 
		projects.GEOMETRY, 
		projects.cluster, 
		projects.rdp, 
		cbd_centroids_stef.town,
		st_distance(st_centroid(projects.GEOMETRY),st_centroid(cbd_centroids_stef.GEOMETRY))/1000 as distance
	from projects
	cross join  cbd_centroids_stef	
	GROUP BY cluster
	having distance = min(distance)
)  as distances
GROUP BY rdp

