
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout() {
	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd
	
	IniRead, lvlLab, %configFile%, settings, lvlLab, uber
	
	FileDelete, %configFolder%\Lab.jpg
	LabURL:="https://poelab.com/wp-content/labfiles/" Year "-" Month "-" Day "_" lvlLab ".jpg"
	UrlDownloadToFile, %LabURL%, %configFolder%\Lab.jpg

	FileReadLine, Line, %configFolder%\Lab.jpg, 1
	if (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\Lab.jpg
		LabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_" lvlLab ".jpg"
		UrlDownloadToFile, %LabURL%, %configFolder%\Lab.jpg
	}
	
	FileReadLine, Line, %configFolder%\Lab.jpg, 1
	if (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\Lab.jpg
		MsgBox, 0x1040, %prjName%, Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!
	}
}
