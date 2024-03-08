-- 1. Total Number of records.
select count(*) from wfp; 
/* There are 211773 records in the dataset */

------------------------------------------------------------------
-- 2. The duration of the dataset.
select min(date), max(date) from wfp;

/* The dataset is for a period of 30 years. 
It has data from 1994 to 2023. */

------------------------------------------------------------------
-- 3. The number of distinct Category and Commodities in the data.
select category, count(distinct commodity) as 'Commodities_Count'
from wfp 
Group by category with rollup
order by Commodities_Count asc;
/* There are total 6 categories and 23 commodities. Oil and Fats has the maximum number of commodities i.e.6 
and Milk and dairy has the least which is 2.*/

------------------------------------------------------------------
-- 4. Rename the column admin1 and admin2 to State and District respectively.
Alter table wfp rename column admin1 to State;
Alter table wfp rename column admin2 to District;
Alter table wfp modify date date;
update wfp
set date=str_to_date(date, '%d-%m-%Y');

------------------------------------------------------------------
-- 5. Number of states in the dataset.
select count(distinct State) as state 
from wfp
where State not in ('Dadra and Nagar Haveli and Daman & Diu', 'Jammu & Kashmir', 'Ladakh', 'Chandigarh', 'Delhi', 'Puducherry', 'Lakshadweep', 'Andaman and Nicobar')
and State is not null;

select count(distinct State) as Union_Territory
from wfp 
where State IN ('Dadra and Nagar Haveli and Daman & Diu', 'Jammu & Kashmir', 'Ladakh', 'Chandigarh', 'Delhi', 'Puducherry', 'Lakshadweep', 'Andaman and Nicobar');
/*There are 28 states and 4 union territories.*/

------------------------------------------------------------------
-- 6. Replace 'Blank' or "null" values in state column.
select * from wfp 
where state = null or state = "";
/*There are 789 rows which don't have any location information.*/
------------------------------------------------------------------
-- 7. Remove this blank state rows.
Delete from wfp 
where state= null or state ='';

------------------------------------------------------------------
-- 8. Identifying the commodities for Wholesale data has been acquired.

select distinct commodity, unit
from wfp 
where pricetype = 'Wholesale';

/* Dataset has wholesale informatio of Rice, Wheat and Sugar for a unit of 100 kg i.e. 1 Qunital*/

------------------------------------------------------------------

-- 9. Most expensive commodity and in which state - Retail Purchases and Wholesale Purchases.
-- Rice, under Cereals and Tubers - Retail Purchases
with cte as 
(select state, commodity, pricetype, max(price) as price
from wfp
where commodity = 'Rice'
and pricetype = 'Retail'
group by state, commodity, pricetype)
select distinct year(wfp.date) as Year_of_production, cte.state, cte.commodity, cte.pricetype, cte.price from wfp inner join cte
on wfp.commodity=cte.commodity
and wfp.state=cte.state
and wfp.price=cte.price
and wfp.pricetype=cte.pricetype
order by price desc;

/* Meghalaya has had the highest retail price in 2021 for Rice which INR 71.83.
Delhi had the lowest retail price of INR 39 in 2023 in the complete data set. */

-- Rice, under Cereals and Tubers - Wholesale Purchases
with cte as 
(select state, commodity, pricetype, max(price) as price
from wfp
where commodity = 'Rice'
and pricetype = 'Wholesale'
group by state, commodity, pricetype)
select distinct wfp.date as production_date, cte.state, cte.commodity, cte.pricetype, cte.price from wfp inner join cte
on wfp.commodity=cte.commodity
and wfp.state=cte.state
and wfp.price=cte.price
and wfp.pricetype=cte.pricetype
order by price desc;

/* Tamilnadu has had the highest wholesale price in 2020 for Rice which INR 4910 per 100 kg.
Maharashtra had the lowest wholesale price of INR 2800 per 100 kg in 2019 in the complete data set. */

-- Milk, under Milk and dairy - Retail Purchases
with cte as (
select state, commodity, pricetype, max(price) as price
from wfp
where commodity='Milk' and pricetype='Retail'
group by state, commodity, pricetype)
select distinct wfp.date, wfp.state, wfp.commodity, wfp.pricetype, wfp.price
from wfp inner join cte
on cte.state=wfp.state
and cte.commodity=wfp.commodity
and cte.pricetype=wfp.pricetype
and cte.price=wfp.price
order by price desc;

/* Gujarat has had the highest Retail price in 2020 for Milk which is INR 52 per litre.
Karnataka had the lowest Retail price of INR 38 per litre in 2020 in the complete data set. */

with cte as 
(select state, commodity, pricetype, max(price) as price
from wfp
where commodity = 'Sugar'
and pricetype = 'Retail'
group by state, commodity, pricetype)
select distinct wfp.date as production_date, cte.state, cte.commodity, cte.pricetype, cte.price from wfp inner join cte
on wfp.commodity=cte.commodity
and wfp.state=cte.state
and wfp.price=cte.price
and wfp.pricetype=cte.pricetype
order by price desc ;

/* Andaman and Nicobar in 2020 had the highest retail price of INR 60 per kg for Sugar.
Chandigarh had the lowest in 2023 of INR 42.61.*/

