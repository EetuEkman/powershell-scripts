<#
  .SYNOPSIS
    Sets up a new react.js app.

  .PARAMETER AppName
    Mandatory name of the app.

  .PARAMETER Path
    Optional path parameter where to create a directory in which to setup the app.

  .INPUTS
    None.

  .OUTPUTS
    None.

  .EXAMPLE
    New-ReactApp MyReactApp
    Setups an app MyReactApp to current working directory e.g. .\MyReactApp

  .EXAMPLE
    New-ReactApp -AppName MyOtherReactApp -Path C:\react-apps
    Setups an app MyOtherReactApp to C:\react-apps\MyOtherReactApp
#>
function New-ReactApp() {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppName,
    [Parameter()]
    [string]$Path
  )

  Begin {
    #Requires -Version 7

    # Hide progress bars

    $originalProgressPreference = $Global:ProgressPreference

    $Global:ProgressPreference = "SilentlyContinue"

    $nl = [System.Environment]::NewLine

    # App name

    $illegalCharacters = [System.IO.Path]::GetInvalidFileNameChars()

    $index = $AppName.IndexOfAny($illegalCharacters)

    if (-Not ($index -eq -1)) {
      Write-Warning "Project name contains illegal characters.$nl$nl"
      
      Write-Host "Illegal characters are $nl"

      Write-Host ($illegalCharacters + $nl)

      Write-Host "Press any key to continue.."

      $Host.UI.ReadLine() | Out-Null

      Exit
    }

    Write-Host "Creating directories.."

    # Check the Path-parameter

    $pathParameter = [string]::IsNullOrEmpty($Path)

    # No Path-parameter

    if ($pathParameter -eq $true) {
      $_Path = Resolve-Path (Get-Location) | Select-Object -ExpandProperty Path
    }

    # With Path-parameter

    else {
      # Create the path if the path doesn't exist

      $testPath = Test-Path $Path

      if ($testPath -eq $false) {

        try {
          New-Item $Path -ItemType Directory -ErrorAction Stop | Out-Null
        }

        catch {
          $message = $_
  
          Write-Warning $message

          Write-Host "Press any key to continue.."
  
          $Host.UI.ReadLine() | Out-Null

          Exit
        }
      }

      # Get the full path

      try {
        $_Path = Resolve-Path $Path | Select-Object -ExpandProperty Path
      }

      catch {
        $message = $_

        Write-Warning $message

        Write-Host "Press any key to continue.."
  
        $Host.UI.ReadLine() | Out-Null

        Exit
      }
    }

    # $_Path/AppName/

    New-Item $_Path -ItemType Directory -Name $AppName -Force | Out-Null

    $_Path = Join-Path $_Path $AppName

    # $_Path/AppName/src/

    New-Item -Name src -ItemType Directory -Path $_Path -ErrorAction Ignore | Out-Null

    $srcPath = Join-Path $_Path src

    # $_Path/AppName/dist/

    New-Item -Name dist -ItemType Directory -Path $_Path -ErrorAction Ignore | Out-Null

    $distPath = Join-Path $_Path dist
  }

  Process {

    Write-Host "Creating files.."

    # _$Path/AppName/dist/index.html

@"
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>$AppName</title>
  </head>
  <body>
    <div id="root"></div>
    <script src="bundle.js"></script>
  </body>
</html>
"@ | Out-File (Join-Path $distPath index.html) -Encoding utf8NoBOM

   # _$Path/AppName/src/App.js

@"
import React from "react";
import { hot } from "react-hot-loader/root";

function App() {
  return (
    <>
    </>
  )
}

export default hot(App);
"@ | Out-File (Join-Path $srcPath App.js) -Encoding utf8NoBOM

    # _$Path/AppName/src/index.js

@'
import React from "react";
import ReactDOM from "react-dom";
import App from "./App";
import "./styles.css";

ReactDOM.render(<App/>, document.getElementById("root"));
'@ | Out-File (Join-Path $srcPath index.js) -Encoding utf8NoBOM

    ### Style sheet ###

    # _$Path/AppName/src/styles.css

    New-Item $srcPath -ItemType File -Name styles.css -ErrorAction Ignore | Out-Null

    ### Readme ###

    # _$Path/AppName/readme.md

@"
#$AppName

## Building and running on localhost

First install dependencies

``````sh
npm install
``````

To run in hot module reloading mode

``````sh
npm start
``````

To create a production build

``````sh
npm run build-prod
``````

To create a development build

``````sh
npm run build-dev
``````

## Running

Open the file ``dist/index.html`` in your browser

## Testing

To run unit tests

``````sh
npm test
``````
"@ | Out-File (Join-Path $_Path readme.md) -Encoding utf8NoBOM

  ### Babel configuration ###

  # _$Path/AppName/.babelrc.json

@'
{
  presets: [
    [
      "@babel/preset-env",
      {
        modules: false
      }
    ],
    "@babel/preset-react"
  ],
  plugins: [
    "react-hot-loader/babel"
  ]
}
'@ | Out-File (Join-Path $_Path .babelrc.json) -Encoding utf8NoBOM

  # _$Path/AppName/.gitignore

  Invoke-WebRequest -Uri https://raw.githubusercontent.com/facebook/react/main/.gitignore -OutFile (Join-Path $_Path .gitignore)

  ### Webpack configuration ###

  # _$Path/AppName/webpack.config.js

@"
const webpack = require('webpack');
const path = require('path');

module.exports = {
  entry: [
    'react-hot-loader/patch',
    './src/index.js'
  ],
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        use: 'babel-loader',
        exclude: /node_modules/
      },
      {
        test: /\.css$/,
        use: [
          'style-loader',
          'css-loader'
        ]
      },
      {
        test: /\.png$/,
        use: [
          {
            loader: 'url-loader',
            options: {
              mimetype: 'image/png'
            }
          }
        ]
      },
      {
        test: /\.svg$/,
        use: 'file-loader'
      }
    ]
  },
  devServer: {
    'static': {
      directory: './dist'
    }
  }
}
"@ | Out-File (Join-Path $_Path webpack.config.js) -Encoding utf8NoBOM

  # Initialize node package manager and install packages

  $originalLocation = Get-Location

  Set-Location -Path $_Path
  
  Write-Host "Initializing node package manager.."

  npm init -y | Out-Null

  Write-Host "Installing dependencies.."

  npm install --silent --loglevel silent --no-optional --save-dev webpack webpack-cli @babel/preset-react babel-loader @babel/core @babel/preset-env @hot-loader/react-dom jest babel-jest webpack-dev-server css-loader style-loader html-webpack-plugin file-loader url-loader | Out-Null
  
  npm installreact react-dom react-hot-loader --silent --loglevel silent --no-optional | Out-Null

  # _$Path/AppName/package.json
  
  $packageJson = Get-Content (Join-Path $_Path package.json) -Raw | ConvertFrom-Json

  $packageJson.description = ""
  $packageJson.scripts | Add-Member -NotePropertyName clean -NotePropertyValue "rm dist/bundle.js"
  $packageJson.scripts | Add-Member -NotePropertyName build-dev -NotePropertyValue "webpack --mode development"
  $packageJson.scripts | Add-Member -NotePropertyName build-prod -NotePropertyValue "webpack --mode production"
  $packageJson.scripts | Add-Member -NotePropertyName start -NotePropertyValue "webpack serve --hot --mode development"
  $packageJson.scripts.test = "jest"
  
  $packageJson | ConvertTo-Json | Out-file (Join-Path $_Path package.json) -Encoding utf8NoBOM

  }

  End {
    Set-Location $originalLocation

    $Global:ProgressPreference = $originalProgressPreference

    Write-Host "All done!$nl"

    Write-Host "Press any key to continue.."

    $Host.UI.ReadLine() | Out-Null
  }
}

Export-ModuleMember -Function New-ReactApp