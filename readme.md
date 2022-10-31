# PowerShell Scripts

Contains various useful PowerShell modules and scripts.

Modules and scripts aim to be cross-platform and require [powershell 7](https://github.com/PowerShell/PowerShell).

Modules can be imported or copied manually, but a powershell helper script has been provided.

For powershell to find the modules, modules have to be located in a path in $env:PSModulePath environmental variable.

On a windows systems, a new path can be persistently appended to the environment variable using the windows registry.

Lastly, modules can be imported using the Import-Module cmdlet with the command `PS> Import-Module path\to\module\folder`. Import-Module cmdlets can be set to be run automatically on PowerShell startup by adding the import-module commands to PowerShell profiles whose paths can be found in $profile variable.

## Module-Helper.ps1

Module-Helper.ps1 provides various options to import or remove the modules.

To run the script, changing the execution policy might be needed. `Unblock-File` PowerShell cmdlet can also be used.

Because the script has to copy files or alter module paths, the script requires administrator privileges.

The script can be run with `PS> .\module-helper.ps1` from the current directory.

### Requirements

* PowerShell 7 ran as administrator

## New-ReactApp

New-ReactApp sets up a simple react app, similar way to the [Create React App](https://create-react-app.dev/), but without all the added features.

### Requirements

* PowerShell 7 ran as administrator
* Node package manager installed with executable found in PATH

Syntax: `New-ReactApp [-AppName] <String> [-Path <String>]`

AppName parameter is mandatory. Certain characters are not allowed. Invalid characters are listed in `PS> [System.IO.Path]::GetInvalidFileNameChars()`

Path parameter is optional. Without the parameter, the react app will be set up in a directory created to the current working directory.