# Some-Logparser-Queries
Some Logparser Queries to help my peers

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

