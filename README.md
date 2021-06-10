# Some-Logparser-Queries
Some Logparser Queries to help my peers

```sql
"/* Pull all requests*/
/* If an error is returned there may be no matces */
/*#Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status time-taken*/

SELECT TO_LOCALTIME(TO_TIMESTAMP(date, time)) as TimeStamp,
   cs-username,
   cs-uri-stem,
   sc-status,
   time-taken
FROM '[LOGFILEPATH]'
WHERE cs-uri-stem LIKE '/EWS/mrsproxy.svc%'
ORDER BY TimeStamp"
![image](https://user-images.githubusercontent.com/33433229/121607554-3ca1d300-ca1e-11eb-9f42-e65987f8f861.png)

``` 
