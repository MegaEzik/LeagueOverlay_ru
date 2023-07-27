
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout(LabURL="https://www.poelab.com/wfbra", openPage=false) {
	;Сравним текущую дату UTC с датой загрузки лабиринта 
	IniRead, labLoadDate, %configFile%, info, labLoadDate, %A_Space%
	FormatTime, CurrentDate, %A_NowUTC%, yyyyMMdd
	If (CurrentDate==labLoadDate && FileExist(configFolder "\MyFiles\Labyrinth.jpg"))
		return
	
	;В это время раскладка лабиринта может быть недоступной
	FormatTime, Hour, %A_NowUTC%, H
	If (Hour<1)
		return
	
	;Отроем сайт, если загрузка осуществляется по время запуска макроса
	If openPage && !debubMode
		run, %LabURL%
		
	;Очистка файлов
	FileDelete, %A_Temp%\MegaEzik\labpage.html
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	
	;Загружаем страницу с убер-лабой и извлекаем ссылку на изображение
	LoadFile(LabURL, A_Temp "\MegaEzik\labpage.html")
	
	FileRead, LabData, %A_Temp%\MegaEzik\labpage.html
	LabDataSplit:=StrSplit(LabData, "`n")
	For k, val in LabDataSplit {
		If RegExMatch(LabDataSplit[k], "<img id=""notesImg"" style=""margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"">", URL)
			break
		If RegExMatch(LabDataSplit[k], "<img id=""notesImg"" style=""width: margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"" />", URL)
			break
		If RegExMatch(LabDataSplit[k], "<img id=""light-notesImg"" style=""width: margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"" /", URL)
			break
	}
	FileDelete, %A_Temp%\MegaEzik\labpage.html
	If (StrLen(URL1)<23 || StrLen(URL1)>100) {
		TrayTip, Labyrinth.ahk, Не удалось скачать страницу с раскладкой!
		devLog("Не удалось скачать страницу с раскладкой!")
		return
	}
	
	;Загружаем изображение убер-лабы
	LoadFile(URL1, configFolder "\MyFiles\Labyrinth.jpg")
	
	;Проверим изображение, чтобы оно не было пустым файлом или веб-страницей
	FileReadLine, Line, %configFolder%\MyFiles\Labyrinth.jpg, 1
	If (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
		TrayTip, Labyrinth.ahk, Получен некорректный файл лабиринта!
		devLog("Получен некорректный файл лабиринта!")
		return
	}
	
	;Запишем дату загрузки лабиринта
	IniWrite, %CurrentDate%, %configFile%, info, labLoadDate
	sleep 100
}

initLab(){
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	If loadLab {
		downloadLabLayout(,true)
		SetTimer, downloadLabLayout, 1800000
	}
}

reloadLab(LabURL){
	SplashTextOn, 400, 20, %prjName%, Загрузка лабиринта, пожалуйста подождите...
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	sleep 25
	downloadLabLayout(LabURL, true)
	SplashTextOff
}
