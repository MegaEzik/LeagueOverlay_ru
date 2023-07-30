
;Инициализация и создание меню разработчика
devInit(){
	If !(GetKeyState("Ctrl", P) || RegExMatch(args, "i)/DebugMode"))
		return
	
	debugMode:=1
	traytip, %prjName%, Режим отладки активен!
	
	Menu, devMenu, Add, Файл отладки, devOpenLog
	Menu, devMenu, Add, Экран запуска, devStartUI
	Menu, devMenu, Add, Изменить конфиг, editConfig
	Menu, devMenu, Add
	Menu, devMenu, Add, Папка макроса, openScriptFolder	
	Menu, devMenu, Add, Папка настроек, openConfigFolder
	Menu, devMenu, Add
	Menu, devMenu, Add, Автозагрузка, devAutoStart
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Перезагрузить данные, devClSD
	Menu, devSubMenu1, Add, https://poelab.com/gtgax, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/r8aws, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/riikv, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/wfbra, reloadLab
	Menu, devMenu, Add, Лабиринт, :devSubMenu1
	Menu, devMenu, Add
	Menu, devSubMenu2, Standard
	Menu, devMenu, Add, AutoHotkey, :devSubMenu2
}

;Откатиться на релизную версию
devRestoreRelease() {
	IniWrite, 0, %configFile%, info, verConfig
	verScript:=0
	CheckUpdate()
}

;Перезагрузка данных
devClSD(){
	FileDelete, Data\Packages.txt
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	FileDelete, Data\JSON\*
	FileRemoveDir, %A_Temp%\MegaEzik, 1
	Sleep 100
	ReStart()
}

;Запись отладочной информации
devLog(msg){
	If !debugMode
		return
	FormatTime, Time, dddd MMMM, dd.MM HH:mm:ss
	FileAppend, %Time% v%verScript% - %msg%`n, %configFolder%\%prjName%.log, UTF-8
}

devOpenLog(){
	filePath:=configFolder "\" prjName ".log"
	textFileWindow(filePath, filePath, false)
}

;Добавление в отслеживаемый список
devAddInList(Line){
	If !debugMode
		return
	FilePath:=configFolder "\devList.txt"
	FileRead, DataList, %FilePath%
	DataListSplit:=strSplit(StrReplace(DataList, "`r", ""), "`n")
	For k, val in DataListSplit
		If DataListSplit[k]=Line
			return
	FileAppend, %Line%`n, %FilePath%, UTF-8
}

editConfig(){
	RunWait, notepad.exe "%configFile%"
	ReStart()
}

LeaguesList(){
	File:=A_ScriptDir "\Data\JSON\leagues.json"
	LoadFile("http://api.pathofexile.com/leagues?type=main", File, true)
	FileRead, html, %File%
	html:=StrReplace(html, "},{", "},`n{")
	
	leagues_list:=""
	
	htmlSplit:=StrSplit(html, "`n")
	For k, val in htmlSplit {
		If !RegExMatch(htmlSplit[k], "(SSF|Ruthless)") && RegExMatch(htmlSplit[k], "id"":""(.*)"",""realm", res)
			leagues_list.="|" res1
	}
	
	leagues_list:=subStr(leagues_list, 2)
	
	return leagues_list
}

devStartUI(){
	InputBox, inputLine, Введите текст,,, 300, 100
	showStartUI(inputLine)
	sleep 5000
	closeStartUI()
}

devAutoStart(){
	RegRead, StartLine, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %prjName%
	If (StartLine="") {
		RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %prjName%, "%A_ScriptFullPath%" %args%
		TrayTip, %prjName%, Добавлен в автозагрузку!
	} Else {
		RegDelete, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %prjName%
		TrayTip, %prjName%, Удален из автозагрузки!
	}
}

devAHKLoadFile(URL, File, UserAgent:=""){
	hObject:=comObjCreate("WinHttp.WinHttpRequest.5.1")
	hObject.open("GET", URL)
	If (UserAgent)
		hObject.setRequestHeader("User-Agent",UserAgent)
	hObject.send()
		
	uBytes:=hObject.responseBody,cLen:=uBytes.maxIndex()
	fileHandle:=fileOpen(File,"w")
	varSetCapacity(f,cLen,0)
	Loop % cLen+1
		numPut(uBytes[a_index-1],f,a_index-1,"UChar")
	fileHandle.rawWrite(f,cLen+1)
	devLog("AHKLoader > " URL " | " File " | " UserAgent )
}

devVoid(){
}
