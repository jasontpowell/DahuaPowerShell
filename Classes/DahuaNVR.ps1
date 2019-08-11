class DahuaNVR {

    # Properties
    [String]
    $Uri

    [PSCredential]
    $Credentials

    [PSObject[]]
    $Log

    [PSObject[]]
    $Channels


    # Methods
    [void] GetLog () {

        $CurrentDate = Get-Date

        $GetDeviceLogArgs = @{
            StartTime           = $CurrentDate.AddDays(-30)
            EndTime             = $CurrentDate
            BaseUri             = $this.Uri
            DahuaCredentials    = $this.Credentials
        }

        $this.Log = Get-DahuaDeviceLog @GetDeviceLogArgs
    }

    [void] GetChannels () {

        $this.Channels = $null

        $RequestUriArgs = @{
            Uri                             = $this.Uri+"/cgi-bin/configManager.cgi?action=getConfig&name=ChannelTitle"
            Credential                      = $this.Credentials
            AllowUnencryptedAuthentication  = $true
        }

        $Response = (Invoke-WebRequest @RequestUriArgs).Content -split "\r\n" 
        
        $Response | ForEach-Object {
            [Int32]$ChannelNumber = ($_ -split 'table.ChannelTitle\[' -split '\]\[' -split '\]')[1]
            $ChannelName = ($_ -split 'table.ChannelTitle\[' -split '\]\[' -split '\]' -split '.Name=')[3]

            if ($ChannelName -notlike "CAM *" -and $null -ne $ChannelName) {
                $Channel = [PSCustomObject]@{
                    Name    = $ChannelName
                    Number  = $($ChannelNumber + 1)
                }
    
                $this.Channels += $Channel
            }
        }
    }

    [String] BuildEventStreamUrl ($Channel, $StartTime, $EndTime) {
        $Protocol = "rtsp"
        $Path = "/cam/playback"

        $QueryParameters = [ordered]@{
            channel     = $Channel
            starttime   = ($StartTime).GetDateTimeFormats()[94] -replace "[^0-9]","_"
            endtime     = ($EndTime).GetDateTimeFormats()[94] -replace "[^0-9]","_"
        }

        # Doing this to prevent colon characters from being URL encoded (:)
        $QueryString =  ( $QueryParameters.GetEnumerator() |
            ForEach-Object {
                "$($_.name)=$($_.value)"
            } ) -join "&"

        $Url = $Protocol + "://" + $this.Uri + $Path + "?" + $QueryString

        return $Url
    }
   
    [void] ExportNVR () {
        $Path = "$env:LOCALAPPDATA\DahuaPowerShell"

        if ( (Test-Path $Path) -eq $false) {
            New-Item $Path -ItemType Directory | Out-Null
        }

        $FileName = "Dahua_NVR.xml"
        $FullPath = Join-Path -Path $Path -ChildPath $FileName

        $ProfileTable = @{}
        if ($this.Uri) {
            $ProfileTable["Uri"] = $this.Uri
        }
        if ($this.Credentials) {
            $ProfileTable["Credentials"] = $this.Credentials
        }
        if ($this.Log) {
            $ProfileTable["Log"] = $this.Log
        }

        $Profile = [PSCustomObject]$ProfileTable
        $Profile | Export-Clixml -Path $FullPath
    }

    # Constructors
    DahuaNVR () {}

    DahuaNVR ([String]$ConfigPath) {
        if (Test-Path $ConfigPath) {
            $Profile = Import-Clixml -Path $ConfigPath -ErrorAction Stop

            if ($Profile.Credentials) {
                $this.Credentials = $Profile.Credentials
            }
            if ($Profile.Uri) {
                $this.Uri = $Profile.Uri
            }
            if ($Profile.Log) {
                $this.Log = $Profile.Log
            }
        }
    }

}
