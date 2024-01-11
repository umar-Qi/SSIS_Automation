$location = "D:\"
$ProjectDir = "TestProject"
$ProjectPath = $location+$ProjectDir
$GitRepo = "https://gitlab.com/qiwa1/TestProject.git"

$directories = Get-ChildItem -Path $location -Directory
$exists = $directories.Name -like $pattern

if (Test-Path $ProjectPath) {
    Write-Host "Path exists"
    cd $ProjectPath
    git pull origin master
} else {
    Write-Host "No folder found on given path"
    cd $location
    git clone $GitRepo
    cd $ProjectDir
    git switch master
}