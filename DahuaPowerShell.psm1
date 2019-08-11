param (
    [bool]$DebugModule = $false
)

# Script-scoped variables
$Script:ModuleRoot  = $PSScriptRoot

# Get public and private function definition files
    $Public         = @( Get-ChildItem -r -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue )
    $Private        = @( Get-ChildItem -r -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue )
    $FilesToLoad    = @([object[]]$Public + [object[]]$Private) | Where-Object {$_}


# Dot source the files

    Foreach($File in $FilesToLoad)
    {
        Write-Verbose "Importing [$File]"
        Try
        {
            if ($DebugModule)
            {
                . $File.FullName
            }
            else {
                . (
                    [scriptblock]::Create(
                        [io.file]::ReadAllText($File.FullName, [Text.Encoding]::UTF8)
                    )
                )
            }
        }
        Catch
        {
            Write-Error -Message "Failed to import function $($File.fullname)"
            Write-Error $_
        }
    }

Export-ModuleMember -Function $Public.BaseName
