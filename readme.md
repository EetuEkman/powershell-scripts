# PowerShell Scripts

Contains various useful PowerShell modules and scripts.

Modules and scripts aim to be cross-platform and require [powershell 7](https://github.com/PowerShell/PowerShell).

Modules can be imported or copied manually, but a powershell helper script has been provided.

For powershell to find the modules, modules have to be located in a path in $env:PSModulePath environmental variable.

On a windows systems, a new path can be persistently appended to the environment variable using the windows registry.

Lastly, modules can be imported using the Import-Module cmdlet with the command `Import-Module path\to\module\folder`. Import-Module cmdlets can be set to be run automatically on PowerShell startup by adding the import-module commands to PowerShell profiles whose paths can be found in $profile variable.

## Module-Helper.ps1

The script provides various options to import or remove the modules.

Before running the script, changing the execution policy might be needed or use the `Unblock-File` PowerShell cmdlet.

Because the script has to copy files or change module paths, the script requires administrator privileges.

The script can be run with `.\module-helper.ps1` from the current directory.

## New-ReactApp

New-ReactApp sets up a new simple barebones react app, similar way to the [Create React App](https://create-react-app.dev/), but without all the added libraries and functionalities.

Syntax: `New-ReactApp [-AppName] <String> [-Path <String>]`

AppName parameter is mandatory. Certain characters are not allowed. Invalid characters are found in `[System.IO.Path]::GetInvalidFileNameChars()`

Path parameter is optional. Without the parameter, the React app will be bootstrapped to a directory in the current working directory.