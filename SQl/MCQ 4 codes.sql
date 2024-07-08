Use md_water_services;

select l.province_name provice_name,l.town_name town_name,v.visit_count visit_count,v.location_id location_id
From location l
join visits v
on v.location_id = l.location_id;

select l.province_name provice_name,
		town_name town_name,
        v.visit_count visit_count,
		v.location_id location_id,
        ws.type_of_water_source type_of_water_source,
        ws.number_of_people_served number_of_people_served
From location l
join visits v on v.location_id = l.location_id
join water_source ws on ws.source_id=v.source_id;


select l.province_name provice_name,
		town_name town_name,
        v.visit_count visit_count,
		v.location_id location_id,
        ws.type_of_water_source type_of_water_source,
        ws.number_of_people_served number_of_people_served
From location l
join visits v on v.location_id = l.location_id
join water_source ws on ws.source_id=v.source_id
WHERE v.visit_count = 1;

select l.province_name provice_name,
		town_name town_name,
        l.location_type,
        ws.type_of_water_source type_of_water_source,
        ws.number_of_people_served number_of_people_served,
        v.time_in_queue
From location l
join visits v on v.location_id = l.location_id
join water_source ws on ws.source_id=v.source_id
WHERE v.visit_count = 1;

select l.province_name provice_name,
		town_name town_name,
        l.location_type,
        ws.type_of_water_source type_of_water_source,
        ws.number_of_people_served number_of_people_served,
        v.time_in_queue,
        wp.results
From location l
join visits v on v.location_id = l.location_id
join water_source ws on ws.source_id=v.source_id
left join well_pollution wp on wp.source_id=v.source_id
WHERE v.visit_count = 1;
drop view combined_analysis_table;

create view combined_analysis_table as 
			select l.province_name province_name,
					l.town_name,
					l.location_type,
					ws.type_of_water_source source_type,
					ws.number_of_people_served people_served,
					v.time_in_queue,
					wp.results
			From location l
			join visits v on v.location_id = l.location_id
			join water_source ws on ws.source_id=v.source_id
			left join well_pollution wp on wp.source_id=v.source_id
			WHERE v.visit_count = 1;
            
select * from combined_analysis_table;            

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;

WITH town_totals AS (
			-- This CTE calculates the population of each town
			-- Since there are two Harare towns, we have to group by province_name and town_name
			SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
			FROM combined_analysis_table
			GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
			-- This CTE calculates the population of each town
			-- Since there are two Harare towns, we have to group by province_name and town_name
			SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
			FROM combined_analysis_table
			GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

select * from town_aggregated_water_access order by river desc;

select * from town_aggregated_water_access order by province_name,tap_in_home;

SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access
order by 3 desc;

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same
source more than once in the future.
*/
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,
and should refer to the source table. This ensures data integrity.
*/
Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.
*/
Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded.
Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
);

drop table project_progress;

/* uncomment version of the code
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);*/

-- Project_progress_query
select * from project_progress limit 30;

select count(*) from project_progress where Improvement like '%UV%';

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
case 
	when type_of_water_source='well' then if(results like '%chem%','Install RO filters','Install UV and RO filters')
	when type_of_water_source ='river' then 'Drill wells'
    when type_of_water_source = 'tap_in_home_broken' then 'Diagnose infrastructure'
    when type_of_water_source = 'shared_tap' and time_in_queue >30 then concat('install ',floor(time_in_queue/30),' taps nearby')
end as intervention
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id 
where visits.visit_count=1 and 
((visits.time_in_queue >= 30 and water_source.type_of_water_source = 'shared_tap') 
or well_pollution.results != 'Clean' or water_source.type_of_water_source in ('river','tap_in_home_broken'))
limit 100000;




