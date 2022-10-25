# PowerShell Scripts

Contains various useful PowerShell modules and scripts.

Modules and scripts aim to be cross-platform and require [powershell 7](https://github.com/PowerShell/PowerShell).

Modules can be imported or copied manually, but a powershell helper script has been provided.

## Module-Helper.ps1

The script provides various options to import or remove the modules.

Because the script has to copy files or change module paths, the script requires administrator privileges.

## New-ReactApp

New-ReactApp bootstraps a new barebones react app, similar way to Create React App, without added features.

`New-ReactApp
    [-AppName] <String>
    [-Path <String>]`

AppName parameter is mandatory. "Illegal" characters are not allowed. Invalid characters are found in `[System.IO.Path]::GetInvalidFileNameChars()`

Path parameter is optional. Without the parameter, the React app will be bootstrapped to a directory in the current working directory.