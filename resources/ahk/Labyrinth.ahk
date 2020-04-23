
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout() {
	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd	
	FormatTime, Hour, %A_NowUTC%, H
	
	;Проверка условий
	If FileExist(A_WinDir "\System32\curl.exe") {
		CurlLine:="curl "
	} Else If FileExist(configfolder "\curl.exe") {
		CurlLine:="""" configFolder "\curl.exe"" "
	} Else {
		msgbox, 0x1040, %prjName% - Загрузка лабиринта, В вашей системе не найдена утилита Curl!`nБез нее загрузка изображения лабиринта невозможна!`n`nРешение этой проблемы есть в теме на форуме), 10
		return
	}
	
	If (Hour<2) {
		TrayTip, %prjName% - Загрузка лабиринта, Сейчас неподходящее время)
		return
	}
	
	If FileExist(configfolder "\images\Lab.jpg") {
		FileGetTime, FileDate, %configfolder%\images\Lab.jpg
		UtcFileDate:=(A_Now-A_NowUTC>140000)?FileDate:FileDate+A_NowUTC-A_Now
		FormatTime, FileDateString, %UtcFileDate%, yyyyMMdd
		CurrentDate:=Year Month Day
		If (FileDateString==CurrentDate)
			return
	}
	
	If !devMode
		run, https://www.poelab.com/
	
	;Назначение переменных и очистка файлов
	UserAgent:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36"
	If FileExist(configfolder "\UserAgent.txt")
		FileReadLine, UserAgent, %configFolder%\UserAgent.txt, 1
	CurlLine.="-L -A """ UserAgent """ -o "

	FileDelete, %A_Temp%\labmain.html
	FileDelete, %A_Temp%\labpage.html
	FileDelete, %configFolder%\images\Lab.jpg

	sleep 25
	
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
	debugMsg(URL1)
	If (StrLen(URL1)<23 || StrLen(URL1)>100) {
		msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать страницу!, 3
		return
	}
	*/
	
	;Загружаем страницу с убер-лабой и извлекаем ссылку на изображение
	;CurlLineLabPage:=CurlLine A_Temp "\labpage.html " URL1
	CurlLineLabPage:=CurlLine A_Temp "\labpage.html https://www.poelab.com/wfbra"
	RunWait, %CurlLineLabPage%
	FileRead, LabData, %A_Temp%\labpage.html
	LabDataSplit:=StrSplit(LabData, "`n")
	For k, val in LabDataSplit {
		If RegExMatch(LabDataSplit[k], "<img id=""notesImg"" style=""width: margin: 0 auto; display: inline-block; cursor: zoom-in;"" src=""(.*)"" />", URL)
			break
		If RegExMatch(LabDataSplit[k], "data-mfp-src=""(.*)"" data-mfp-type=", URL)
			break
	}
	FileDelete, %A_Temp%\labpage.html
	debugMsg(URL1)
	If (StrLen(URL1)<23 || StrLen(URL1)>100) {
		msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать страницу!, 3
		return
	}
	
	;Загружаем изображение убер-лабы
	CurlLineImg:=CurlLine configFolder "\images\Lab.jpg " URL1
	RunWait, %CurlLineImg%
	
	;Проверим изображение, чтобы оно не было пустым файлом или веб-страницей
	FileReadLine, Line, %configFolder%\images\Lab.jpg, 1
	If (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\images\Lab.jpg
		MsgBox, 0x1010, %prjName% - Загрузка лабиринта, Получен некорректный файл лабиринта!, 5
	}
}

;Создание интерфейса с испытаниями
showLabTrials() {
	global
	Gui, LabTrials:Destroy
	trialsFile:=configFolder "\trials.ini"
	
	Menu, ltMenuBar, Add, Сохранить `tCtrl+S, saveLabTrials
	Gui, LabTrials:Menu, ltMenuBar
	
	IniRead, trialAS, %trialsFile%, LabTrials, trialA, 0
	IniRead, trialBS, %trialsFile%, LabTrials, trialB, 0
	IniRead, trialCS, %trialsFile%, LabTrials, trialC, 0
	IniRead, trialDS, %trialsFile%, LabTrials, trialD, 0
	IniRead, trialES, %trialsFile%, LabTrials, trialE, 0
	IniRead, trialFS, %trialsFile%, LabTrials, trialF, 0
	
	Gui, LabTrials:Add, Checkbox, vtrialAS x15 y5 w145 h28 Checked%trialAS%, Пронзающей истинной`nPiercing Truth
	Gui, LabTrials:Add, Checkbox, vtrialBS xp+0 y+5 w145 h28 Checked%trialBS%, Крутящимся страхом`nSwirling Fear
	Gui, LabTrials:Add, Checkbox, vtrialCS xp+0 y+5 w145 h28 Checked%trialCS%, Калечащей печалью`nCrippling Grief
	Gui, LabTrials:Add, Checkbox, vtrialDS xp+155 y5 w145 h28 Checked%trialDS%, Пылающей яростью`nBurning Rage
	Gui, LabTrials:Add, Checkbox, vtrialES xp+0 y+5 w145 h28 Checked%trialES%, Постоянной болью`nLingering Pain
	Gui, LabTrials:Add, Checkbox, vtrialFS xp+0 y+5 w145 h28 Checked%trialFS%, Жгучим сомнением`nStinging Doubt
	Gui, LabTrials:Show, w320, Испытания лабиринта
}

;Сохранение информации и удаление интерфейса
saveLabTrials() {
	global
	Gui, LabTrials:Submit
	IniWrite, %trialAS%, %trialsFile%, LabTrials, trialA
	IniWrite, %trialBS%, %trialsFile%, LabTrials, trialB
	IniWrite, %trialCS%, %trialsFile%, LabTrials, trialC
	IniWrite, %trialDS%, %trialsFile%, LabTrials, trialD
	IniWrite, %trialES%, %trialsFile%, LabTrials, trialE
	IniWrite, %trialFS%, %trialsFile%, LabTrials, trialF
	Gui, LabTrials:Destroy
}
