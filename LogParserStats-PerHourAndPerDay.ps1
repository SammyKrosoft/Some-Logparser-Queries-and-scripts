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
    & "C:\Program Files (x86)\Log Parser 2.2\logparser.exe" "SELECT TO_LOCALTIME(QUANTIZE(TO_TIMESTAMP(TO_STRING(EXTRACT_PREFIX([#Fields: date-time],0,'.')), 'yyyy-MM-ddThh:mm:ss'),3600)) AS Hour,	COUNT(*) AS Messages FROM '\\$Server\$TrackingLogPaths\*.log' WHERE event-id='RECEIVE' GROUP BY Hour ORDER BY Hour ASC" -i:CSV -nSkipLines:4 -rtp:-1
}

