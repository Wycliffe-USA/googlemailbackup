Param(
  [parameter(Mandatory=$false)][string]$scriptPath = 'C:\scripts',
  [parameter(Mandatory=$false)][int]$maxParallel = 2,
  [bool]$logToFile = $true
)
#Check for environment variables
if (Get-ChildItem Env:maxParallel -ErrorAction SilentlyContinue){$maxParallel = (Get-ChildItem Env:maxParallel).value}

################
#XXXXXXXXXXXXXXXXXXXXX
$startTime = Get-Date
cd $scriptPath
$backupJobs = @{}
If ($logToFile){
  If (Test-Path -Path "C:\data\gyb_backup.log"){ Clear-Content -Path "C:\data\gyb_backup.log"} 
}

Write-Output $startTime
Write-Output "Getting list of users."

#Get active user list.
# Randomize the list order.
$activeUserFile = "${scriptPath}\active_users.txt"
python c:\gam\gam.py report users fields "accounts:is_disabled" filter "accounts:is_disabled==FALSE"| Out-FIle -FilePath $activeUserFile
Get-Content $activeUserFile| select -Skip 1|%{ $_.Split(',')[0];}|Sort-Object {Get-Random}|Set-Content "${scriptPath}\activeUsersTemp.txt" ;
Move-Item -Force "${scriptPath}\activeUsersTemp.txt" $activeUserFile;

$lines = (Get-Content $activeUserFile | Measure-Object -Line).Lines
Write-Output "Found $lines.Lines accounts"


#Functions
function checkResults(){
  #Helps to get the results from jobs that were spawned in the background.
  $backupJobsToRemove = New-Object System.Collections.ArrayList
  foreach ($email in $backupJobs.Keys) {
    $jobId = $backupJobs[$email]
    
    If ((Get-Job -Id $jobId).State -eq 'Completed'){
      $result = Receive-Job -Id $jobId -ErrorAction SilentlyContinue
      
      #Display results to screen, also output them to a common log and to individual logs per email.
      Write-Output "Results from ${email}:"
      Write-Output $result
      If ($logToFile){
        $result | Set-Content -Path "C:\data\${email}\gyb_backup.log"
        $result | Add-Content -Path "C:\data\gyb_backup.log"
      }
      $backupJobsToRemove.Add($email)|Out-Null
      $date = Get-Date
      Write-Output "${date} : Complete backup of ${email}"
    }
  }
  for ($i=$backupJobsToRemove.count-1; $i -ge 0; $i--){
    $emailToRemove = $backupJobsToRemove[$i]
    $backupJobs.Remove($backupJobsToRemove[$i])
  }
}

function waitJobs($maxCount){
  #Wait if / while we have -ge $maxParallel jobs running before starting any more.
  If ($maxCount -eq 0){
    While (((Get-Job -Name "*GoogleMailBackup*"|Where-Object {$_.State -eq 'Running'}| measure)).Count -gt $maxCount){
      Start-Sleep -Seconds 5
    }
  }else{
    While (((Get-Job -Name "*GoogleMailBackup*"|Where-Object {$_.State -eq 'Running'}| measure)).Count -ge $maxCount){
      Start-Sleep -Seconds 5
    }
  }
}


### Start Backups
####################
$date = Get-Date
Write-Output "${date} : Performing backups..."


Get-Content $activeUserFile|ForEach-Object{
  #Start new jobs.
  $userEmail = $_
  Write-Output "${date} : Starting backup of $userEmail"
  #Start an instance of gyb in the backround so we can parrallelize processes.  Limit with $maxParallel to avoid google api limits.
  $job = Start-Job -Name "GoogleMailBackup" -ScriptBlock { $email = $args[0]; c:\gyb\gyb.exe --service-account --action backup --email $email --local-folder "C:\data\${email}" } -ArgumentList $userEmail


  #Add job information to list so we can track it.
  $jobId = $job.Id
  $backupJobs.Add($userEmail, $jobId)|Out-Null

  waitJobs($maxParallel)

  checkResults

  Start-Sleep -Seconds 5
}

#Wait while any final jobs complete.
waitJobs(0)

checkResults

$date = Get-Date
Write-Output "${date} : Completed backups..."; Write-Output "";
