#requires -version 7 -RunAsAdministrator

# Persistently appends the new module path to PSModulePath environment variable the windows registry way
function Set-PSModulePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$modulePath
    )
    
    $key = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager').OpenSubKey('Environment', $true)
       
    $psModulePath = $key.GetValue('PSModulePath', '', 'DoNotExpandEnvironmentNames')

    if ($psModulePath.ToString().Contains($modulePath)) {
        Write-Host ('$env:PSModulePath ' + "already contains $modulePath, no changes necessary.") -ForegroundColor DarkYellow

        return
    }

    $newPsModulePath = ($psModulePath + ";" + $modulePath)

    $key.SetValue('PSModulePath', $newPsModulePath, [Microsoft.Win32.RegistryValueKind]::ExpandString)

    Write-Host ("$modulePath appended to " + '$PSModulePath.')

    Write-Host ("New " + '$env:PSModulePath: ' + $newPsModulePath) -ForegroundColor Green

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

    if ($psModulePath.ToString().Contains($modulePath) -eq $false) {
        Write-Host ('$env:PSModulePath ' + "does not contain $modulePath, no changes necessary.") -ForegroundColor DarkYellow

        return
    }

    $newPsModulePath = $psModulePath.ToString().Replace(";$modulePath", "");

    $key.SetValue('PSModulePath', $newPsModulePath, [Microsoft.Win32.RegistryValueKind]::ExpandString)

    Write-Host ("$modulePath removed from " + '$PSModulePath.')

    Write-Host ("New " + '$env:PSModulePath: ' + $newPsModulePath) -ForegroundColor Green

    Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
}

# Linux or mac

if (($isLinux -eq $true) -or ($isMac -eq $true)) {
    $currentUserModulePath = "$HOME/.local/share/powershell/Modules"
    $allUsersModulePath = "usr/local/share/powershell/Modules"

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
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $modulesPath $module

                Write-Host "Importing $modulePath" -ForegroundColor DarkYellow
                Import-Module $modulePath
            }
        }
        2 {
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $modulesPath $module

                try {
                    Write-Host "Copying $modulePath to $currentUserModulePath" -ForegroundColor DarkYellow
                    Copy-Item $modulePath -Destination $currentUserModulePath -Recurse -Force
                }
                catch {
                    $message = $_
    
                    Write-Warning $message
                }
            }
        }
        3 {
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $modulesPath $module

                try {
                    Write-Host "Copying $modulePath to $allUserModulePath" -ForegroundColor DarkYellow
                    Copy-Item $modulePath -Destination $allUsersModulePath -Recurse -Force
                }
                catch {
                    $message = $_
    
                    Write-Warning $message
                }
            }
        }
        4 {
            <#
            
            PROFILE FILES
            
            Different powershell profiles are stored in $profile variable 
            as noteproperties

            $profile | Get-Member -Type NoteProperty

            For example,

            Current User, Current Host - $PROFILE
            Current User, Current Host - $PROFILE.CurrentUserCurrentHost
            Current User, All Hosts - $PROFILE.CurrentUserAllHosts
            All Users, Current Host - $PROFILE.AllUsersCurrentHost
            All Users, All Hosts - $PROFILE.AllUsersAllHosts

            The path to all users, current host profile would be in 
            $PROFILE.AllUsersAllHosts

            #>

            if ((Test-Path -Path $profile) -eq $false) {
                New-Item -ItemType File -Path $profile -Force
            }

            $content = Get-Content $profile -Raw

            $command = ('$Env:PSModulePath += ;' + $modulesPath)

            if ($content.Contains($command) -eq $true) {
                Write-Host ("$profile already contains $modulesPath, no changes necessary. ") -ForegroundColor DarkYellow
            
                return
            }

            Write-Host "Writing $command to $profile" -ForegroundColor DarkYellow

            Add-Content $profile -Value $command

            Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
        }
        5 {
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name
            
            foreach ($module in $modules) {
                $modulePath = Join-Path $currentUserModulePath $module

                if ((Test-Path $modulePath) -eq $true) {
                    Remove-Item $modulePath -Recurse -ErrorAction SilentlyContinue
                    Write-Host "Removing $modulePath" -ForegroundColor DarkYellow
                }
                
            }
        }
        6 {
            [string[]]$modules = Get-ChildItem $modulePath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $allUsersModulePath $module

                if ((Test-Path $modulePath) -eq $true) {
                    Remove-Item $modulePath -Recurse -ErrorAction SilentlyContinue
                    Write-Host "Removing $modulePath" -ForegroundColor DarkYellow
                }
                
            }
        }
        7 {
            if ((Test-Path -Path $profile) -eq $false) {
                Write-Host "The profile does not exist. No changes necessary." -ForegroundColor DarkYellow

                exit
            }

            $content = Get-Content $profile -Raw

            $command = ('$Env:PSModulePath += ;' + $modulesPath)

            if ($content.Contains($command) -eq $false) {
                Write-Host ("$profile does not contain $command, no changes necessary. ") -ForegroundColor DarkYellow
            
                exit
            }
            Write-Host "Removing $command from $profile" -ForegroundColor DarkYellow

            $content -replace $command, "" | Set-Content $profile

            Write-Host ("Restart powershell for the changes to take effect.") -ForegroundColor DarkYellow
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
}

