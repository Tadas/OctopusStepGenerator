<#
    Takes a DSC resource module file as input and generates a ready to run OctopusDeploy Step Template
#>
Param(
	[string]$FileName = ".\Example modules\DSC_TestResource.psm1",
    [string]$FunctionName = "Set-TargetResource"
)


# Parses a parameter and adds it to the Step Template object
function Add-Parameter {
    Param(
        $ToStepTemplate,
        [System.Management.Automation.Language.ParameterAst]$Parameter
    )

    # Tests if named arguments array contains a certain argument (used to test if parameter is Mandatory)
    function Test-NamedArguments {
		Param(
			[System.Management.Automation.Language.NamedAttributeArgumentAst[]]$ArgumentList,
			[string]$Contains
		)
		foreach($NamedArgument in $ArgumentList){
			if($NamedArgument.ArgumentName -eq $Contains){
				return $true
			}
		}
		$false
	}

    # Returns an array of all positional arguments (used to generate the array of valid parameter values)
    function Get-PositionalArguments {
		Param(
			[Object[]]$Attribute
		)
		$Result = @()
		foreach($PositionalArgument in $Attribute){
			$Result += $PositionalArgument.Value
		}
		$Result
	}

    Write-Host "$($Parameter.Name.VariablePath.ToString())" -NoNewLine -Background Black -Foreground White

    # Ignore additional parameters added by PowerShell
    $PsAdditionalParameters = @("Verbose", "Debug", "ErrorAction", "WarningAction", "ErrorVariable", "WarningVariable",`
        "OutVariable", "OutBuffer", "PipelineVariable")
    if ($Parameter.Name.VariablePath.ToString() -in $PsAdditionalParameters) {
        Write-Host " (Default cmdlet parameter. Skipping) " -NoNewLine -Foreground Yellow
        return
    }


    $StepTemplateParameter = New-Object -TypeName PSObject
    $StepTemplateParameter | Add-Member -MemberType NoteProperty -Name Name -Value $Parameter.Name.VariablePath.ToString()
    $StepTemplateParameter | Add-Member -MemberType NoteProperty -Name Label -Value $Parameter.Name.VariablePath.ToString()
    $StepTemplateParameter | Add-Member -MemberType NoteProperty -Name HelpText -Value "PowerShell type: $($Parameter.StaticType.ToString())"
   
    
    # --- Parse default value for this parameter
    if($Parameter.DefaultValue -ne $null){
        switch($Parameter.DefaultValue.GetType().FullName){
            
            "System.Management.Automation.Language.StringConstantExpressionAst" { # Default value is a plain string
                $StepTemplateParameter | Add-Member -MemberType NoteProperty -Name DefaultValue -Value $Parameter.DefaultValue.Value.ToString()
            }

            "System.Management.Automation.Language.VariableExpressionAst" { # Default value is a variable
                $StepTemplateParameter | Add-Member -MemberType NoteProperty -Name DefaultValue -Value $Parameter.DefaultValue.ToString()
            }

        }
        Write-Host " (DefaultValue: $($StepTemplateParameter.DefaultValue))" -NoNewLine
    } else {
        # No default value
        $StepTemplateParameter | Add-Member -MemberType NoteProperty -Name DefaultValue -Value ""
    }
    

    # --- Parse the parameter attributes - validation sets, mandatory parameters and etc.
    foreach ($ParameterAttribute in $Parameter.Attributes){
        switch ($ParameterAttribute.TypeName.ToString()){
            "Parameter" {
                    if(Test-NamedArguments $ParameterAttribute.NamedArguments -Contains "Mandatory"){
                        Write-Host " (Mandatory)" -NoNewLine
                        $StepTemplateParameter.Label = "(MANDATORY) " + $StepTemplateParameter.Label
                    }
                }

            "ValidateSet" {
                    $ValidValues = Get-PositionalArguments $ParameterAttribute.PositionalArguments 

                    Write-Host " (ValidateSet: $($ValidValues -join ", "))" -NoNewLine
            
                    # Create the dropdown with possible values
                    $DisplaySettings = New-Object –TypeName PSObject –Prop (@{"Octopus.ControlType"=""; "Octopus.SelectOptions"= ""})
                    $StepTemplateParameter | Add-Member -MemberType NoteProperty -Name DisplaySettings -Value $DisplaySettings
                    $StepTemplateParameter.DisplaySettings."Octopus.ControlType" = "Select"
                    $StepTemplateParameter.DisplaySettings."Octopus.SelectOptions" = $($ValidValues -join "`n")
                }

            "ValidateNotNullOrEmpty" {
                    Write-Host " (Not null/empty)" -NoNewLine
                    $StepTemplateParameter.Label = "(Not null/empty) " + $StepTemplateParameter.Label
                }

            default {
                    # Unknown parameter attribute
                }
        }

    }
    
    # Add this parameter to the step template object
    $ToStepTemplate.Parameters += $StepTemplateParameter
}



