# ------------------------------------------------------------
# Customize the following variables:
# ------------------------------------------------------------
# Replace $Servers with your servers
$Servers = "E2016-01", "E2016-02"

# Replace the root where Exchange is installed (Can be E:\)
$TrackingLogPaths = "C:\Program Files\Microsoft\Exchange Server\v15\TransportRoles\Logs\MessageTracking\"
# ------------------------------------------------------------
# End of variables customization
# ------------------------------------------------------------


# Changing path to colon-backslash with UNC root like C$\ or E$\ ...
$TrackingLogPaths = $TrackingLogPaths -replace ":\\","$\"
if ($TrackingLogPaths -match "\\$"){
    write-host "File path with trailing backslash \ detected ... removing for the remainder of the script"
    $TrackingLogPaths = $TrackingLogPaths -replace "\\$",""
}


# iterate for each server in the list, execute Logparser
Foreach ($Server in $Servers) {
    Write-host "Processing Server $Server" -ForegroundColor Blue -BackgroundColor Yellow
    & "C:\Program Files (x86)\Log Parser 2.2\logparser.exe" "SELECT TO_LOCALTIME(TO_TIMESTAMP(EXTRACT_PREFIX(TO_STRING([#Fields: date-time]),0,'T'), 'yyyy-MM-dd')) AS Date, COUNT(*) AS Hits from '\\$Server\$TrackingLogPaths\*.log' where (event-id='RECEIVE') GROUP BY Date ORDER BY Date ASC" -i:CSV -nSkipLines:4 -rtp:-1
}
