SetWorkingDir, %A_ScriptDir%

IfNotExist, %windir%\System32\curl.exe
	ExitApp

FormatTime, Year, %A_NowUTC%, yyyy
FormatTime, Month, %A_NowUTC%, MM
FormatTime, Day, %A_NowUTC%, dd
UberLabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_uber.jpg"
RunWait, curl %UberLabURL% --output %A_ScriptDir%\images\Lab.jpg

FileGetSize, Size, %A_ScriptDir%\images\Lab.jpg
if (Size=0||Size="") {
	MsgBox Не удалось получить файл с раскладкой лабиринта, возможно информация на текущуюю дату еще не появилась!
}

run Overlay.ahk