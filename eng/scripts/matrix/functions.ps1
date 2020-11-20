function GenerateMatrix($Parameters, $Variables) {
    $bbpDebug = $true
    if ($bbpDebug) {
        return @{
            JobA = @{
                TestVariable = "var a"
            };
            JobB = @{
                TestVariable = "var b"
            }
        }
    }

    $matrix = @{}

    foreach ($key in $Variables.Keys) {
        $matrix[$key] = "KEY"
    }

    foreach ($key in $Parameters.Keys) {
        $matrix[$key] = "KEY"
    }

    return $matrix
}

function GenerateSerializedMatrix($Parameters, $Variables) {
    $matrix = GenerateMatrix($Parameters, $Variables)
    $serializedMatrix = $matrix | ConvertTo-Json -Compress
    return $serializedMatrix
}