------------------------------------------------------------------
-- 10. Comparing the percentage change in average prices of commodities under category 'oil and fats' from 2020 to 2023.
with cte as(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2023
from wfp
where category='oil and fats'
and Year(date)='2023'
group by Year(date), commodity),
cte1 as
(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2020
from wfp
where category='oil and fats'
and Year(date)='2020'
group by Year(date), commodity)
select cte.commodity, cte.Average_price2023, cte1.Average_price2020, Truncate((((cte.Average_price2023-cte1.Average_price2020)/cte1.Average_price2020)*100),2) as price_change
from cte inner join cte1
on cte.commodity=cte1.commodity
order by price_change desc;

/* There has been a substantial increase in the average price of Ghee of about 41 % in a period of 4 years.
Palm oil prices has seen only about 20% change which is the lowest in the category 'oil and fats*/

------------------------------------------------------------------
-- 11. Comparing the percentage change in average prices of commodities under category 'cereals and tubers' under 'Retail' pricetype from 2020 to 2023.
-- This category contains basic food-items e.g. Rice, Wheat, Wheat Flour and Potatoes.
with cte as(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2023
from wfp
where category='cereals and tubers'
and pricetype ='Retail'
and Year(date)='2023'
group by Year(date), commodity),
cte1 as
(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2020
from wfp
where category='cereals and tubers'
and pricetype ='Retail'
and Year(date)='2020'
group by Year(date), commodity)
select cte.commodity, cte.Average_price2023, cte1.Average_price2020, Truncate((((cte.Average_price2023-cte1.Average_price2020)/cte1.Average_price2020)*100),2) as price_change
from cte inner join cte1
on cte.commodity=cte1.commodity
order by price_change desc;

/* Over a period of 4 years wheat flour price as increased about 24% whereas 
there has been a dip in the prices of Potatoes of about 34%.*/

------------------------------------------------------------------
-- 11. Comparing the percentage change in average prices of commodities under category 'pulses and nuts' under 'Retail' pricetype from 2020 to 2023.
-- This category contains basic pulses e.g. Lentils, Lentils (masur), Lentils (urad),Lentils (moong).

with cte as(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2023
from wfp
where category='pulses and nuts'
and pricetype ='Retail'
and Year(date)='2023'
group by Year(date), commodity),
cte1 as
(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2020
from wfp
where category='pulses and nuts'
and pricetype ='Retail'
and Year(date)='2020'
group by Year(date), commodity)
select cte.commodity, cte.Average_price2023, cte1.Average_price2020, Truncate((((cte.Average_price2023-cte1.Average_price2020)/cte1.Average_price2020)*100),2) as price_change
from cte inner join cte1
on cte.commodity=cte1.commodity
order by price_change desc;

/* Lentils have seen highest increase i.e. 23.31% whereas 
we see least change in the Lentils(moong) */

------------------------------------------------------------------
-- 12. Comparing the percentage change in average prices of commodities under category 'vegetables and fruits' under 'Retail' pricetype from 2020 to 2023.
-- This category contains basic pulses e.g. Lentils, Lentils (masur), Lentils (urad),Lentils (moong).

with cte as(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2023
from wfp
where category='vegetables and fruits'
and pricetype ='Retail'
and Year(date)='2023'
group by Year(date), commodity),
cte1 as
(
Select Year(date), commodity, Truncate(avg(price),2) as Average_price2020
from wfp
where category='vegetables and fruits'
and pricetype ='Retail'
and Year(date)='2020'
group by Year(date), commodity)
select cte.commodity, cte.Average_price2023, cte1.Average_price2020, Truncate((((cte.Average_price2023-cte1.Average_price2020)/cte1.Average_price2020)*100),2) as price_change
from cte inner join cte1
on cte.commodity=cte1.commodity
order by price_change desc;

/* The average price of Tomatoes has increased by about 5% and Onions has seen a significant drop in the prices by noticeable 38% 
which was mainly due to the export ban by the govt. The central government had first imposed a minimum export price (MEP) on onion, 
which was followed by the decision to impose a complete ban on exports on December 7 2023. 
Onion prices started falling immediately after the export ban was announced. */
------------------------------------------------------------------
-- 13. Create a new table Zone and insert values accordingly.

create table zones (
state char(255) primary key, city char(255), zone char (255));

alter table zones drop primary key;

Insert into zones
select distinct state, District, null 
from wfp;

update zones
set zone = 'North' 
where state IN ( 'Himachal Pradesh', 'Punjab', 'Haryana', 'Uttarakhand', 'Uttar Pradesh');

update zones
set zone = 'South' 
where state IN ( 'Karnataka', 'Telangana', 'Tamil Nadu', 'Andhra Pradesh', 'Kerala');

update zones
set zone = 'East' 
where state IN ( 'Bihar', 'Orissa', 'Jharkhand', 'West Bengal');

update zones
set zone = 'West' 
where state IN ( 'Rajasthan', 'Gujarat', 'Goa', 'Maharashtra');

update zones
set zone = 'Central' 
where state IN ( 'Madhya Pradesh', 'Chhattisgarh');

update zones
set zone = 'North East' 
where state IN ( 'Assam', 'Sikkim', 'Manipur', 'Meghalaya', 'Nagaland', 'Mizoram', 'Tripura', 'Arunachal Pradesh');

update zones
set zone = 'Union Territory' 
where state IN ( 'Chandigarh', 'Delhi', 'Puducherry', 'Andaman and Nicobar');

select * from zones ;
------------------------------------------------------------------
-- 14. Average of commodities zone wise in the year 2023.

select z.zone, z.city, w.commodity, Truncate(Avg(w.price),2) as Average_price
from zones z inner join wfp w
on z.state=w.state
where year(date)='2023'
group by z.zone, z.city, w.commodity;
