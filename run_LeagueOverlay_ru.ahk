FileDelete, %A_ScriptDir%\resources\Labyrinth.jpg

FormatTime, Year, %A_NowUTC%, yyyy
FormatTime, Month, %A_NowUTC%, MM
FormatTime, Day, %A_NowUTC%, dd
UberLabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_uber.jpg"
UrlDownloadToFile, %UberLabURL%, %A_ScriptDir%\resources\Labyrinth.jpg

FileReadLine, Line, %A_ScriptDir%\resources\Labyrinth.jpg, 1

if (Line=""||Line="<!DOCTYPE html>") {
	FileDelete, %A_ScriptDir%\resources\Labyrinth.jpg
	MsgBox Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!
	FileCopy, %A_ScriptDir%\resources\LabyrinthError.jpg, %A_ScriptDir%\resources\Labyrinth.jpg
}

run %A_AhkPath% %A_ScriptDir%\Overlay.ahk
ExitApp