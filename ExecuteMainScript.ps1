#Command to import modules from MainModule.psm1
Import-Module -function Start-DbaSsisRestore D:\SSIS_Catalog_Project\MainModule.psm1

Import-Module -function Start-DbaPkgDeploy D:\SSIS_Catalog_Project\MainModule.psm1

#command for build SSIS Project
#Start-DbaSsisBuild

#command for deploy .ispac file to SSIS Catlog
Start-DbaSsisDeploy

#command for restore old version of .ispac
#Start-DbaSsisRestore

#command to deploy single package into catalog
#Start-DbaPkgDeploy
