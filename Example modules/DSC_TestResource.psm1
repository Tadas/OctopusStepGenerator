function Set-TargetResource{
	Param(
        [Parameter(Mandatory)]
        [string]$MandatoryString,
        [Parameter(Mandatory = $true)]
        [string]$MandatoryEqTrueString,


        [string]$DefaultValueString = "autoexec.bat",
        [Int]$DefaultValueInt = 13,
        [string]$DefaultValueVar = $DefaultValueString,
        [string[]]$DefaultValueArrOfOne = ("One Item"),
        [string[]]$DefaultValueArrOfStrings = ("Item1", "Item2"),
        [Int[]]$DefaultValueArrOfInts = (1, 2),

        [ValidateNotNullOrEmpty()]
        [string]$ValidateNotNullOrEmpty,

        [ValidateSet("Present", "Absent")]
        [String]$ValidateSetString = "Present",
        [ValidateSet("Any", "Domain", "Private", "Public")]
        [String[]]$ValidateSetStringArray = ("Domain"),

        [ValidateSet(1, 2, 3, 4, 5, 6)]
        [Int]$ValidateSetInt = 1,
        [ValidateSet(1, 2, 3, 4, 5, 6)]
        [Int[]]$ValidateSetIntArray = (1,2,3),

        [bool]$BooleanParameter,
        [int]$IntegerParameter
    )

    # Basic comment, hello
    # Here is a // JS comment
    if ($MandatoryString -eq $null)       { Write-Error "`$MandatoryString is `$null" } else { Write-Output "`$MandatoryString = $MandatoryString" }
    if ($MandatoryEqTrueString -eq $null) { Write-Error "`$MandatoryEqTrueString is `$null" } else { Write-Output "`$MandatoryEqTrueString = $MandatoryEqTrueString" }

    if ($DefaultValueString -ne "autoexec.bat") { Write-Error "`$DefaultValueString is not autoexec.bat" } else { Write-Output "`$DefaultValueString = $DefaultValueString" }
    if ($DefaultValueInt -ne 13) { Write-Error "`$DefaultValueString is not autoexec.bat" } else { Write-Output "`$DefaultValueInt = $DefaultValueInt" }

    # When the default value is a variable just make it a string. Not the best solution
    if ($DefaultValueVar -ne "`$DefaultValueString") { Write-Error "`$DefaultValueVar is not `$DefaultValueString" } else { Write-Output "`$DefaultValueString = $DefaultValueString" }

    if (($DefaultValueArrOfOne.GetType().ToString() -ne "System.String[]") -or ($DefaultValueArrOfOne[0] -ne "One Item")) {
        Write-Error "`$DefaultValueArrOfOne type not System.String[] or `$DefaultValueArrOfOne[0] not `"One Item`""
    } else { Write-Output "`$DefaultValueArrOfOne = $DefaultValueArrOfOne" }

    if (($DefaultValueArrOfStrings.GetType().ToString() -ne "System.String[]") -or `
        ($DefaultValueArrOfStrings.Count -ne 2) -or `
        ($DefaultValueArrOfStrings[0] -ne "Item1") -or `
        ($DefaultValueArrOfStrings[1] -ne "Item2"))
    {
        Write-Error "`$DefaultValueArrOfStrings type not System.String[] or `$DefaultValueArrOfStrings.Count not 2 or `$DefaultValueArrOfStrings values are wrong"
    } else { Write-Output "`$DefaultValueArrOfStrings = $DefaultValueArrOfStrings" }

    if (($DefaultValueArrOfInts.GetType().ToString() -ne "System.Int32[]") -or `
        ($DefaultValueArrOfInts.Count -ne 2) -or `
        ($DefaultValueArrOfInts[0] -ne 1) -or `
        ($DefaultValueArrOfInts[1] -ne 2))
    {
        Write-Error "`$DefaultValueArrOfInts type not System.Int32[] or `$DefaultValueArrOfInts.Count not 2 or `$DefaultValueArrOfInts values are wrong"
    } else { Write-Output "`$DefaultValueArrOfInts = $DefaultValueArrOfInts" }

    Write-Test
}

export-modulemember -Function *-TargetResources

function Write-Test{
    Param(
        [ValidateNotNullOrEmpty()]
        [String]$Protocol
    )
    Write-Output "Hello from Write-Test!"
}

Export-ModuleMember -Function *-TargetResource