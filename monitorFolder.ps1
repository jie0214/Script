$Folder = "C:\Users\jie\Desktop\測試資料"
$timeout = 60000
$FileSystemWatcher = New-Object System.IO.FileSystemWatcher $folder
Write-Host "Start"
while ($true) {
$result = $FileSystemWatcher.WaitForChanged('Created', $timeout)

  if ($result.TimedOut -eq $false)

   {
   Write-Warning ('File {0} : {1}' -f $result.ChangeType, $result.name)

   }

} 
Write-Host '监控被取消.'