param (
    [Parameter(Mandatory = $true)]
    [string]$SearchStaxAccountName,
    [Parameter(Mandatory = $true)]
    [string]$SearchStaxDeploymentId,
    [Parameter(Mandatory = $true)]
    [string]$SearchStaxUsername,
    [Parameter(Mandatory = $true)]
    [string]$SearchStaxPassword,
    [string]$ConfigDir,
    [string]$SearchStaxApiBaseUrl = "https://app.searchstax.com/api/rest/v2/",
    [string]$SitecoreConfigZipFileName = "sitecore_configs.zip",
    [string]$CollectionPrefix = "sitecore",   
    [string[]] $AdditionalCollections = @()
)
function New-AuthToken
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SearchStaxUsername,
        [Parameter(Mandatory = $true)]
        [string]$SearchStaxPassword,
        [string]$SearchStaxApiBaseUrl = "https://app.searchstax.com/api/rest/v2/"
    )

    $SearchStaxAuthUri = "${SearchStaxApiBaseUrl}obtain-auth-token/"
    $authForm = @{
        username = $SearchStaxUsername
        password = $SearchStaxPassword
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $authResponse = Invoke-RestMethod -Uri $SearchStaxAuthUri -Method POST -Body $authForm
    $token = $authResponse.token

    if ([string]::IsNullOrEmpty($token) -eq $true) {
        Write-Host "Could not authenticate"
        return
    }

    return $token
}

function New-ZooKeeperConfig 
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SearchStaxAccountName,
        [Parameter(Mandatory = $true)]
        [string]$SearchStaxDeploymentId,
        [Parameter(Mandatory = $true)]
        [string]$SearchStaxToken,
        [Parameter(Mandatory = $true)]
        [string]$ConfigFilePath,
        [Parameter(Mandatory = $true)]
        [string]$ConfigName,
        [string]$SearchStaxApiBaseUrl = "https://app.searchstax.com/api/rest/v2/"
    )

    $SearchStaxApiUri = "${SearchStaxApiBaseUrl}account/${SearchStaxAccountName}/deployment/${SearchStaxDeploymentId}/zookeeper-config/"
    $ConfigFile = Get-Item -Path $ConfigFilePath

    $headers = @{
        "Authorization" = "Token ${SearchStaxToken}"
    }

    $form = @{
        name = $ConfigName
        files = $ConfigFile
    }

    Write-Host "Uploading configuration from $ConfigFilePath for $ConfigName"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	try {
        $response = Invoke-RestMethod -Uri $SearchStaxApiUri -Method POST -Form $form -Headers $headers
        return $response.success
	} catch {
	    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "Exception Details:" $_.Exception
        return $false
	}
}

$SitecoreDefaultCollections = @(
    "core_index",
    "web_index",
    "master_index",
    "fxm_master_index",
    "fxm_web_index",
    "marketingdefinitions_master",
    "marketingdefinitions_web",
    "marketing_asset_index_master",
    "marketing_asset_index_web",
    "testing_index",
    "suggested_test_index"
)

$token = New-AuthToken  -SearchStaxUsername $SearchStaxUsername `
                        -SearchStaxPassword $SearchStaxPassword `
                        -SearchStaxApiBaseUrl $SearchStaxApiBaseUrl

$SitecoreCollections = $SitecoreDefaultCollections | ForEach-Object { "${CollectionPrefix}_$_" }
$SitecoreCollections += $AdditionalCollections

if ([string]::IsNullOrEmpty($ConfigDir))
{
    $ConfigDir = Split-Path $PSScriptRoot -Parent
    $ConfigDir = "${ConfigDir}\conf"
}

$SitecoreConfigFilePath = "${ConfigDir}\${SitecoreConfigZipFileName}"

ForEach ($collection in $SitecoreCollections) {

    $success = New-ZooKeeperConfig -SearchStaxAccountName $SearchStaxAccountName `
                        -SearchStaxDeploymentId $SearchStaxDeploymentId `
                        -SearchStaxToken $token `
                        -ConfigFilePath $SitecoreConfigFilePath `
                        -ConfigName $collection

    if ($success -eq $true) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red 
    }

}