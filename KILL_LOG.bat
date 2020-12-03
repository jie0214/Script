rem 路徑
set LogPath=D:\temp
rem 保留天數
set DayToKeepLog=5
rem 副檔名
set FileExten=*.txt
forfiles.exe -p "%LogPath%" /s /m "%FileExten%" /d -%DayToKeepLog% -c "cmd /C del @FILE"