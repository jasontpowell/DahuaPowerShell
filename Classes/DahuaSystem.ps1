class DahuaSystem {

    # Properties
    [DahuaCamera[]]
    $Cameras

    [DahuaNVR]
    $NVR

    [PSObject[]]
    $IvsEvents

    # Methods
    [void] ImportDevices () {
   
        $this.NVR = [DahuaNVR]::new($($env:LOCALAPPDATA+"\DahuaPowerShell\Dahua_NVR.xml"))

        $Profiles = @( Get-ChildItem -r -Path $env:LOCALAPPDATA\DahuaPowerShell\DahuaCamera_*.xml -ErrorAction SilentlyContinue )

        $Profiles | ForEach-Object {
            $this.Cameras += [DahuaCamera]::new($_)
        }
    }

    [void] PlayIvsEvents ([DateTime]$StartTime, [DateTime]$EndTime) {
        $FilteredIvsEvents = $this.IvsEvents | Where-Object {
            $_.StartTime -ge $StartTime -and
            $_.EndTime -le $EndTime
        }
        Start-VLC -Inputs $FilteredIvsEvents -DahuaCredentials $this.NVR.Credentials
    }

    [void] PlayIvsEvents () {

        [DateTime]$StartTime = (Get-Date -Hour "21" -Minute "00" -Second "00").AddDays(-1)
        [DateTime]$EndTime = ($StartTime.AddHours(9))

        $FilteredIvsEvents = $this.IvsEvents | Where-Object {
            $_.StartTime -ge $StartTime -and
            $_.EndTime -le $EndTime
        }
        Start-VLC -Inputs $FilteredIvsEvents -DahuaCredentials $this.NVR.Credentials
}

    [void] BuildIvsEvents () {
        $this.NVR.GetChannels()

        $this.Cameras | ForEach-Object {
            $Name = $_.Name
            $Channel = $this.NVR.Channels |
                Where-Object {
                    $_.Name -eq $Name
                } |
                Select-Object -ExpandProperty 'Number'

            $_.GetIvsEventLog()

            $_.IvsEventLog | ForEach-Object {
                $StreamUrl = $this.NVR.BuildEventStreamUrl($Channel, $_.StartTime, $_.EndTime)

                $Duration = ($_.EndTime - $_.StartTime).TotalSeconds

                $IvsEvent = [PSCustomObject]@{
                    DeviceName  = $Name
                    StartTime   = $_.StartTime
                    EndTime     = $_.EndTime
                    Duration    = $Duration
                    StreamUrl   = $StreamUrl
                }

                $this.IvsEvents += $IvsEvent
            }
        }
    }

    [void] EnableIvsLogging () {
        $this.Cameras | ForEach-Object {
            $_.EnableIvsLogging()
        }
    }

    [void] EnableIvsRecording() {
        $this.Cameras | ForEach-Object {
            $_.EnableIvsRecording()
        }
    }

    [void] GetEncoding () {
        $this.Cameras | ForEach-Object {
            $_.GetEncoding()
        }
    }

    [void] ExportDevices () {
        $this.Cameras | ForEach-Object {
            $_.ExportCamera()
        }

        $this.NVR.ExportNVR()
    }

    # Constructors
    DahuaSystem () {}
}
