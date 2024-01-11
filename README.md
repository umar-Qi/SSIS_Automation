# SSIS_Automation

after complete requirement, we need to create xml file in which we mention each of the file path like below file
ReleaseConfig.xml
then we create environment variable and place the above file path in it.

now moving forward, we have few files with respective names like below
MainModule.psm1
CallBuildModule.ps1
CallDeployModule.ps1
PackageDeployModel.csx

Files description:
MainModule is our main file which contain four functions in it, each of these function contain code of it's respective behavior.
We have four behavior of our working scenario, Build, Deploy, Revert and single pckg deployment.

CallBuildModule and CallDeployModule simply import their respective functions and call them.
that's how we achieve our two requirments that is build and deploy.

PackageDeployModel is contain code of C# which is different than other files, so we simply put the path of this file into our MainModule
function and execute it with "dotnet script" command, and call this function on powershell CLI.
that's how single package deployment works.

Note:
"If you want to add mor description inside of each file then you can open and review code and then make your own script."
