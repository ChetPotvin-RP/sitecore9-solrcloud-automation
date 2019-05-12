param (
    [Parameter(Mandatory = $true)]
    [string]$SolrHost, 
    [string]$Username,
    [string]$Password,
    [string]$CollectionPrefix = "sitecore",   
    [string]$ReplicationFactor = 1,
    [string]$NumberofShards = 1,
    [string[]] $AdditionalCollections = @()
)

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

$XdbCollections = @(
    "xdb",
	"xdb_rebuild"
)

$AllCollections = $SitecoreDefaultCollections | ForEach-Object { "${CollectionPrefix}_$_" }
$AllCollections += $AdditionalCollections

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Password)))
$headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}

ForEach ($collection in $AllCollections) { 

    $createCollectionCommand = "${SolrHost}/solr/admin/collections?action=CREATE&name=${collection}&collection.configName=${collection}&replicationFactor=${ReplicationFactor}&numShards=${NumberOfShards}"
    Write-Host "Creating Collection: ${collection}"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-RestMethod -Uri $createCollectionCommand -Method GET -Headers $headers
    $success = $response.responseHeader.status -eq 0

    if ($success -eq $true) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red 
    }
}

$XdbCollections = $XdbCollections | ForEach-Object { "${CollectionPrefix}_$_" }

ForEach ($collection in $XdbCollections) {
   
    $createCollectionCommand = "${SolrHost}/solr/admin/collections?action=CREATE&name=${collection}&collection.configName=_default&replicationFactor=${ReplicationFactor}&numShards=${NumberOfShards}"
    Write-Host "Creating Collection: ${collection}"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-RestMethod -Uri $createCollectionCommand -Method GET -Headers $headers
    $success = $response.responseHeader.status -eq 0

    if ($success -eq $true) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red 
    }
}

