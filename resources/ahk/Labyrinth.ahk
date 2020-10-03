
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout(LabURL="https://www.poelab.com/wfbra") {
	;Проверим нужно ли загружать лабиринт
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	If !loadLab {
		FileDelete, %configFolder%\images\Labyrinth.jpg
		return
	}

	;Сравним текущую дату UTC с датой загрузки лабиринта 
	IniRead, labLoadDate, %configFile%, info, labLoadDate, %A_Space%
	FormatTime, CurrentDate, %A_NowUTC%, yyyyMMdd
	If (CurrentDate==labLoadDate && FileExist(configFolder "\images\Labyrinth.jpg"))
		return
	
	;Очистка файлов
	FileDelete, %A_Temp%\labmain.html
	FileDelete, %A_Temp%\labpage.html
	FileDelete, %configFolder%\images\Labyrinth.jpg
	
	;В это время раскладка лабиринта может быть недоступной
	FormatTime, Hour, %A_NowUTC%, H
	If (Hour<1) {
		msgbox, 0x1040, %prjName% - Загрузка лабиринта, Повторите попытку после 4:00 по МСК), 3
		return
	}
		
	;Проверка наличия утилиты Curl
	If FileExist(A_WinDir "\System32\curl.exe") {
		CurlLine:="curl "
	} Else If FileExist(configfolder "\curl.exe") {
		CurlLine:="""" configFolder "\curl.exe"" "
	} Else {
		msgbox, 0x1040, %prjName% - Загрузка лабиринта, В вашей системе не найдена утилита Curl!`nБез нее загрузка изображения лабиринта невозможна!`n`nРешение этой проблемы есть в теме на форуме), 10
		return
	}
	
	;Назначение переменных
	UserAgent:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36"
	If FileExist(configfolder "\UserAgent.txt")
		FileReadLine, UserAgent, %configFolder%\UserAgent.txt, 1
	CurlLine.="-L -A """ UserAgent """ -o "

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
	If (StrLen(URL1)<23 || StrLen(URL1)>100) {
		msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать основную страницу!, 3
		return
	}
	*/
	
	;Загружаем страницу с убер-лабой и извлекаем ссылку на изображение
	;CurlLineLabPage:=CurlLine A_Temp "\labpage.html " URL1
	;CurlLineLabPage:=CurlLine A_Temp "\labpage.html https://www.poelab.com/wfbra"
	CurlLineLabPage:=CurlLine A_Temp "\labpage.html " LabURL
	RunWait, %CurlLineLabPage%
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
		msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать страницу с раскладкой!, 3
		return
	}
	
	;Загружаем изображение убер-лабы
	CurlLineImg:=CurlLine configFolder "\images\Labyrinth.jpg " URL1
	RunWait, %CurlLineImg%
	
	;Проверим изображение, чтобы оно не было пустым файлом или веб-страницей
	FileReadLine, Line, %configFolder%\images\Labyrinth.jpg, 1
	If (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\images\Labyrinth.jpg
		MsgBox, 0x1010, %prjName% - Загрузка лабиринта, Получен некорректный файл лабиринта!, 5
		return
	}
	
	;Если режим разработчика не включен, то откроем сайт
	If !debugMode
		run, %LabURL%
	
	/*
	;Удалим и другие лабиринты
	If FileExist(configFolder "\images\Labyrinth.jpg") {
		FileDelete, %configFolder%\images\*_normal.jpg
		FileDelete, %configFolder%\images\*_cruel.jpg
		FileDelete, %configFolder%\images\*_merciless.jpg
		FileDelete, %configFolder%\images\*_uber.jpg
	}
	*/
	
	;Запишем дату загрузки лабиринта
	IniWrite, %CurrentDate%, %configFile%, info, labLoadDate
	sleep 100
}

;Создание интерфейса с испытаниями
showLabTrials() {
	global
	Gui, LabTrials:Destroy
	trialsFile:=configFolder "\trials.ini"
	
	IniRead, trialA, %trialsFile%, LabTrials, trialA, 0
	IniRead, trialB, %trialsFile%, LabTrials, trialB, 0
	IniRead, trialC, %trialsFile%, LabTrials, trialC, 0
	IniRead, trialD, %trialsFile%, LabTrials, trialD, 0
	IniRead, trialE, %trialsFile%, LabTrials, trialE, 0
	IniRead, trialF, %trialsFile%, LabTrials, trialF, 0
	
	trialsStatus:=сompletionLabTrials()
	
	Gui, LabTrials:Add, Checkbox, vtrialA x5 y0 w140 h28 Checked%trialA% +Center, Пронзающей истинной`nPiercing Truth
	Gui, LabTrials:Add, Checkbox, vtrialB xp+0 y+28 w140 h28 Checked%trialB% +Center, Крутящимся страхом`nSwirling Fear
	Gui, LabTrials:Add, Checkbox, vtrialC xp+0 y+28 w140 h28 Checked%trialC% +Center, Калечащей печалью`nCrippling Grief
	
	Gui, LabTrials:Add, Checkbox, vtrialD xp+140 y0 w140 h28 Checked%trialD% +Center, Пылающей яростью`nBurning Rage
	Gui, LabTrials:Add, Checkbox, vtrialE xp+0 y+28 w140 h28 Checked%trialE% +Center, Томительной болью`nLingering Pain
	Gui, LabTrials:Add, Checkbox, vtrialF xp+0 y+28 w140 h28 Checked%trialF% +Center, Жалящим сомнением`nStinging Doubt
	
	Gui, LabTrials:+AlwaysOnTop -Caption +Border
	Gui, LabTrials:Show, w285 h225, Испытания лабиринта
	
	Gui, LabTrials:Color, 6BCA94
	WinSet, Transparent, 210, Испытания лабиринта
	WinMove,Испытания лабиринта,,,,,145
	sleep 50
	SetTimer, autoSaveLabTrials, 250
}

;Сохранение информации и удаление интерфейса
autoSaveLabTrials() {
	global
	IfWinNotActive Испытания лабиринта
	{
		SetTimer, autoSaveLabTrials, Delete
		Gui, LabTrials:Submit
		IniWrite, %trialA%, %trialsFile%, LabTrials, trialA
		IniWrite, %trialB%, %trialsFile%, LabTrials, trialB
		IniWrite, %trialC%, %trialsFile%, LabTrials, trialC
		IniWrite, %trialD%, %trialsFile%, LabTrials, trialD
		IniWrite, %trialE%, %trialsFile%, LabTrials, trialE
		IniWrite, %trialF%, %trialsFile%, LabTrials, trialF
		If (trialsStatus<сompletionLabTrials()){
			msgtext:="Поздравляю, вы завершили все испытания лабиринта)`n" prjName " уберет этот пункт из 'Быстрого доступа'!`n`nЕсли понадобится вернуть, то уберите отметки, через аналогичный пункт в 'Области уведомлений'!"
			msgbox, 0x1040, %prjName% - Испытания завершены, %msgtext%, 15
		}
		Gui, LabTrials:Destroy
	}
}

сompletionLabTrials() {
	trialsFile:=configFolder "\trials.ini"
	IniRead, trialA, %trialsFile%, LabTrials, trialA, 0
	IniRead, trialB, %trialsFile%, LabTrials, trialB, 0
	IniRead, trialC, %trialsFile%, LabTrials, trialC, 0
	IniRead, trialD, %trialsFile%, LabTrials, trialD, 0
	IniRead, trialE, %trialsFile%, LabTrials, trialE, 0
	IniRead, trialF, %trialsFile%, LabTrials, trialF, 0
	if (trialA && trialB && trialC && trialD && trialE && trialF)
		return true
	return false
}