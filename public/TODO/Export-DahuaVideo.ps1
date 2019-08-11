function Export-DahuaVideo {
    param(
        [DateTime]
        $StartTime,

        [DateTime]
        $EndTime,

        $Camera,

        [Int16]
        $SubType = 0,

        [String]
        $NvrIP,

        [String]
        $OutPath = "$env:USERPROFILE\Desktop",

        [PSCredential]
        $DahuaCredentials
    )

    $WebClient = New-Object System.Net.WebClient
    $WebClient.Credentials = $DahuaCredentials
    $WebClient.BaseAddress = $NvrIP

    [String]$StartTime = ($StartTime).GetDateTimeFormats()[94]
    [String]$EndTime = ($EndTime).GetDateTimeFormats()[94]

    $OutFile = "$($StartTime  -replace "[^0-9]","-")-$($EndTime  -replace "[^0-9]","-")-video.dav"

    switch ($Camera) {
        "Front" { $Channel = 2 }
        "Back" { $Channel = 1 }
    }

    $QueryParams = @{
        action      = "startLoad"
        channel     = $Channel
        subtype     = $SubType
        startTime   = $StartTime
        endTime     = $EndTime
    }
    
    $WebClient.QueryString = $QueryParams

    $Path = "/cgi-bin/loadfile.cgi"

    $WebClient.DownloadFile($Path,"$OutPath\$OutFile")
}
