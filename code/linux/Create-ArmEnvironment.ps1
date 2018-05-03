﻿# the script take 3 parameters: 
# 1. a deployment folder
# 2. the PowerShell modules file which contains the a module list to import. will copy this file to deployment folder as Module.psm1
# 3. the excel sheet file. we will copy this file to the deployment folder and rename it as AzureEnv.xlsx

 param (
    [Parameter()][string] $DeployID = "209912310000" # a test folder which will not conflict with current date
    [Parameter()][string] $DeployFolder = "/var/lib/jenkins/workspace/az-infra-as-code/deployment",
    [Parameter()][string] $PSModule = "/usr/local/share/powershell/Modules/ImportExcel/4.0.12/allenk-Module-Json.psm1",
    [Parameter()][string] $AzureFile = "/var/lib/jenkins/workspace/az-infra-as-code/AzureEnv.xlsx"
 )

# create the deployment folder. the folder should be empty as we create the folder with datetime.
New-Item -ItemType Directory -Force -Path "$DeployFolder/$DeployID"
cd "$DeployFolder/$DeployID"

# copy PSModule and AzureFile to the deployment folder
$moduleFile = "./"+"Module.psm1"
$excelSheet = "./"+"AzureEnv.xlsx"

Copy-Item -Path $PSModule -Destination $moduleFile
Copy-Item -Path $AzureFile -Destination $excelSheet

# read configuration data
Import-Module $moduleFile
$environmentSheet = Import-Excel -Path $excelSheet -WorksheetName Environment -DataOnly

$batchFile = "./az-env-create-cmd.bat"

cd "$DeployFolder/$DeployID"
"az cloud list --output table" | Out-File -Encoding utf8 -Append $batchFile
"az cloud set -n " + $environmentSheet[1].Cloud | Out-File -Encoding utf8 -Append $batchFile
"az login --service-principal -u " + $environmentSheet[1].ApplicationID + " -p " + $environmentSheet[1].Certification + " --tenant " + $environmentSheet[1].TenantID  | Out-File -Encoding utf8 -Append $batchFile
"az account list --output table" | Out-File -Encoding utf8 -Append $batchFile
"az account set -s" + $environmentSheet[1].SubscriptionID | Out-File -Encoding utf8 -Append $batchFile


