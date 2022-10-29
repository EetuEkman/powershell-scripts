#requires -version 7 -RunAsAdministrator

# Persistently appends the new module path to PSModulePath environment variable the windows registry way
function Set-PSModulePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath
    )
    
    $key = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager').OpenSubKey('Environment', $true)
       
    [string]$psModulePath = $key.GetValue('PSModulePath', '', 'DoNotExpandEnvironmentNames')

    if (($psModulePath.Contains($ModulePath)) -eq $true) {
        Write-Host ('$Env:PSModulePath ' + "already contains $ModulePath, no changes necessary.") -ForegroundColor DarkYellow

        return
    }

    $newPsModulePath = ($psModulePath + ";" + $ModulePath)

    $key.SetValue('PSModulePath', $newPsModulePath, [Microsoft.Win32.RegistryValueKind]::ExpandString)

    Write-Verbose ("$ModulePath appended to " + '$Env:PSModulePath.')

    Write-Verbose ("New " + '$Env:PSModulePath: ' + $newPsModulePath)

    Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
}

# Remove the module path from PSModulePath environment variable the windows registry way
function Remove-PSModulePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$modulePath
    )

    $key = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager').OpenSubKey('Environment', $true)
       
    $psModulePath = $key.GetValue('PSModulePath', '', 'DoNotExpandEnvironmentNames')

    if (($psModulePath.Contains($modulePath)) -eq $false) {
        Write-Host ('$Env:PSModulePath ' + "does not contain $modulePath, no changes necessary.") -ForegroundColor DarkYellow

        return
    }

    $newPsModulePath = $psModulePath.Replace(";$modulePath", "");

    $key.SetValue('PSModulePath', $newPsModulePath, [Microsoft.Win32.RegistryValueKind]::ExpandString)

    Write-Verbose ("$modulePath removed from " + '$Env:PSModulePath.')

    Write-Verbose ("New " + '$Env:PSModulePath: ' + $newPsModulePath)

    Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
}

# Appends the set $Env:PSModulePath-command to a profile file in path
function Set-Profile {
    param(
        [string]$ProfilePath,
        [string]$ModulesPath
    )

    if ((Test-Path -Path $ProfilePath) -eq $false) {
        New-Item -ItemType File -Path $ProfilePath -Force
    }

    $profileFile = Get-Content -Path $ProfilePath

    # Line to be appended

    $line = ('$Env:PSModulePath += ' + '";' + $ModulesPath + '"')

    # Empty profile file

    if (($null -eq $profileFile) -eq $true ) {
        Write-Verbose "Writing line $line to the profile file in $ProfilePath"

        Set-Content $ProfilePath -Value $line -Encoding utf8NoBOM

        Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
        
        return
    }

    # Prevent duplicate lines

    if ($profileFile -contains $line) {
        Write-Host ("The profile file in $ProfilePath already contains $line, no changes necessary.") -ForegroundColor DarkYellow
    
        return
    }

    $length = $profileFile.Length

    # Text file ends on a new line

    if ([string]::IsNullOrEmpty($profileFile[$length - 1]) -eq $true) {
        Write-Verbose "Writing line $line to the profile file in $ProfilePath"

        $profileFile[$length - 1] = $line

        Set-Content -Path $ProfilePath -Value $profileFile -Encoding utf8NoBOM

        Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
    
        return
    }

    # Text file does not end in new line

    Write-Verbose "Writing line $line to the profile file in $ProfilePath"

    $profileFile += [System.Environment]::NewLine

    $profileFile += $line
    
    Set-Content -Path $ProfilePath -Value $profileFile -Encoding utf8NoBOM 

    Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
}

function Remove-FromProfile {
    param(
        [string]$ProfilePath,
        [string]$ModulesPath
    )

    if ((Test-Path -Path $ProfilePath) -eq $false) {
        Write-Host "The profile file in $ProfilePath does not exist, no changes necessary." -ForegroundColor DarkYellow

        return
    }

    $profileContent = Get-Content -Path $ProfilePath

    $line = ('$Env:PSModulePath += ' + '";' + $ModulesPath + '"')

    if (($profileContent -contains $line) -eq $false) {
        Write-Host ("The profile file in $ProfilePath does not contain $line, no changes necessary.") -ForegroundColor DarkYellow
    
        return
    }

    # Line contains regular expression escape characters

    $profileContent | Where-Object {$_ -notmatch [regex]::escape($line)} | Set-Content -Path $ProfilePath -Encoding utf8NoBOM
}

function Copy-Modules {
    param(
        [string]$Source,
        [string]$Destination
    )

    $modules = Get-ChildItem $Source | Select-Object -ExpandProperty Name

    foreach ($module in $modules) {
        $modulePath = Join-Path $Source $module

        try {
            Write-Verbose "Copying $modulePath to $Destination"
            
            Copy-Item -Path $modulePath -Destination $Destination -Recurse -Force
        }
        catch {
            $message = $_

            Write-Warning $message
        }
    }
}

function Remove-Modules {
    param(
        [string]$AvailableModules,
        [string]$From
    )

    [string[]]$modules = Get-ChildItem $AvailableModules | Select-Object -ExpandProperty Name
    
    foreach ($module in $modules) {
        $modulePath = Join-Path $From $module

        if ((Test-Path -Path $modulePath) -eq $true) {
            Write-Verbose "Removing $modulePath"

            Remove-Item $modulePath -Recurse -ErrorAction SilentlyContinue
        }
        
    }
}

function Import-Modules {
    param(
        [string]$From
    )

    [string[]]$modules = Get-ChildItem $From | Select-Object -ExpandProperty Name

    foreach ($module in $modules) {
        $modulePath = Join-Path $From $module

        Write-Host "Importing $modulePath" -ForegroundColor DarkYellow

        Import-Module $modulePath
    }
}

