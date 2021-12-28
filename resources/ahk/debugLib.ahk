﻿
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
	
	pkgsMgr_packagesMenu()
	
	Menu, devMenu, Add, Режим отладки, switchDebugMode
	If debugMode
		Menu, devMenu, Check, Режим отладки
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Открыть папку макроса, openScriptFolder
	Menu, devMenu, Add, Перезагрузить фильтр, forceReloadFilter
	Menu, devMenu, Add, Перезагрузить лабиринт, :devMenu2
	Menu, devMenu, Add, Управление пакетами, :packagesMenu
	Menu, devMenu, Add, AutoHotkey, :devMenu1
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
	IniRead, useEvent, %configFile%, settings, useEvent, 0
	If !useEvent
		return
	
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
		If RegExMatch(eventDataSplit[k], ";StartDate=(.*)$", StartDate)
			rStartDate:=StartDate1
		If RegExMatch(eventDataSplit[k], ";EndDate=(.*)$", EndDate)
			rEndDate:=EndDate1
		If RegExMatch(eventDataSplit[k], ";MinVersion=(.*)$", MinVersion)
			rMinVersion:=MinVersion1
	}

	If (rMinVersion>verScript || rEventName="" || rStartDate="" || rEndDate="" || CurrentDate<StartDate || CurrentDate>rEndDate)
		return
	
	trayMsg(rEventName "`n" rStartDate " - " rEndDate, "Активен набор события")
	return eventData
}

pkgsMgr_packagesMenu(){
	FilePath:="resources\Packages.txt"
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			PackName:=PackInfo[1]
			Menu, packagesMenu, Add, + %PackName%, pkgsMgr_loadPackage
		}
	}
	Menu, packagesMenu, Add
	Loop, %configFolder%\*.ahk, 1
	{
		PackName:=RegExReplace(A_LoopFileName, ".ahk$", "")
		Menu, packagesMenu, Add, × %PackName%, pkgsMgr_delPackage
	}
}

pkgsMgr_loadPackage(Name){
	Name:=SubStr(Name, 3)
	FilePath:="resources\Packages.txt"
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			If (PackInfo[1]!="" && PackInfo[2]!="" && PackInfo[3]!="") {
				If (PackInfo[1]=Name) {
					If LoadFile(PackInfo[2], A_Temp "\Package.zip", PackInfo[3]) {
						unZipArchive(A_Temp "\Package.zip", configFolder)
						If FileExist(configFolder "\" Name ".ahk")
							ReStart()
						Sleep 500
						TrayTip, %prjName%, Пакет '%Name%' установлен!
						return
					} else {
						TrayTip, %prjName%, Возникла ошибка при установке пакета!
						return
					}
				}
			}
		}
	}
	return
}

pkgsMgr_delPackage(Name){
	Name:=SubStr(Name, 3)
	FileDelete, %configFolder%\%Name%.ahk
	FileDelete, %configFolder%\presets\%Name%.preset
	FileRemoveDir, %configFolder%\%Name%, 1
	FileRemoveDir, %configFolder%\presets\%Name%, 1
	Sleep 1000
	ReStart()
}

pkgsMgr_startCustomScripts(){
	Loop, %configFolder%\*.ahk, 1
	{
		IniRead, MD5, %configFolder%\pkgsMgr.ini, pkgsMgr, %A_LoopFileName%, %A_Space%
		MD5File:=MD5_File(configFolder "\" A_LoopFileName)
		If (MD5!=MD5File)
			msgbox, 0x1024, %prjName%, Разрешить выполнять '%A_LoopFileName%'?
			IfMsgBox No
				Continue
		IniWrite, %MD5File%, %configFolder%\pkgsMgr.ini, pkgsMgr, %A_LoopFileName%
		RunWait *RunAs "%A_AhkPath%" "%configFolder%\%A_LoopFileName%" "%A_ScriptDir%"
	}
}
