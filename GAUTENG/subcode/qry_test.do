





    UNION ALL 

    SELECT A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
           A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
           A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
           A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
           A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011hh' AS source, 'rdp' AS hulltype, 2011 AS year

    FROM census_hh_2011 AS A  
    JOIN distance_sal_2011_rdp AS B ON B.sal_code=A.SAL_code

    UNION ALL 

    SELECT A.H01_QUARTERS AS quarters_typ, A.H02_MAINDWELLING AS dwelling_typ,
           A.H03_TOTROOMS AS tot_rooms, A.H04_TENURE AS tenure, A.H07_WATERPIPED AS water_piped,
           A.H08_WATERSOURCE AS water_source, A.H10_TOILET AS toilet_typ, 
           A.H11_ENERGY_COOKING AS enrgy_cooking, A.H11_ENERGY_HEATING AS enrgy_heating,
           A.H11_ENERGY_LIGHTING AS enrgy_lighting, A.H12_REFUSE AS refuse_typ, A.DERH_HSIZE AS hh_size,

           cast(B.sal_code AS TEXT) as sal_code, B.distance, B.cluster, B.area_int,

           'census2011hh' AS source, 'placebo' AS hulltype, 2011 AS year

    FROM census_hh_2011 AS A  
    JOIN distance_sal_2011_placebo AS B ON B.sal_code=A.SAL_code

    ) AS AA

    LEFT JOIN (SELECT DISTINCT cluster, cluster_siz, mode_yr, frac1, frac2 
    FROM rdp_clusters) AS BB on AA.cluster = BB.cluster

    LEFT JOIN placebo_conhulls AS CC on CC.cluster = AA.cluster


    

local qry = " 

  	SELECT AA.*, GP.mo_date_placebo, GR.mo_date_rdp, IR.cluster AS cluster_int_rdp, 
    IP.cluster AS cluster_int_placebo

    FROM 

  	(
    SELECT B.distance AS distance_rdp, B.target_id AS cluster_rdp,  
    BP.distance AS distance_placebo, BP.target_id AS cluster_placebo, 

    A.OGC_FID, A.s_lu_code, A.t_lu_code, AXY.X, AXY.Y

    FROM bblu_pre  AS A  
    JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_bblu_pre_rdp WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS B ON A.OGC_FID=B.input_id


    JOIN (SELECT input_id, distance, target_id, COUNT(input_id) AS count FROM distance_bblu_pre_placebo WHERE distance<=4000
  GROUP BY input_id HAVING COUNT(input_id)<=50 AND distance == MIN(distance)) 
    AS BP ON A.OGC_FID=BP.input_id  

      LEFT JOIN bblu_pre_xy AS AXY ON AXY.OGC_FID = A.OGC_FID

    WHERE (A.s_lu_code=7.1 OR A.s_lu_code=7.2)

    ) AS AA 

    LEFT JOIN (SELECT cluster_placebo, mo_date_placebo FROM cluster_placebo) AS GP ON AA.cluster_placebo = GP.cluster_placebo
    LEFT JOIN (SELECT cluster_rdp, mo_date_rdp FROM cluster_rdp) AS GR ON AA.cluster_rdp = GR.cluster_rdp    

    LEFT JOIN int_placebo_bblu_pre AS IP ON IP.OGC_FID = AA.OGC_FID
    LEFT JOIN int_rdp_bblu_pre AS IR  ON IR.OGC_FID = AA.OGC_FID     
    ";