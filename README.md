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

An example on an Exchange Tracking log (specific to Exchange Tracking Logs, we need to EXTRACT the "#Fields: date-time" string from the tracking log before calling TO_TIMESTAMP():
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

