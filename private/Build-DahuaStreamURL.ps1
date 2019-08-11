function Build-DahuaStreamURL {
    param(
        # Objects returned by Get-DahuaIVSEvents 
        $Event,

        [ValidateSet("GetStream",
                     "GetVideo",
                     "Playback",
                     "Download",
                     "PlayBack By Filename",
                     "LoadFile By Filename",
                     "GetStream By Http",
                     "Playback By Http")]
        [String]
        $EndPoint = "Playback",

        [String]
        $NvrIP = "192.168.1.100"
    )

    switch ($Event.BaseUri) {
        "192.168.1.101" { $Channel = 1 }
        "192.168.1.102" { $Channel = 2 }
    }

    switch ($EndPoint) {
        Playback {
            $Protocol = "rtsp"
            $HostName = $NvrIP
            $Path = "/cam/playback"

            $QueryParameters = [ordered]@{
                channel     = $Channel
                starttime   = ($Event.StartTime).GetDateTimeFormats()[94] -replace "[^0-9]","_"
                endtime     = ($Event.EndTime).GetDateTimeFormats()[94] -replace "[^0-9]","_"
            }

            # Doing this to prevent colon characters from being URL encoded (:)
            $QueryString =  ( $QueryParameters.GetEnumerator() |
                ForEach-Object {
                    "$($_.name)=$($_.value)"
                } ) -join "&"
            
          }

          "Playback By Http" {
            $Protocol = "http"
            $HostName = $NvrIP
            $Path = "/cgi-bin/playBack.cgi"

            $QueryParameters = [ordered]@{
                action      = "getStream"
                channel     = $Channel
                subtype     = 0
                startTime   = ($Event.StartTime).GetDateTimeFormats()[94] -replace "[^0-9]","_"
                endTime     = ($Event.EndTime).GetDateTimeFormats()[94] -replace "[^0-9]","_"
            }

            # Doing this to prevent colon characters from being URL encoded (:)
            $QueryString =  ( $QueryParameters.GetEnumerator() |
                ForEach-Object {
                    "$($_.name)=$($_.value)"
                } ) -join "&"
          }

        Default {}
    }
    
    $Url = $Protocol + "://" + $HostName + $Path + "?" + $QueryString
    # $StreamURL = "rtsp://$NvrIP/cam/playback?channel=$Channel&starttime=$StartTime&endtime=$EndTime"

    Write-Output $Url
}
