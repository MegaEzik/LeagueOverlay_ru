
/*
[info]
version=261206.01
*/

;Инициализация и создание меню разработчика
devInit(){
	;devSpecialUpdater()
	SplitPath, A_AhkPath,,AHKPath
	If (configFolder = A_MyDocuments "\AutoHotKey\LeagueOverlay_ru") && FileExist(configFolder "\pkgsMgr.ini") && FileExist(AHKPath "\AutoHotkeyU32.exe") && FileExist(A_ScriptDir "\Data\MigrateAddons.ahk")
		RunWait, "%AHKPath%\AutoHotkeyU32.exe" "%A_ScriptDir%\Data\MigrateAddons.ahk" "%A_ScriptFullPath%"
		
	devPoE2EA()
	
	Menu, devMenu, Add, Экран запуска(5 секунд), devStartUI
	;Menu, devMenu, Add, Отслеживаемые файлы, showTrackingList
	;Menu, devMenu, Add, Задать файл 'Меню команд', devFavoriteList
	Menu, devMenu, Add
	Menu, devMenu, Add, Папка макроса, openScriptFolder	
	Menu, devMenu, Add, Папка настроек, openConfigFolder
	Menu, devMenu, Add
	Menu, devMenu, Add, Переустановить, devRestoreRelease
	Menu, devMenu, Add, Перезагрузить данные, devClSD
	If FileExist("_DevTools\_CreateRuToEnLists.ahk")
		Menu, devMenu, Add, Инструмент для 'Файлов соответствий', devCreateRuToEnLists
	Menu, devMenu, Add
	Menu, devSubMenu2, Standard
	Menu, devMenu, Add, AutoHotkey, :devSubMenu2
	
	/*
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	FormatTime, CurrentDate, %A_NowUTC%, yyyyMMdd
	If loadLab && RegExMatch(args, "i)/Dev"){
		downloadLabLayout("https://www.poelab.com/gtgax", true, "Lab1_Normal")
		downloadLabLayout("https://www.poelab.com/r8aws", true, "Lab2_Cruel")
		downloadLabLayout("https://www.poelab.com/riikv", true, "Lab3_Merciless")
	} else {
		FileDelete, %configFolder%\MyFiles\Lab1_Normal.jpg
		FileDelete, %configFolder%\MyFiles\Lab2_Cruel.jpg
		FileDelete, %configFolder%\MyFiles\Lab3_Merciless.jpg
	}
	*/
}

devPoE2EA(){
	IniWrite, 1, %configFile%, settings, updateLib
	/*
	If !RegExMatch(args, "i)/PoE2") {
		args.=" /PoE2"
		ReStart()
	}
	*/
	If !FileExist(configFolder "\Presets\PoE2EA") {
		FileCreateDir, %configFolder%\Presets\PoE2EA
		IniWrite, Path of Exile 2, %configFolder%\Presets\PoE2EA\PresetConfig.ini, Windows
		IniWrite, PoE2DB.url, %configFolder%\Presets\PoE2EA\PresetConfig.ini, SpecialNames, База данных
		
		IniWrite, https://poe2db.tw/, %configFolder%\Presets\PoE2EA\PoE2DB.url, InternetShortcut, URL
		
		IniWrite, *PoE2EA, %configFile%, settings, preset2
		Sleep 10
		devClSD()
	}
}

;Загрузить событие
loadEvent(){
	IniRead, EventURL, %buildConfig%, settings, EventURL, %A_Space%
	IniRead, useEvent, %configFile%, settings, useEvent, 1
	If !useEvent || (EventURL="")
		return
	
	;EventPath:=A_Temp "\MegaEzik\LOEvent\event.txt"
	EventPath:=configFolder "\Event\event.txt"
	LoadFile(eventURL, EventPath, true)
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	
	IniRead, EventName, %EventPath%, Event, EventName, %A_Space%
	IniRead, EventLogo, %EventPath%, Event, EventLogo, %A_Space%
	IniRead, EventMsg, %EventPath%, Event, EventMsg, %A_Space%
	IniRead, StartDate, %EventPath%, Event, StartDate, %A_Space%
	IniRead, EndDate, %EventPath%, Event, EndDate, %A_Space%
	IniRead, MinVersion, %EventPath%, Event, MinVersion, %A_Space%
	
	If (EventName="" || MinVersion>verScript || StartDate="" || EndDate="" || (CurrentDate<StartDate && !RegExMatch(args, "i)/Dev")) || CurrentDate>EndDate)
		return
	
	EventName.="(" SubStr(EndDate, 7, 2) "." SubStr(EndDate, 5, 2) ")"
	
	If (EventLogo!="")
		LoadFile(EventLogo, configFolder "\Event\bg.jpg", true)
	
	If (EventMsg!="")
		showStartUI(EventName "`n" EventMsg, (EventLogo!="")?configFolder "\Event\bg.jpg":"")
	
	eventDataSplit:=StrSplit(loadFastFile(EventPath), "`n")
	For k, val in eventDataSplit
		If RegExMatch(eventDataSplit[k], "ResourceFile=(.*)$", rURL)=1
			loadEventResourceFile(rURL1)
			
	Globals.Set("eventName", EventName)
	
	Sleep 1000
	
	return
}

