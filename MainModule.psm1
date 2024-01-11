function Start-DbaSsisBuild
{
$path = (Get-ChildItem -Path env:Releasefilepath).value

$date = (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")

$BackupPath = select-xml -Path $path -XPath configuration/BackupPath | foreach {$_.node.InnerText}
$Backupsource = select-xml -Path $path -XPath configuration/Backupsource | foreach {$_.node.InnerText}

$renamefolder = New-item $BackupPath -Name "backup_$date" -ItemType Directory

if (Test-Path -Path $Backupsource) {
  $file = Get-ChildItem -Path $Backupsource
  Copy-Item -Path $Backupsource"\"$file -Destination $renamefolder
}else{
'No file to backup'
}

$SlnFilePath=select-xml -Path $path -XPath configuration/SlnFilePath | foreach {$_.node.InnerText}
$VSDevFilePath=select-xml -Path $path -XPath configuration/VSDevFilePath | foreach {$_.node.InnerText}

& $VSDevFilePath $SlnFilePath /Rebuild

}
function Start-DbaSsisDeploy
{
    $path = (Get-ChildItem -Path env:Releasefilepath).value

    $FilePath=select-xml -Path $path -XPath configuration/IspacFilePath | foreach {$_.node.InnerText}
    $SqlInstance=select-xml -Path $path -XPath configuration/InstanceName | foreach {$_.node.InnerText}
    $Catalog=select-xml -Path $path -XPath configuration/CatalogName | foreach {$_.node.InnerText}
    $CatalogPwd=select-xml -Path $path -XPath configuration/CatalogPassword | foreach {$_.node.InnerText}
    $Folder=select-xml -Path $path -XPath configuration/CatalogFolder | foreach {$_.node.InnerText}

    # Load the IntegrationServices Assembly
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null;
    $SSISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
    Write-Host ("Connecting to SqlInstance {0}" -f $SqlInstance)

    # Create a connection to the server
    $sqlConnectionString = "Data Source=$sqlInstance;Initial Catalog=master;Integrated Security=SSPI;"
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

    $ssisServer = New-Object "$SSISNamespace.IntegrationServices"  $sqlConnection
    if(!$ssisServer)  {
        Write-Host ("Cannot connect to SqlInstance {0}." -f $SqlInstance) -ForegroundColor Yellow
        return
    }

    Write-Host ("Connecting to SSIS Catalog {0}" -f $Catalog)

    $ssisCatalog = $ssisServer.Catalogs[$Catalog]

    # Create the Integration Services object if it does not exist

    if(!$ssisCatalog)
    {
        # Provision a new SSIS Catalog
        Write-Host "Creating SSIS Catalog ..."
        $ssisCatalog = New-Object "$SSISNamespace.Catalog" ($ssisServer, $Catalog, $CatalogPwd)
        $ssisCatalog.Create()
    }
     
    Write-Host "Searching Folder ..."
    $ssisFolder = $ssisCatalog.Folders[$Folder]

    # Create the SSIS catalog folder if it does not exist

    if (!$ssisFolder)
    {
        Write-Host "Creating Folder " $Folder "...."
        $ssisFolder = New-Object "$SSISNamespace.CatalogFolder" ($ssisCatalog, $Folder, $Folder)            
        $ssisFolder.Create()  
    }

    # Read the project file, and deploy it to the folder
    $file = Get-Item $FilePath 
    if (!$file)
    {
        Write-Host ("SSIS ISPAC Not found {0}" -f $FilePath ) -ForegroundColor Yellow 
        return
    }
    $ProjectName= $file.BaseName 
    Write-Host "Deploying SSIS Project ..."
    [byte[]] $projectFile = [System.IO.File]::ReadAllBytes($FilePath)
    $ssisFolder.DeployProject($ProjectName, $projectFile) | Out-Null;
    Write-Host "SSIS Deployment Complete  ..."
        
}

function Start-DbaSsisRestore
{
    $path = (Get-ChildItem -Path env:Releasefilepath).value

    $BackupPath=select-xml -Path $path -XPath configuration/BackupPath | foreach {$_.node.InnerText}   
    $RestoreFile=select-xml -Path $path -XPath configuration/RestoreFile | foreach {$_.node.InnerText}
    $Backupsource=select-xml -Path $path -XPath configuration/Backupsource | foreach {$_.node.InnerText}
    $SqlInstance=select-xml -Path $path -XPath configuration/InstanceName | foreach {$_.node.InnerText}
    $Catalog=select-xml -Path $path -XPath configuration/CatalogName | foreach {$_.node.InnerText}
    $CatalogPwd=select-xml -Path $path -XPath configuration/CatalogPassword | foreach {$_.node.InnerText}
    $Folder=select-xml -Path $path -XPath configuration/CatalogFolder | foreach {$_.node.InnerText}

    $date = (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")

    # Load the IntegrationServices Assembly
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null;
    $SSISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
    Write-Host ("Connecting to SqlInstance {0}" -f $SqlInstance)

    # Create a connection to the server
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection "Data Source=$sqlInstance;Initial Catalog=master;Integrated Security=SSPI"
    $ssisServer = New-Object "$SSISNamespace.IntegrationServices"  $sqlConnection
    if(!$ssisServer)  {
        Write-Host ("Cannot connect to SqlInstance {0}." -f $SqlInstance) -ForegroundColor Yellow
        return
    }

    Write-Host ("Connecting to SSIS Catalog {0}" -f $Catalog)

    $ssisCatalog = $ssisServer.Catalogs[$Catalog]

    # Create the Integration Services object if it does not exist

    if(!$ssisCatalog)
    {
        # Provision a new SSIS Catalog
        Write-Host "Creating SSIS Catalog ..."
        $ssisCatalog = New-Object "$SSISNamespace.Catalog" ($ssisServer, $Catalog, $CatalogPwd)
        $ssisCatalog.Create()
    }
     
    Write-Host "Searching Folder ..."
    $ssisFolder = $ssisCatalog.Folders[$Folder]

    # Create the SSIS catalog folder if it does not exist

    if (!$ssisFolder)
    {
        Write-Host "Creating Folder " $Folder "...."
        $ssisFolder = New-Object "$SSISNamespace.CatalogFolder" ($ssisCatalog, $Folder, $Folder)            
        $ssisFolder.Create()  
    }

    # Read the backup file, and restore it to the folder

    if (Test-Path -Path $RestoreFile) {
	Write-Host "Searching backup file ...."
	$backupfile = Get-Item $RestoreFile
        $newfile = "$($backupfile.BaseName)_COPY$($backupfile.Extension)"
        $backupfile | Copy-Item -Destination (Join-Path $backupsource $newfile)
       
        
    }else{
	'No file to restore'
    }
    $file = Get-ChildItem -Path $backupsource -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (!$file)
    {
        Write-Host ("SSIS ISPAC Not found {0}" -f $NewFile ) -ForegroundColor Yellow 
        return
    }
    $FilePath = $backupsource+"\"+$file
    $ProjectName= $file.BaseName 
    Write-Host "Restoring previous version ..."
    [byte[]] $projectFile = [System.IO.File]::ReadAllBytes($FilePath)
    $ssisFolder.DeployProject($ProjectName, $projectFile) | Out-Null;
    Write-Host "Restoration Complete  ..."
    Remove-Item $FilePath
        
}

function Start-DbaPkgDeploy{

    #$path = (Get-ChildItem -Path env:Releasefilepath).value

    #$SqlInstance=select-xml -Path $path -XPath configuration/InstanceName | foreach {$_.node.InnerText}
    #$Catalog=select-xml -Path $path -XPath configuration/CatalogName | foreach {$_.node.InnerText}
    #$Folder=select-xml -Path $path -XPath configuration/CatalogFolder | foreach {$_.node.InnerText}
    #$Project=select-xml -Path $path -XPath configuration/ProjectName | foreach {$_.node.InnerText}
    #$Package=select-xml -Path $path -XPath configuration/PackagePath | foreach {$_.node.InnerText}

	dotnet script D:\SSIS_Catalog_project\PackageDeployModel.csx $SqlInstance $Catalog $Folder $Project $Package

#dotnet script D:\SSIS_Catalog_project\PackageDeployModel.csx "DESKTOP-9MN031Q\DEVSQL" "SSISDB" "TempMART" "FinalProjectDeploymentCatalog_MART" "D:\FinalProjectDeploymentCatalog_MART\FinalProjectDeploymentCatalog\Package1.dtsx"
}

export-modulemember -function Start-DbaSsisBuild
export-modulemember -function Start-DbaSsisDeploy
export-modulemember -function Start-DbaSsisRestore
export-modulemember -function Start-DbaPkgDeploy