insert into Project_progress (source_id,Address,Town,Province,Source_type,Improvement)
select 
water_source.source_id,
location.address,
location.town_name,
location.province_name,
water_source.type_of_water_source,
case 
	when type_of_water_source='well' then if(results like '%chem%','Install RO filters','Install UV and RO filters')
	when type_of_water_source ='river' then 'Drill wells'
    when type_of_water_source = 'tap_in_home_broken' then 'Diagnose infrastructure'
    when type_of_water_source = 'shared_tap' and time_in_queue >30 then concat('install ',floor(time_in_queue/30),' taps nearby')
end as intervention
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id 
where visits.visit_count=1 and 
((visits.time_in_queue >= 30 and water_source.type_of_water_source = 'shared_tap') 
or well_pollution.results != 'Clean' or water_source.type_of_water_source in ('river','tap_in_home_broken'))
limit 100000;


select * from project_progress limit 30;

select count(*) from project_progress where Improvement like '%UV%';

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results,
case 
	when type_of_water_source='well' then if(results like '%chem%','Install RO filters','Install UV and RO filters')
	when type_of_water_source ='river' then 'Drill wells'
    when type_of_water_source = 'tap_in_home_broken' then 'Diagnose infrastructure'
    when type_of_water_source = 'shared_tap' and time_in_queue >30 then concat('install ',floor(time_in_queue/30),' taps nearby')
end as intervention
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id 
where visits.visit_count=1 and 
((visits.time_in_queue >= 30 and water_source.type_of_water_source = 'shared_tap') 
or well_pollution.results != 'Clean' or water_source.type_of_water_source in ('river','tap_in_home_broken'))
limit 100000;


WITH town_totals AS (
			-- This CTE calculates the population of each town
			-- Since there are two Harare towns, we have to group by province_name and town_name
			SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
			FROM combined_analysis_table
                 where combined_analysis_table.results="Clean"
			GROUP BY province_name,town_name
       
)
select * from town_totals;



-- mcq 4 question 2
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
			-- This CTE calculates the population of each town
			-- Since there are two Harare towns, we have to group by province_name and town_name
			SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
			FROM combined_analysis_table
			GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well' 
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

Select * from combined_analysis_table;

select province_name, count(*) from test where tap_in_home < 50 and tap_in_home_broken < 50 group by province_name
intersect
select province_name, count(*) from test group by 1;

CREATE TABLE test as
select * from town_aggregated_water_access;

CREATE TEMPORARY TABLE province_aggregated_water_access
WITH Province_totals AS (
			-- This CTE calculates the population of each town
			-- Since there are two Harare towns, we have to group by province_name and town_name
			SELECT province_name, SUM(people_served) AS total_ppl_serv
			FROM combined_analysis_table
			GROUP BY province_name
)
SELECT
ct.province_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well' 
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
Province_totals pt ON ct.province_name = pt.province_name
GROUP BY -- We group by province first
ct.province_name;

select * from province_aggregated_water_access order by river desc;

select * from project_progress ;

create table infrastructure_cost (
improvement varchar(100),
unit_cost_USD int);

insert into infrastructure_cost
values ('Drill well',8500),
('Install UV and RO filter',4200),
('Diagnose local infrastructure',350);

select * from infrastructure_cost;

update infrastructure_cost
set improvement='Install UV and RO filters' where improvement = 'Install UV and RO filter';


SELECT
    p.Improvement,
    c.unit_cost_USD,
    COUNT(p.Improvement) AS count_of_upgrade,
    COUNT(p.Improvement) * c.unit_cost_USD AS total_cost
FROM
    project_progress p
JOIN
    infrastructure_cost c
ON
    p.Improvement = c.improvement
GROUP BY
    p.Improvement,
    c.unit_cost_USD
LIMIT 1000;

SELECT
project_progress.Project_id, 
project_progress.Town, 
project_progress.Province, 
project_progress.Source_type, 
project_progress.Improvement,
Water_source.number_of_people_served,
RANK() OVER(PARTITION BY Province ORDER BY number_of_people_served)
FROM  project_progress 
JOIN water_source 
ON water_source.source_id = project_progress.source_id
WHERE Improvement = "Drill wells"
ORDER BY Province DESC, number_of_people_served;
