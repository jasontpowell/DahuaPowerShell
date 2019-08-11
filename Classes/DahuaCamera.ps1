class DahuaCamera {

    # Properties
    [String]
    $Name

    [String]
    $Uri

    [PSCredential]
    $Credentials

    [PSObject[]]
    $Log

    [PSObject[]]
    $Encoding

    [PSObject[]]
    $IvsRules

    [PSObject[]]
    $IvsEventLog

    # Seconds
    [Int16]
    $EventBuffer


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

    [void] GetIvsEventLog () {
        if ($null -eq $this.Log) {
            $this.GetLog()
        }

        if ($null -eq $this.EventBuffer) {
            $this.EventBuffer = 3
        } 

        $LogEntries = $this.Log | Where-Object {
                $_."Event Type" -eq "Tripwire"
            } |
            Sort-Object -Property 'Event ID' -Descending | 
            Select-Object -Property Time,Type

        $i = 0
        while ( $i -lt $LogEntries.count ) {
            if ( $LogEntries[$i].Type -eq "Event Begin" ) {
                $EventStart = ($LogEntries[$i].Time).AddSeconds(-$this.EventBuffer)
            }
            else {
                $i++
                Continue
            }
    
            $j = $i++
            
            while ( $LogEntries[$j].Type -ne "Event End" ) {
                $j++
            }
    
            $EventEnd = ($LogEntries[$j].Time).AddSeconds($this.EventBuffer)
    
            $Event = [pscustomobject]@{
                StartTime   = $EventStart
                EndTime     = $EventEnd
            }
    
            $i = $j++
            
            $this.IvsEventLog += $Event
        }
        
        $this.MergeIvsEvents(10)
    }

    [void] MergeIvsEvents ([Int16]$EventMergeDistance) {

        if ($null -ne $this.IvsEventLog) {
            $NewEvents = New-Object System.Collections.ArrayList

            for ($i = 0; $i -lt $this.IvsEventLog.Count; $i++) {
        
                    if ($i -lt $this.IvsEventLog.Count -1) {
                    $NextEvent = ([DateTime]$this.IvsEventLog[$i+1].StartTime - [DateTime]$this.IvsEventLog[$i].EndTime).TotalSeconds
                }
                else {
                    $NextEvent = 0
                }
        
                $AddMemberArgs = @{
                    NotePropertyName    = "NextEvent"
                    NotePropertyValue   = $NextEvent
                }
        
                $this.IvsEventLog[$i] | Add-Member @AddMemberArgs
            }
        
            for ($i = 0; $i -lt $this.IvsEventLog.Count; $i++) {
        
                $StartTime = $this.IvsEventLog[$i].StartTime
        
                while ($this.IvsEventLog[$i].NextEvent -le $EventMergeDistance -and $i -lt $this.IvsEventLog.Count - 1) {
                        $i++
                }
                
                $EndTime = $this.IvsEventLog[$i].EndTime
                $Duration = ($EndTime - $StartTime).TotalSeconds
        
                $Event = [pscustomobject]@{
                    StartTime   = $StartTime
                    EndTime     = $EndTime
                    Duration    = $Duration
                }
                
                $NewEvents.Add($Event) > $null
            }

            $this.IvsEventLog = $NewEvents
        }
    }


    [void] GetIvsRules () {

        $RequestUriArgs = @{
            Uri                             = $this.Uri+"/cgi-bin/configManager.cgi?action=getConfig&name=VideoAnalyseRule"
            Credential                      = $this.Credentials
            AllowUnencryptedAuthentication  = $true
        }

        $Response = (Invoke-WebRequest @RequestUriArgs).Content -split "\r\n" 
        
        $Response | ForEach-Object {
                ($_ -split 'table.VideoAnalyseRule\[' -split '\]\[' -split '\]')[2]
            } | 
            Select-Object -Unique |
            ForEach-Object {
                $this.IvsRules += $_
            }
    }

    [void] EnableIvsLogging () {

        if ($null -eq $this.IvsRules) {
            $this.GetIvsRules()
        }

        $this.IvsRules | ForEach-Object {

            $RequestUriArgs = @{
                Uri                             = $this.Uri + "/cgi-bin/configManager.cgi?action=setConfig&VideoAnalyseRule[0][" + $_ + "].EventHandler.LogEnable=true"
                Credential                      = $this.Credentials
                AllowUnencryptedAuthentication  = $true
            }

            Invoke-WebRequest @RequestUriArgs
        }
    }

    [void] EnableIvsRecording () {

        if ($null -eq $this.IvsRules) {
            $this.GetIvsRules()
        }

        $this.IvsRules | ForEach-Object {

            $RecordEnableArgs = @{
                Uri                             = $this.Uri + "/cgi-bin/configManager.cgi?action=setConfig&VideoAnalyseRule[0][" + $_ + "].EventHandler.RecordEnable=true"
                Credential                      = $this.Credentials
                AllowUnencryptedAuthentication  = $true
            }

            $RecordChannelsArgs = @{
                Uri                             = $this.Uri + "/cgi-bin/configManager.cgi?action=setConfig&VideoAnalyseRule[0][" + $_ + "].EventHandler.RecordChannels[0]=1"
                Credential                      = $this.Credentials
                AllowUnencryptedAuthentication  = $true
            }

            $FeatureEnableArgs = @{
                Uri                             = $this.Uri + "/cgi-bin/configManager.cgi?action=setConfig&VideoAnalyseRule[0][" + $_ + "].FeatureEnable=true"
                Credential                      = $this.Credentials
                AllowUnencryptedAuthentication  = $true
            }

            $EnableArgs  = @{
                Uri                             = $this.Uri + "/cgi-bin/configManager.cgi?action=setConfig&VideoAnalyseRule[0][" + $_ + "].Enable=true"
                Credential                      = $this.Credentials
                AllowUnencryptedAuthentication  = $true
            }

            Invoke-WebRequest @RecordEnableArgs
            Invoke-WebRequest @RecordChannelsArgs
            Invoke-WebRequest @FeatureEnableArgs
            Invoke-WebRequest @EnableArgs
        }
    }

    [void] GetEncoding () {

        $RequestUriArgs = @{
            Uri                             = $this.Uri+"/cgi-bin/configManager.cgi?action=getConfig&name=Encode"
            Credential                      = $this.Credentials
            AllowUnencryptedAuthentication  = $true
        }

        $Response = (Invoke-WebRequest @RequestUriArgs).Content -split "\r\n" 

        $this.Encoding = $Response

        #TODO: parse the returned lines and create properties for each one under $this.Encoding
    }

    [void] ExportCamera () {
        $Path = "$env:LOCALAPPDATA\DahuaPowerShell"

        if ( (Test-Path $Path) -eq $false) {
            New-Item $Path -ItemType Directory | Out-Null
        }

        $FileName = "DahuaCamera_$( $this.Name ).xml"
        $FullPath = Join-Path -Path $Path -ChildPath $FileName

        $ProfileTable = @{}
        if ($this.Name) {
            $ProfileTable["Name"] = $this.Name
        }
        if ($this.Uri) {
            $ProfileTable["Uri"] = $this.Uri
        }
        if ($this.Credentials) {
            $ProfileTable["Credentials"] = $this.Credentials
        }
        if ($this.IvsEventLog) {
            $ProfileTable["IvsEvents"] = $this.IvsEventLog
        }
        if ($this.EventBuffer) {
            $ProfileTable["EventBuffer"] = $this.EventBuffer
        }

        $Profile = [PSCustomObject]$ProfileTable
        $Profile | Export-Clixml -Path $FullPath
    }

    # Constructors
    DahuaCamera () {
        $this.EventMergeDistance = 10
        $this.EventBuffer = 3
    }

    DahuaCamera ([String]$ConfigPath) {
        if (Test-Path $ConfigPath) {
            $Profile = Import-Clixml -Path $ConfigPath -ErrorAction Stop

            if ($Profile.Name) {
                $this.Name = $Profile.Name
            }
            if ($Profile.Credentials) {
                $this.Credentials = $Profile.Credentials
            }
            if ($Profile.Uri) {
                $this.Uri = $Profile.Uri
            }
            if ($Profile.Log) {
                $this.Log = $Profile.Log
            }
            if ($Profile.IvsEvents) {
                $this.IvsEventLog = $Profile.IvsEvents
            }
            if ($Profile.EventBuffer) {
                $this.EventBuffer = $Profile.EventBuffer
            } elseif ($null -eq $Profile.EventBuffer) {
                $this.EventBuffer = 3
            }
        }
    }

}
