Set-Location -Path 'C:\PowerShell\Modules\ShowUI'
$env:PSModulePath += ";$pwd"

Import-Module ShowUI.Core 

Import-Module CodeGenerator.ShowUI -Force

Invoke-WPFCodeGeneration -Path "$pwd\ShowUI.WPF"

Import-Module ShowUI.WPF