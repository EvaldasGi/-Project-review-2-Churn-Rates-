--- 1.Take a look at the first 100 rows of data in the subscriptions table.

select * from subscriptions limit 100;

--- How many different segments do you see?

select count(distinct(segment)) as 'number of different segments' from subscriptions;

--2. Determine the range of months of data provided. Which months will you be able to calculate churn for?

select min(subscription_start), max(subscription_end) from subscriptions;

--3. Create a temporary table of months.

with months as (

select '2017-01-01' as first_day, '2017-01-31' as last_day

union select '2017-02-01' as first_day, '2017-02-28' as last_day

union select '2017-03-01' as first_day, '2017-03-31' as last_day
)

select * from months;

--------- Code below points 4-8 works as one unit

--4. Create a temporary table 'Status' with is_active by segment statements.

with months as (

select '2017-01-01' as first_day, '2017-01-31' as last_day

union select '2017-02-01' as first_day, '2017-02-28' as last_day

union select '2017-03-01' as first_day, '2017-03-31' as last_day
),

cross_join as (

select * from subscriptions cross join months

),

--5. Create 'Status' table with 'is_active' status by segment

status as (

select id, first_day as month, Case when ( segment is '87' ) and (subscription_start < first_day) and (subscription_end > last_day or subscription_end is null) then 1 else 0 end as is_active_87 ,

Case when ( segment is '30' ) and (subscription_start < first_day) and (subscription_end > last_day or subscription_end is null) then 1 else 0 end as is_active_30 ,

-- 6. Add 'is_canceled' status by segment

Case when (segment is '87') and subscription_end between first_day and last_day then 1 else 0 end as is_canceled_87 ,

Case
when (segment is '30') and subscription_end between first_day and last_day then 1 else 0 end as is_canceled_30

from cross_join  
 ),

-- 7. Create 'status_aggregate' temp.table

status_aggregate as (

select month, sum(is_active_87) as sum_active_87 , sum(is_active_30) as sum_active_30 , sum(is_canceled_87) as sum_canceled_87, sum(is_canceled_30) as sum_canceled_30

from status group by month )

-- 8. Calculate the churn rates for the two segments over the three month period, which segment has lower churn rate?

select month, 1.0 * sum_canceled_87 / sum_active_87 as 'Segment 87 Churn rate', 1.0 * sum_canceled_30 / sum_active_30 as 'Segment 30 Churn rate'

from status_aggregate ;

-- 9. How would you modify this code to support a large number of segments?

-- I would count distinct segments, create temp table for segment types, cross join and status temp table would include extra argument about segment type