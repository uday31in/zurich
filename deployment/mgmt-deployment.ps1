function Invoke-AzDeployment {
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
    process {
        Get-ChildItem -Recurse -Path ./referenceImplementations/core/managementGroupTemplates/ -Filter *.json -Exclude *.gold.json, *.alpha.json  | % {
            $rootMgmtName = Get-AzManagementGroup -GroupName 'alpha' -ErrorVariable errorVariable -ErrorAction SilentlyContinue
            $managementGroupID = ($errorVariable) ? ((Get-AzContext).Tenant.Id) :($rootMgmtName)
            $parameterFile = (Join-Path $_.Directory.FullName -ChildPath ($_.BaseName + "." + $enviornment + $_.Extension))

            $parameters = @{
                'Name'                        = 'azops'
                'Location'                    = 'eastus'
                'ManagementGroupId'           = $managementGroupID
                'TemplateFile'                = $_.FullName
                'TemplateParameterFile'       = ((Test-Path $parameterFile) ? $parameterFile : "./emptyParameters.json")
                #'TemplateParameterObject'     = @{scope='alpha'}
                #'SkipTemplateParameterPrompt' = $true
            }
            $deploymentCommand = 'New-AzManagementGroupDeployment'
            New-AzManagementGroupDeployment @parameters
        }
    }
}
