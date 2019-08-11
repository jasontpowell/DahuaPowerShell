function Get-DahuaIVSEvents {
    param(
        # The IP address or hostname for the device to query
        [String]
        $BaseUri,

        [String]
        $DeviceName,

        [DateTime]
        $StartTime = (Get-Date -Hour "20" -Minute "00" -Second "00").AddDays(-1),

        [DateTime]
        $EndTime =  ($StartTime.AddHours(10)),

        [Int16]
        $BufferSeconds = 3,

        # Seconds
        [Int16]
        $MergeDistance = 10,

        [PSCredential]
        $DahuaCredentials
    )

    $Events = New-Object System.Collections.ArrayList

    if ($DeviceName -eq "") {
        switch ($BaseUri) {
            "192.168.1.102" { $DeviceName = "Back" }
            "192.168.1.101" { $DeviceName = "Front" }
        }
    }
   

    $DeviceLogArgs = @{
        BaseUri             = $BaseUri
        StartTime           = $StartTime
        EndTime             = $EndTime
        DahuaCredentials    = $DahuaCredentials
    }

    $LogEntries = Get-DahuaDeviceLog @DeviceLogArgs | Where-Object {
            $_."Event Type" -eq "Tripwire"
        } |
        Sort-Object -Property Time -Unique | 
        Select-Object -Property Time,Type


    $i = 0
    while ( $i -lt $LogEntries.count ) {
        if ( $LogEntries[$i].Type -eq "Event Begin" ) {
            $EventStart = ($LogEntries[$i].Time).AddSeconds(-$BufferSeconds)
        }
        else {
            $i++
            Continue
        }

        $j = $i++
        
        while ( $LogEntries[$j].Type -ne "Event End" ) {
            $j++
        }

        $EventEnd = ($LogEntries[$j].Time).AddSeconds($BufferSeconds)

        $Duration = ($EventEnd - $EventStart).TotalSeconds

        $Event = [pscustomobject]@{
            DeviceName  = $DeviceName
            BaseUri     = $BaseUri
            StartTime   = $EventStart
            EndTime     = $EventEnd
            Duration    = $Duration
        }

        $i = $j++
        
        $Events.Add($Event) > $null
    }


    if ($MergeDistance -gt 0) {
        $Events = Merge-DahuaEvents -Events $Events -MergDistance $MergeDistance
    }


    $Events | ForEach-Object {

        $StreamUrl = Build-DahuaStreamURL -Event $_
        $StreamUrlArgs = @{
            NotePropertyName    = "StreamUrl"
            NotePropertyValue   = $StreamUrl
        }
        $_ | Add-Member @StreamUrlArgs

<#         $StreamUrl = Build-DahuaStreamURL -Event $_ -EndPoint "Playback By Http"
        $StreamUrlArgs = @{
            NotePropertyName    = "PlaybackByHttpUrl"
            NotePropertyValue   = $StreamUrl
        }
        $_ | Add-Member @StreamUrlArgs #>
        
        $DownloadUrl = Build-DahuaDownloadURL -Event $_
        $DownloadUrlArgs = @{
            NotePropertyName    = "DownloadUrl"
            NotePropertyValue   = $DownloadUrl
        }
        $_ | Add-Member @DownloadUrlArgs
    }

        Write-Output $Events
}
