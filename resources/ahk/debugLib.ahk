
;Инициализация и создание меню разработчика
devInit() {
	Menu, devMenu, Add, /Debug /LoadTimer, createShortcut
	Menu, devMenu, Add
	Menu, devMenu, Add, Папка макроса, openScriptFolder	
	Menu, devMenu, Add, Папка настроек, openConfigFolder	
	Menu, devMenu, Add
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	IniRead, updateResources, %configFile%, settings, updateResources, 0
	If updateResources
		Menu, devMenu, Add, Перезагрузить данные, devClSD
	Menu, devMenu, Add
	Menu, devMenu, Add, https://poelab.com/gtgax, reloadLab
	Menu, devMenu, Add, https://poelab.com/r8aws, reloadLab
	Menu, devMenu, Add, https://poelab.com/riikv, reloadLab
	Menu, devMenu, Add, https://poelab.com/wfbra, reloadLab
	Menu, devMenu, Add
	Menu, devMenu, Standard
}

;Откатиться на релизную версию
devRestoreRelease() {
	IniWrite, 0, %configFile%, info, verConfig
	verScript:=0
	CheckUpdateFromMenu()
}

devClSD(){
	FileDelete, resources\Packages.txt
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	FileDelete, resources\data\*
	delFilter()
	Sleep 100
	ReStart()
}

;Запись отладочной информации
devLog(msg){
	If RegExMatch(args, "i)/Debug") {
		FormatTime, Time, dddd MMMM, dd.MM HH:mm:ss
		FileAppend, %Time% v%verScript% - %msg%`n, %configFolder%\dev.log, UTF-8
	}
}

;Добавление в отслеживаемый список
devAddInList(Line){
	If !RegExMatch(args, "i)/Debug")
		return
	FilePath:=configFolder "\devList.txt"
	FileRead, DataList, %FilePath%
	DataListSplit:=strSplit(StrReplace(DataList, "`r", ""), "`n")
	For k, val in DataListSplit
		If DataListSplit[k]=Line
			return
	FileAppend, %Line%`n, %FilePath%, UTF-8
}

createShortcut(Params){
	FileCreateShortcut, %A_ScriptFullPath%, %A_Desktop%\LeagueOverlay_ru.lnk, %A_ScriptDir%, %Params%
}
