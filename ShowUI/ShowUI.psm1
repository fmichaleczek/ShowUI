
$ShowUIModuleRoot = (Get-Variable PSScriptRoot).Value

#region Assembly Loading

$Assemblies = @(
	[Reflection.Assembly]::Load("WindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
	[Reflection.Assembly]::Load("PresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
	[Reflection.Assembly]::Load("PresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
	[Reflection.Assembly]::Load("WindowsFormsIntegration, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"),
	[Reflection.Assembly]::Load("System.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
)

try {
    $Assemblies += [Reflection.Assembly]::Load("System.Windows.Controls.Ribbon, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
} 
catch {}

#endregion


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



#region Alias

## Generate aliases for all the New-* cmdlets
## Ideally, with the module name on it: ShowUI\New-Whatever

[String]$ModulePath = $ExecutionContext.SessionState.Module.Name + "\"

if($ModulePath.Length -le 1) { 
	$ModulePath = "" 
}

$importedCommands = @()
foreach($m in @($importedModule)) {
    $importedCommands += $m.ExportedCommands.Values
    foreach($ta in $importedCommands | Where-Object { $_.Verb -eq 'New' }) {
        Set-Alias -Name $ta.Noun -Value "$ModulePath$ta"
    }
}

#endregion Alias



#region Styles
$script:UIStyles = @{}

if (-not (Test-Path "$PSScriptRoot\Styles\*")) {

    Set-UIStyle -StyleName "Hyperlink" -Style @{
        Resource = @{
                AllowedSchemes = 'http','https'
            }
            Foreground = 'DarkBlue'
            TextDecorations = { 
                 [Windows.TextDecorations]::Underline
            }
            On_PreviewMouseDown = {
                if ($this.Resources.Url) {
                    $realUrl = [Uri]$this.Resources.Url
                    $allowedSchemes = $this.Resources.AllowedSchemes
                    if (-not $allowedSchemes) { $allowedSchemes = 'http', 'https' }
                    if ($allowSchemes -contains $realUrl.Scheme) {
                        Start-Process -FilePath $realUrl 
                    }
                }
            }
    }

    Set-UIStyle -StyleName Bold -Style @{
        FontWeight = 'Bold'
    }

    Set-UIStyle -StyleName BoldItalic -Style @{
        FontWeight = 'Bold'
        FontStyle = 'Italic'
    }

    Set-UIStyle -StyleName SmallText -Style @{
        FontSize = 9
    }

    Set-UIStyle -StyleName MediumText -Style @{
        FontSize = 14
    }

    Set-UIStyle -StyleName LargeText -Style @{
        FontSize = 18
    }

    Set-UIStyle -StyleName HugeText -Style @{
        FontSize = 32
    }

    Set-UIStyle -StyleName ErrorStyle -Style @{
        Foreground = 'DarkRed'
        TextDecorations = { [Windows.TextDecorations]::Underline }
    }

    Set-UIStyle -StyleName "CueText" -Style @{
        On_Loaded = {
            $this.Resources.OriginalText =  $this.Text
        }
        FontStyle = "Italic"
        Foreground = "DarkGray"
        On_GotFocus = {
            if ($this.Text -eq $OriginalText) {
                $this.Text = ""
            }
            $this.ClearValue([Windows.Controls.Control]::ForegroundProperty)
            $this.ClearValue([Windows.Controls.Control]::FontStyleProperty)
        }
        On_LostFocus = {
            if($this.Text -eq "") {
                $this.Text = $OriginalText   
            }
            if ($this.Text -eq $OriginalText) {
                $this.Foreground = "DarkGray"
                $this.FontStyle = "Italic"
            } 
			else {
                $this.ClearValue([Windows.Controls.Control]::ForegroundProperty)
                $this.ClearValue([Windows.Controls.Control]::FontStyleProperty)
            }
        }
    }
    
    Set-UIStyle -StyleName "Widget" -Style @{
        AllowsTransparency = $true
        WindowStyle = "None"
        Background = "Transparent"
        SizeToContent = "WidthAndHeight"
        ResizeMode = "NoResize"
    }
    
} 
else {
    Use-UiStyle "Current"
}

#endregion Styles



Export-ModuleMember -Cmdlet * -Function $PublicFunction.Basename -Alias *