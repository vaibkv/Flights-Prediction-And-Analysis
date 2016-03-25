use _flights;

--Tables
select top 10 * from [data].[flights]
select top 10 * from [data].[OriginDestinationCodes]
select top 10 * from [data].[CancellationCodes]
select top 10 * from [data].[AirportIDs]

--Important variables where values are missing
select * from [data].[flights] where DEP_TIME is null or DEP_TIME = ''
select * from [data].[flights] where ARR_TIME is null or ARR_TIME = ''
select * from [data].[flights] where CANCELLED is null or CANCELLED = ''
select * from [data].[flights] where CANCELLATION_CODE is null or CANCELLATION_CODE = ''

--Adding departure delay and arrival delay columns in the main table
alter table [data].[flights]
add Departure_Delay float, Arrival_Delay float

--Populating those columns
--some testing
declare @time1 time(0) = '08:41'
declare @time2 time(0) = '08:43'
select DATEDIFF(MINUTE, @time2, @time1)

SELECT STUFF('1513', 3, 0, ':'); --adding colon

alter table [data].[flights]
alter column crs_dep_time varchar(5)

alter table [data].[flights]
alter column dep_time varchar(5)

alter table [data].[flights]
alter column crs_arr_time varchar(5)

alter table [data].[flights]
alter column arr_time varchar(5)

--updating columns to add colons
update data.flights
set crs_dep_time = STUFF(crs_dep_time, 3, 0, ':') where crs_dep_time is not null and crs_dep_time <> ''

update data.flights
set dep_time = STUFF(dep_time, 3, 0, ':') where dep_time is not null and dep_time <> ''

update data.flights
set crs_arr_time = STUFF(crs_arr_time, 3, 0, ':') where crs_arr_time is not null and crs_arr_time <> ''

update data.flights
set arr_time = STUFF(arr_time, 3, 0, ':') where arr_time is not null and arr_time <> ''

update data.flights
set arr_time = '23:59' where arr_time = '24:00'

update data.flights
set crs_arr_time = '23:59' where crs_arr_time = '24:00'

update data.flights
set dep_time = '23:59' where dep_time = '24:00'

update data.flights
set crs_dep_time = '23:59' where crs_dep_time = '24:00'

--deleting data we don't need
delete from data.flights where arr_time is null or arr_time = ''
delete from data.flights where crs_arr_time is null or crs_arr_time = ''
delete from data.flights where dep_time is null or dep_time = ''
delete from data.flights where crs_dep_time is null or crs_dep_time = ''

update data.flights
set Arrival_Delay = DATEDIFF(MINUTE, cast(rtrim(ltrim(crs_arr_time)) as time(0)), cast(ltrim(rtrim(arr_time)) as time(0))) 
where arr_time is not null and crs_arr_time is not null and arr_time <> '' and crs_arr_time <> ''

update data.flights
set Departure_Delay = DATEDIFF(MINUTE, cast(rtrim(ltrim(crs_dep_time)) as time(0)), cast(ltrim(rtrim(dep_time)) as time(0))) 
where dep_time is not null and crs_dep_time is not null and dep_time <> '' and crs_dep_time <> ''

--Flights arrived on time - 9k
select COUNT(*) from data.flights where Arrival_Delay =0

--Departed on time -- 24k
select COUNT(*) from data.flights where Departure_Delay = 0

--Arrived before time
select COUNT(*) from data.flights where Arrival_Delay < 0

--Departed before time
select COUNT(*) from data.flights where Departure_Delay < 0

--Any fligts that started late but arrived early
select Departure_Delay, Arrival_Delay, Distance from data.flights where Departure_Delay > 0 and Arrival_Delay < 0 order by Distance

	select COUNT(*) from data.flights where Departure_Delay < -1000
	select COUNT(*) from data.flights where Arrival_Delay < -1000
	
		select COUNT(*) from data.flights where Departure_Delay > 1000
	select COUNT(*) from data.flights where Arrival_Delay > 1000
	
	select * from data.flights where Arrival_Delay > 1000

--number of delayed arrivals -- 105518
select COUNT(*) from data.flights where arrival_delay > 0

--number of before/on time arrivals - 328402
select COUNT(*) from data.flights where arrival_delay <= 0

--number of delayed departures - 105885
select COUNT(*) from data.flights where departure_delay > 5

--number of before/on time departures - 328035
select COUNT(*) from data.flights where departure_delay <= 5

--Get Day of week
SELECT DATENAME(dw,fl_date) as 'DayOfWeek', SUBSTRING(crs_dep_time,0,3) as 'Hour', case when arrival_delay > 10 then 'Delayed' when arrival_delay >= -10 and arrival_delay <= 10 then 'OnTime' else 'BeforeTime' end as 'WhatTime' from data.flights

--Security delay airport wise - only on departure
select origin, sum(security_delay) as 'TotalSecurityDelay' from data.flights where security_delay is not null and security_delay > 0 group by origin

--What if a flight is diverted
select * from data.flights where diverted = 1 and arrival_delay >=0

--Number of flights cancelled and their reasons
select COUNT(*) from data.flights where cancelled =0

--Any bad weather days this month?
select origin, sum(weather_delay) from data.flights where weather_delay > 0 group by origin

--airport busyness
select origin_airport_id, COUNT(*) as 'FlightCount' into ##BusyOrigin 
from data.flights group by origin_airport_id order by COUNT(*) desc

0-1, 2-3, 4-8
select a.*, case when zscore <=0.12 then 'NonBusyAirport' when (zscore >0.12 and zscore <= 2.6) then 'MediumBusy' else 'VeryBusy' end 'OriginBusyness' into OriginBusyZscores from 
(
select origin_airport_id, FlightCount, ((FlightCount - 1475.0)/3399.80) as zscore from ##BusyOrigin
) a order by a.zscore

select stdev(FlightCount) from ##BusyOrigin
select avg(FlightCount) from ##BusyOrigin

--removing duplicate counts

select origin_airport_id, dest_airport_id, TotalFlightCount from ##totaldata
union
select B.origin_airport_id, B.dest_airport_id, FlightCount from ##totaldata A right outer join ##BusyAirports B
on B.origin_airport_id = A.origin_airport_id and B.dest_airport_id = A.dest_airport_id where A.origin_airport_id is null and A.dest_airport_id is null
 
--candidate features - Departure delay, carrier, origin, dest, diverted, distance, weather_delay, busyness of origin-dest, weekday, hour of day
select carrier, origin, dest, diverted, distance, weather_delay, arrival_delay, departure_delay, DATENAME(dw,fl_date) as 'DayOfWeek', SUBSTRING(crs_dep_time,0,3) as 'Hour', case when arrival_delay > 10 then 'ArrivalDelayed' when arrival_delay >= -10 and arrival_delay <= 10 then 'ArrivalOnTime' else 'ArrivalBeforeTime' end as 'ArrivalTarget', zs.OriginBusyness, case when departure_delay > 10 then 'DepartureDelayed' when departure_delay >= -10 and departure_delay <= 10 then 'DepartureOnTime' else 'DepartureBeforeTime' end as 'DepartureClass' from data.flights fl join #OriginBusyZscores zs on zs.origin_airport_id = fl.origin_airport_id