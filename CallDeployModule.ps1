#Importing Deploy module from main script
Import-Module -function Start-DbaSsisDeploy D:\SSIS_Catalog_Project\MainModule.psm1

#Calling module
Start-DbaSsisDeploy
