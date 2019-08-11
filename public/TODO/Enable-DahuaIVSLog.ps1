function Enable-DahuaIVSLog {
    param(
        # The IP address or hostname for the device to query
        [String]
        $BaseUri,

        [PSCredential]
        $DahuaCredentials
    )

    $Camera | ForEach-Object {
        $CurrentCamera = $_
        $Rules = Get-DahuaIVSRuleList -Camera $_ -DahuaCredentials $DahuaCredentials

        $Rules | ForEach-Object {
            $RequestAPIArgs = @{
                Camera              = $CurrentCamera
                Action              = "/cgi-bin/configManager.cgi?action=setConfig&VideoAnalyseRule[0][$_].EventHandler.LogEnable=true"
                DahuaCredentials    = $DahuaCredentials
            }

            # Sending to $null because I don't need an output from this function. 
            Request-DahuaAPI @RequestAPIArgs > $null
        }
    }
}
