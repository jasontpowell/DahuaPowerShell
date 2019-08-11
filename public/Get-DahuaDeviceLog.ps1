function Get-DahuaDeviceLog {

    param(

        [DateTime]
        $StartTime,

        [DateTime]
        $EndTime,
        
        # The IP address or hostname for the device to query
        [String]
        $BaseUri,

        [PSCredential]
        $DahuaCredentials
    )

    $Path = "/cgi-bin/log.cgi"
    
    $LogEntries = New-Object System.Collections.ArrayList
    
    if ($null -eq $StartTime -and $null -eq $EndTime) {
        $StartTime = (Get-Date).AddDays(-1)
        $EndTime = Get-Date
    }

    $QueryParameters = [ordered]@{
        'action'                = "startFind"
        'condition.StartTime'   = ($StartTime).GetDateTimeFormats()[94]
        'condition.EndTime'     = ($EndTime).GetDateTimeFormats()[94]
    }

    # Doing this to prevent colon characters from being URL encoded (:)
    $QueryString =  ( $QueryParameters.GetEnumerator() |
        ForEach-Object {
            "$($_.name)=$($_.value)" -replace " ","%20"
        } ) -join "&"

    $RequestAPIArgs = @{
        Uri                             = $BaseUri+$Path+"?"+$QueryString
        Credential                      = $DahuaCredentials
        AllowUnencryptedAuthentication  = $true
    }

    $Response = Invoke-WebRequest @RequestAPIArgs
    $Token = [regex]::Matches($Response.Content,'\d+').Value

    $EventSequence = 1
    $Loop = $true
    while ($Loop -eq $true) {
        $IncomingLogEntries = @{}

        $QueryParameters = [ordered]@{
            action  = "doFind"
            token   = $Token
            count   = 100
        }

        $RequestAPIArgs.Uri = $BaseUri+$Path
        $RequestAPIArgs.Body = $QueryParameters
        $Response = Invoke-WebRequest @RequestAPIArgs

        [Int32]$Found = [regex]::Matches($Response.Content,'(?<=found=)\d*').Value

        $Response.Content -split "\r\n" | ForEach-Object {
                $RecordKey = ($_ -split '=')[0]
                $IncomingLogEntries[$RecordKey] = ($_ -split '=')[1]
            }

        for ($i = 0; $i -lt $Found; $i++) {
            $LogEntry = [PSCustomObject]@{
                'Device'        = $BaseUri
                'Time'          = $IncomingLogEntries["items[$i].Time"] -as [DateTime]
                'Type'          = $IncomingLogEntries["items[$i].Type"]
                'User'          = $IncomingLogEntries["items[$i].User"]
                'Channel'       = $IncomingLogEntries["items[$i].Detail.Channel NO."]
                'Event Type'    = $IncomingLogEntries["items[$i].Detail.Event Type"]
                'Address'       = $IncomingLogEntries["items[$i].Detail.Address"]
                'Event ID'      = $EventSequence
            }

            $LogEntries.Add($LogEntry) > $null

            $EventSequence++
        }

        if ($Found -eq 100) {
            $Loop = $true
        }
        else {
            $Loop = $false
        }
    }
    
    Write-Output $LogEntries
}
