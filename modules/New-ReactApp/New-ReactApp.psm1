$indexHtml = @"
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
"@

$appJs = @"
import React from "react";
import { hot } from "react-hot-loader/root";

function App() {
  return (
    <>
    </>
  )
}

export default hot(App);
"@

$indexJs = @'
import React from "react";
import ReactDOM from "react-dom";
import App from "./App";
import "./styles.css";

ReactDOM.render(<App/>, document.getElementById("root"));
'@ 

$readMe = @"
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
"@

$babelRc = @'
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
'@

$webPackConfigJs = @"
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
"@

$appTsx = @"
import * as React from 'react';
import { hot } from "react-hot-loader/root";

function App() {
  return (
    <>
    </>
  )
}

export default hot(App);
"@

$indexTsx = @"
import * as React from 'react';
import * as ReactDOM from "react-dom";

import App from './App';
import "./styles.css";

ReactDOM.render(<App/>, document.getElementById("root"));
"@

$tsConfig = @"
{
  "compilerOptions": {
      "outDir": "./dist/",
      "sourceMap": true,
      "strict": true,
      "noImplicitReturns": true,
      "noImplicitAny": true,
      "module": "es6",
      "moduleResolution": "node",
      "target": "es5",
      "allowJs": true,
      "jsx": "react",
  },
  "include": [
      "./src/**/*"
  ]
}
"@

$webpackConfigTs = @"
const webpack = require('webpack');
const path = require('path');

const config = {
  entry: [
    'react-hot-loader/patch',
    './src/index.tsx'
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
        test: /\.ts(x)?$/,
        loader: 'ts-loader',
        exclude: /node_modules/
      }
    ]
  },
  devServer: {
    'static': {
      directory: './dist'
    }
  },
  resolve: {
    extensions: [
      '.tsx',
      '.ts',
      '.js'
    ],
    alias: {
      'react-dom': '@hot-loader/react-dom'
    }
  }
};

module.exports = config;
"@

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
    Sets up an app MyReactApp to the current working directory e.g. .\MyReactApp

  .EXAMPLE
    New-ReactApp -AppName MyOtherReactApp -Path C:\react-apps
    Sets up an app MyOtherReactApp to C:\react-apps\MyOtherReactApp
