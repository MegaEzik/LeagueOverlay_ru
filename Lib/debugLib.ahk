
/*
[info]
version=250822
*/

;Инициализация и создание меню разработчика
devPreInit(){
	;If RegExMatch(args, "i)/Dev") && FileExist("Data\imgs\icon_dev.png")
	;	Menu, Tray, Icon, Data\imgs\icon_dev.png
	If RegExMatch(args, "i)/PoE2") {
		showStartUI("Сборка LeagueOverlay_ru под Ранний доступ PoE 2", "Data\imgs\poe2ea.jpg", "400000")
	}
	
	;devSpecialUpdater()
	SplitPath, A_AhkPath,,AHKPath
	If (configFolder = A_MyDocuments "\AutoHotKey\LeagueOverlay_ru") && FileExist(configFolder "\pkgsMgr.ini") && FileExist(AHKPath "\AutoHotkeyU32.exe") && FileExist(A_ScriptDir "\Data\MigrateAddons.ahk")
		RunWait, "%AHKPath%\AutoHotkeyU32.exe" "%A_ScriptDir%\Data\MigrateAddons.ahk" "%A_ScriptFullPath%"
	
	Menu, devMenu, Add, Загрузить Лабиринт, loadLabWithCookies
	;Menu, devMenu, Add, Cookies, devEditCookies
	Menu, devMenu, Add, Экран запуска(5 секунд), devStartUI
	;Menu, devMenu, Add, Отслеживаемые файлы, devTrackingList
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
}

devPostInit(){
	Sleep 100
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
	IniRead, EventIcon, %EventPath%, Event, EventIcon, %A_Space%
	IniRead, EventMsg, %EventPath%, Event, EventMsg, %A_Space%
	IniRead, AccentColor, %EventPath%, Event, AccentColor, %A_Space%
	IniRead, MsgColor, %EventPath%, Event, MsgColor, 000000
	IniRead, StartDate, %EventPath%, Event, StartDate, %A_Space%
	IniRead, EndDate, %EventPath%, Event, EndDate, %A_Space%
	IniRead, MinVersion, %EventPath%, Event, MinVersion, %A_Space%
	IniRead, EventLeagues, %EventPath%, Event, EventLeagues, %A_Space%
	
	If (EventName="" || MinVersion>verScript || StartDate="" || EndDate="" || (CurrentDate<StartDate && !RegExMatch(args, "i)/Dev")) || CurrentDate>EndDate)
		return
	
	EventName.="(" SubStr(EndDate, 7, 2) "." SubStr(EndDate, 5, 2) ")"
	
	If (EventLogo!="")
		LoadFile(EventLogo, configFolder "\Event\bg.jpg", true)
	
	If (EventIcon!="")
		LoadFile(EventIcon, configFolder "\Event\icon.png", true)
	If FileExist(configFolder "\Event\icon.png")
		Menu, Tray, Icon, %configFolder%\Event\icon.png
	
	If (EventMsg!="")
		showStartUI(EventName "`n" EventMsg, (EventLogo!="")?configFolder "\Event\bg.jpg":"", AccentColor, MsgColor)
		
	If (EventLeagues!="")
		Globals.Add("devAdditionalLeagues", "|" EventLeagues)
	
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
	FileDelete, %configFolder%\%prjName%.log
	FileDelete, Data\Addons.ini
	FileDelete, %configFolder%\MyFiles\Lab1_Normal.jpg
	FileDelete, %configFolder%\MyFiles\Lab2_Cruel.jpg
	FileDelete, %configFolder%\MyFiles\Lab3_Merciless.jpg
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	;FileDelete, Data\JSON\*
	FileDelete, Data\JSON\leagues.json
	FileDelete, Data\JSON\leagues2.json
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

;Тест окна запуска
devStartUI(){
	InputBox, inputLine, Введите текст,,, 500, 100
	Globals.Set("vProgress", 0)
	Globals.Set("pProgress", 95)
	showStartUI((inputLine="")?"Здесь могла быть ваша реклама...":inputLine)
	sleep 5000
	closeStartUI()
}

;Окно редактирования для отслеживаемых файлов
devTrackingList(){
	textFileWindow("Список прямых ссылок на файлы в интернете для автоматического отслеживания и загрузки в 'Мои файлы'", configFolder "\TrackingURLs.txt", false)
}

;Загрузка отслеживаемых файлов
devLoadTrackingFiles(){
	FileRead, Data, %configFolder%\TrackingURLs.txt
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	
	If (DataSplit.MaxIndex()>1)
		customProgress(, "Обновление отслеживаемых файлов...")
	For k, val in DataSplit 
		If (RegExMatch(DataSplit[k], "i)https://(.*).(png|jpg|jpeg|bmp|txt|fmenu)$")=1){
		customProgress(A_Index/DataSplit.MaxIndex()*100)
		FileURL:=DataSplit[k]
		SplitPath, FileURL, FileName
			LoadFile(FileURL, configFolder "\MyFiles\" FileName, CheckDate=true)
		}
	Gui CustomProgressUI:Destroy
}

devEditCookies(){
	FileRead, Cookies, %configFolder%\cookies.txt
	If (Cookies="")
		Cookies:="cf_clearance="
	InputBox, Cookies, Cookies,,, 500, 100,,,,, %Cookies%
	FileDelete, %configFolder%\cookies.txt
	If (Cookies!="") && (Cookies!="cf_clearance=")
		FileAppend, %Cookies%, %configFolder%\cookies.txt, UTF-8
	ReStart()
}

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
	Msgbox, 0x1040, Список доступных параметров запуска, /Dev - режим разработчика`n`n/NoCurl - запрещает использование 'curl.exe'`n`n/ShowCurl - отображает выполнение 'curl.exe'`n`n/NoTheme - не применять системную тему к меню`n`n/Gamepad - компоновка 'Меню быстрого доступа' в стиле используемом с игровым контроллером`n`n/PoE2 - принудительный режим PoE2(для отладки)
}

devVoid(){
}
