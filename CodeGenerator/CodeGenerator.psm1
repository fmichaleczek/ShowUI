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

Export-ModuleMember -Function $PublicFunction.Basename -Alias *