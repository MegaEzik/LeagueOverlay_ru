
;Инициализация
devInit() {
	devMenu()
	
	IniRead, hotkeyGamepad, %configFile%, hotkeys, hotkeyGamepad, %A_Space%
	If (hotkeyGamepad!="")
		Hotkey, % hotkeyGamepad, shGamepadMenu, On
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu, Add, Создать ярлык, createShortcut
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

loadEvent(onStart=false){
	IniRead, updateResources, %configFile%, settings, updateResources, 0
	If !updateResources
		return
	Path:="resources\data\Event.txt"
	LoadFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/resources/data/Event.txt", Path, true)
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	
	eventData:=loadPreset("Event")
	eventDataSplit:=StrSplit(eventData, "`n")
	For k, val in eventDataSplit {
		If RegExMatch(eventDataSplit[k], ";;")=1
			Continue
		If (onStart && RegExMatch(eventDataSplit[k], ";StartUIMsg=(.*)$", StartUIMsg))
			rStartUIMsg:=StartUIMsg1
		If RegExMatch(eventDataSplit[k], ";EventName=(.*)$", EventName)
			rEventName:=EventName1
		If RegExMatch(eventDataSplit[k], ";StartDate=(.*)$", StartDate)
			rStartDate:=StartDate1
		If RegExMatch(eventDataSplit[k], ";EndDate=(.*)$", EndDate)
			rEndDate:=EndDate1
		If RegExMatch(eventDataSplit[k], ";MinVersion=(.*)$", MinVersion)
			rMinVersion:=MinVersion1
		If RegExMatch(eventDataSplit[k], ";ResourceFile=(.*)$", rURL)
			loadEventResourceFile(rURL1)
	}
	
	If (rMinVersion>verScript || rStartDate="" || rEndDate="" || CurrentDate<rStartDate || CurrentDate>rEndDate)
		return
	
	If (rStartUIMsg!="")
		showStartUI(rStartUIMsg)
	
	If (onStart && rEventName!="")
		trayMsg(rStartDate " - " rEndDate, rEventName)
	
	return eventData
}

loadEventResourceFile(URL){
	eventFileSplit:=strSplit(URL, "/")
	filePath:="resources\data\" eventFileSplit[eventFileSplit.MaxIndex()]
	LoadFile(URL, filePath, true)
}

pkgsMgr_packagesMenu(){
	FilePath:="resources\Packages.txt"
	IniRead, updateResources, %configFile%, settings, updateResources, 0
	If updateResources
		LoadFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/resources/Packages.txt", FilePath, true)
	
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			PackName:=PackInfo[1]
			If (RegExMatch(PackName, ";")!=1)
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
			If (PackInfo[1]=Name && PackInfo[2]!="") {
				Name:=RegExReplace(Name, ".(pkg|zip|img|txt)$", "")
				If RegExMatch(PackInfo[2], ".(jpg|jpeg|bmp|png|txt)$", ftype){
					LoadFile(PackInfo[2], configFolder "\MyFiles\" Name ftype)
					TrayTip, %prjName%, Файл '%Name%%ftype%' загружен!
					return
				}
				If RegExMatch(Name, ".ahk$") && RegExMatch(PackInfo[2], ".ahk$"){
					LoadFile(PackInfo[2], configFolder "\" Name)
					ReStart()
					return
				}
				If (PackInfo[3]!="") {
					If LoadFile(PackInfo[2], A_Temp "\Package.zip", false, PackInfo[3]) {
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
	IniWrite, %A_Space%, %configFile%, pkgsMgr, %Name%.ahk
	FileDelete, %configFolder%\%Name%.ahk
	FileDelete, %configFolder%\presets\%Name%.preset
	FileRemoveDir, %configFolder%\%Name%, 1
	FileRemoveDir, %configFolder%\presets\%Name%, 1
	Sleep 1000
	ReStart()
}

pkgsMgr_startCustomScripts(){
	If RegExMatch(args, "i)/DisableAddons")
		return
	Loop, %configFolder%\*.ahk, 1
	{
		IniRead, MD5, %configFile%, pkgsMgr, %A_LoopFileName%, %A_Space%
		MD5File:=MD5_File(configFolder "\" A_LoopFileName)
		If (MD5!=MD5File)
			msgbox, 0x1024, %prjName%, Разрешить выполнять '%A_LoopFileName%'?
			IfMsgBox No
				Continue
		IniWrite, %MD5File%, %configFile%, pkgsMgr, %A_LoopFileName%
		RunWait *RunAs "%A_AhkPath%" "%configFolder%\%A_LoopFileName%" "%A_ScriptDir%"
	}
}

createShortcut(){
	FileCreateShortcut, %A_ScriptFullPath%, %A_Desktop%\LeagueOverlay_ru.lnk, %A_ScriptDir%, /Debug /LoadTimer
}

;GamepadBeta
shGamepadMenu(){
	IniRead, hotkeyGamepad, %configFile%, hotkeys, hotkeyGamepad, %A_Space%
	destroyOverlay()
	Sleep 700
	GetKeyState, MyJoy, %hotkeyGamepad%
	If (MyJoy="D") {
		Run *RunAs "%A_AhkPath%" resources\PseudoMouse.ahk %hotkeyGamepad%,,, PseudoMousePID
		shMainMenu()
		Run *RunAs TASKKILL.EXE /PID %PseudoMousePID% /F,, hide
	}
}

cfgGamepad(){
	Gui, Settings:Destroy
	
	SetTimer, setHotkeyGamepad, 500
}

setHotkeyGamepad(){
	showToolTip("Нажмите и удерживайте желаемую кнопку на геймпаде!`n`nДля DualShock рекомендуется TouchPad[Joy14]`nДля XBox рекомендуется кнопка Guide[vk07]`n`nДля выхода из настройки удерживайте [Escape]")
	hotkeyGamepad:=""
	Loop 32 {
		GetKeyState, currentJoy, Joy%A_Index%
		If (currentJoy="D")
			hotkeyGamepad:="Joy" A_Index
	}
	GetKeyState, currentJoy, vk07
	If (currentJoy="D")
		hotkeyGamepad:="vk07"
	GetKeyState, currentJoy, Esc
	If (currentJoy="D")
		hotkeyGamepad:=A_Space
		
	If (hotkeyGamepad!="") {
		SetTimer, setHotkeyGamepad, Delete
		removeToolTip()
		msgbox, 0x1024, %prjName%, Хотите назначить [%hotkeyGamepad%]?
		IfMSgBox Yes
		{
			IniWrite, %hotkeyGamepad%, %configFile%, hotkeys, hotkeyGamepad
			ReStart()
		}
		Return
	}
}
