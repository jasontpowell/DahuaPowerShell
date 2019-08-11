function Get-DahuaIVSRuleList {
    param(
        [ValidateSet("Front",
                     "Back",
                     "NVR")]
        [String]
        $Camera,

        [PSCredential]
        $DahuaCredentials
    )
    
    $Rules = New-Object System.Collections.ArrayList
    $Action = "/cgi-bin/configManager.cgi?action=getConfig&name=VideoAnalyseRule"

    $RequestAPIArgs = @{
        Camera              = $Camera
        Action              = $Action
        DahuaCredentials    = $DahuaCredentials
    }

    $IvsRulesSettings = (Request-DahuaAPI @RequestAPIArgs).content -split "\r\n"

    $IvsRulesSettings | ForEach-Object {
            ($_ -split 'table.VideoAnalyseRule\[' -split '\]\[' -split '\]')[2]
        } |
        Select-Object -Unique |
        ForEach-Object {
            $Rules.Add($_)
        } > $null

    Write-Output $Rules
}