# Windows

else {
    # $env:PSModulePath environment variable contains the list of paths that are searched to find modules and resources

    $availableModulePaths = $env:PSModulePath -Split ";"

    $currentUserModulePath = $availableModulePaths[0]

    $allUsersModulePath = $availableModulePaths[1]

    # .\modules

    $modulesPath = Join-Path $PSScriptRoot modules

    Write-Host "--- Importing modules ---" -ForegroundColor Green
    Write-Host "1. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Temporarily import the modules for this session"
    Write-Host "2. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Persistently import the modules for the current user by copying the modules to $currentUserModulePath" 
    Write-Host "3. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Persistently import the modules for all users by copying the modules to $allUsersModulePath"
    Write-Host "4. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Persistently import the modules by appending $modulesPath to " + '$env:PSModulePath')
    
    Write-Host "--- Removing modules ---" -ForegroundColor Green
    Write-Host "5. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Remove the modules from the current user by removing the modules from $currentUserModulePath"
    Write-Host "6. " -ForegroundColor DarkYellow -NoNewline; Write-Host "Remove the modules from all users by removing the modules from $allUsersModulePath"
    Write-Host "7. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Remove the modules by removing the path $modulesPath from " + '$env:PSModulePath')
    Write-Host ""
    Write-Host "0. " -ForegroundColor DarkYellow -NoNewline; Write-Host ("Exit")

    $selection = Read-Host "Selection"

    switch ($selection) {
        1 {
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $modulesPath $module

                Write-Host "Importing $modulePath" -ForegroundColor DarkYellow
                Import-Module $modulePath
            }
        }
        2 {
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $modulesPath $module

                try {
                    Write-Host "Copying $modulePath to $currentUserModulePath" -ForegroundColor DarkYellow
                    Copy-Item $modulePath -Destination $currentUserModulePath -Recurse -Force
                }
                catch {
                    $message = $_
    
                    Write-Warning $message
                }
            }
        }
        3 {
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $modulesPath $module

                try {
                    Write-Host "Copying $modulePath to $allUserModulePath" -ForegroundColor DarkYellow
                    Copy-Item $modulePath -Destination $allUsersModulePath -Recurse -Force
                }
                catch {
                    $message = $_
    
                    Write-Warning $message
                }
            }
        }
        4 {
            Set-PSModulePath -modulePath $modulesPath
        }
        5 {
            [string[]]$modules = Get-ChildItem $modulesPath | Select-Object -ExpandProperty Name
            
            foreach ($module in $modules) {
                $modulePath = Join-Path $currentUserModulePath $module

                if ((Test-Path $modulePath) -eq $true) {
                    Remove-Item $modulePath -Recurse -ErrorAction SilentlyContinue
                    Write-Host "Removing $modulePath" -ForegroundColor DarkYellow
                }
                
            }
        }
        6 {
            [string[]]$modules = Get-ChildItem $modulePath | Select-Object -ExpandProperty Name

            foreach ($module in $modules) {
                $modulePath = Join-Path $allUsersModulePath $module

                if ((Test-Path $modulePath) -eq $true) {
                    Remove-Item $modulePath -Recurse -ErrorAction SilentlyContinue
                    Write-Host "Removing $modulePath" -ForegroundColor DarkYellow
                }
                
            }
        }
        7 {
            Remove-PSModulePath -modulePath $modulesPath
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