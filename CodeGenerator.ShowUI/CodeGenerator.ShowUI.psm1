$CGShowUIModuleRoot = (Get-Variable PSScriptRoot).Value

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