create database olympics;

use olympics;

create table if not exists olympics_history
(
	id int, 
    name_ varchar(200),
    sex varchar(100),
    age varchar(100),
    height varchar(100),
    weight varchar(100),
    team varchar(100),
    noc varchar(100),
    games varchar(100),
    year_ int,
    season  varchar(100),
    city varchar(100),
    sport varchar(100),
    event_ varchar(100),
    medal varchar(100)
);

select* from olympics_history;


create table olympics_history_noc_region
(
	noc varchar(100),
    region varchar(100),
    notes varchar(100)
);

select* from olympics_history_noc_region;


load data infile 'E:\\PowerBi Tutorial\\SQL Kaggle Porject\\archive\\athlete_events.csv'
into table olympics_history
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 lines;


-- 1. How many olympic games have been held.

select count(distinct games) as total_olympic_games
from olympics_history;


-- 2.  List down all olympic games held so far.

select distinct year_, season, city
from olympics_history
order by year_;


-- 3. Mention the total number of nations who participated in each olympics game?

with all_countries as 
	(select games, nr.region
        from olympics_history oh
        join olympics_history_noc_region nr ON nr.noc = oh.noc
        group by games, nr.region)
        select games , count(1) as total_countries
        from all_countries
        group by games
        order by games;
        
        
-- 4. Which year saw the highest and lowest no of countries participating in olympics.

      with all_countries as
              (select games, nr.region
              from olympics_history oh
              join olympics_history_noc_region nr ON nr.noc=oh.noc
              group by games, nr.region),
          tot_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)
      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries;
      
      
-- 5. Which nation has participated in all of the olympic games.

with tot_games as
              (select count(distinct games) as total_games
              from olympics_history),
          countries as
              (select games, nr.region as country
              from olympics_history oh
              join olympics_history_noc_region nr ON nr.noc=oh.noc
              group by games, nr.region),
          countries_participated as
              (select country, count(1) as total_participated_games
              from countries
              group by country)
      select cp.*
      from countries_participated cp
      join tot_games tg on tg.total_games = cp.total_participated_games
      order by 1;


-- 6. Identify the sport which was played in all summer olympics.

with t1 as
	(select count(distinct games) as total_summer_games
	 from olympics_history
	 where season = 'Summer'), 
t2 as
	(select distinct sport , games 
     from olympics_history
     where season = 'Summer' order by games),
t3 as 
	(select sport, count(games) as no_of_games
	 from t2
	 group by sport)

select* from t3
join t1 on t1.total_summer_games = t3.no_of_games;


-- 7. Which Sports were just played only once in the olympics.

      with t1 as
          	(select distinct games, sport
          	from olympics_history),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;

-- 8. Fetch the total no of sports played in each olympic games.

      with t1 as
      	(select distinct games, sport
      	from olympics_history),
        t2 as
      	(select games, count(1) as no_of_sports
      	from t1
      	group by games)
      select * from t2
      order by no_of_sports desc;
      
-- 9. Fetch oldest athletes to win a gold medal.

with temp as 
	(select *
	from olympics_history
	where medal = 'Gold' and age = (select max(age) from olympics_history where medal = 'Gold')),
    
ranking as 
	(select *, rank() over(order by age desc) as rnk
	from temp
	where medal='Gold')
    
select* from ranking
where rnk = 1;



-- 10. Find the Ratio of male and female athletes participated in all olympic games.

with t1 as (
	select sex, count(*) as count_all
	from olympics_history
	group by sex),
t2 as(
	select * , row_number () over(order by count_all) as Row_No
	from t1),
    
maxcount as (select * from t2 where Row_No = 2),
mincount as (select * from t2 where Row_No = 1)

select concat( '1:',round(cast(maxcount.count_all as decimal)/ mincount.count_all, 2)) as Ratio
from mincount, maxcount;
    
    
-- 11) Fetch top 5 athletes who have won most gold medals.
 
 with t1 as
	(select name_, count(1) as total_medals
	from olympics_history
	where medal = 'Gold'
	group by name_
	order by count(1) desc),

t2 as 
	(select*, dense_rank() over(order by total_medals desc) as rnk 
     from t1)

select * from t2
where rnk <=5;

