
;Инициализация
devInit() {
	IniRead, debugMode, %configFile%, dev, debugMode, 0
	devMenu()
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu1, Standard
	
	Menu, devMenu2, Add, https://poelab.com/gtgax, reloadLab
	Menu, devMenu2, Add, https://poelab.com/r8aws, reloadLab
	Menu, devMenu2, Add, https://poelab.com/riikv, reloadLab
	Menu, devMenu2, Add, https://poelab.com/wfbra, reloadLab
	
	Menu, devMenu, Add, Режим отладки, switchDebugMode
	If debugMode
		Menu, devMenu, Check, Режим отладки
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Открыть папку макроса, openScriptFolder
	Menu, devMenu, Add, Перезагрузить фильтр, forceReloadFilter
	Menu, devMenu, Add, Перезагрузить лабиринт, :devMenu2
	Menu, devMenu, Add, AutoHotkey, :devMenu1
	
	;Обновлять фильтр предметов(NeverSink-2semistr)
}

;Переключение режима разработчика
switchDebugMode() {
	If !debugMode
		MsgBox, 0x1024, %prjName%, Включение режима отладки может сделать работу %prjName% нестабильной!`n`nВы уверены, что хотите продолжить?
		IfMsgBox No
			return
	newDebugMode:=!debugMode
	IniWrite, %newDebugMode%, %configFile%, dev, debugMode
	Sleep 500
	Reload
}

;Откатиться на релизную версию
devRestoreRelease() {
	IniWrite, 0, %configFile%, info, verConfig
	verScript:=0
	CheckUpdateFromMenu()
}

;Запись отладочной информации
devLog(msg){
	If debugMode {
		FormatTime, Time, dddd MMMM, dd.MM HH:mm:ss
		FileAppend, %Time% v%verScript% - %msg%`n, %configFolder%\dev.log, UTF-8
	}
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

loadEvent(){
	Path:="resources\presets\Event.txt"
	
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	FileGetTime, LoadDate, %Path%, M
	FormatTime, LoadDate, %LoadDate%, yyyyMMdd
	IfNotExist, %Path%
		LoadDate:=0
	
	If (LoadDate!=CurrentDate)
		LoadFile("https://raw.githubusercontent.com/MegaEzik/LeagueOverlay_ru/master/resources/presets/Event.txt", Path)
	
	eventData:=loadPreset("Event")
	eventDataSplit:=StrSplit(eventData, "`n")
	For k, val in eventDataSplit {
		If RegExMatch(eventDataSplit[k], ";EventName=(.*)$", EventName)
			rEventName:=EventName1
		If RegExMatch(eventDataSplit[k], ";EventInfo=(.*)$", EventInfo)
			rEventInfo:=EventInfo1
		If RegExMatch(eventDataSplit[k], ";StartDate=(.*)$", StartDate)
			rStartDate:=StartDate1
		If RegExMatch(eventDataSplit[k], ";EndDate=(.*)$", EndDate)
			rEndDate:=EndDate1
	}

	If (rEventName="" || rStartDate="" || rEndDate="" || CurrentDate<StartDate || CurrentDate>rEndDate)
		return
	
	trayMsg(rEventName "`n" rStartDate " - " rEndDate, "Активен набор события")
	return eventData
}
