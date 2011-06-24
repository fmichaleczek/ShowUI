﻿function Set-Property
{
    <#
    .Synopsis
        Sets properties on an object or subscribes to events
    .Description
        Set-Property is used by each parameter in the automatically generated
        controls in ShowUI.
    .Parameter InputObject
        The object to set properties on
    .Parameter Hashtable
        A Hashtable contains properties to set.
        The key is the name of the property on an object, or "On_" + the name 
        of an event you can subscribe to (i.e. On_Loaded).
        The value can either be a literal value (such as a string), a block of XAML,
        or a script block that produces the value that needs to be set.
    .Example
        $window = New-Window
        $window | Set-Property @{Width=100;Height={200}} 
        $window | show-Window
    #>
    param(    
    [Parameter(ValueFromPipeline=$true)]    
    $inputObject,
    [Parameter(Position=0)] 
    [Hashtable]$property,
    
    [switch]$AllowXaml,
    
    [switch]$doNotAutoCreateLabel,
    
    [Switch]$PassThru
    )
       
    process {    
                                
        $inAsJob  = $host.Name -eq 'Default Host'
        if ($inputObject.GetValue -and 
            ($inputObject.GetValue([ShowUI.ShowUISetting]::StyleNameProperty))) {
            # Since Set-Property will be called by Set-UIStyle, make sure to check the callstack
            # rather than infinitely recurse            
            $styleName = $inputObject.GetValue([ShowUI.ShowUISetting]::StyleNameProperty)
           

            if ($styleName) {
                $setUiStyleInCallStack = foreach ($_ in (Get-PSCallStack)) { 
                    if ($_.Command -eq 'Set-UIStyle') { $_ }
                }
                if (-not $setUiStyleInCallStack) {
                    Set-UIStyle -Visual $inputObject -StyleName $StyleName 
                }
            } 
        }
            
        if ($property) {
            $p = $property
            foreach ($k in $p.Keys) {

                $realKey = $k
                if ($k.StartsWith("On_")) {
                    $realKey = $k.Substring(3)
                }                

                if ($inputObject.GetType().GetEvent($realKey)) {
                    # It's an Event!
                    foreach ($sb in $p[$k]) {
                        Add-EventHandler $InputObject $realKey $sb
                    } 
                    continue
                }
                
                $realItem  = $inputObject.psObject.Members[$realKey]                 
                if (-not $realItem) { 
                    continue 
                }
                    
                $itemName = $realItem.Name
                if ($realItem.MemberType -eq 'Property') {                    
                    if ($realItem.Value -is [Collections.IList]) {                                                                                               
                        $v = $p[$realKey]
                        $collection = $inputObject.$itemName
                        if (-not $v) { continue } 
                        if ($v -is [ScriptBlock]) { 
                            if ($inAsJob) {                            
                                $v = . ([ScriptBlock]::Create($v))
                            } else {
                                $v = . $v
                            }
                        }                         
                        if (-not $v) { continue } 

                        foreach ($ri in $v) {                                                                
                            $null = $collection.Add($ri)
                            trap [Management.Automation.PSInvalidCastException] {
                                $label = New-Label $ri
                                $null = $collection.Add($label)
                                continue
                            }                        
                        }
                    } else {                                                                                                        
                        
                        $v = $p[$realKey]                            
                                                    
                        if ($v -is [ScriptBlock]) {
                            if ($inAsJob) {                            
                                $v = . ([ScriptBlock]::Create($v))
                            } else {
                                $v = . $v
                            }
                        }
                        
                        if ($allowXaml) {
                            $xaml = ConvertTo-Xaml $v
                            if ($xaml) {
                                try {                                            
                                    $rv = [Windows.Markup.XamlReader]::Parse($xaml)
                                    if ($rv) { $v = $rv } 
                                }
                                catch {
                                    Write-Debug ($_ | Out-String)
                                }
                            }
                        }
                                                
                        $inputObject.$itemName = $v                        
                    }                            
                } elseif ($realItem.MemberType -eq 'Method') {
                    $inputObject."$($itemName)".Invoke(@($p[$realKey]))
                }                    
            }
        }
        
        if ($passThru) {
            $inputObject
        }
    }
}