-- 12. Top 5 athletes who have won the most medals (gold/silver/bronze).

    with t1 as
            (select name_, team, count(1) as total_medals
            from olympics_history
            where medal in ('Gold', 'Silver', 'Bronze')
            group by name_, team
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_medals desc) as rnk
            from t1)
    select name_, team, total_medals
    from t2
    where rnk <= 5;
    
    
-- 13. Top 5 most successful countries in olympics. Success is defined by no of medals won.


    with t1 as
            (select nr.region, count(1) as total_medals
            from olympics_history oh
            join olympics_history_noc_region nr on nr.noc = oh.noc
            where medal <> 'NA'
            group by nr.region
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over(order by total_medals desc) as rnk
            from t1)
    select *
    from t2
    where rnk <= 5;
    

-- 14) list down total gold , silver and bronze medals won by each country.


with medals as 
	(select nr.region as country,
		(case when medal = 'Gold' then 1 else 0 end) as Gold,
		(case when medal = 'Silver' then 1 else 0 end) as Silver,
		(case when medal = 'Bronze' then 1 else 0 end) as Bronze
		from olympics_history oh
	 	join olympics_history_noc_region nr on nr.noc = oh.noc
	 	where medal <> 'NA')
select  country, sum(medals.Gold) as gold, sum(medals.Silver) as silver, sum(medals.Bronze) as bronze
from medals
group by country
order by gold desc, silver desc, bronze desc;


-- 15)List down total gold, silver and broze medals won by each country corresponding to each olympic games.

with temp as
	(select t1.NOC, t1.games, t2.region, t1.medal
    from olympics_history as t1 
    join olympics_history_noc_region as t2 on t1.NOC = t2.NOC)
    
select games, region as Country,
sum(case when medal = 'Gold' then 1 else 0 end) as gold,
sum(case when medal = 'Silver' then 1 else 0 end) as silver,
sum(case when medal = 'Bronze' then 1 else 0 end) as bronze
from temp
group by games, region, medal
order by games, medal;


-- 16) Identify which country won most gold, most silver, most bronze medals in each olympics games.

with medals as 
	(select oh.games as games, nr.region as country,
		(case when medal = 'Gold' then 1 else 0 end) as Gold,
		(case when medal = 'Silver' then 1 else 0 end) as Silver,
		(case when medal = 'Bronze' then 1 else 0 end) as Bronze
		from olympics_history oh
	 	join olympics_history_noc_region nr on nr.noc = oh.noc
	 	where medal <> 'NA'),
county_wise as
	(select games, country, sum(medals.Gold) as gold, sum(medals.Silver) as silver, sum(medals.Bronze) as bronze
		from medals
		group by games, country
		order by games, gold desc, silver desc, bronze desc)
select distinct(games),
		 concat(first_value(country) over(partition by games order by gold desc),
					 ' - ', first_value(gold) over(partition by games order by gold desc)) as Max_gold,
		 concat(first_value(country) over(partition by games order by silver desc),
					 ' - ', first_value(silver) over(partition by games order by silver desc)) as Max_silver,
		 concat(first_value(country) over(partition by games order by bronze desc),
					 ' - ', first_value(bronze) over(partition by games order by bronze desc)) as Max_bronze
from county_wise
order by games;



-- 17.Which countries have never won gold medal but have won silver / bronze medals?

with cte as(
	select region,
	if(medal = 'gold', 1, 0) gold,
	if(medal = 'silver', 1, 0) silver,
	if(medal = 'bronze', 1, 0) bronze
    from olympics_history oh
	join olympics_history_noc_region ohn on ohn.noc = oh.noc
	where medal != 'gold'
	and medal is not null)

select region, sum(gold) gold, sum(silver) silver, sum(bronze) bronze
from cte
group by region;


-- 18. In which Sport/event, India has won highest medals.


    with t1 as
        	(select sport, count(1) as total_medals
        	from olympics_history
        	where medal <> 'NA'
        	and team = 'India'
        	group by sport
        	order by total_medals desc),
        t2 as
        	(select *, rank() over(order by total_medals desc) as rnk
        	from t1)
    select sport, total_medals
    from t2
    where rnk = 1;


-- 19. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games


    select team, sport, games, count(1) as total_medals
    from olympics_history
    where medal <> 'NA'
    and team = 'India' and sport = 'Hockey'
    group by team, sport, games
    order by total_medals desc;

