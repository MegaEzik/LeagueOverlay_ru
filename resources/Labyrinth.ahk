﻿
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout() {
	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd
	
	;IniRead, lvlLab, %configFile%, settings, lvlLab, uber
	
	If FileExist(A_WinDir "\System32\curl.exe") {
		FileDelete, %configFolder%\Lab.jpg
		sleep 25
		LabURL:="http://poelab.com/wp-content/labfiles/" Year "-" Month "-" Day "_uber.jpg"
		CurlLine:="curl -A ""Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36"" -o " configfolder "\Lab.jpg " LabURL
		RunWait, %CurlLine%
	} else {
		msgbox, 0x1040, %prjName%, В вашей системе не найдена утилита Curl!`n`nБез нее загрузка изображения лабиринта невозможна(, 5
		return
	}
	
	/*
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
	
	FileReadLine, Line, %configFolder%\Lab.jpg, 1
	if (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\Lab.jpg
		MsgBox, 0x1040, %prjName%, Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!, 5
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
