$ErrorActionPreference = "Stop"

echo "-----> Credhub supply buildpack"

$buildDir = $args[0]
$depsDir = $args[2]
$index = $args[3]

$buildPackBinDir = $PSScriptRoot
$profileDir = Join-Path $buildDir -ChildPath '.profile.d'
$certBatDest = Join-Path $profileDir -ChildPath 'load_certstore.bat'
$certPs1Src = Join-Path $buildPackBinDir -ChildPath 'load_certstore.ps1'
$certPs1Dest = (Join-Path $depsDir -ChildPath $index | Join-Path -ChildPath 'load_certstore.ps1')
$certPs1Exe = "%~dp0\..\..\deps\$index\load_certstore.ps1"

# create batch file which will execute the powershell script in the dep/$idx dir
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
echo '@echo off' | Out-File -Encoding ASCII "$certBatDest"
echo "powershell.exe -ExecutionPolicy Unrestricted -File ""$certPs1Exe""" | Out-File -Append -Encoding ASCII "$certBatDest"

# copy the load_certstore.ps1 script to the dep/$idx dir
Copy-Item $certPs1Src -Destination $certPs1Dest