# 主機名稱及IP
$IP = foreach($ipv4 in (ipconfig) -like '*IPv4*') { ($ipv4 -split ' : ')[-1]}
Get-WMIObject Win32_ComputerSystem |select Name > C:\Users\jie\Desktop\123.txt
echo $IP >> C:\Users\jie\Desktop\123.txt

# 取得當前記憶體資訊
$a=(get-wmiobject -class Win32_PhysicalMemory  -namespace "root\cimv2").Capacity
$b=(get-wmiobject -class Win32_PerfFormattedData_PerfOS_Memory  -namespace "root\cimv2").AvailableMBytes
$f=$b/1024
$c=$a/1024/1024/1024
$d=$c-$f
$g=$d/$c*100
$h="{0:N1}" -f $g
cls
echo 您當前總記憶體$c"GB" 可用記憶體$f"GB" 已用記憶體$d"GB" 已使用$h"%" >> C:\Users\jie\Desktop\123.txt

# 取得所有硬碟的資訊
$Disks = Get-WmiObject -Class Win32_LogicalDisk

# 輸出每一個硬碟的資訊
$output = foreach ($Disk in $Disks) {
  "------------"
  "磁碟機代碼：{0}" -f $Disk.DeviceID
  "磁碟機名稱：{0}" -f $Disk.VolumeName
  "磁碟機大小：{0:0.0} GB" -f ($Disk.Size / 1GB)
  "剩餘空間：{0:0.0} GB" -f ($Disk.FreeSpace / 1GB)
  $Used = ([int64]$Disk.size - [int64]$Disk.FreeSpace)
  "已用空間：{0:0.0} GB" -f ($Used / 1GB)
  $Percent = ($Used * 100.0) / $Disk.Size
  "已用比例：{0:N0} %" -f $Percent
}

$output >> C:\Users\jie\Desktop\123.txt