# OctopusStepGenerator
Generate Octopus Deploy step templates from PowerShell DSC resources

Supported parameter types:

 - [string]
 - [int]
 - [boolean]
 - array (in Octopus use a comma separated list like so: "Value1","Value2")

Supported parameter attributes:

- [Parameter(Mandatory)]
- [ValidateNotNullOrEmpty]
- [ValidateSet("a","b","c")]

Bootstrap code is added at the end of the module that puts all the Octopus Deploy parameters in a hastable and uses splatting to call the function in your module:

    ---- Auto generated bootstrap by OctopusStepGenerator
	$FunctionParameters = @{}
	if($OctopusParameters['MandatoryString'] -ne $null){$FunctionParameters.Add('MandatoryString', $OctopusParameters['MandatoryString'])}
	if($OctopusParameters['DefaultValueArrOfStrings'] -ne $null){$FunctionParameters.Add('DefaultValueArrOfStrings', $($OctopusParameters['DefaultValueArrOfStrings'] -split ','))}
	if($OctopusParameters['BooleanParameter'] -ne $null){$FunctionParameters.Add('BooleanParameter', [System.Convert]::ToBoolean($OctopusParameters['BooleanParameter']))}
	if($OctopusParameters['IntegerParameter'] -ne $null){$FunctionParameters.Add('IntegerParameter', [System.Convert]::ToInt32($OctopusParameters['IntegerParameter']))}
	Set-TargetResource @FunctionParameters

## TODO

 1. Improve test module
 2. Better help text for the parameters
 2. Complex parameter types don't work (credentials and etc.)