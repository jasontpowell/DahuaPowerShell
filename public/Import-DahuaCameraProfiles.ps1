function Import-DahuaCameraProfiles {
    $ProfileCollection = @{}
    
    $Profiles = @( Get-ChildItem -r -Path $env:LOCALAPPDATA\DahuaPowerShell\*.xml -ErrorAction SilentlyContinue ) 
    
    $Profiles | ForEach-Object {
        $Connector = [DahuaCamera]::new($_)
        $ProfileCollection[$Connector.Name] = $Connector
    }
    
    Write-Output $ProfileCollection
}