;Загрузить файл для события
loadEventResourceFile(URL){
	eventFileSplit:=strSplit(URL, "/")
	filePath:=configFolder "\Event\" eventFileSplit[eventFileSplit.MaxIndex()]
	LoadFile(URL, filePath, true)
}

;Меню события
eventMenu(){
	shFastMenu(configFolder "\Event\event.txt", false)
}

;Обновление Библиотеки
updateLib(libName){
	IniRead, updateLib, %configFile%, settings, updateLib, 0
	If !updateLib
		Return
	libPath:=A_ScriptDir "\Lib\" libName
	tempLibPath:=tempDir "\Lib\" libName
	LoadFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/Lib/" libName, tempLibPath, true)
	IniRead, currentVerLib, %libPath%, info, version, %A_Space%
	IniRead, newVerLib, %tempLibPath%, info, version, %A_Space%
	
	If (newVerLib="") || (Floor(verScript)<Floor(newVerLib)) {
		Return
	}
	If (newVerLib>currentVerLib) {
		FileCopy, %tempLibPath%, %libPath%, 1
		MsgBox,  0x1040, %prjName%, Обновлена библиотека '%libName%'`n`t%currentVerLib% >> %newVerLib%, 3
		ReStart()
	}
}

devCreateRuToEnLists(){
	Run *RunAs "%A_AhkPath%" "%A_ScriptDir%\_DevTools\_CreateRuToEnLists.ahk"
}

;Откатиться на релизную версию
devRestoreRelease() {
	IniWrite, 0, %configFile%, info, verConfig
	verScript:=0
	CheckUpdate(True)
}

;Перезагрузка данных
devClSD(){
	FileDelete, Data\Addons.ini
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	;FileDelete, Data\JSON\*
	FileDelete, Data\JSON\leagues.json
	FileRemoveDir, %A_Temp%\MegaEzik, 1
	FileRemoveDir, %tempDir%, 1
	FileRemoveDir, %configFolder%\Event, 1
	Sleep 50
	ReStart()
}

;Запись отладочной информации
devLog(msg){
	If !RegExMatch(args, "i)/Dev")
		return
	FormatTime, Time, dddd MMMM, dd.MM HH:mm:ss
	FileAppend, %Time% v%verScript% - %msg%`n, %configFolder%\%prjName%.log, UTF-8
}

;Добавление в отслеживаемый список
devAddInList(Line, File="devList.txt"){
	If !RegExMatch(args, "i)/Dev")
		return
	FilePath:=configFolder "\" File
	FileRead, DataList, %FilePath%
	DataListSplit:=strSplit(StrReplace(DataList, "`r", ""), "`n")
	For k, val in DataListSplit
		If DataListSplit[k]=Line
			return
	FileAppend, %Line%`n, %FilePath%, UTF-8
}

devStartUI(){
	InputBox, inputLine, Введите текст,,, 300, 100
	Globals.Set("vProgress", 0)
	Globals.Set("pProgress", 95)
	showStartUI((inputLine="")?"Здесь могла быть ваша реклама...":inputLine)
	sleep 5000
	closeStartUI()
}

/*
devFavoriteList(){
	Menu, favoriteList, Add
	Menu, favoriteList, DeleteAll
	Loop, %configFolder%\MyFiles\*.fmenu, 1
		Menu, favoriteList, Add, %A_LoopFileName%, devFavoriteSetFile
	Menu, favoriteList, Show
}

devFavoriteSetFile(Name){
	IniWrite, %Name%, %configFile%, settings, sMenu
}
*/

/*
devSpecialUpdater(){
	IniRead, update, %configFile%, settings, update, 0
	If !update
		Return
	
	FilePath:="Data\Packages.txt"
	IniRead, PackagesURL, %buildConfig%, settings, PackagesURL, %A_Space%
	If (PackagesURL!="")
		LoadFile(PackagesURL, FilePath, true)
		
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			PackName:=PackInfo[1]
			If RegExMatch(PackInfo[1], "^(\d+|\d+.\d+).upd.zip$", res)
				break
		}
	}
	If (verScript<res1) {
		MsgBox, 0x1024, %prjName%, Дополнение '%res1%.upd.zip' скорее всего содержит обновление для %prjName%!`n`nУстановить?
		IfMsgBox Yes
			pkgsMgr_loadPackage(res1 ".upd.zip")
		Return
	}
}
*/

showArgsInfo(){
	Msgbox, 0x1040, Список доступных параметров запуска, /Dev - режим разработчика`n/NoCurl - запрещает использование 'curl.exe'`n/ShowCurl - отображает выполнение 'curl.exe'`n/NoTheme - не применять системную тему`n/HideCmds - скрыть 'Меню команд'`n/PoE2 - принудительный режим PoE2(для отладки)
}

devVoid(){
}
