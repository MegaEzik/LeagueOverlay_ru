SetWorkingDir, %A_ScriptDir%

cURL=%A_WinDir%\System32\curl.exe
If !FileExist(cURL) {
	MsgBox Не найдена утилита curl.exe,`nработа скрипта будет прервана!
	ExitApp
}

FormatTime, Year, %A_NowUTC%, yyyy
FormatTime, Month, %A_NowUTC%, MM
FormatTime, Day, %A_NowUTC%, dd
UberLabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_uber.jpg"
RunWait, curl %UberLabURL% --output %A_ScriptDir%\images\Lab.jpg

FileGetSize, Size, %A_ScriptDir%\images\Lab.jpg
if (Size=0||Size="") {
	MsgBox Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nРабота скрипта будет прервана,`nпопробуйте запустить скрипт позднее!
	ExitApp
}

run %A_AhkPath% %A_ScriptDir%\Overlay.ahk
ExitApp