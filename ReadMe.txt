We have three files for our catalog project.
1) ssisTools.psm1
2) ReleaseConfig.xml
3) ExecuteMainScript.ps1

#first file containing main code 
#while second containing all path related with different environment variables
#and the last is containing some commands, which need to be executed at once.

#If none of the script is working then run below command on power shell.

#command to bypass execution policy to running power shell scripts
Set-ExecutionPolicy -Scope [Process/CurrentUser] -ExecutionPolicy Bypass

#installation of dotnet script with below command, in order to run .csx C# code.
dotnet tool install -g dotnet-script