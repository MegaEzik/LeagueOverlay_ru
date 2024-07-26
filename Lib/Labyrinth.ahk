
/*
[info]
version=240724.01
*/

;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout(LabURL="https://www.poelab.com/wfbra", openPage=false, fileName="Labyrinth") {
	;Сравним текущую дату UTC с датой загрузки лабиринта 
	IniRead, labLoadDate, %configFile%, info, labfile%fileName%, %A_Space%
	FormatTime, CurrentDate, %A_NowUTC%, yyyyMMdd
	If (CurrentDate==labLoadDate && FileExist(configFolder "\MyFiles\" fileName ".jpg"))
		return
	
	;В это время раскладка лабиринта может быть недоступной
	FormatTime, Hour, %A_NowUTC%, H
	If (Hour<2)
		return
	
	;Отроем сайт, если загрузка осуществляется по время запуска макроса
	If openPage
		Run, %LabURL%
		
	;Очистка файлов
	FileDelete, %tempDir%\labpage.html
	FileDelete, %configFolder%\MyFiles\%fileName%.jpg
	
	;Загружаем страницу с убер-лабой и извлекаем ссылку на изображение
	LoadFile(LabURL, tempDir "\labpage.html")
	
	FileRead, LabData, %tempDir%\labpage.html
	LabDataSplit:=StrSplit(LabData, "`n")
	For k, val in LabDataSplit {
		If RegExMatch(LabDataSplit[k], "U)https://www.poelab.com/wp-content/labfiles/(.*).jpg", URL) {
			URL1:=URL
			break
		}
		If RegExMatch(LabDataSplit[k], "<img id=""notesImg"" style=""margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"">", URL)
			break
		If RegExMatch(LabDataSplit[k], "<img id=""notesImg"" style=""width: margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"" />", URL)
			break
		If RegExMatch(LabDataSplit[k], "<img id=""light-notesImg"" style=""width: margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"" /", URL)
			break
		If RegExMatch(LabDataSplit[k], "<img decoding=""async"" id=""notesImg"" style=""margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"">", URL)
			break
	}
	If (StrLen(URL1)<23 || StrLen(URL1)>100) {
		TrayTip, Labyrinth.ahk, Не удалось скачать страницу с раскладкой!
		devLog("Не удалось скачать страницу с раскладкой!")
		return
	}
	FileDelete, %tempDir%\labpage.html
	
	;Загружаем изображение убер-лабы
	LoadFile(URL1, configFolder "\MyFiles\" fileName ".jpg")
	
	;Проверим изображение, чтобы оно не было пустым файлом или веб-страницей
	FileReadLine, Line, %configFolder%\MyFiles\%fileName%.jpg, 1
	If (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\MyFiles\%fileName%.jpg
		TrayTip, Labyrinth.ahk, Получен некорректный файл лабиринта!
		devLog("Получен некорректный файл лабиринта!")
		return
	}
	
	IniWrite, %CurrentDate%, %configFile%, info, labfile%fileName%
	sleep 50
}

initLab(){
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	If loadLab {
		downloadLabLayout(,true)
		SetTimer, downloadLabLayout, 7200000
	}
}

