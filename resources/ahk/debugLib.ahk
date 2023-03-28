
;Инициализация и создание меню разработчика
devInit(){
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	
	;Menu, devMenu, Add, Мои наборы, devPresetMenuShow
	;Menu, devMenu, Add, devStartUI
	Menu, devMenu, Add, Режим отладки, switchDebugMode
	If debugMode
		Menu, devMenu, Check, Режим отладки
	Menu, devMenu, Add
	Menu, devMenu, Add, Папка макроса, openScriptFolder	
	Menu, devMenu, Add, Папка настроек, openConfigFolder
	Menu, devMenu, Add, Изменить конфиг, editConfig
	Menu, devMenu, Add
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Перезагрузить данные, devClSD
	Menu, devSubMenu1, Add, https://poelab.com/gtgax, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/r8aws, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/riikv, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/wfbra, reloadLab
	Menu, devMenu, Add, Лабиринт, :devSubMenu1
	;Menu, devMenu, Add
	;Menu, devMenu, Add, Избранные комманды, favoriteList
	Menu, devMenu, Add
	Menu, devMenu, Add, Контрольная сумма(MD5), devMD5FileCheck
	Menu, devMenu, Add
	Menu, devSubMenu2, Standard
	Menu, devMenu, Add, AutoHotkey, :devSubMenu2
}

;Переключить режим разработчика
switchDebugMode(){
	newDebugMode:=!debugMode
	IniWrite, %newDebugMode%, %configFile%, settings, debugMode
	Sleep 100
	ReStart()
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
	FileRemoveDir, %A_Temp%\MegaEzik, 1
	Sleep 100
	ReStart()
}

;Запись отладочной информации
devLog(msg){
	If !debugMode
		return
	FileCreateDir, %A_Temp%\MegaEzik
	FormatTime, Time, dddd MMMM, dd.MM HH:mm:ss
	FileAppend, %Time% v%verScript% - %msg%`n, %A_Temp%\MegaEzik\%prjName%.log, UTF-8
}

;Добавление в отслеживаемый список
devAddInList(Line){
	If !debugMode
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

favoriteList(){
	Menu, favoriteList, Add
	Menu, favoriteList, DeleteAll
	Loop, %configFolder%\MyFiles\*.fmenu, 1
		Menu, favoriteList, Add, %A_LoopFileName%, favoriteSetFile
	Menu, favoriteList, Show
}

favoriteSetFile(Name){
	IniWrite, %Name%, %configFile%, settings, sMenu
}

editConfig(){
	;textFileWindow("", configFile, false)
	RunWait, notepad.exe "%configFile%"
	ReStart()
}

LeaguesList(){
	File:=A_Temp "\MegaEzik\Leagues.json"
	LoadFile("http://api.pathofexile.com/leagues?type=main", File, true)
	FileRead, html, %File%
	html:=StrReplace(html, "},{", "},`n{")
	
	leagues_list:=""
	
	htmlSplit:=StrSplit(html, "`n")
	For k, val in htmlSplit {
		If !RegExMatch(htmlSplit[k], "SSF") && RegExMatch(htmlSplit[k], "id"":""(.*)"",""realm", res)
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

devVoid(){
}
