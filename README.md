# LogParser download links

- [LogParser Studio](https://techcommunity.microsoft.com/gxcuf89792/attachments/gxcuf89792/Exchange/16744/1/LPSV2.D2.zip)

- [Logparser v2.2 (required for LogParser Studio to work)](https://www.microsoft.com/en-us/download/confirmation.aspx?id=24659)

# LogParser scripts

In the repository, along with this Readme.md file, you'll find some LogParser PowerShell scripts generated with LogParser Studio for quick reference. I'll document these later on.

# Some-Logparser-Queries
Some Logparser Queries to help my peers

#### Quantize by hour - use TO_LOCALTIME and QUANTIZE

Hint if you want to count stuff that happened by minute (60 seconds) or my hour (3600 seconds), we make use of

```sql
QUANTIZE(Time_Stamp,Sample_rate_in_seconds)
```
Example, the Sample rate of 3600 seconds will count all occurences by 3600 seconds = 1 hour

> NOTE: for IIS logs, on newer servers, you may need to select the W3CLOG instead of IISW3CLOG if the latter does not return anything.

An application of QUANTIZE:

*Log Type:***W3CLOG****

```sql
SELECT
    QUANTIZE(TO_TIMESTAMP(date, time), 60) AS Minute,
    COUNT(*) AS Total,  
    SUM(sc-bytes) AS TotBytesSent 
FROM
    '[LOGFILEPATH]'
WHERE
    date > '2016-04-23'
GROUP BY Minute
ORDER BY Minute
```

Another example, on an IIS log, with QUANTIZE, and TO_LOCALTIME to convert to local time - this one quantize to display information such as cs-URI-Stem aka URL reached, Average of time taken and in which log file, quantized in 5 minutes time slices:

*Log Type:***W3CLOG****

```sql
SELECT TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(date, time), 300)) AS FiveMinuteInterval,
       cs-uri-stem,
       AVG(time-taken) as AverageTime,
       LogFileName
/*Use the below to target specific log file once found:*/      
/*FROM 'C:\temp\IISLogs\u_ex22101715_x.log'*/
/*Use the below to use LogParser Studio's Log files selected file or folder:*/
FROM '[LOGFILEPATH]'
WHERE cs-uri-stem not like '%/healthcheck.htm'
GROUP BY FiveMinuteInterval, LogFileNAme,cs-uri-stem
```

The below is similar to the above, instead we display the number of hits per URL reached (cs-uri-stem), in each log file:

```sql
SELECT cs-uri-stem,
       COUNT(*) as hits,
       LogFileName
/*FROM 'C:\temp\IISLogs\u_ex22101715_x.log'*/
FROM '[LOGFILEPATH]'
WHERE cs-uri-stem not like '%/healthcheck.htm'
GROUP BY LogFileNAme,cs-uri-stem
ORDER BY hits DESC
```


An example on an Exchange Tracking log (specific to Exchange Tracking Logs, we need to EXTRACT the "#Fields: date-time" string from the tracking log before calling TO_TIMESTAMP():

*Log Type:***EELLOG****

```sql
SELECT TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(TO_STRING(EXTRACT_PREFIX([#Fields: date-time],0,'.')), 'yyyy-MM-ddThh:mm:ss'),3600)) AS Hour,
	cs-username,
	sc-status,
	etc...
	# NOTE: don't put a comma after the last element of the SELECT clause

COUNT(*) AS Messages
FROM '\\$Server\$TrackingLogPaths\*.log'
WHERE event-id='RECEIVE'
GROUP BY cs-username,sc-status,etc...,Hour /*<<<<<<<<<<<<<----- Group by the quantized time named on the SELECT clause*/ 
ORDER BY Hour ASC
```

#### Pull IIS logs data with some fields, and convert IIS UTC time to local time, for a specific URI (/EWS/mrsproxy.svc)

```sql
/* Pull all requests*/
/* If an error is returned there may be no matches */
/*#Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status time-taken*/

SELECT   TO_LOCALTIME(TO_TIMESTAMP(date, time)) as TimeStamp,
         cs-username,
         cs-uri-stem,
         sc-status,
         time-taken
FROM 'c:\temp\IIS logs\*.log'
WHERE cs-uri-stem LIKE '/EWS/mrsproxy.svc%'
ORDER BY TimeStamp
```

#### Pull IIS logs data with all fields for a specific URI (/EWS/mrsproxy.svc)

```sql
/* Pull all requests*/
/* If an error is returned there may be no matches */
/*#Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status time-taken*/

SELECT   TO_LOCALTIME(TO_TIMESTAMP(date, time)) as TimeStamp,
         cs-username, 
         s-ip, 
         cs-method, 
         cs-uri-stem, 
         cs-uri-query, 
         s-port, 
         c-ip, 
         cs(User-Agent), 
         cs(Referer), 
         sc-status, 
         sc-substatus, 
         sc-win32-status, 
         time-taken

FROM     'c:\temp\IIS logs\*.log'
WHERE    cs-uri-stem LIKE '/EWS/mrsproxy.svc%'
ORDER BY TimeStamp
```

#### To save the results into a CSV

Simply use the following stance:
```sql
INTO     'C:\temp\My_CSV_Results.CSV'
```

For example, taking the above complete SQL like request, adding the INTO 'Myfile.csv' :

```sql
SELECT   TO_LOCALTIME(TO_TIMESTAMP(date, time)) as TimeStamp,
         cs-username,
         cs-uri-stem,
         sc-status,
         time-taken

INTO     'c:\temp\IISLog Filtered for MRSProxy.CSV'
FROM     'c:\temp\IIS logs\*.log'
WHERE    cs-uri-stem LIKE '/EWS/mrsproxy.svc%'
ORDER BY TimeStamp
```

> NOTE: Saving direclty in a CSV file will not print the results into Logparser Studio.
> 
> ![image](https://user-images.githubusercontent.com/33433229/121620577-92837480-ca38-11eb-88e3-4ff1a3873a96.png)


# Logparser requests for users and apps inventory

## Show all ActiveSync users

```sql
SELECT   cs-username AS UserID, 
	cs(User-Agent) AS Application, 
	cs-uri-stem AS Vdir,
	s-ip AS SERVER,
	c-ip AS CLIENT,
	cs-method,
	Count(*)
FROM     '[LOGFILEPATH]'
WHERE    cs-uri-stem LIKE '%Microsoft-Server-ActiveSync%' and UserID not like '%health%'
GROUP BY UserID, Application, Vdir, Server, Client, cs-method
ORDER BY COUNT(*) DESC
```

Log Parser Studio Log type: ```IISW3CLOG```

## All Autodiscover requests

```sql
SELECT   cs-username AS UserID, 
	cs(User-Agent) AS Application, 
	cs-uri-stem AS Vdir,
	s-ip AS SERVER,
	c-ip AS CLIENT,
	cs-method,
	Count(*)
FROM     '[LOGFILEPATH]'
WHERE    cs-uri-stem LIKE '%Autodiscover%' and UserID not like '%health%'
GROUP BY UserID, Application, Vdir, Server, Client, cs-method
ORDER BY COUNT(*) DESC
```

Log Parser Studio Log type: ```IISW3CLOG```

## Query hits on specific URL (example with Autodiscover again), between 2 date/time stamps

### Example 0 - dump everything just to have an idea of the fields and other filters you can make

The below query dumps all the IIS file intormation (note the wildcard * on the SELECT clause), including the time stamps (TO_TIMESTAMP(date,time)) converted to local time (TO_LOCALTIME()) as the default IIS time is the Universal Time Coordinated (UTC).
I also filter some user names I don't want (cs-username NOT LIKE '') and filtering out the blank cs-username.

**Log Type** : ```W3CLOG```

```sql
SELECT 
    TO_LOCALTIME(TO_TIMESTAMP(date, time)) AS LocalTime,
    *
FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log','\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
WHERE LocalTime BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/28/2023 23:59:59','MM/dd/yyyy hh:mm:ss') AND cs-username NOT LIKE '%HealthMailbox%' AND cs-username IS NOT NULL
ORDER BY LocalTime
```

And then you want to filter the cs(User-Agent) which is the application used (like Outlook v15.0 for Outlook 2013), you would add on the WHERE clause:

```sql
cs(User-Agent) LIKE '%Outlook%' AND cs(User-Agent) LIKE '%15.0%'
```

the full WHERE clause would look like:

```sql
WHERE LocalTime BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/28/2023 23:59:59','MM/dd/yyyy hh:mm:ss') AND cs-username NOT LIKE '%HealthMailbox%' AND cs-username IS NOT NULL AND cs(User-Agent) LIKE '%Outlook%' AND cs(User-Agent) LIKE '%15.0%'
```

### Example 1 - show URL total hits quantized to every quarter, for Autodiscover, excluding Health Mailboxes, between 2 date/times

Use the ```sql TimeVariable BETWEEN TimeStamp('01/23/2022 06:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/23/2022 20:00:00','MM/dd/yyyy hh:mm:ss')```  synthax after the ```sql WHERE ``` clause.

> NOTE1: you can use ```sql TO_LOCALTIME(SYSTEM_TIMESTAMP()) ``` if you want to query between a time in the past and the current time ... 
> NOTE2: you can also substract a few minutes in case the latest data don't fill a quantized hour at the time of the run for example using the ```sql SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()),TIMESTAMP('20','mm')) ``` sequence. use '20','mm' to remove 20 minutes, or '01','hh' to substract 1 hour, ...

```sql
SELECT QUANTIZE(TO_TIMESTAMP(date, time), 900) AS QuarterHour,
       /*cs-username as UserName,*/
       cs-uri-stem as TargetURL,
       /*cs(User-Agent) as ClientApp,*/
	COUNT(*) AS Total
FROM '\\E2016-01\C$\Users\samdrey.CANADADREY\Downloads\IISLogs\IISLogs\*.log', '\\E2016-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
WHERE TargetURL like '%/autodiscover/autodiscover%' AND cs-username NOT LIKE '%HealthMailbox%' AND QuarterHour BETWEEN TimeStamp('10/17/2022 07:00:00','MM/dd/yyyy hh:mm:ss') and TimeStamp('10/17/2022 20:00:00','MM/dd/yyyy hh:mm:ss') 
/*
If you want to express time stamp corresponding to current time MINUS 20 minutes:
SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()),TIMESTAMP('20','mm'))
*/ 
GROUP BY QuarterHour, TargetURL
ORDER BY QuarterHour
```

### Example 2 - show entries for RPC URL (RPC over HTTP) with user names, between 2 date/times on 2 remote IIS log folders

```sql
SELECT TO_LOCALTIME(TO_TIMESTAMP(date, time)) AS Minute,
       cs-uri-stem,
       cs-username,
	COUNT(*) AS Total 
FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log','\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
WHERE Minute BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/28/2023 23:59:59','MM/dd/yyyy hh:mm:ss') AND cs-username NOT LIKE '%HealthMailbox%' AND cs-username IS NOT NULL AND cs-uri-stem LIKE '%rpc%'
GROUP BY Minute,cs-uri-stem, cs-username
ORDER BY Minute
```

<img width="235" alt="image" src="https://user-images.githubusercontent.com/33433229/215248868-83de7231-01ae-486e-88bf-67b191d5e9ee.png">

### Example 3 - show IIS files lines between to dates, with only the time stamp, User name, target URL, client application and HTTP status

```sql
SELECT TO_LOCALTIME(TO_TIMESTAMP(date, time)) AS DateTime,
       cs-username as UserName,
       cs-uri-stem as TargetURL,
       cs(User-Agent) as ClientApp,
       sc-status as HTTPStatus
FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log', '\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
/*WHERE TargetURL like '%/autodiscover/autodiscover%' AND cs-username NOT LIKE '%HealthMailbox%' AND DateTime BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/28/2023 23:59:59','MM/dd/yyyy hh:mm:ss') */
WHERE DateTime BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/28/2023 23:59:59','MM/dd/yyyy hh:mm:ss') AND cs-username NOT LIKE '%HealthMailbox%' AND cs-username IS NOT NULL AND cs(User-Agent) LIKE '%Outlook%' AND cs(User-Agent) LIKE '%15.0%'

/*
HINT:
If you want to express time stamp corresponding to current time MINUS 20 minutes:
SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()),TIMESTAMP('20','mm'))
For example between a set date in the past, and current date/time minus 20 minutes
*/ 

ORDER BY DateTime
```

Here's an extract for my lab servers (I only have 1 active user so you'll see always the same for me:

<img width="461" alt="image" src="https://user-images.githubusercontent.com/33433229/215290687-d743fc82-bf35-4f1d-8707-a3def98abc0d.png">

#### Example 4 - using COUNT(*) as HitCount

NOTE: When you use COUNT(*) on the SELECT clause to count the number of Hits, you must use GROUP BY before ORDER BY, followed by all the headers you have in SELECT (except the COUNT() header of course)

NOTE2: You can also uses QUANTIZE( Time stamp, seconds ) along with COUNT() to group the number of hits in a time interval like 5, 15, or 60 minutes:

```sql
SELECT QUANTIZE(TO_TIMESTAMP(date, time), 900) AS QuarterHour,
       cs-username as UserName,
       cs-uri-stem as TargetURL,
       cs(User-Agent) as ClientApp,
	COUNT(*) AS Total

FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log', '\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
WHERE TargetURL like '%/autodiscover/autodiscover%' AND cs-username NOT LIKE '%HealthMailbox%' AND QuarterHour BETWEEN TimeStamp('01/28/2023 20:00:00','MM/dd/yyyy hh:mm:ss') AND TO_LOCALTIME(SYSTEM_TIMESTAMP())

GROUP BY QuarterHour,UserName, TargetURL, ClientApp
ORDER BY QuarterHour

```

> NOTE : here I aadded the QUANTIZE( time stamp , seconds ), and COUNT(*) as Total and then added GROUP BY with all SELECT fields.

> NOTE 2 : I also used a WHERE filter to filter the search/results between a time in the past, and the system time.


### Other examples wich are variants from the above examples...

```sql
/*
Display Autodiscover hits and UserName, URL stem, HTTP query, Client App, HTTP status, and hits in case there are many at the same date, time and second...
*/

SELECT TO_LOCALTIME(TO_TIMESTAMP(date, time)) AS DateTime,
       cs-username as UserName,
       cs-uri-stem as TargetURL,
       cs-uri-query as HTTPQuery,
       cs(User-Agent) as ClientApp,
       sc-status as HTTPStatus,
       COUNT(*) as Hits
FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log', '\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
/*WHERE TargetURL like '%/autodiscover/autodiscover%' AND cs-username NOT LIKE '%HealthMailbox%' AND DateTime BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/28/2023 23:59:59','MM/dd/yyyy hh:mm:ss') */
WHERE DateTime BETWEEN TimeStamp('01/28/2023 20:00:00','MM/dd/yyyy hh:mm:ss') AND TO_LOCALTIME(SYSTEM_TIMESTAMP()) AND cs-username NOT LIKE '%HealthMailbox%' AND cs-username IS NOT NULL

/*
If you want to express time stamp corresponding to current time MINUS 20 minutes:
SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()),TIMESTAMP('20','mm'))
*/ 

GROUP BY DateTime, UserName, TargetURL, HttpQuery, ClientApp, HTTPStatus
ORDER BY DateTime DESC
```

```sql
/*
Dumps Time, UserName, URL stem, Client app, and HTTP status between a date in the past, and current date for Autodiscover entries in IIS log.
*/

SELECT TO_TIMESTAMP(date, time) AS LocalTime,
       cs-username as UserName,
       cs-uri-stem as TargetURL,
       sc-status as HTTPStatus,
       cs(User-Agent) as ClientApp
FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log', '\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
WHERE TargetURL like '%/autodiscover/autodiscover%' AND cs-username NOT LIKE '%HealthMailbox%' AND LocalTime BETWEEN TimeStamp('01/28/2023 20:00:00','MM/dd/yyyy hh:mm:ss') AND SYSTEM_TIMESTAMP()

/*
If you want to express time stamp corresponding to current time MINUS 20 minutes:
SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()),TIMESTAMP('20','mm'))
*/ 

ORDER BY LocalTime

```

And also below an example to show entries between a time in the past and the current time for all URL stems if you want to monitor until current activity for example:

```sql
/*
Display all IIS hits with UserName, URL stem, HTTP query, Client App, HTTP status,...
*/

SELECT TO_LOCALTIME(TO_TIMESTAMP(date, time)) AS LocalTime,
       cs-username as UserName,
       cs-uri-stem as TargetURL,
       cs-uri-query as HTTPQuery,
       cs(User-Agent) as ClientApp,
       sc-status as HTTPStatus
FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log', '\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
/*WHERE TargetURL like '%/autodiscover/autodiscover%' AND cs-username NOT LIKE '%HealthMailbox%' AND LocalTime BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND TimeStamp('01/28/2023 23:59:59','MM/dd/yyyy hh:mm:ss') */
WHERE LocalTime BETWEEN TimeStamp('01/28/2023 16:00:00','MM/dd/yyyy hh:mm:ss') AND SYSTEM_TIMESTAMP() AND TargetURL LIKE '%/autodiscover/autodiscover%'

/*
If you want to express time stamp corresponding to current time MINUS 20 minutes:
SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()),TIMESTAMP('20','mm'))
*/ 

ORDER BY LocalTime DESC
```

Show grouped stats about User names, target URL, Client Application used, HTTP status and number of hits ...

```sql
/*
Show which user names target which URL stem with which Client App, and what's the HTTP status. Counts number of these by User Name, URL stem, client App and HTTP Status between 2 dates
*/

SELECT cs-username as UserName,
       cs-uri-stem as TargetURL,
       cs(User-Agent) as ClientApp,
       sc-status as HTTPStatus,
       COUNT(*) as NumberOfHits
FROM '\\E2019-01\C$\inetpub\logs\LogFiles\W3SVC1\*.log', '\\E2019-02\C$\inetpub\logs\LogFiles\W3SVC1\*.log'
WHERE TO_LOCALTIME(TO_TIMESTAMP(date, time)) BETWEEN TimeStamp('01/28/2023 00:00:00','MM/dd/yyyy hh:mm:ss') AND SYSTEM_TIMESTAMP() AND ClientApp LIKE '%Outlook%' AND ClientApp LIKE '%15.0%' AND UserName IS NOT NULL

/*
If you want to express time stamp corresponding to current time MINUS 20 minutes:
SUB(TO_LOCALTIME(SYSTEM_TIMESTAMP()),TIMESTAMP('20','mm'))
*/ 

GROUP BY UserName, TargetURL, ClientApp, HTTPStatus
```

Hope this helps on your LogParser queries !
