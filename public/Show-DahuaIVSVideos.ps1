function Show-DahuaIVSVideos {
    param(

        [DateTime]
        $StartTime = (Get-Date -Hour "21" -Minute "00" -Second "00").AddDays(-1),

        [DateTime]
        $EndTime =  ($StartTime.AddHours(9)),
        
        # The IP address or hostname for the device to query
        [String]
        $BaseUri,

        [PSCredential]
        $DahuaCredentials
    )

    $GetDahuaIvsEventsArgs = @{
        BaseUri             = $BaseUri
        StartTime           = $StartTime
        EndTime             = $EndTime
        DahuaCredentials    = $DahuaCredentials
    }

    $Events = Get-DahuaIvsEvents @GetDahuaIvsEventsArgs

    Start-VLC -Inputs $Events -DahuaCredentials $DahuaCredentials
}
