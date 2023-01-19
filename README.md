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
