
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout(LabURL="https://www.poelab.com/wfbra", openPage=false) {
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	If !loadLab
		return

	;Сравним текущую дату UTC с датой загрузки лабиринта 
	IniRead, labLoadDate, %configFile%, info, labLoadDate, %A_Space%
	FormatTime, CurrentDate, %A_NowUTC%, yyyyMMdd
	If (CurrentDate==labLoadDate && FileExist(configFolder "\images\Labyrinth.jpg"))
		return
	
	;В это время раскладка лабиринта может быть недоступной
	FormatTime, Hour, %A_NowUTC%, H
	If (Hour<1)
		return
	
	;Отроем сайт, если загрузка осуществляется по время запуска макроса
	If openPage
		run, %LabURL%
		
	;Очистка файлов
	FileDelete, %A_Temp%\labmain.html
	FileDelete, %A_Temp%\labpage.html
	FileDelete, %configFolder%\images\Labyrinth.jpg
	
	/*
	;Загружаем основную страницу и извлекаем ссылку на страницу с убер-лабой
	CurlLineLabMain:=CurlLine A_Temp "\labmain.html https://www.poelab.com/"
	RunWait, %CurlLineLabMain%
	FileRead, LabData, %A_Temp%\labmain.html
	LabDataSplit:=StrSplit(LabData, "`n")
	For k, val in LabDataSplit {
		If RegExMatch(LabDataSplit[k], "<a href=""(.*)"">Uber Labyrinth Daily Notes</a>", URL)
			break
		If RegExMatch(LabDataSplit[k], "href=""(.*)""><strong>UBER LAB</strong>", URL)
			break
	}
	FileDelete, %A_Temp%\labmain.html
	If (StrLen(URL1)<23 || StrLen(URL1)>100) {
		msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать основную страницу!, 3
		return
	}
	
	CurlLineLabPage:=CurlLine A_Temp "\labpage.html " URL1
	*/
	
	;Загружаем страницу с убер-лабой и извлекаем ссылку на изображение
	LoadFile(LabURL, A_Temp "\labpage.html")
	
	FileRead, LabData, %A_Temp%\labpage.html
	LabDataSplit:=StrSplit(LabData, "`n")
	For k, val in LabDataSplit {
		If RegExMatch(LabDataSplit[k], "<img id=""notesImg"" style=""margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"">", URL)
			break
		If RegExMatch(LabDataSplit[k], "<img id=""notesImg"" style=""width: margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"" />", URL)
			break
		If RegExMatch(LabDataSplit[k], "<img id=""light-notesImg"" style=""width: margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"" /", URL)
			break
	}
	FileDelete, %A_Temp%\labpage.html
	If (StrLen(URL1)<23 || StrLen(URL1)>100) {
		TrayTip, %prjName% - Загрузка лабиринта, Не удалось скачать страницу с раскладкой!
		devLog("Не удалось скачать страницу с раскладкой!")
		;msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать страницу с раскладкой!, 3
		return
	}
	
	;Загружаем изображение убер-лабы
	LoadFile(URL1, configFolder "\images\Labyrinth.jpg")
	
	
	;Проверим изображение, чтобы оно не было пустым файлом или веб-страницей
	FileReadLine, Line, %configFolder%\images\Labyrinth.jpg, 1
	If (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\images\Labyrinth.jpg
		TrayTip, %prjName% - Загрузка лабиринта, Получен некорректный файл лабиринта!
		devLog("Получен некорректный файл лабиринта!")
		;MsgBox, 0x1010, %prjName% - Загрузка лабиринта, Получен некорректный файл лабиринта!, 5
		return
	}
	
	;Запишем дату загрузки лабиринта
	IniWrite, %CurrentDate%, %configFile%, info, labLoadDate
	sleep 100
}

checkLab(){
	downloadLabLayout(,true)
	IniRead, useLoadTimers, %configFile%, settings, useLoadTimers, 0
	If useLoadTimers
		SetTimer, downloadLabLayout, 3600000
}

reloadLab(LabURL){
	SplashTextOn, 400, 20, %prjName%, Загрузка лабиринта, пожалуйста подождите...
	FileDelete, %configFolder%\images\Labyrinth.jpg
	sleep 25
	downloadLabLayout(LabURL, true)
	SplashTextOff
}
