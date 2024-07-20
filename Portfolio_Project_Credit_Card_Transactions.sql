-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

select city,sum(amount) as amount_spend,
(sum(amount)/ (select sum(amount) from credit_card_transcations))*100 as percentage_contribution
from credit_card_transcations
group by city
order by amount_spend desc
limit 5;

-- 2- write a query to print highest spend month and amount spent in that month for each card type

with cte as (
select card_type,monthname(transaction_date) as month,sum(amount) as amount_spend
from credit_card_transcations
group by card_type,monthname(transaction_date)),

cte1 as (
select *,
dense_rank() over(partition by card_type order by amount_spend desc) as rn 
from cte)

select card_type, month, amount_spend from cte1
where rn = 1;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
SELECT *,
sum(amount) over(partition by card_type order by amount) as total_spend
FROM credit_card_transcations),

cte1 as (
select *,
row_number() over(partition by card_type order by total_spend asc) as rn
from cte 
where total_spend >= 1000000)

select * from cte1 where rn = 1;

-- 4- write a query to find city which had lowest percentage spend for gold card type

with cte as (
select city, sum(amount) as total
from credit_card_transcations
group by city),

cte1 as (
select city,sum(amount) as goldTotal
from credit_card_transcations
where card_type = 'gold'
group by city),

cte2 as (
select c.*,c1.goldTotal
from cte c inner join cte1 c1
on c.city = c1.city)

select city, round((goldTotal/total)*100 ,2)as gold_per
from cte2
order by gold_per
limit 1;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (
select city,exp_type,sum(amount) as Amt
from credit_card_transcations
group by city,exp_type),

high as (
select city,exp_type as highest_expense_type,amt,
dense_rank() over(partition by city order by amt desc) as drn
from cte),

low as (
select city,exp_type as lowest_expense_type,amt,
dense_rank() over(partition by city order by amt) as arn
from cte)

select h.city,h.highest_expense_type,l.lowest_expense_type
from high h inner join low l
on h.city = l.city
where h.drn = 1 and l.arn = 1;

-- 6- write a query to find percentage contribution of spends by females for each expense type

with cte as (
select exp_type, sum(amount) as total
from credit_card_transcations
group by exp_type),

cte1 as (
select exp_type,sum(amount) as femaleTotal
from credit_card_transcations
where gender = 'F'
group by exp_type),

cte2 as (
select c.*,c1.femaleTotal
from cte c inner join cte1 c1
on c.exp_type = c1.exp_type)

select exp_type, round((femaleTotal/total)*100 ,2)as female_contribution
from cte2
order by female_contribution;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type,year(transaction_date) as yr,month(transaction_date) as mn,sum(amount) as total
from credit_card_transcations
group by card_type,exp_type,year(transaction_date),month(transaction_date)
order by card_type asc),

cte1 as(
select *,
lag(total) over (partition by card_type,exp_type) as previous_mn
from cte),

cte2 as(
select *,
((total-previous_mn)/previous_mn)*100 as growth
from cte1)

select card_type,exp_type,yr,mn,growth
from cte2
where yr = 2014 and mn =1
order by growth desc
limit 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
SELECT city, 
       SUM(amount) / COUNT(*) AS spend_per_transaction
FROM credit_card_transcations
WHERE DAYOFWEEK(transaction_date) IN (1, 7)  -- 1 = Sunday, 7 = Saturday
GROUP BY city
ORDER BY spend_per_transaction DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte1 as(select city as cn
from credit_card_transcations
group by city
having count(*)>500),

cte2 as (
select *,
min(transaction_date) over (partition by city order by transaction_date asc,transaction_id asc) as min_trans,
row_number() over (partition by city order by transaction_date asc,transaction_id asc) as rn
from credit_card_transcations
where city in (select * from cte1))

select city,
timestampdiff(day,min_trans,transaction_date) as days_to_reach_500_transaction
from cte2
where rn= 500
order by days_to_reach_500_transaction
limit 1;