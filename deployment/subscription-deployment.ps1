<# function Invoke-AzDeployment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DeploymentName = "azops-template-deployment",

        [string]
        $Mode = "Incremental",

        [string]
        $enviornment = "alpha"
    )
    process { #>
        $enviornment = "alpha"
        Get-ChildItem -Recurse -Path ./referenceImplementations/core/subscriptionTemplates -Filter *.json -Exclude *.gold.json, *.alpha.json  | % {
            $parameterFile = (Join-Path $_.Directory.FullName -ChildPath ($_.BaseName + ".parameters." + $enviornment + $_.Extension))

            $parameters = @{
                'Name'                        = 'azops'
                'Location'                    = 'eastus'
                'TemplateFile'                = $_.FullName
                'TemplateParameterFile'       = ((Test-Path $parameterFile) ? $parameterFile : "./emptyParameters.json")
                'SkipTemplateParameterPrompt' = $true
            }
            $deploymentCommand = 'New-AzSubscriptionDeployment'
            New-AzSubscriptionDeployment @parameters -WhatIf
        }
<#     }
}
 #>