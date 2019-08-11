function Show-DahuaVideo {
    param(
        [ValidateSet("Front",
                     "Back")]
        [String]    
        $Camera,

        [DateTime]
        $StartTime,

        [DateTime]
        $EndTime
    )

    $VideoPeriod = [PSCustomObject]@{
        'Camera'        = $Camera
        'Time - Start'  = "$((Get-Date($StartTime)).GetDateTimeFormats()[94])"
        'Time - End'    = "$((Get-Date($EndTime)).GetDateTimeFormats()[94])"
    }

    $PlaybackUrls = @(Build-DahuaPlaybackURLs $VideoPeriod)

    Start-VLC -URLs $PlaybackUrls -DahuaCredentials $DahuaCredentials
}
