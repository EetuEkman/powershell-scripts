# PowerShell Scripts

Contains various useful PowerShell modules and scripts.

Modules and scripts are cross-platform and require [powershell 7](https://github.com/PowerShell/PowerShell).

Modules can be imported or copied manually, but a powershell helper script has been provided.

For powershell to find the modules, modules have to be located in a path in $env:PSModulePath environmental variable.

On a windows systems, a new path can be persistently appended to the environment variable using the windows registry.

Lastly, modules can be imported using the Import-Module cmdlet with the command `PS> Import-Module path\to\module\folder`. Import-Module cmdlets can be set to be run automatically on PowerShell startup by adding the import-module commands to PowerShell profiles whose paths can be found in $profile variable.

## Module-Helper.ps1

Module-Helper.ps1 provides options to import or remove the modules in the repository.

Options:

* Temporary import
* Copy the modules
* Use a powershell profile
* Environment variable (Windows)

To run the script, changing the execution policy might be needed. `Unblock-File` PowerShell cmdlet can also be used.

Because the script has to copy or write to files or alter environment variables, the script requires administrator privileges.

The script can be run with navigating to the script directory and running a command `PS> .\module-helper.ps1`.

### Requirements

* PowerShell 7 ran as administrator

## New-ReactApp

New-ReactApp sets up a boilerplate code and files for a react app, similar way to the [Create React App](https://create-react-app.dev/), but without all the added dependencies.

### Requirements

* PowerShell 7 ran as administrator
* Node package manager installed with executable found in the PATH environment variable.

Syntax: `New-ReactApp [-AppName] <String> [-Path <String>] [-TypeScript]`

AppName parameter is mandatory. Certain characters are not allowed. Invalid characters are listed in `PS> [System.IO.Path]::GetInvalidFileNameChars()`

Path parameter is optional. Without the parameter, the react app will be set up in a directory created to the current working directory.

TypeScript switch parameter sets up the app as a typescript app.

Boilerplate configuration includes:

* Jest test framework
* Babel code transpiler
* Webpack module bundler