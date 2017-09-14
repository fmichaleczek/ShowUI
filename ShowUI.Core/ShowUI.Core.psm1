#region Assemblies

$OutputPathBase = "$PSScriptRoot\Assemblies"
if (-not (Test-Path $OutputPathBase)) {
    New-Item $OutputPathBase -ItemType "Directory" -Force | Out-Null
}

$CoreSourceCodePath  =  "$OutputPathBase\ShowUI.Core.cs"
$CoreOutputPath = "$OutputPathBase\ShowUI.Core.dll"

if ( -not (Test-Path $CoreOutputPath) ) {

	Write-Verbose "Compiling Core Features"
	
	# Source
	$controlNameDependencyObject = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\ShowUIDependencyObjects.cs")
	$cmdCode = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\ShowUICommand.cs")
	$ValueConverter = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\LanguagePrimitivesValueConverter.cs")
	$wpfJob = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\WPFJob.cs")
	$PowerShellDataSource = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\PowerShellDataSource.cs")
	$GetReferencedCommandSource = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\GetReferencedCommand.cs")
	$ScriptBlockBindingAttributeSource = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\ScriptBlockBindingAttribute.cs")
	$OutXamlCmdlet = [IO.File]::ReadAllText("$PSScriptRoot\Source\CSharp\OutXaml.cs")

	# Output
	$generatedCode = @"
$controlNameDependencyObject
$cmdCode
$ValueConverter
$wpfJob 
$PowerShellDataSource
$GetReferencedCommandSource
$ScriptBlockBindingAttributeSource
$OutXamlCmdlet

"@

	try {
		# For debugging purposes, try to put the code in the module.  
		# The module could be run from CD or a filesystem without write access, 
		# so redirect errors into the Debug channel.
		[IO.File]::WriteAllText($CoreSourceCodePath, $generatedCode)
	} 
	catch {
		$_ | Out-String | Write-Debug
	}
	
	try {
        $Assemblies = 
        [Reflection.Assembly]::Load("WindowsBase, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
        [Reflection.Assembly]::Load("PresentationFramework, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
        [Reflection.Assembly]::Load("PresentationCore, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
        [Reflection.Assembly]::Load("WindowsFormsIntegration, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")

        if ($PSVersionTable.ClrVersion.Major -ge 4) {
            $Assemblies += [Reflection.Assembly]::Load("System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
        }
    } 
	catch {
        throw $_
    }
	
	$RequiredAssemblies = $Assemblies + @("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	if ($PSVersionTable.ClrVersion.Major -ge 4) {
		$RequiredAssemblies += "System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
		$RequiredAssemblies += [PSObject].Assembly.Fullname
	}

	$AddTypeParameters = @{
		TypeDefinition = $generatedCode
		IgnoreWarnings = $true
		ReferencedAssemblies = Get-AssemblyName -RequiredAssemblies $RequiredAssemblies -ExcludedAssemblies "MSCorLib","System"
	}
	
	# Check to see if the outputpath can be written to: we don't *have* to save it as a dll
	if (Set-Content "$OutputPathBase\test.write" -Value "1" -ErrorAction SilentlyContinue -PassThru) {
		Remove-Item "$OutputPathBase\test.write" -ErrorAction SilentlyContinue
		$AddTypeParameters.OutputAssembly = $CoreOutputPath
	}

	Write-Verbose "Type Parameters:`n$($addTypeParameters | Out-String)"
	Add-Type @addTypeParameters
}

Add-Type -Path $CoreOutputPath

## Fix xaml Serialization 
[ShowUI.XamlTricks]::FixSerialization()

#endregion Assemblies





#region Functions

$FunctionRoot = "$PSScriptRoot\Functions"

$PublicFunction  = @( Get-ChildItem -Path "$FunctionRoot\Public"  -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunction = @( Get-ChildItem -Path "$FunctionRoot\Private" -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue )

foreach ($Function in @($PublicFunction + $PrivateFunction)) {
    try {
		# Dot source the function
        . $Function.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Function.FullName): $_"
    }
}

#endregion Functions


Export-ModuleMember -Function $PublicFunction.Basename -Alias *