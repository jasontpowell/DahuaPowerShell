function Get-DahuaChannelList {
    param(
        [ValidateSet("Front",
                     "Back",
                     "NVR")]
        [String]
        $Camera,

        [PSCredential]
        $DahuaCredentials
    )
    
    $Channels = New-Object System.Collections.ArrayList
    $Action = "/cgi-bin/configManager.cgi?action=getConfig&name=Encode"

    $RequestAPIArgs = @{
        Camera              = $Camera
        Action              = $Action
        DahuaCredentials    = $DahuaCredentials
    }

    $VideoEncodeSettings = (Request-DahuaAPI @RequestAPIArgs).content -split "\r\n"

    $VideoEncodeSettings | ForEach-Object {
        ($_ -split 'table.Encode\[' -split '\]')[1]
        } |
        Select-Object -Unique |
        ForEach-Object {
            $Channels.Add($_)
        } > $null

    Write-Output $Channels
}
