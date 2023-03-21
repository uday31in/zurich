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

        Get-ChildItem -Recurse -Path ./referenceImplementations/core/managementGroupTemplates/policyAssignments -Filter *.json -Exclude *.gold.json, *.alpha.json  | % {

            Write-Warning "Processing Deployment: $_"

            $rootMgmtName = Get-AzManagementGroup -GroupName $enviornment -ErrorVariable errorVariable -ErrorAction SilentlyContinue -WarningAction:SilentlyContinue
            $managementGroupID = ($errorVariable) ? ((Get-AzContext).Tenant.Id) :($rootMgmtName).Name
            $parameterFile = (Join-Path $_.Directory.FullName -ChildPath ($_.BaseName + ".parameters." + $enviornment + $_.Extension))
            $deploymentName = ('azops-' + $_.BaseName)
            if ($deploymentName.Length -gt 53) { $deploymentName = $deploymentName.SubString(0, 53) }

            $parameters = @{
                'Name'                        = $deploymentName
                'Location'                    = 'eastus'
                'ManagementGroupId'           = $managementGroupID
                'TemplateFile'                = $_.FullName
                'TemplateParameterFile'       = ((Test-Path $parameterFile) ? $parameterFile : "./emptyParameters.json")
                #'TemplateParameterObject'     = @{scope='alpha'}
                'SkipTemplateParameterPrompt' = $true
            }
            $deploymentCommand = 'New-AzManagementGroupDeployment'
            New-AzManagementGroupDeployment @parameters
        }
    }
}
#Invoke-AzDeployment
