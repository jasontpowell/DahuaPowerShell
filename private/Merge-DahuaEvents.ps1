function Merge-DahuaEvents {
    param(
        $Events,

        # Seconds
        $MergeDistance = 10
    )

    $NewEvents = New-Object System.Collections.ArrayList

    for ($i = 0; $i -lt $Events.Count; $i++) {

            if ($i -lt $Events.Count -1) {
            $NextEvent = ([DateTime]$Events[$i+1].StartTime - [DateTime]$Events[$i].EndTime).TotalSeconds
        }
        else {
            $NextEvent = 0
        }

        $AddMemberArgs = @{
            NotePropertyName    = "NextEvent"
            NotePropertyValue   = $NextEvent
        }

        $Events[$i] | Add-Member @AddMemberArgs
    }

    for ($i = 0; $i -lt $Events.Count; $i++) {

        $StartTime = $Events[$i].StartTime

        while ($Events[$i].NextEvent -le $MergeDistance -and $i -lt $Events.Count - 1) {
                $i++
        }
        
        $EndTime = $Events[$i].EndTime
        $Duration = ($EndTime - $StartTime).TotalSeconds

    <#  Used for debugging   
        if ($i -lt $Events.Count -1) {
            $NextEvent = ($Events[$i+1].StartTime - $EndTime).TotalSeconds
        }
        else {
            $NextEvent = 0
        } #>

        $Event = [pscustomobject]@{
            DeviceName  = $Events[$i].DeviceName
            BaseUri     = $Events[$i].BaseUri
            StartTime   = $StartTime
            EndTime     = $EndTime
            Duration    = $Duration
            # NextEvent  = $NextEvent
        }
        
        $NewEvents.Add($Event) > $null
    }

    Write-Output $NewEvents
}
