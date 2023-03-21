function Invoke-AzDeployment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DeploymentName = "azops-template-deployment",

        [string]
        $Mode = "Incremental",

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $enviornment = "alpha",

        [string]
        $location = "eastus",

        [string]
        $path = "./referenceImplementations/core/",

        [Parameter(ParameterSetName = "subscription", Mandatory = $true, ValueFromPipeline = $true)]
        [switch]$subscription,

        [Parameter(ParameterSetName = "subscription", Mandatory = $true, ValueFromPipeline = $true)]
        [string]$subscriptionId,

        [Parameter(ParameterSetName = "managementGroup", Mandatory = $true, ValueFromPipeline = $true)]
        [switch]$managementGroup,

        [Parameter(ParameterSetName = "managementGroup", Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ManagementGroupId
    )
    process {
        Get-ChildItem -Recurse -Path $path -Filter *.json -Exclude *.gold.json, *.alpha.json  | % {

            Write-Warning "Processing Deployment: $_"

            $parameterFile = (Join-Path $_.Directory.FullName -ChildPath ($_.BaseName + ".parameters." + $enviornment + $_.Extension))
            $templateParameterFile = ((Test-Path $parameterFile) ? $parameterFile : "./emptyParameters.json")
            $deploymentName = ($deploymentName) ? $deploymentName : ('azops-' + $_.BaseName)
            if ($deploymentName.Length -gt 53) { $deploymentName = $deploymentName.SubString(0, 53) }

            if ($subscription) {

                Set-AzContext -Subscription $subscriptionId

                $parameters = @{
                    'Name'                        = $deploymentName
                    'Location'                    = $location
                    'TemplateFile'                = $_.FullName
                    'TemplateParameterFile'       = $templateParameterFile
                    'SkipTemplateParameterPrompt' = $true
                }
                $deploymentCommand = 'New-AzSubscriptionDeployment'
                New-AzSubscriptionDeployment @parameters
            }
            elseif ($managementGroup) {

                if (-not $managementGroupID) {
                    $rootMgmtName = Get-AzManagementGroup -GroupName $enviornment -ErrorVariable errorVariable -ErrorAction SilentlyContinue -WarningAction:SilentlyContinue
                    $ManagementGroupId = ($errorVariable) ? ((Get-AzContext).Tenant.Id) :($rootMgmtName).Name
                }

                $parameters = @{
                    'Name'                        = $deploymentName
                    'Location'                    = $location
                    'ManagementGroupId'           = $managementGroupID
                    'TemplateFile'                = $_.FullName
                    'TemplateParameterFile'       = $templateParameterFile
                    'SkipTemplateParameterPrompt' = $true
                }
                $deploymentCommand = 'New-AzManagementGroupDeployment'
                New-AzManagementGroupDeployment @parameters
            }
            else {
                Write-Warning "No Scope specified"
            }
        }
    }
}
#Invoke-AzDeployment