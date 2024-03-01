-- 1 user can have averagely how many accounts 
-- calculate the users creating more than the average account one user can hold?
-- Customers retention
select 
	user_id, 
	`First Use Day`,
	concat("Day", " ", frequency) as "Day Number",
	frequency, 
	`date`,
	`Total Use Day`
from (select
	Total_day.user_id,
	`date`, 
	`First Use Day`, 
	Frequency, 
	`Total Use Day`
from (select distinct 
	user_id,
	`date`,
	dense_rank() over (partition by user_id order by `date`) as Frequency
from events 
where user_id is not null) as Total_day
left join (
select 
	user_id,
	min(`date`) as "First Use Day",
	count(distinct `date`) as "Total Use Day"
from events
where user_id is not null 
group by user_id) as First_day
on Total_day.user_id = First_day.user_id) Evaluation

-- Fake customers spot 
select 
	*,
	sum(total_accounts) over () as Test,
case 
	when Total_Accounts <= Average_Accounts then "Normal"
	when Total_Accounts <= Average_Accounts * 2 then "Normal"
	when Total_Accounts <= Average_Accounts * 3 then "Normal"
	when Total_Accounts <= Average_Accounts * 4 or Average_Accounts * 5 then "Serious"
end as "Evaluation"
from (select 
	*,
	Ceil(avg(Total_Accounts) over()) as Average_Accounts 
from (
select distinct 
	user_id, 
	count(*) over (partition by user_id) as Total_Accounts
from user_info ui 
where user_id is not null) as Source) as Evaluation

-- New methods (Acess greater than 6 hours will be counted as 1, else, it will not be counted)
select 
	user_id, 
	`New_Access_Day`, 
	`New_Access`, 
	`Next_Access_Day`,
	`Next_Access`,
	`Period`, 
	sum(`Access_Count`) over (partition by user_id) as "Total_Access",
	sum(`Access_Count`) over 
	(partition by user_id order by `Next_Access` rows between unbounded preceding and current row) as Sort,
	concat("Time", " ",
	sum(`Access_Count`) over 
	(partition by user_id order by `Next_Access` rows between unbounded preceding and current row))
	as "Access_Time"
from (select 
	*, 
	sec_to_time(abs(`Secs2` - `Secs1`)) as "Period",
case 
	when sec_to_time(abs(`Secs2` - `Secs1`)) >= "06:00:00" then 1
	when New_Access = First_Access then 1
else 0
end as "Access_Count"
from (select 
	user_id,
	`date` as "New_Access_Day", 
	`datetime` as "New_Access",
	min(datetime) over (partition by user_id) as "First_Access", 
	time_to_sec(`datetime`) as Secs1,
	lead(`date`, 1, `date`) over (partition by user_id order by `date`) as Next_Access_Day, 
	lead(`datetime`, 1, `datetime`) over (partition by user_id order by `datetime`) as Next_Access,
	time_to_sec(lead(`datetime`, 1, `datetime`) over (partition by user_id order by `datetime`)) as Secs2
from events
where user_id is not null
) as Source) as Evaluation
where `Access_Count` = 1


-- old methods (1 access, time doesn't matter, will always count)
select 
	user_id,
	`date` as "New_Access_Day",
	`datetime` as "New_Access",
	lead(`date`, 1,`date`) over (partition by user_id order by `date`) as "Next_Access_Day",
	lead(`datetime`, 1, `datetime`) over (partition by user_id  order by `datetime`) as "Next_Access", 
	count(*) over (partition by user_id) as "Total_Access",
	count(`datetime`) over 
	(partition by user_id order by `datetime` rows between unbounded preceding and current row) as Sort, 
	concat("Time", " ", 
	count(`datetime`) over 
	(partition by user_id order by `datetime` rows between unbounded preceding and current row)) 
	as Total_Access
from events 
where user_id is not null 

-- RFM calculating method 
with base_table as(
select distinct 
	user_id,
	date_format(Earliest_Access, '%Y-%m-%d') as Earliest_Access, 
	date_format(Latest_Access, '%Y-%m-%d') as Latest_Access, 
	Total_Volume,
	sum(Total_Access) over (partition by user_id) as Access_time 
from (select 
	user_id, 
	Earliest_Access,
	Latest_Access, 
	Total_Volume,
case 
	when Period >= "06:00:00" then 1 
	when First_Access = Earliest_Access then 1
	else 0
end as Total_Access
from (select 
	user_id,
	First_Access,
	Next_Access,
	min(First_Access) over (partition by user_id) as "Earliest_Access",
	max(Next_Access) over (partition by user_id) as "Latest_Access", 
	sec_to_time(abs(Secs1 - Secs2)) as Period,
	Total_Volume
from (select 
	user_id, 
	datetime as "First_Access",
	lead(datetime, 1, datetime) over (partition by user_id order by datetime) as "Next_Access",
	ceil(sum(volume) over (partition by user_id)) as "Total_Volume", 
	time_to_sec(`datetime`) as "Secs1", 
	time_to_sec(lead(`datetime`, 1, `datetime`) over (partition by user_id order by `datetime`)) as "Secs2" 
from events 
where user_id is not null
) as Source
) as Evaluation
) as RFM)

select 
	user_id,
	Total_Volume,
	Access_time,
	Latest_Access,
	case 
		when Total_Volume >= Min_Volume and Total_Volume < Max_Volume * 0.25 then 1
		when Total_Volume >= Max_Volume * 0.25 and Total_Volume < Max_Volume * 0.5 then 2
		when Total_Volume >= Max_Volume * 0.5 and Total_Volume < Max_Volume * 0.75 then 3 
		when Total_Volume >= Max_Volume * 0.75 and Total_Volume <= Max_Volume then 4 
	end as Monetary, 
	case 
		when Access_time >= Min_Access and Access_time < Max_Access * 0.25 then 1
		when Access_time >= Max_Access * 0.25 and Access_Time < Max_Access * 0.5 then 2
		when Access_Time >= Max_Access * 0.5 and Access_Time < Max_Access * 0.75 then 3 
		when Access_Time >= Max_Access * 0.75 and Access_Time <= Max_Access then 4 
	end as Frequency, 
	CASE 
	    WHEN Latest_Access >= '2023-01-01' AND Latest_Access <= '2023-01-14' THEN 1
	    WHEN Latest_Access >= '2023-01-15' AND Latest_Access <= '2023-01-28' THEN 2 
	    WHEN Latest_Access >= '2023-01-29' AND Latest_Access <= '2023-02-11' THEN 3 
	    WHEN Latest_Access >= '2023-02-12' AND Latest_Access <= '2023-02-28' THEN 4
	END AS Recency
from (select 
	*,
	min(Total_Volume) over () as Min_Volume,
	max(Total_Volume) over () as Max_Volume,
	min(Earliest_Access) over () as Min_Frequency,
	max(Latest_Access) over () as Max_Frequency,
	min(Access_time) over () as Min_Access,
	max(Access_time) over () as Max_Access
from base_table) as Rating

#Identified recognized userse 
select 
	count(distinct user_id) as Recognized_Users
from user_info ui 
where user_id in
(select 
	user_id 
from events
where user_id is not null)

#Identified missing users 
select 
	count(distinct e.user_id) as Missing_users
from events e
left join user_info ui 
on e.user_id = ui.user_id 
where ui.user_id  is null

