<#
    .SYNOPSIS
        Generates a JSON object representing an Azure Pipelines Job Matrix.
        See https://docs.microsoft.com/en-us/azure/devops/pipelines/process/phases?view=azure-devops&tabs=yaml#parallelexec

    .EXAMPLE
    .\eng\scripts\Create-JobMatrix $context
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)][object] $Parameters,
    [Parameter(Mandatory=$True)][object] $Variables
)

. $PSScriptRoot/functions.ps1

$serializedMatrix = GenerateSerializedMatrix($Parameters, $Variables)

Write-Output "##vso[task.setVariable variable=matrix;isOutput=true]$serializedMatrix"
