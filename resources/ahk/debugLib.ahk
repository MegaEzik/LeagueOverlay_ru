
;Инициализация и создание меню разработчика
devInit(){
	;Menu, devMenu, Add, /Debug, createShortcut
	Menu, devMenu, Add, Папка макроса, openScriptFolder	
	Menu, devMenu, Add, Папка настроек, openConfigFolder
	Menu, devMenu, Add
	Menu, devMenu, Add, Контрольная сумма(MD5), devMD5FileCheck
	Menu, devMenu, Add
	Menu, devMenu, Add, Перезагрузить данные, devClSD
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add
	Menu, devMenu, Standard
}

;Подсчет MD5 файла
devMD5FileCheck(){
	FileSelectFile, FilePath
	If FileExist(FilePath){
		Clipboard:=MD5_File(FilePath)
		TrayTip, %prjName% - Контрольная сумма, Скопировано в буфер обмена:`n%Clipboard%
	}
}

;Откатиться на релизную версию
devRestoreRelease() {
	IniWrite, 0, %configFile%, info, verConfig
	verScript:=0
	CheckUpdate()
}

;Перезагрузка данных
devClSD(){
	FileDelete, resources\Packages.txt
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	FileDelete, resources\data\*
	Sleep 100
	ReStart()
}

;Запись отладочной информации
devLog(msg){
	If FileExist(configFolder "\dev.log") {
		FormatTime, Time, dddd MMMM, dd.MM HH:mm:ss
		FileAppend, %Time% v%verScript% - %msg%`n, %configFolder%\dev.log, UTF-8
	}
}

;Добавление в отслеживаемый список
devAddInList(Line){
	If !RegExMatch(args, "i)/Debug")
		return
	FilePath:=configFolder "\devList.list"
	FileRead, DataList, %FilePath%
	DataListSplit:=strSplit(StrReplace(DataList, "`r", ""), "`n")
	For k, val in DataListSplit
		If DataListSplit[k]=Line
			return
	FileAppend, %Line%`n, %FilePath%, UTF-8
}

;Создать ярлык
createShortcut(Params){
	FileCreateShortcut, %A_ScriptFullPath%, %A_Desktop%\LeagueOverlay_ru.lnk, %A_ScriptDir%, %Params%
}
