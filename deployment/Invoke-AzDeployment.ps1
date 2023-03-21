param (
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]
    $deploymentName,

    [string]
    $Mode = "Incremental",

    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateSet('alpha','gold')]
    $enviornment = "alpha",

    [string]
    $location = "eastus",

    [string]
    $path,

    [Parameter(ParameterSetName = "subscription", Mandatory = $true, ValueFromPipeline = $true)]
    [string]$subscriptionId,

    [Parameter(ParameterSetName = "managementGroup", Mandatory = $false, ValueFromPipeline = $true)]
    [string]$managementGroupId
)
process {
    Get-ChildItem -Recurse -Path $path -Filter *.json -Exclude *.gold.json, *.alpha.json  | % {

        Write-Warning "Processing Deployment: $_"

        $parameterFile = (Join-Path $_.Directory.FullName -ChildPath ($_.BaseName + ".parameters." + $enviornment + $_.Extension))
        $templateParameterFile = ((Test-Path $parameterFile) ? $parameterFile : "./emptyParameters.json")
        $name = ($deploymentName) ? $deploymentName : ('azops-' + $_.BaseName)
        if ($deploymentName.Length -gt 53) { $deploymentName = $deploymentName.SubString(0, 53) }

        if ($subscriptionId) {

            Set-AzContext -Subscription $subscriptionId

            $parameters = @{
                'Name'                        = $name
                'Location'                    = $location
                'TemplateFile'                = $_.FullName
                'TemplateParameterFile'       = $templateParameterFile
                'SkipTemplateParameterPrompt' = $true
            }
            Write-Host $parameters
            $deploymentCommand = 'New-AzSubscriptionDeployment'
            New-AzSubscriptionDeployment @parameters
        }
        elseif($managementGroupId){

            $parameters = @{
                'Name'                        = $name
                'Location'                    = $location
                'ManagementGroupId'           = $managementGroupId
                'TemplateFile'                = $_.FullName
                'TemplateParameterFile'       = $templateParameterFile
                'SkipTemplateParameterPrompt' = $true
            }
            Write-Host $parameters
            $deploymentCommand = 'New-AzManagementGroupDeployment'
            New-AzManagementGroupDeployment @parameters
        }
        else {
            Write-Warning "No Scope specified"
        }
    }
}

#Invoke-AzDeployment