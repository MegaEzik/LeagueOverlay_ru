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
RunWait, curl %UberLabURL% --output %A_ScriptDir%\resources\Lab.jpg

FileGetSize, Size, %A_ScriptDir%\resources\Lab.jpg
if (Size=0||Size="") {
	FileDelete, %A_ScriptDir%\resources\Lab.jpg
	MsgBox Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!
	FileCopy, %A_ScriptDir%\resources\LabError.jpg, %A_ScriptDir%\resources\Lab.jpg
}

run %A_AhkPath% %A_ScriptDir%\Overlay.ahk
ExitApp