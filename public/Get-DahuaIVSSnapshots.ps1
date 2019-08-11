function Get-DahuaIVSSnapshots {
    param(

        [DateTime]
        $StartTime = (Get-Date -Hour "20" -Minute "00" -Second "00").AddDays(-1),

        [DateTime]
        $EndTime =  ($StartTime.AddHours(10)),
        
        [Switch]
        $LastNight,
        
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

    $Events | ForEach-Object {
        Start-VLC -Inputs $_ -DahuaCredentials $DahuaCredentials -Snapshot
    }
}
