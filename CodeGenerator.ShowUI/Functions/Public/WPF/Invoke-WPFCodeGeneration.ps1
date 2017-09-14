function Invoke-WPFCodeGeneration {
	[CmdletBinding()]
	param(
	    [Parameter(ParameterSetName='Path', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('OutputPath')]
        [string]
        $Path
	)
	
	#region Rules

	. "$CGShowUIModuleRoot\Rules\WPFCodeGenerationRules.ps1"

	#endregion


	#region Generator
	
	$progressId = Get-Random
	$childId = Get-Random    

	Write-Progress "Preparing Show-UI for First Time Use" "Please Wait" -Id $progressId 

	Write-Progress "Compiling Core Features" " " -ParentId $progressId -Id $childId

	Write-Verbose "Generating Commands From Assemblies:`n$($Assemblies | Format-Table @{name="Version";expr={$_.ImageRuntimeVersion}}, FullName -auto | Out-String)"

	try {
		$Assemblies = 
		[Reflection.Assembly]::Load("WindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
		[Reflection.Assembly]::Load("PresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
		[Reflection.Assembly]::Load("PresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
		[Reflection.Assembly]::Load("WindowsFormsIntegration, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
		[Reflection.Assembly]::Load("System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
		try {
			$Assemblies += [Reflection.Assembly]::Load("System.Windows.Controls.Ribbon, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
		} catch {}
	} 
	catch {
		throw $_
	}

	$RequiredAssemblies = $Assemblies + @("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	$RequiredAssemblies += "System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
	$RequiredAssemblies += [PSObject].Assembly.Fullname

	$WPFModuleArgs = @{
		Name = $Path
		AssemblyName = $Assemblies 
		RequiredAssemblies = $RequiredAssemblies 
		ProgressParentId = $progressId 
		ProgressId = $ChildId
	}

	Add-WPFModule @WPFModuleArgs

	#endregion Generator

}