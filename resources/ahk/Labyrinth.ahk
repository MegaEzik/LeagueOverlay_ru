﻿
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout() {
	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd	
	FormatTime, Hour, %A_NowUTC%, H
	
	;Проверка условий
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
	
	If FileExist(A_WinDir "\System32\curl.exe") {
		CurlLine:="curl "
	} Else If FileExist(configfolder "\curl.exe") {
		CurlLine:="""" configFolder "\curl.exe"" "
	} Else {
		msgbox, 0x1040, %prjName% - Загрузка лабиринта, В вашей системе не найдена утилита Curl!`nБез нее загрузка изображения лабиринта невозможна!`n`nРешение этой проблемы есть в теме на форуме), 10
		return
	}
	
	If (!devMode) {
		run, https://www.poelab.com/
		sleep 2000
	}
	
	;Назначение переменных и очистка файлов
	UserAgent:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36"
	CurlLine.="-L -A """ UserAgent """ -o "

	FileDelete, %configFolder%\labmain.html
	FileDelete, %configFolder%\labpage.html
	FileDelete, %configFolder%\images\Lab.jpg

	sleep 25
	
	;Загружаем основную страницу и извлекаем ссылку на страницу с убер-лабой
	CurlLineLabMain:=CurlLine configFolder "\labmain.html https://www.poelab.com/"
	RunWait, %CurlLineLabMain%
	URL:=""
	FileRead, LabData, %configFolder%\labmain.html
	LabDataSplit:=StrSplit(LabData, "`n")
	For k, val in LabDataSplit {
		If RegExMatch(LabDataSplit[k], "href=""(.*)""><strong>UBER LAB</strong>", FindText)
			URL:=FindText1
	}
	FileDelete, %configFolder%\labmain.html
	If (StrLen(URL)<3 || StrLen(URL)>200) {
		msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать страницу!, 3
		return
	}
	
	;Загружаем страницу с убер-лабой и извлекаем ссылку на изображение
	CurlLineLabPage:=CurlLine configFolder "\labpage.html " URL
	RunWait, %CurlLineLabPage%
	URL:=""
	FileRead, LabData, %configFolder%\labpage.html
	LabDataSplit:=StrSplit(LabData, "`n")
	For k, val in LabDataSplit {
		If RegExMatch(LabDataSplit[k], "data-mfp-src=""(.*)"" data-mfp-type=", FindText)
			URL:=FindText1
	}
	FileDelete, %configFolder%\labpage.html
	If (StrLen(URL)<3 || StrLen(URL)>200) {
		msgbox, 0x1010, %prjName% - Загрузка лабиринта, Не удалось скачать страницу!, 3
		return
	}
	
	;Загружаем изображение убер-лабы
	CurlLineImage:=CurlLine configFolder "\images\Lab.jpg " URL
	RunWait, %CurlLineImage%
	
	/*
	If (CurlLine!="") {
		FileDelete, %configFolder%\images\Lab.jpg
		sleep 25
		LabURL:="http://poelab.com/wp-content/labfiles/" Year "-" Month "-" Day "_" lvlLab ".jpg"
		CurlLine.="-A """ UserAgent """ -o " configfolder "\images\Lab.jpg " LabURL
		RunWait, %CurlLine%
	}
	*/
	
	/*
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
	*/
	
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
