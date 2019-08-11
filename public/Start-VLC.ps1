function Start-VLC {
    param(

        $Inputs,

        [ValidateSet("22:15",
                     "16:9")]
        [String]
        $AspectRatio = "16:9",

        [Float]
        $Zoom = .48,

        [Int16]
        $HorizontalCoordinate = 480,

        [Int16]
        $VerticalCoordinate = 330,

        [Switch]
        $Stop,

        [String]
        $SnapshotPath,

        [PSCredential]
        $DahuaCredentials,

        [Switch]
        $Snapshot
    )

    $VlcArgs = @()
    $ArgCollections = @()

    if ($Stop) {
        Get-Process -Name "*vlc*" | ForEach-Object {
            Stop-Process $_
        }
    }

    $RtspCredentials = @{
        '--rtsp-user'   = "$($DahuaCredentials.UserName)"
        '--rtsp-pwd'    = "$($DahuaCredentials.GetNetworkCredential().Password)"
    }
    $ArgCollections += $RtspCredentials

    if ($Snapshot) {
        $SnapshotArgs = @{
            '--vout'            = "dummy"
            '--video-filter'    = "scene"
            '--scene-format'    = "png"
            '--scene-ratio'     = "130"
            '--scene-path'      = "$($SnapshotPath)"
            '--scene-prefix'    = $($Inputs.DeviceName + " " + $Inputs.StartTime.GetDateTimeFormats()[5])
        }
        $ArgCollections += $SnapshotArgs

    } else {
        $GuiArgs = @{
            '--rtsp-timeout'            = '-1'
            '--rtsp-frame-buffer-size'  = '500000'
            '--prefetch-buffer-size'    = '1048576'
            '--prefetch-read-size'      = '1048576'
            '--qt-notification'         = '0'
            '--qt-minimal-view'         = $true
            '--qt-start-minimized'      = $true
            '--no-qt-system-tray'       = $true
            '--aspect-ratio'            = $AspectRatio
            '--zoom'                    = $Zoom
            '--video-x'                 = $HorizontalCoordinate
            '--video-y'                 = $VerticalCoordinate
            '--play-and-exit'           = $true
            '--no-video-deco'           = $true
            '--no-embedded-video'       = $true
            '--no-sout-audio'           = $true
            '--video-title-position'    = '4'
        }
        $ArgCollections += $GuiArgs
    }

    $ArgCollections | ForEach-Object {
        $_.GetEnumerator() | ForEach-Object {
            if ($_.value -eq $true) {
                $Argument = "$($_.name)"
            } else {
                $Argument = "$($_.name)=""$($_.value)"""
            }

            $VlcArgs += $Argument
        }
    }

    #Write-Output $VlcArgs

    if ($Snapshot -eq $false) {
        $i = 1
        $Inputs | ForEach-Object{
    
            $Day = $_.StartTime.DayOfWeek
            $Time = $_.StartTime.ToShortTimeString()
            $Duration = $_.Duration
            $Position = "$i of $($Inputs.Count)"
            $Title = "$Day $Time ($($Duration)s)`n$Position"
    
            $VlcArgs += """$($_.StreamUrl)"""
            $VlcArgs += ":meta-title=""$($Title)"""
    
            $i++
        }
    } elseif ($Snapshot) {
        $VlcArgs += """$($Inputs.StreamUrl)"""
        $VlcArgs += "vlc://quit"
    }

    & "C:\Program Files\VideoLAN\VLC\vlc.exe" $VlcArgs
}