# Linux or mac

if (($isLinux -eq $true) -or ($isMac -eq $true)) {
    $currentUserModulePath = Join-Path $HOME .local share powershell Modules
    
    $allUsersModulePath = Join-Path usr local share powershell Modules

    # ./modules

    $modulesPath = Join-Path $PSScriptRoot modules

    Write-Host "--- Importing modules ---" -ForegroundColor Green
    Write-Host "1. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Temporarily import the modules for this session"
    Write-Host "2. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Persistently import the modules for the current user by copying the modules to $currentUserModulePath" 
    Write-Host "3. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Persistently import the modules for all users by copying the modules to $allUsersModulePath"
    Write-Host "4. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Append the import modules command to profile in path $profile"

    Write-Host "--- Removing modules ---" -ForegroundColor Green
    Write-Host "5. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Remove the modules from the current user by removing the modules from $currentUserModulePath"
    Write-Host "6. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Remove the modules from all users by removing the modules from $allUsersModulePath"
    Write-Host "7. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Remove the import modules command from the profile in path $profile"
    Write-Host ""

    Write-Host "0. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Exit")

    $selection = Read-Host "Selection"

    switch ($selection) {
        1 {
            Import-Modules -From $modulesPath
        }
        2 {
            Copy-Modules -Source $modulesPath -Destination $currentUserModulePath
        }
        3 {
            Copy-Modules -Source $modulesPath -Destination $allUsersModulePath
        }
        4 {
            Set-Profile -ProfilePath $PROFILE -ModulesPath $modulesPath
        }
        5 {
            Remove-Modules -AvailableModules $modulesPath -From $currentUserModulePath
        }
        6 {
            Remove-Modules -AvailableModules $modulesPath -From $allUsersModulePath
        }
        7 {
            Remove-FromProfile -ProfilePath $PROFILE -ModulesPath $modulesPath
        }
        0 {
            Write-Host "Exiting without changes." -ForegroundColor DarkYellow

            exit
        }
        Default {
            Write-Host "Undefined option. Exiting without changes." -ForegroundColor DarkYellow -NoNewline

            exit
        }
    }

    Write-Host "Done!" -ForegroundColor DarkYellow -NoNewline

    exit
}

# Windows

# .\modules

$modulesPath = Join-Path $PSScriptRoot modules

# $Env:PSModulePath environment variable contains the list of paths that are searched to find modules and resources

$availableModulePaths = $Env:PSModulePath -Split ";"

$currentUserModulePath = $availableModulePaths[0]

$allUsersModulePath = $availableModulePaths[1]

Write-Host "--- Importing modules ---" -ForegroundColor Green
Write-Host "1. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Temporarily import the modules for this session"
Write-Host "2. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Persistently import the modules for the current user by copying the modules" 
Write-Host "3. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Persistently import the modules for all users by copying the modules"
Write-Host "4. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Persistently import the modules by setting the " + '$Env:PSModulePath')
Write-Host "5. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Persistently import the modules using the profile file")
    
Write-Host "--- Removing modules ---" -ForegroundColor Green
Write-Host "6. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Remove the module files from the current user"
Write-Host "7. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Remove the module files from all users"
Write-Host "8. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Remove the modules by setting the " + '$Env:PSModulePath')
Write-Host "9. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Remove the modules from the profile file")
Write-Host ""

Write-Host "0. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Exit")

$selection = Read-Host "Selection"

switch ($selection) {
    1 {
        Import-Modules -From $modulesPath
    }
    2 {
        Copy-Modules -Source $modulesPath -Destination $currentUserModulePath
    }
    3 {
        Copy-Modules -Source $modulesPath -Destination $allUsersModulePath
    }
    4 {
        Set-PSModulePath -modulePath $modulesPath
    }
    5 {
        Set-Profile -ProfilePath $PROFILE -ModulesPath $modulesPath
    }
    6 {
        Remove-Modules -AvailableModules $modulesPath -From $currentUserModulePath
    }
    7 {
        Remove-Modules -AvailableModules $modulesPath -From $allUsersModulePath
    }
    8 {
        Remove-PSModulePath -modulePath $modulesPath
    }
    9 {
        Remove-FromProfile -ProfilePath $PROFILE -ModulesPath $modulesPath
    }
    0 {
        Write-Host "Exiting without changes." -ForegroundColor DarkYellow
            
        exit
    }
    Default {
        Write-Host "Undefined option. Exiting without changes." -ForegroundColor DarkYellow -NoNewline

        exit
    }
}

Write-Host "Done!" -ForegroundColor DarkYellow -NoNewline

<#
# Persistently appends the new module path to PSModulePath environment variable the get/set-environment variable way
function Set-PSModulePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$modulePath
    )

    $psModulePath = [Environment]::GetEnvironmentVariable("PSModulePath")

    if ($psModulePath.Contains($modulePath) -eq $true) {
        Write-Host ('$PSModulePath already contains ' + $modulePath + ", no changes necessary.")

        return;
    }

    $newPSModulePath = ($psModulePath + ";" + $modulePath)

    [Environment]::SetEnvironmentVariable("PSModulePath", $newPSModulePath)
}

# Remove the module path from PSModulePath environment variable the get/set-environment variable way
function Remove-PSModulePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$modulePath
    )

    $psModulePath = [Environment]::GetEnvironmentVariable("PSModulePath")

    if ($psModulePath.Contains($modulePath) -eq $false) {
        Write-Host ('$PSModulePath does not contain ' + $modulePath + ", no changes necessary.")

        return;
    }

    $newPSModulePath = $psModulePath.Remove() + ";" + $modulePath

    [Environment]::SetEnvironmentVariable("PSModulePath", $newPSModulePath)
}
#>