#>
function New-ReactApp() {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppName,
    [Parameter()]
    [string]$Path,
    [Switch]
    $TypeScript
  )

  Begin {
    #Requires -Version 7

    # Hide progress bars

    $originalProgressPreference = $Global:ProgressPreference

    $Global:ProgressPreference = "SilentlyContinue"

    $nl = [System.Environment]::NewLine

    # App name

    $invalidCharacters = [System.IO.Path]::GetInvalidFileNameChars()

    $index = $AppName.IndexOfAny($invalidCharacters)

    if (($index -eq -1) -eq $false) {
      Write-Warning "App name contains invalid characters."
      
      Write-Verbose ("Invalid characters are: " + ($invalidCharacters -join " "))

      $Host.UI.RawUI.ReadKey() | Out-Null

      Exit
    }

    Write-Verbose "Creating directories.."

    # Check the Path-parameter

    $pathParameter = [string]::IsNullOrEmpty($Path)

    # No Path-parameter, use the current location

    if ($pathParameter -eq $true) {
      $basePath = Resolve-Path (Get-Location) | Select-Object -ExpandProperty Path
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

          Exit
        }
      }

      # Resolve relative path into absolute path

      try {
        $basePath = Resolve-Path $Path -ErrorAction Stop | Select-Object -ExpandProperty Path
      }
      catch {
        $message = $_

        Write-Warning $message

        Exit
      }
    }

    # $basePath/AppName/

    New-Item $basePath -ItemType Directory -Name $AppName -Force | Out-Null

    # $appPath = $basePath/AppName/

    $appPath = Join-Path $basePath $AppName

    # $appPath/src/

    New-Item -Name src -ItemType Directory -Path $appPath -ErrorAction Ignore | Out-Null

    $srcPath = Join-Path $appPath src

    # $appPath/dist/

    New-Item -Name dist -ItemType Directory -Path $appPath -ErrorAction Ignore | Out-Null

    $distPath = Join-Path $appPath dist
  }

  Process {
    Write-Verbose "Creating files.."

    # $appPath/dist/index.html

    $indexHtml | Out-File (Join-Path $distPath index.html) -Encoding utf8NoBOM

    # $appPath/src/App.js
    # $appPath/src/App.tsx

    if ($TypeScript -eq $true) {
      $appTsx | Out-File (Join-Path $srcPath App.tsx) -Encoding utf8NoBOM
    }
    else {
      $appJs | Out-File (Join-Path $srcPath App.js) -Encoding utf8NoBOM
    }

    # $appPath/src/index.js
    # $appPath/src/index.tsx

    if ($TypeScript -eq $true) {
      $indexTsx | Out-File (Join-Path $srcPath index.tsx) -Encoding utf8NoBOM
    }
    else {
      $indexJs | Out-File (Join-Path $srcPath index.js) -Encoding utf8NoBOM
    }

    # $appPath/src/styles.css

    New-Item $srcPath -ItemType File -Name styles.css -ErrorAction Ignore | Out-Null

    # $appPath/readme.md

    $readme | Out-File (Join-Path $appPath readme.md) -Encoding utf8NoBOM

    # $appPath/.babelrc.json

    $babelRc | Out-File (Join-Path $appPath .babelrc.json) -Encoding utf8NoBOM

    # $appPath/.gitignore

    $gitignore = Join-Path $appPath .gitignore

    Invoke-WebRequest -Uri https://raw.githubusercontent.com/facebook/react/main/.gitignore -OutFile $gitignore

    # $appPath/webpack.config.js

    $webpackConfig = Join-Path $appPath webpack.config.js

    if ($TypeScript -eq $true) {
      $webpackConfigTs | Out-File $webpackConfig -Encoding utf8NoBOM
    }
    else {
      $webPackConfigJs | Out-File $webpackConfig -Encoding utf8NoBOM
    }
    

    # Initialize node package manager and install packages

    $originalLocation = Get-Location

    Set-Location -Path $appPath
  
    Write-Verbose "Initializing node package manager.."

    npm init -y | Out-Null

    Write-Verbose "Installing dependencies.."

    npm install react react-dom react-hot-loader --silent

    if ($TypeScript -eq $true) {
      npm install --save-dev webpack webpack-cli '@types/react' '@types/react-dom' '@babel/preset-react' babel-loader @babel/core @babel/preset-env '@hot-loader/react-dom' webpack-dev-server css-loader style-loader typescript ts-loader '@hot-loader/react-dom'
    }
    else {
      npm install --silent --save-dev webpack webpack-cli @babel/preset-react babel-loader @babel/core @babel/preset-env '@hot-loader/react-dom' jest babel-jest webpack-dev-server css-loader style-loader html-webpack-plugin file-loader url-loader
    }
    
    # $appPath/package.json
    
    $packageJson = Get-Content (Join-Path $appPath package.json) -Raw | ConvertFrom-Json

    $packageJson.description = ""
    $packageJson.scripts | Add-Member -NotePropertyName clean -NotePropertyValue "rm dist/bundle.js"
    $packageJson.scripts | Add-Member -NotePropertyName build-dev -NotePropertyValue "webpack --mode development"
    $packageJson.scripts | Add-Member -NotePropertyName build-prod -NotePropertyValue "webpack --mode production"
    $packageJson.scripts | Add-Member -NotePropertyName start -NotePropertyValue "webpack serve --hot --mode development"
    $packageJson.scripts.test = "jest"
    
    $packageJson | ConvertTo-Json | Out-file (Join-Path $appPath package.json) -Encoding utf8NoBOM

    # $appPath/tsconfig.json

    if ($TypeScript -eq $true) {
      $tsConfig | Out-File (Join-Path $appPath tsconfig.json) -Encoding utf8NoBOM
    }
  }

  End {
    Set-Location $originalLocation

    $Global:ProgressPreference = $originalProgressPreference

    Write-Host "All done!$nl"
  }
}

Export-ModuleMember -Function New-ReactApp