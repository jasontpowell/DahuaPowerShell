function Build-DahuaDownloadURL {
    param(
        # Objects returned by Get-DahuaIVSEvents 
        $Event,

        # 0 = higher quality
        # 1 = lower quality
        $SubType = 0,

        [String]
        $BaseUri = "192.168.1.100"
    )

    switch ($Event.BaseUri) {
        "192.168.1.101" { $Channel = 1 }
        "192.168.1.102" { $Channel = 2 }
    }
    
    $Path = "/cgi-bin/loadfile.cgi"

    $StartTime = ($Event.StartTime).GetDateTimeFormats()[94]
    $EndTime = ($Event.EndTime).GetDateTimeFormats()[94]

    $QueryParameters = [ordered]@{
        action      = "startLoad"
        channel     = $Channel
        subtype     = $SubType
        startTime   = $StartTime
        endTime     = $EndTime
    }

    # Doing this to prevent colon characters from being URL encoded (:)
    $QueryString =  ( $QueryParameters.GetEnumerator() |
        ForEach-Object {
            "$($_.name)=$($_.value)" -replace " ","%20"
        } ) -join "&"

    $DownloadURL = $BaseUri+$Path+"?"+$QueryString

    Write-Output $DownloadURL
}
