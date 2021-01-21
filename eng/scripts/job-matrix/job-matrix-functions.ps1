Set-StrictMode -Version "4.0"

class MatrixConfig {
    [PSCustomObject]$displayNames
    [Hashtable]$displayNamesLookup
    [PSCustomObject]$matrix
    [System.Collections.Specialized.OrderedDictionary]$orderedMatrix
    [Array]$include
    [Array]$exclude
}

function CreateDisplayName([string]$parameter, [Hashtable]$displayNames)
{
    $name = $parameter

    if ($displayNames.ContainsKey($parameter)) {
        $name = $displayNames[$parameter]
    }

    # Matrix naming restrictions:
    # https://docs.microsoft.com/en-us/azure/devops/pipelines/process/phases?view=azure-devops&tabs=yaml#multi-job-configuration
    $name = $name -replace "^[^A-Za-z]*", ""  # strip leading digits
    $name = $name -replace "[^A-Za-z0-9_]", ""
    return $name
}

function GenerateMatrix(
    [MatrixConfig]$config,
    [string]$selectFromMatrixType,
    [string]$displayNameFilter = ".*",
    [array]$filters = @()
) {
    if ($selectFromMatrixType -eq "sparse") {
        [Array]$matrix = GenerateSparseMatrix $config.orderedMatrix $config.displayNamesLookup
    } elseif ($selectFromMatrixType -eq "all") {
        [Array]$matrix = GenerateFullMatrix $config.orderedMatrix $config.displayNamesLookup
    } else {
        throw "Matrix generator not implemented for selectFromMatrixType: $($platform.selectFromMatrixType)"
    }

    if ($config.exclude) {
        [Array]$matrix = ProcessExcludes $matrix $config.exclude
    }
    if ($config.include) {
        [Array]$matrix = ProcessIncludes $matrix $config.include $config.displayNamesLookup
    }

    [Array]$matrix = FilterMatrixDisplayName $matrix $displayNameFilter
    [Array]$matrix = FilterMatrix $matrix $filters
    return $matrix
}

function FilterMatrixDisplayName([array]$matrix, [string]$filter) {
    return $matrix | ForEach-Object {
        if ($_.Name -match $filter) {
            return $_
        }
    }
}

# Filters take the format of key=valueregex,key2=valueregex2
function FilterMatrix([array]$matrix, [array]$filters) {
    $matrix = $matrix | ForEach-Object {
        if (MatchesFilters $_ $filters) {
            return $_
        }
    }
    return $matrix
}

function MatchesFilters([hashtable]$entry, [array]$filters) {
    $nonMatching = $filters | Where-Object { $null -ne $_ } | ForEach-Object {
        $key, $regex, $excludeKey = ParseFilter $_
        if ($excludeKey) {
            if (-not $entry.parameters.Contains($key)) {
                return
            }
            return $false
        }
        if ($entry.parameters.Contains($key) -and $entry.parameters[$key] -match $regex) {
            return
        }
        return $false
    }

    return $null -eq $nonMatching
}