# --- START
try {
    Write-Host "Loading target function $FunctionName from $FileName " -NoNewLine
        Import-Module $FileName
        $CommandInfo = Get-Command -Module ([System.IO.Path]::GetFileNameWithoutExtension($FileName)) -Name $FunctionName

        # Get everything in the script file. That way we avoid dependency problems
        $ScriptBody = (Get-Content $FileName -Raw).ToString()

        # Since this is a module we need to comment out all Export-ModuleMember calls because it will break when Octopus runs the script.
        $ScriptBody = $ScriptBody -ireplace "(Export-ModuleMember)", '#$1'
    Write-Host "☑" -ForegroundColor DarkGreen


    Write-Host "Creating step template " -NoNewLine
        $StepTemplate = New-Object -TypeName PSObject
        $StepTemplate | Add-Member -MemberType NoteProperty -Name Id -Value ([System.IO.Path]::GetFileNameWithoutExtension($FileName))
        $StepTemplate | Add-Member -MemberType NoteProperty -Name Name -Value "$([System.IO.Path]::GetFileNameWithoutExtension($FileName)) - $FunctionName"
        $StepTemplate | Add-Member -MemberType NoteProperty -Name Description -Value "Automatically generated from $FileName, function $FunctionName by OctopusStepGenerator"
        $StepTemplate | Add-Member -MemberType NoteProperty -Name ActionType -Value "Octopus.Script"
        $StepTemplate | Add-Member -MemberType NoteProperty -Name Version -Value 1
        $StepTemplate | Add-Member -MemberType NoteProperty -Name Properties -Value @{"Octopus.Action.Script.ScriptBody" = $ScriptBody}
        $StepTemplate | Add-Member -MemberType NoteProperty -Name SensitiveProperties -Value @{}
        $StepTemplate | Add-Member -MemberType NoteProperty -Name Parameters -Value @()
        $StepTemplate | Add-Member -MemberType NoteProperty -Name LastModifiedOn -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffzzz")
        $StepTemplate | Add-Member -MemberType NoteProperty -Name LastModifiedBy -Value "unknown"
        $StepTemplate | Add-Member -MemberType NoteProperty -Name `$Meta -Value @{"Type" = "ActionTemplate"}
    Write-Host "☑" -ForegroundColor DarkGreen


    Write-Host "Adding parameters"
        foreach($Parameter in $CommandInfo.ScriptBlock.Ast.Body.ParamBlock.Parameters){
            Write-Host "`tParameter " -NoNewLine
                Add-Parameter -ToStepTemplate $StepTemplate $Parameter
            Write-Host "☑" -ForegroundColor DarkGreen
        }
    Write-Host "☑" -ForegroundColor DarkGreen
    

    Write-Host "Adding bootstrap code " -NoNewLine
        <#
            Genereates and adds code to call the target function when running in the Octopus Tentacle.
            We're creating a hastable of parameters (skipping not provided parameters) and then using splatting
            to call the target function using our parameter hastable.

            Generated code looks like this:
                $FunctionParameters = @{}
                if($OctopusParameters['Name'] -ne $null){$FunctionParameters.Add('Name', $OctopusParameters['Name'])}
                if($OctopusParameters['Service'] -ne $null){$FunctionParameters.Add('Service', $OctopusParameters['Service'])}
                ... other remaining parameters...
                Set-TargetResource @FunctionParameters
        #>

        $BootstrapScript = "`r`n`r`n#---- Auto generated boothstrap by OctopusStepGenerator`r`n`$FunctionParameters = @{}`r`n"
        foreach ($StepParameter in $StepTemplate.Parameters){
            $BootstrapScript += "if(`$OctopusParameters['$($StepParameter.Name)'] -ne `$null){`$FunctionParameters.Add('$($StepParameter.Name)', `$OctopusParameters['$($StepParameter.Name)'])}`r`n"
        }
        $BootstrapScript += "$FunctionName @FunctionParameters"
        
        $StepTemplate.Properties."Octopus.Action.Script.ScriptBody" += $BootstrapScript

    Write-Host "☑" -ForegroundColor DarkGreen


    Write-Host "Writing JSON to clipboard " -NoNewline
        [Windows.Forms.Clipboard]::SetText($(ConvertTo-Json $StepTemplate -Depth 10))
    Write-Host "☑" -ForegroundColor DarkGreen

} finally {
    Remove-Module ([System.IO.Path]::GetFileNameWithoutExtension($FileName)) -ErrorAction SilentlyContinue
}