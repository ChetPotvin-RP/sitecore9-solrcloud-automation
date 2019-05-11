#SS = Search Stax

.\2-Write-SitecoreZookeeperConfiguration.ps1 `
	-SearchStaxAccountName "{Your SS Account Name}" `
	-SearchStaxDeploymentId "{Your SS Deployment Id}" `
	-SearchStaxUsername "{Your SS Username}" `
	-SearchStaxPassword "{Your SS Password}" `
	-SitecoreConfigZipFileName "sitecore_configs.zip" `
	-CollectionPrefix "fatstax"

.\3-Create-SitecoreSolrCollections.ps1 `
	-SolrHost "https://{Your Solr Instance}.searchstax.com" `
	-Username "searchuser" `
	-Password "{Your Basic Auth Password}" `
	-CollectionPrefix "fatstax"	