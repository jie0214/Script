$TodayMon = Get-Date -format "yyyy_MM"
$TodayDay = Get-Date -format "dd"
$TodayDay = [int]$TodayDay
$TodayDay.GetType()
$Today = $TodayMon + "_" + $TodayDay
Write-Output $Today
$dd = -1
$before=(Get-Date).AddDays($dd).ToString('dd')
Write-Output $before
Test-Path -Path C:\Users\jie\Desktop\測試資料\$Today.fullbackup.txt
if (Test-Path -Path C:\Users\jie\Desktop\測試資料\$Today.fullbackup.txt) {
$NewFolder = New-Item C:\Users\jie\Desktop\測試資料\$Today -ItemType "directory"
Move-Item C:\Users\jie\Desktop\測試資料\*.log.txt -Destination $NewFolder
    for ($TodayDay -ge 1; $TodayDay-- ) {
    $lastFile = $TodayMon + "_" + $TodayDay
    echo $lastFile
    Remove-Item C:\Users\jie\Desktop\測試資料\$lastFile.fullbackup.txt -Recurse
    if ($TodayDay -le 1){
    }
}
}