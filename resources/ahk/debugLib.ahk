
;Инициализация и создание меню разработчика
devInit(){
	localUpdate()
	Menu, devMenu, Add, Папка макроса, openScriptFolder	
	Menu, devMenu, Add, Папка настроек, openConfigFolder
	Menu, devMenu, Add
	Menu, devMenu, Add, Контрольная сумма(MD5), devMD5FileCheck
	Menu, devMenu, Add
	Menu, devMenu, Add, Перезагрузить данные, devClSD
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add
	Menu, devMenu, Add, https://poelab.com/gtgax, reloadLab
	Menu, devMenu, Add, https://poelab.com/r8aws, reloadLab
	Menu, devMenu, Add, https://poelab.com/riikv, reloadLab
	Menu, devMenu, Add, https://poelab.com/wfbra, reloadLab
	Menu, devMenu, Add
	Menu, devMenu, Standard
}

localUpdate(){
	If FileExist(configFolder "\update.zip"){
		msgbox, 0x1024, %prjName%, Установить локальное обновление?`nВ случае отказа пакет обновления будет удален!
		IfMsgBox Yes
			unZipArchive(configFolder "\update.zip", A_ScriptDir)
		FileDelete, %configFolder%\update.zip
		ReStart()
	}
}

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
	CheckUpdateFromMenu()
}

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

createShortcut(Params){
	FileCreateShortcut, %A_ScriptFullPath%, %A_Desktop%\LeagueOverlay_ru.lnk, %A_ScriptDir%, %Params%
}

shFastMenu(presetPath) {
	destroyOverlay()
	fastMenu(presetPath)
	Menu, fastMenu, Show
}

fastMenu(presetPath){
	destroyOverlay()
	Globals.Set("fastPreset", loadPreset(presetPath))
	Menu, fastMenu, Add
	Menu, fastMenu, DeleteAll
	presetsDataSplit:=StrSplit(Globals.Get("fastPreset"), "`n")
	For k, val in presetsDataSplit {
		If InStr(presetsDataSplit[k], ";")=1
			Continue
		If (presetsDataSplit[k]="---") {
			Menu, fastMenu, Add
			Continue
		}
		cmdInfo:=StrSplit(presetsDataSplit[k], "|")
		cmdName:=cmdInfo[1]
		If (cmdInfo[1]!="")
			Menu, fastMenu, Add, %cmdName%, fastMenuCmd
	}
}

fastMenuCmd(cmdName){
	presetsDataSplit:=StrSplit(Globals.Get("fastPreset"), "`n")
	For k, val in presetsDataSplit {
		cmdInfo:=StrSplit(presetsDataSplit[k], "|")
		If (cmdName=cmdInfo[1] && cmdInfo[2]!="") {
			presetCmd:=SubStr(presetsDataSplit[k], StrLen(cmdInfo[1])+2)
			commandFastReply(presetCmd)
			return
		}
	}
	commandFastReply(cmdName)
}
