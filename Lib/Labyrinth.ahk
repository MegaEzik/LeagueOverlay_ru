
/*
[info]
version=250822
*/

;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout(LabURL="https://www.poelab.com/wfbra", fileName="Labyrinth") {
	;Сравним текущую дату UTC с датой загрузки лабиринта 
	IniRead, lDate, %configFile%, info, labfile%fileName%, %A_Space%
	FormatTime, cDate, %A_NowUTC%, yyyyMMdd
	If (cDate==lDate && FileExist(configFolder "\MyFiles\" fileName ".jpg"))
		return
	
	;В это время раскладка лабиринта может быть недоступной
	FormatTime, Hour, %A_NowUTC%, H
	If (Hour<2)
		return
	
	;Откроем сайт, если загрузка осуществляется по время запуска макроса
	;If openPage
		;Run, %LabURL%
		
	FileRead, Cookies, %configFolder%\LabCookies.txt
		
	;Очистка файлов
	FileDelete, %tempDir%\labpage.html
	FileDelete, %configFolder%\MyFiles\%fileName%.jpg
	
	;Загружаем страницу с убер-лабой и извлекаем ссылку на изображение
	LoadFile(LabURL, tempDir "\labpage.html",, Cookies)
	
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
		If RegExMatch(LabData, "i)Just a moment...") && RegExMatch(LabData, "_cf_") {
			TrayTip, Labyrinth, Не возможно скачать - активен CloudFlare!
			devLog("Не возможно скачать - активен CloudFlare!")
			return
		}
		TrayTip, Labyrinth, Не удалось извлечь ссылку!
		devLog("Не удалось извлечь ссылку!")
		return
	}
	FileDelete, %tempDir%\labpage.html
	
	;Загружаем изображение убер-лабы
	LoadFile(URL1, configFolder "\MyFiles\" fileName ".jpg",, Cookies)
	
	;Проверим изображение, чтобы оно не было пустым файлом или веб-страницей
	FileReadLine, Line, %configFolder%\MyFiles\%fileName%.jpg, 1
	If (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\MyFiles\%fileName%.jpg
		TrayTip, Labyrinth, Некорректный файл лабиринта!
		devLog("Некорректный файл лабиринта!")
		return
	}
	
	IniWrite, %cDate%, %configFile%, info, labfile%fileName%
	sleep 50
}

loadLabWithCookies(){
	Run, "https://www.poelab.com"
	Sleep 1000
	InputBox, Cookies, PoELab.com - cf_clearance,,, 500, 100,,,,, %Cookies%
	If (Cookies!="") {
		FileDelete, %configFolder%\LabCookies.txt
		Sleep 100
		FileAppend, cf_clearance=%Cookies%, %configFolder%\LabCookies.txt, UTF-8
	}
	Sleep 100
	
	SplashTextOn, 400, 20, %prjName%, Загрузка раскладки Лабиринта, пожалуйста подождите...
	
	downloadLabLayout()
	If GetKeyState("LCtrl", P) && RegExMatch(args, "i)/Dev") && FileExist(configFolder "\MyFiles\Labyrinth.jpg") && FileExist(configFolder "\LabCookies.txt") {
		downloadLabLayout("https://www.poelab.com/gtgax", "Lab1_Normal")
		downloadLabLayout("https://www.poelab.com/r8aws", "Lab2_Cruel")
		downloadLabLayout("https://www.poelab.com/riikv", "Lab3_Merciless")
	} else {
		FileDelete, %configFolder%\MyFiles\Lab1_Normal.jpg
		FileDelete, %configFolder%\MyFiles\Lab2_Cruel.jpg
		FileDelete, %configFolder%\MyFiles\Lab3_Merciless.jpg
	}
	
	SplashTextOff
}

addLoadLabInMenu(MenuName, Name="LoadLab"){
	IniRead, lDate, %configFile%, info, labfileLabyrinth, 0
	FormatTime, сDate, %A_NowUTC%, yyyyMMdd
	If FileExist(configFolder "\LabCookies.txt") && ((lDate<сDate) || !FileExist(configFolder "\MyFiles\Labyrinth.jpg"))
		Menu, %MenuName%, Add, %Name%, loadLabWithCookies
}

autoLoadLab(){
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	IniRead, lDate, %configFile%, info, labfileLabyrinth, 0
	If !loadLab
		return
	FormatTime, сDate, %A_NowUTC%, yyyyMMdd
	If FileExist(configFolder "\LabCookies.txt") && ((lDate<сDate) || !FileExist(configFolder "\MyFiles\Labyrinth.jpg"))
		loadLabWithCookies()
}

initLab(){
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	If loadLab {
		downloadLabLayout()
		;SetTimer, downloadLabLayout, 10800000
	}
}