function ParseFilter([string]$filter) {
    if ($filter -match "\!(.*)") {
        return $matches[1], "", $true
    } elseif ($filter -match "(.*?)=(.*)") {
        $key = $matches[1]
        $regex = $matches[2]
        return $key, $regex, $false
    } else {
        throw "Invalid filter: `"${filter}`", expected !<key> or <key>=<regex> format"
    }
}

# Importing the JSON as PSCustomObject preserves key ordering,
# whereas ConvertFrom-Json -AsHashtable does not
function GetMatrixConfigFromJson($jsonConfig)
{
    [MatrixConfig]$config = $jsonConfig | ConvertFrom-Json
    $config.orderedMatrix = [ordered]@{}
    $config.displayNamesLookup = @{}

    if ($null -ne $config.matrix) {
        $config.matrix.PSObject.Properties | ForEach-Object {
            $config.orderedMatrix.Add($_.Name, $_.Value)
        }
    }
    if ($null -ne $config.displayNames) {
        $config.displayNames.PSObject.Properties | ForEach-Object {
            $config.displayNamesLookup.Add($_.Name, $_.Value)
        }
    }
    $config.include = $config.include | Where-Object { $null -ne $_ } | ForEach-Object {
        $ordered = [ordered]@{}
        $_.PSObject.Properties | ForEach-Object {
            $ordered.Add($_.Name, $_.Value)
        }
        return $ordered
    }
    $config.exclude = $config.exclude | Where-Object { $null -ne $_ } | ForEach-Object {
        $ordered = [ordered]@{}
        $_.PSObject.Properties | ForEach-Object {
            $ordered.Add($_.Name, $_.Value)
        }
        return $ordered
    }

    return $config
}

function ProcessExcludes([Array]$matrix, [Array]$excludes)
{
    $deleteKey = "%DELETE%"
    $exclusionMatrix = @()

    foreach ($exclusion in $excludes) {
        $converted = ConvertToMatrixArrayFormat $exclusion
        $full = GenerateFullMatrix $converted
        $exclusionMatrix += $full
    }

    foreach ($element in $matrix) {
        foreach ($exclusion in $exclusionMatrix) {
            $match = MatrixElementMatch $element.parameters $exclusion.parameters
            if ($match) {
                $element.parameters[$deleteKey] = $true
            }
        }
    }

    return $matrix | Where-Object { !$_.parameters.Contains($deleteKey) }
}

function ProcessIncludes([Array]$matrix, [Array]$includes, [Hashtable]$displayNames)
{
    foreach ($inclusion in $includes) {
        $converted = ConvertToMatrixArrayFormat $inclusion
        $full = GenerateFullMatrix $converted $displayNames
        $matrix += $full
    }

    return $matrix
}

function MatrixElementMatch([System.Collections.Specialized.OrderedDictionary]$source, [System.Collections.Specialized.OrderedDictionary]$target)
{
    if ($target.Count -eq 0) {
        return $false
    }

    foreach ($key in $target.Keys) {
        if (-not $source.Contains($key) -or $source[$key] -ne $target[$key]) {
            return $false
        }
    }

    return $true
}

function ConvertToMatrixArrayFormat([System.Collections.Specialized.OrderedDictionary]$matrix)
{
    $converted = [Ordered]@{}

    foreach ($key in $matrix.Keys) {
        if ($matrix[$key] -isnot [Array]) {
            $converted[$key] = ,$matrix[$key]
        } else {
            $converted[$key] = $matrix[$key]
        }
    }

    return $converted
}

function SerializePipelineMatrix([Array]$matrix)
{
    $pipelineMatrix = [Ordered]@{}
    foreach ($entry in $matrix) {
        $pipelineMatrix.Add($entry.name, [Ordered]@{})
        foreach ($key in $entry.parameters.Keys) {
            $pipelineMatrix[$entry.name].Add($key, $entry.parameters[$key])
        }
    }

    return @{
        compressed = $pipelineMatrix | ConvertTo-Json -Compress ;
        pretty = $pipelineMatrix | ConvertTo-Json;
    }
}

function GenerateSparseMatrix([System.Collections.Specialized.OrderedDictionary]$parameters, [Hashtable]$displayNames)
{
    [Array]$dimensions = GetMatrixDimensions $parameters
    $size = ($dimensions | Measure-Object -Maximum).Maximum

    [Array]$matrix = GenerateFullMatrix $parameters $displayNames
    $sparseMatrix = @()

    # With full matrix, retrieve items by doing diagonal lookups across the matrix N times.
    # For example, given a matrix with dimensions 3, 2, 2:
    # 0, 0, 0
    # 1, 1, 1
    # 2, 2, 2
    # 3, 0, 0 <- 3, 3, 3 wraps to 3, 0, 0 given the dimensions
    for ($i = 0; $i -lt $size; $i++) {
        $idx = @()
        for ($j = 0; $j -lt $dimensions.Length; $j++) {
            $idx += $i % $dimensions[$j]
        }
        $sparseMatrix += GetNdMatrixElement $idx $matrix $dimensions
    }

    return $sparseMatrix
}

function GenerateFullMatrix([System.Collections.Specialized.OrderedDictionary] $parameters, [Hashtable]$displayNames = @{})
{
    $parameterArray = $parameters.GetEnumerator() | ForEach-Object { $_ }

    $matrix = [System.Collections.ArrayList]::new()
    InitializeMatrix $parameterArray $displayNames $matrix

    return $matrix.ToArray()
}

function CreateMatrixEntry([System.Collections.Specialized.OrderedDictionary]$permutation, [Hashtable]$displayNames = @{})
{
    $names = @()
    foreach ($key in $permutation.Keys) {
        $nameSegment = CreateDisplayName $permutation[$key] $displayNames
        if ($nameSegment) {
            $names += $nameSegment
        }
    }
    # The maximum allowed matrix name length is 100 characters
    $name = $names -join "_"
    if ($name.Length -gt 100) {
        $name = $name[0..99] -join ""
    }
    return @{
        name = $name
        parameters = $permutation
    }
}

function InitializeMatrix
{
    param(
        [Array]$parameters,
        [Hashtable]$displayNames,
        [System.Collections.ArrayList]$permutations,
        $permutation = [Ordered]@{}
    )

    if (!$parameters) {
        $entry = CreateMatrixEntry $permutation $displayNames
        $permutations.Add($entry) | Out-Null
        return
    }

    $head, $tail = $parameters
    foreach ($value in $head.value) {
        $newPermutation = [Ordered]@{}
        foreach ($element in $permutation.GetEnumerator()) {
            $newPermutation[$element.Name] = $element.Value
        }
        $newPermutation[$head.name] = $value
        InitializeMatrix $tail $displayNames $permutations $newPermutation
    }
}

function GetMatrixDimensions([System.Collections.Specialized.OrderedDictionary]$parameters)
{
    $dimensions = @()
    foreach ($val in $parameters.Values) {
        $dimensions += $val.Length
    }

    return $dimensions
}

function SetNdMatrixElement
{
    param(
        $element,
        [ValidateNotNullOrEmpty()]
        [Array]$idx,
        [ValidateNotNullOrEmpty()]
        [Array]$matrix,
        [ValidateNotNullOrEmpty()]
        [Array]$dimensions
    )

    if ($idx.Length -ne $dimensions.Length) {
        throw "Matrix index query $($idx.Length) must be the same length as its dimensions $($dimensions.Length)"
    }

    $arrayIndex = GetNdMatrixArrayIndex $idx $dimensions
    $matrix[$arrayIndex] = $element
}

function GetNdMatrixArrayIndex
{
    param(
        [ValidateNotNullOrEmpty()]
        [Array]$idx,
        [ValidateNotNullOrEmpty()]
        [Array]$dimensions
    )

    if ($idx.Length -ne $dimensions.Length) {
        throw "Matrix index query length ($($idx.Length)) must be the same as dimension length ($($dimensions.Length))"
    }

    $stride = 1
    # Commented out does lookup with wrap handling
    # $index = $idx[$idx.Length-1] % $dimensions[$idx.Length-1]
    $index = $idx[$idx.Length-1]

    for ($i = $dimensions.Length-1; $i -ge 1; $i--) {
        $stride *= $dimensions[$i]
        # Commented out does lookup with wrap handling
        # $index += ($idx[$i-1] % $dimensions[$i-1]) * $stride
        $index += $idx[$i-1] * $stride
    }

    return $index
}

function GetNdMatrixElement
{
    param(
        [ValidateNotNullOrEmpty()]
        [Array]$idx,
        [ValidateNotNullOrEmpty()]
        [Array]$matrix,
        [ValidateNotNullOrEmpty()]
        [Array]$dimensions
    )

    $arrayIndex = GetNdMatrixArrayIndex $idx $dimensions
    return $matrix[$arrayIndex]
}

function GetNdMatrixIndex
{
    param(
        [int]$index,
        [ValidateNotNullOrEmpty()]
        [Array]$dimensions
    )

    $matrixIndex = @()
    $stride = 1

    for ($i = $dimensions.Length-1; $i -ge 1; $i--) {
        $stride *= $dimensions[$i]
        $page = [math]::floor($index / $stride) % $dimensions[$i-1]
        $matrixIndex = ,$page + $matrixIndex
    }
    $col = $index % $dimensions[$dimensions.Length-1]
    $matrixIndex += $col

    return $matrixIndex
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The below functions are non-dynamic examples that   #
# help explain the above N-dimensional algorithm      #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #
function Get4dMatrixElement([Array]$idx, [Array]$matrix, [Array]$dimensions)
{
    $stride1 = $idx[0] * $dimensions[1] * $dimensions[2] * $dimensions[3]
    $stride2 = $idx[1] * $dimensions[2] * $dimensions[3]
    $stride3 = $idx[2] * $dimensions[3]
    $stride4 = $idx[3]

    return $matrix[$stride1 + $stride2 + $stride3 + $stride4]
}

function Get4dMatrixIndex([int]$index, [Array]$dimensions)
{
    $stride1 = $dimensions[3]
    $stride2 = $dimensions[2]
    $stride3 = $dimensions[1]
    $page1 = [math]::floor($index / $stride1) % $dimensions[2]
    $page2 = [math]::floor($index / ($stride1 * $stride2)) % $dimensions[1]
    $page3 = [math]::floor($index / ($stride1 * $stride2 * $stride3)) % $dimensions[0]
    $remainder = $index % $dimensions[3]

    return @($page3, $page2, $page1, $remainder)
}

