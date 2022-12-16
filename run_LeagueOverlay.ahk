
/*
	Оригинальная идея https://github.com/heokor/League-Overlay
	Данный скрипт создан MegaEzik
	
	Назначение дополнительных библиотек:
		*Gdip_All.ahk - Библиотека для работы с изображениями, авторство https://www.autohotkey.com/boards/viewtopic.php?t=6517
		*JSON.ahk - Разбор данных от api, авторство https://github.com/cocobelgica/AutoHotkey-JSON
		*Overlay.ahk - Набор функций для расчета и отображения изображений оверлея
		*Labyrinth.ahk - Загрузка убер-лабиринта с poelab.com
		*Updater.ahk - Проверка и установка обновлений
		*debugLib.ahk - Библиотека для функций отладки и тестирования новых функций
		*fastReply.ahk - Библиотека с функциями для команд
		*ItemDataConverterLib.ahk - Библиотека для конвертирования описания предмета
		*itemMenu.ahk - Библиотека для формирования меню предмета
		*MD5.ahk - Подсчет контрольной суммы файла
		*Gamepad.ahk - Отвечает за игровой контроллер
		*pkgsMgr.ahk - Управление дополнениями
	
	Управление:
		[Alt+F1] - Последнее изображение
		[Alt+F2] - Меню быстрого доступа
		Остальные клавиши по умолчанию не назначены и определяются пользователем через настройки или файл конфигурации
*/

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

;Подключение библиотек
#Include, %A_ScriptDir%\resources\ahk\Gdip_All.ahk
#Include, %A_ScriptDir%\resources\ahk\JSON.ahk
#Include, %A_ScriptDir%\resources\ahk\Overlay.ahk
#Include, %A_ScriptDir%\resources\ahk\Labyrinth.ahk
#Include, %A_ScriptDir%\resources\ahk\Updater.ahk
#Include, %A_ScriptDir%\resources\ahk\fastReply.ahk
#Include, %A_ScriptDir%\resources\ahk\debugLib.ahk
#Include, %A_ScriptDir%\resources\ahk\ItemDataConverterLib.ahk
#Include, %A_ScriptDir%\resources\ahk\itemMenu.ahk
#Include, %A_ScriptDir%\resources\ahk\MD5.ahk
#Include, %A_ScriptDir%\resources\ahk\Gamepad.ahk
#Include, %A_ScriptDir%\resources\ahk\pkgsMgr.ahk

;Объявление и загрузка переменных
global githubUser, prjName="LeagueOverlay_ru"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
If InStr(FileExist(A_ScriptDir "\..\Profile"), "D") {
	SplitPath, A_ScriptDir,, configFolder
	configFolder.="\Profile"
}
global configFile:=configFolder "\settings.ini"
global buildConfig:=A_ScriptDir "\resources\Build.ini"
global textCmd1, textCmd2, textCmd3, textCmd4, textCmd5, textCmd6, textCmd7, textCmd8, textCmd9, textCmd10, textCmd11, textCmd12, textCmd13, textCmd14, textCmd15, textCmd16, textCmd17, textCmd18, textCmd19, textCmd20, cmdNum=20
global verScript, args, LastImg, globalOverlayPosition, OverlayStatus=0, debugMode=0

Loop, %0%
	args.=" " %A_Index%
FileReadLine, verScript, resources\Updates.txt, 1

IniRead, githubUser, %buildConfig%, Settings, Author, MegaEzik

IniRead, LastImg, %configFile%, info, lastImg, %A_Space%
IniRead, globalOverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
IniRead, mouseDistance, %configFile%, settings, mouseDistance, 500
Globals.Set("mouseDistance", mouseDistance)

;Добавляем окна для отслеживания
GroupAdd, WindowGrp, ahk_exe GeForceNOWStreamer.exe
splitWinList:=strSplit(strReplace(WinList(), "`r", ""), "`n")
For k, val in splitWinList
	If (splitWinList[k]!="") {
		WinName:=splitWinList[k]
		GroupAdd, WindowGrp, %WinName%
	}
	
;Проверка требований и параметров запуска
checkRequirementsAndArgs()
	
;Установка иконки и описания в области уведомлений
If FileExist("resources\imgs\icon.png")
	Menu, Tray, Icon, resources\imgs\icon.png
Menu, Tray, Tip, %prjName% %verScript% | AHK %A_AhkVersion%

;UI загрузки и загрузка инструментов разработчика
showStartUI()
devInit()

;Проверка обновлений
IniRead, update, %configFile%, settings, update, 1
If update
	CheckUpdate()
IniRead, updateAHK, %configFile%, settings, updateAHK, 1
If update && updateAHK
	updateAutoHotkey()

;Проверка версии и перенос настроек
migrateConfig()

;Загрузка события, лабиринта, и данных для IDCL
loadEvent()
initLab()
ItemMenu_IDCLInit()

;Выполним все файлы с окончанием .ahk, передав им папку расположения скрипта
pkgsMgr_startCustomScripts()

;Назначим управление и создадим меню
menuCreate()
setHotkeys()

systemTheme()

;Завершение загрузки
closeStartUI()

Return

;#################################################

#IfWinActive ahk_group WindowGrp

;Проверка требований
checkRequirementsAndArgs() {
	If !A_IsAdmin
		ReStart()
	If RegExMatch(args, "i)/Help") {
		Msgbox, 0x1040, Список доступных параметров запуска, /Help - вывод данного сообщения`n/ShowCurl - отображать окно cURL`n/NoAddons - пропуск загрузки дополнений`n/BypassSystemCheck - пропуск проверки системы
		ExitApp
	}
	If !RegExMatch(args, "i)/BypassSystemCheck") {
		;RegExMatch(A_OSVersion, "(\d+)$", OSBuild)
		OSBuild:=DllCall("GetVersion") >> 16 & 0xFFFF        
		If (OSBuild<17763) {
			MsgBox, 0x1010, %prjName%, Для работы %prjName% требуется операционная система Windows 10 1809 или выше!
			ExitApp
		}
		If (A_PtrSize!=8) {
			msgtext:="Для работы " prjName " требуется 64-разрядный интерпретатор AutoHotkey!"
			SplitPath, A_AhkPath,,AHKDir
			If FileExist(AhkDir "\Installer.ahk")
				msgtext.="`n`nПосле нажатия кнопки 'ОК' откроется 'AutoHotkey Setup', выберите в нем 'Modify', а затем 'Unicode 64-bit'."
			MsgBox, 0x1010, %prjName%, %msgtext%
			If FileExist(AhkDir "\Installer.ahk")
				Run *RunAs "%AhkDir%\Installer.ahk"
			ExitApp
		}
	}
	If !FileExist(A_WinDir "\System32\curl.exe") {
		msgtext:="В вашей системе не найдена утилита 'curl.exe', без нее некоторые функции " prjName " не будут работать!"
		MsgBox, 0x1030, %prjName%, %msgtext%
	}
	;Запуск gdi+
	If !pToken:=Gdip_Startup()
		{
		   ;MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		   MsgBox, 48, %prjName%, Не удалось запустить gdi+! Пожалуйста, убедитесь, что в вашей системе он есть!
		}
	OnExit, Exit
}

;Перенос настроек
migrateConfig() {
	If !FileExist(configFolder "\MyFiles")
		FileCreateDir, %configFolder%\MyFiles
	If !FileExist(configFolder "\Presets")
		FileCreateDir, %configFolder%\Presets
	
	IniRead, verConfig, %configFile%, info, verConfig, 0
	If (verConfig!=verScript) {
		;FileCopy, %configFile%, %configFolder%\%verConfig%.ini, 1
		If (verConfig>0) {
			If (verConfig<210823.1) {
				FileRemoveDir, %A_MyDocuments%\LeagueOverlay_ru, 1
				FileRemoveDir, %configFolder%\cache, 1
				FileDelete, %configFolder%\Lab.jpg
				FileDelete, %configFolder%\notes.txt
				FileDelete, %configFolder%\trials.ini
				FileMoveDir, %configFolder%\images, %configFolder%\MyFiles, 2
				IniWrite, 1000, %configFile%, curl, limit-rate
				IniWrite, 3, %configFile%, curl, connect-timeout
				IniWrite, 0, %configFile%, settings, loadLab
				FileMove, %configFolder%\commands.txt, %configFolder%\cmds.preset, 1
				FileDelete, %configFolder%\curl.exe
				FileDelete, %configFolder%\curl-ca-bundle.crt
			}
			If (verConfig<220417.2) {
				FileMove, %configFolder%\highlight.txt, %configFolder%\highlight.list, 1
			}
			If (verConfig<221010) {
				FileMove, %configFolder%\cmds.preset, %configFolder%\MyFiles\MyMenu.preset, 1
			}
			If (verConfig<221010.7) {
				FileMove, %configFolder%\Presets\*.preset, %configFolder%\MyFiles\*.fmenu, 1
				FileMove, %configFolder%\MyFiles\*.preset, %configFolder%\MyFiles\*.fmenu, 1
				
				IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
				If (hotkeyToCharacterSelection!="") {
					IniWrite, %hotkeyToCharacterSelection%, %configFile%, fastReply, hotkeyCmd9
					IniWrite, /exit, %configFile%, fastReply, textCmd9
				}
				IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
				If (hotkeyForceSync!="") {
					IniWrite, %hotkeyForceSync%, %configFile%, fastReply, hotkeyCmd10
					IniWrite, /oos, %configFile%, fastReply, textCmd10
				}
			}
			If (verConfig<221010.8)
				IniWrite, PoE_Russian, %configFile%, settings, preset
		}
		
		showSettings()
		
		IniRead, lastImg, %configFile%, info, lastImg, %A_Space%
		IniRead, labLoadDate, %configFile%, info, labLoadDate, 0
		
		FileDelete, %configFile%
		sleep 25
		
		IniWrite, %verScript%, %configFile%, info, verConfig
		IniWrite, %lastImg%, %configFile%, info, lastImg
		If (labLoadDate!="")
			IniWrite, %labLoadDate%, %configFile%, info, labLoadDate
		
		saveSettings()
	}
}

;Формирует список окон для отслеживания
WinList(){
	MainWinList:=""
	If FileExist(configFolder "\windows.list") {
		FileRead, UserWinList, %configFolder%\windows.list
		MainWinList.=UserWinList "`n"
	}
	IniRead, preset, %configFile%, settings, preset, %A_Space%
	If (preset!="") {
		Path:=(InStr(preset, "*")=1?configFolder "\Presets\" SubStr(preset, 2):"resources\presets\" preset) "\windows.list"
		If FileExist(Path) {
			FileRead, PresetWinList, %Path%
			MainWinList.=PresetWinList "`n"
		}
	}
	return MainWinList
}

;Открыть последнее изображение
shLastImage(){
	SplitLastImg:=StrSplit(LastImg, "|")
	shOverlay(SplitLastImg[1], SplitLastImg[2], SplitLastImg[3])
}

;Загрузить событие
loadEvent(){
	IniRead, EventURL, %buildConfig%, settings, EventURL, %A_Space%
	IniRead, useEvent, %configFile%, settings, useEvent, 1
	If !useEvent || (EventURL="")
		return
	
	EventPath:="resources\data\event.txt"
	LoadFile(eventURL, EventPath, true)
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	
	IniRead, EventName, %EventPath%, Event, EventName, %A_Space%
	IniRead, EventLogo, %EventPath%, Event, EventLogo, %A_Space%
	IniRead, EventMsg, %EventPath%, Event, EventMsg, %A_Space%
	IniRead, Require, %EventPath%, Event, Require, %A_Space%
	
	IniRead, StartDate, %EventPath%, Event, StartDate, %A_Space%
	IniRead, EndDate, %EventPath%, Event, EndDate, %A_Space%
	IniRead, MinVersion, %EventPath%, Event, MinVersion, %A_Space%
	
	If (EventName="" || MinVersion>verScript || StartDate="" || EndDate="" || CurrentDate<StartDate || CurrentDate>EndDate)
		return
	
	If (Require!="") {
		IniRead, preset, %configFile%, settings, preset, %A_Space%
		If !RegExMatch(preset, Require)
			return
	}
	
	EventName.="(" SubStr(EndDate, 7, 2) "." SubStr(EndDate, 5, 2) ")"
	
	If (EventLogo!="")
		LoadFile(EventLogo, "resources\data\bg.jpg", true)
	
	showStartUI(EventName "`n" EventMsg, (EventLogo!="")?"resources\data\bg.jpg":"")
	
	eventDataSplit:=StrSplit(loadFastFile(EventPath), "`n")
	For k, val in eventDataSplit
		If RegExMatch(eventDataSplit[k], "ResourceFile=(.*)$", rURL)=1
			loadEventResourceFile(rURL1)
			
	Globals.Set("eventName", EventName)
	
	Sleep 1500
	
	return
}

;Загрузить файл для события
loadEventResourceFile(URL){
	eventFileSplit:=strSplit(URL, "/")
	filePath:="resources\data\" eventFileSplit[eventFileSplit.MaxIndex()]
	LoadFile(URL, filePath, true)
}

;Меню события
eventMenu(){
	shFastMenu("resources\data\event.txt", false)
}

;Открыть мой файл
shMyImage(imagename){
	commandFastReply(configFolder "\MyFiles\" imagename)
}

;Открыть папку с моими файлами
openMyImagesFolder(){
	Gui, Settings:Destroy
	Run, explorer "%configFolder%\MyFiles"
}

;Создать меню с Моими файлами
myImagesMenuCreate(expandMenu=true){
	If expandMenu {
		Loop, %configFolder%\MyFiles\*.*, 1
			If RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp|txt|fmenu)$")
				Menu, mainMenu, Add, %A_LoopFileName%, shMyImage
		Menu, mainMenu, Add
	} Else {
		Menu, myImagesMenu, Add
		Menu, myImagesMenu, DeleteAll
		
		Loop, %configFolder%\MyFiles\*.*, 1
			If RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp|txt|fmenu)$")
				Menu, myImagesMenu, Add, %A_LoopFileName%, shMyImage
		Menu, myImagesMenu, Add
		myImagesActions()
		;Menu, myImagesMenu, Add, Открыть папку, openMyImagesFolder
		Menu, mainMenu, Add, Мои файлы, :myImagesMenu
	}
}

;Меню действий для Моих файлов
myImagesActions(){
	Menu, myImagesSubMenu, Add, Заметку, createNewNote
	Menu, myImagesSubMenu, Add, Меню команд, createNewMenu
	Menu, myImagesMenu, Add, Создать, :myImagesSubMenu
	Menu, myImagesMenu, Add, Открыть папку, openMyImagesFolder
}

;Открыть меню действий для моих файлов
sMenuImagesActions(){
	Menu, myImagesMenu, Add
	Menu, myImagesMenu, DeleteAll
	myImagesActions()
	Menu, myImagesMenu, Show
}

;Окно с текстом
textFileWindow(Title, FilePath, ReadOnlyStatus=true, contentDefault=""){
	global
	tfwFilePath:=FilePath
	Gui, tfwGui:Destroy
	
	If (Title="")
		Title:=FilePath
	
	Gui, tfwGui:Font, s10, Consolas
	FileRead, tfwContentFile, %tfwFilePath%
	If ReadOnlyStatus {
		Gui, tfwGui:Add, Edit, w615 h380 +ReadOnly, %tfwContentFile%
	} Else {
		Menu, tfwMenuBar, Add
		Menu, tfwMenuBar, DeleteAll
		If (tfwContentFile="" && contentDefault!="")
			tfwContentFile:=contentDefault
		Menu, tfwMenuBar, Add, Сохранить `tCtrl+S, tfwSave
		If FileExist(tfwFilePath)
			Menu, tfwMenuBar, Add, Удалить `tCtrl+Del, tfwDelFile
		Menu, tfwMenuBar, Add, Закрыть `tEsc, tfwClose
		Gui, tfwGui:Menu, tfwMenuBar
		Gui, tfwGui:Add, Edit, w615 h380 vtfwContentFile, %tfwContentFile%
	}
	Gui, tfwGui:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, tfwGui:Show,, %Title%
	
	sleep 15
	BlockInput On
	If ReadOnlyStatus {
		SendInput, ^{Home}
	} Else {
		SendInput, ^{End}
	}
	BlockInput Off
}

;Создание заметки
createNewNote(){
	Gui, Settings:Destroy
	InputBox, fileName, Введите название для заметки,,, 300, 100,,,,, NewNote
	filePath:=configFolder "\MyFiles\" fileName ".txt"
	If (FileExist(filePath) || fileName="" || ErrorLevel) {
		traytip, %prjName%, Что-то пошло не так(
		return
	}
	textFileWindow("", filePath, false)
}

;Создание нового меню
createNewMenu(){
	Gui, Settings:Destroy
	InputBox, fileName, Введите название для файла меню,,, 300, 100,,,,, MyMenu
	filePath:=configFolder "\MyFiles\" fileName ".fmenu"
	If (FileExist(filePath) || fileName="" || ErrorLevel) {
		traytip, %prjName%, Что-то пошло не так(
		return
	}
	textFileWindow("", filePath, false, "Список команд>>|>https://pathofexile.fandom.com/wiki/Chat_console#Commands`n---`n@<last> sure`n/global 820`n/whois <last>`n/deaths`n/passives`n/atlaspassives`n/remaining`n/kills`n/dance")
}

;Закрытие окна с текстом
tfwClose(){
	Gui, tfwGui:Destroy
}

;Удаление файла
tfwDelFile(){
	global
	Gui, tfwGui:Submit
	msgbox, 0x1024, %prjName%, Удалить файл '%tfwFilePath%'?
	IfMsgBox No
		return
	FileDelete, %tfwFilePath%
	Gui, tfwGui:Destroy
}

;Сохранение файла
tfwSave(){
	global
	Gui, tfwGui:Submit
	FileDelete, %tfwFilePath%
	sleep 100
	FileAppend, %tfwContentFile%, %tfwFilePath%, UTF-8
	Gui, tfwGui:Destroy
}

;История изменений
showUpdateHistory(){
	textFileWindow("История изменений", "resources\Updates.txt")
}

;Лицензия
showLicense(){
	textFileWindow("Лицензия", "LICENSE.md")
}

;Отслеживаемые окна
setWindowsList(){
	textFileWindow("Отслеживаемые окна", configFolder "\windows.list", false, "ahk_exe notepad++.exe")
}

;Очистка кэша PoE
clearPoECache(){
	FileRemoveDir, %A_AppData%\Path of Exile\Minimap, 1
	
	msgbox, 0x1044, %prjName%, Во время очистки кэша рекомендуется закрыть игру.`n`nХотите продолжить?
	IfMsgBox No
		return

	SplashTextOn, 400, 20, %prjName%, Очистка кэша PoE, пожалуйста подождите...
	
	PoEConfigFolderPath:=A_MyDocuments "\My Games\Path of Exile"
	FileRemoveDir, %PoEConfigFolderPath%\OnlineFilters, 1
	FileDelete, %PoEConfigFolderPath%\*.dmp
	
	IniRead, PoECacheFolder, %PoEConfigFolderPath%\production_Config.ini, GENERAL, cache_directory, %A_Space%
	If (PoECacheFolder="")
		PoECacheFolder:=A_AppData "\Path of Exile\"
	FileRemoveDir, %PoECacheFolder%, 1
	
	SplashTextOff
	TrayTip, %prjName%, Очистка кэша завершена)
}

;Окно запуска
showStartUI(SpecialText="", LogoPath=""){
	Gui, StartUI:Destroy
	
	initMsgs := ["Подготовка макроса к работе"
				,"Опускаемся на 65535 глубину в 'Бесконечном спуске'"
				,"Поиск NPC 'Борис Бритва'"
				,"Призываем Создателя на Сумрачное взморье"
				,"Шагаем сквозь непроглядное безумие"
				,"Получаем приглашение Януса на поминки Кадиро"
				,"Предсказываем... огонь, насилие, СМЕРТЬ"
				,"Входим в 820ый для поиска лаб ... а ну да"
				,"Удаляем Зеркало Каландры из вашего фильтра предметов"]
	
	Random, randomNum, 1, initMsgs.MaxIndex()
	initMsg:=initMsgs[randomNum] "..."
	
	If (SpecialText!="")
		initMsg:=SpecialText
	
	initMsg:=StrReplace(initMsg, "/n", "`n")
	initMsg:=StrReplace(initMsg, "/t", "`t")
	
	IniRead, Supporters, %buildConfig%, Donation, Supporters, %githubUser%
	
	;dNames:=["AbyssSPIRIT", "milcart", "Pip4ik", "ДанилАР", "MONI9K", "ИванАК", "РоманВК", "Sapen"]
	dNames:=strSplit(Supporters, "|")
	Random, randomNum, 1, dNames.MaxIndex()
	dName:="@" dNames[randomNum] " ty) "
	
	If (LogoPath="") && FileExist("resources\imgs\bg.jpg")
		LogoPath:="resources\imgs\bg.jpg"
	
	If FileExist(LogoPath)
		Gui, StartUI:Add, Picture, x0 y0 w500 h70, %LogoPath%
	
	BGTitle:="7F3208"
	;If RegExMatch(verScript, "i)(Experimental|Alpha|Beta|RC)")
		;BGTitle:="505050"
	;Gui, StartUI:Add, Progress, w500 h26 x0 y0 Background%BGTitle%

	Gui, StartUI:Font, s12 c%BGTitle% bold
	
	Gui, StartUI:Add, Text, x5 y2 h20 w490 +Center BackgroundTrans, %prjName% %verScript% | AHK %A_AhkVersion%
	
	Gui, StartUI:Add, Text, x-5 y+2 w510 h1 0x12
	
	Gui, StartUI:Font, c000000
	
	Gui, StartUI:Font, s10 bold italic
	Gui, StartUI:Add, Text, x0 y+2 h30 w500 +Center BackgroundTrans, %initMsg%
	
	Gui, StartUI:Font, s8 norm italic
	Gui, StartUI:Add, Text, x4 y55 w150 BackgroundTrans, %dName%
	
	Gui, StartUI:Add, Text, x+2 w340 BackgroundTrans +Right, %args%
	
	;Gui, StartUI:+AlwaysOnTop -SysMenu
	Gui, StartUI:+ToolWindow -Caption +Border +AlwaysOnTop
	Gui, StartUI:Show, w500 h70, %prjName% %VerScript% | AHK %A_AhkVersion%
}

;Закрыть окно запуска
closeStartUI(){
	sleep 200
	Gui, StartUI:Destroy
	IniRead, showHistory, %configFile%, info, showHistory, 1
	If showHistory {
		showUpdateHistory()
		IniWrite, 0, %configFile%, info, showHistory
	}
	showDonateUIOnStart()
}

;Настройки
showSettings(){
	global
	Gui, Settings:Destroy
	
	IniRead, dCard, %buildConfig%, Donation, Card, %A_Space%
	IniRead, dNumber, %buildConfig%, Donation, Number, %A_Space%
	IniRead, dMsg, %buildConfig%, Donation, Msg, %A_Space%
	dMsg:=StrReplace(dMsg, "/n", "`n")
	
	;Настройки первой вкладки
	IniRead, OverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
	splitOverlayPosition:=strSplit(OverlayPosition, "/")
	posX:=splitOverlayPosition[1]
	posY:=splitOverlayPosition[2]
	posW:=splitOverlayPosition[3]
	posH:=splitOverlayPosition[4]
	
	IniRead, windowLine, %configFile%, settings, windowLine, %A_Space%
	IniRead, expandMyImages, %configFile%, settings, expandMyImages, 1
	IniRead, preset, %configFile%, settings, preset, PoE_Russian
	IniRead, mouseDistance, %configFile%, settings, mouseDistance, 500
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyGamepad, %configFile%, hotkeys, hotkeyGamepad, %A_Space%
	IniRead, hotkeyItemMenu, %configFile%, hotkeys, hotkeyItemMenu, %A_Space%
	
	;Настройки второй вкладки
	IniRead, UserAgent, %configFile%, curl, user-agent, %A_Space%
	IniRead, lr, %configFile%, curl, limit-rate, 1000
	IniRead, ct, %configFile%, curl, connect-timeout, 3
	IniRead, update, %configFile%, settings, update, 1
	IniRead, useEvent, %configFile%, settings, useEvent, 1
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	
	;Скрытые настройки
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	IniRead, sMenu, %configFile%, settings, sMenu, MyMenu.fmenu
	IniRead, useSystemTheme, %configFile%, settings, useSystemTheme, 1
	IniRead, updateAHK, %configFile%, settings, updateAHK, 1
	
	If FileExist("resources\imgs\bg.jpg")
		Gui, Settings:Add, Picture, x0 y0 w500 h70, resources\imgs\bg.jpg
	
	Gui, Settings:Add, Text, x320 y2 w170 +Right BackgroundTrans, Перевод на карту(внутри РФ): 
	Gui, Settings:Add, Edit, x320 y+1 w170 h18 +ReadOnly +Right, %dCard%
	Gui, Settings:Add, Text, x320 y+2 w170 +Right BackgroundTrans, Перевод по номеру телефона: 
	Gui, Settings:Add, Edit, x320 y+1 w170 h18 +ReadOnly +Right, %dNumber%
	
	Gui, Settings:Add, Text, x12 y8 w300 BackgroundTrans, %dMsg%
	
	Gui, Settings:Font, s11
	Gui, Settings:Add, Button, x290 y392 w210 h23 gsaveSettings, Применить и перезапустить ;💾 465
	
	Gui, Settings:Add, Tab3, x0 y70 w500 h345 Bottom, Основные|Загрузки|Команды ;Вкладки
	;Gui, Settings:Add, Tab, x0 y75 w640 h385 Bottom +Theme, Основные|Загрузки|Команды ;Вкладки
	Gui, Settings:Font, s8 normal
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Text, x12 y80 w385, Отслеживаемые окна:
	Gui, Settings:Add, Button, x+1 yp-3 w92 h23 gsetWindowsList, Изменить
	
	Gui, Settings:Add, Text, x12 yp+26 w185, Позиция изображений(пиксели):
	Gui, Settings:Add, Text, x+7 w12 +Right, X
	Gui, Settings:Add, Text, x+60 w12 +Right, Y
	Gui, Settings:Add, Text, x+60 w12 +Right, W
	Gui, Settings:Add, Text, x+60 w12 +Right, H
	
	Gui, Settings:Add, Edit, vposX x+-214 yp-2 w55 h18 Number, %posX%
	Gui, Settings:Add, UpDown, Range-99999-99999 0x80, %posX%
	Gui, Settings:Add, Edit, vposY x+17 w55 h18 Number, %posY%
	Gui, Settings:Add, UpDown, Range-99999-99999 0x80, %posY%
	Gui, Settings:Add, Edit, vposW x+17 w55 h18 Number, %posW%
	Gui, Settings:Add, UpDown, Range0-99999 0x80, %posW%
	Gui, Settings:Add, Edit, vposH x+17 w55 h18 Number, %posH%
	Gui, Settings:Add, UpDown, Range0-99999 0x80, %posH%
	
	presetList:=""
	Loop, resources\presets\*, 2
		presetList.="|" A_LoopFileName
	Loop, %configFolder%\Presets\*, 2
		presetList.="|*" A_LoopFileName
	
	Gui, Settings:Add, Text, x12 yp+24 w360, Набор:
	Gui, Settings:Add, DropDownList, vpreset x+27 yp-4 w90, %presetList%
	GuiControl,Settings:ChooseString, preset, %preset%
	
	Gui, Settings:Add, Text, x12 yp+26 w385, Смещение указателя(пиксели):
	Gui, Settings:Add, Edit, vmouseDistance x+2 yp-2 w90 h18 Number, %mouseDistance%
	Gui, Settings:Add, UpDown, Range5-99999 0x80, %mouseDistance%
	
	Gui, Settings:Add, Checkbox, vexpandMyImages x12 yp+24 w385 Checked%expandMyImages%, Развернуть 'Мои файлы'
	Gui, Settings:Add, Button, x+1 yp-4 w92 h23 gsMenuImagesActions, Действия
	
	Gui, Settings:Add, Text, x10 y+3 w480 h1 0x12
	
	Gui, Settings:Add, Text, x12 yp+6 w385, Последнее изображение:
	Gui, Settings:Add, Hotkey, vhotkeyLastImg x+2 yp-2 w90 h17, %hotkeyLastImg%
	
	Gui, Settings:Add, Text, x12 yp+21 w385, Меню быстрого доступа:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenu x+2 yp-2 w90 h17, %hotkeyMainMenu%
	
	Gui, Settings:Add, Text, x12 yp+21 w385, Меню предмета:
	Gui, Settings:Add, Hotkey, vhotkeyItemMenu x+2 yp-2 w90 h17, %hotkeyItemMenu%
	
	Gui, Settings:Add, Text, x12 yp+21 w385, Игровой контроллер(Beta) - Удерживайте [%hotkeyGamepad%] для использования
	Gui, Settings:Add, Button, x+1 yp-3 w92 h23 gcfgGamepad, Изменить
	
	Gui, Settings:Tab, 2 ;Вторая вкладка
	
	Gui, Settings:Add, Text, x12 y80 w120, cURL | User-Agent:
	Gui, Settings:Add, Edit, vUserAgent x+2 yp-2 w355 h17, %UserAgent%
	
	Gui, Settings:Add, Text, x12 yp+21 w385, cURL | Ограничение загрузки(Кб/с, 0 - без лимита):
	Gui, Settings:Add, Edit, vlr x+2 yp-2 w90 h18 Number, %lr%
	Gui, Settings:Add, UpDown, Range0-99999 0x80, %lr%
	
	Gui, Settings:Add, Text, x12 yp+22 w385, cURL | Время соединения(сек.):
	Gui, Settings:Add, Edit, vct x+2 yp-2 w90 h18 Number, %ct%
	Gui, Settings:Add, UpDown, Range1-99999 0x80, %ct%
	
	Gui, Settings:Add, Text, x10 y+5 w480 h1 0x12
	
	Gui, Settings:Add, Checkbox, vupdate x12 y+6 w480 Checked%update% , Автоматическая проверка обновлений
	
	Gui, Settings:Add, Checkbox, vuseEvent x12 yp+21 w480 Checked%useEvent%, Разрешить события
	
	Gui, Settings:Add, Checkbox, vloadLab x12 yp+21 w385 Checked%loadLab%, Скачивать раскладку лабиринта('Мои файлы'>Labyrinth.jpg)
	Gui, Settings:Add, Link, x+2 yp+0 w90 +Right, <a href="https://www.poelab.com/">POELab.com</a>
	
	Gui, Settings:Tab, 3 ; Третья вкладка
	
	Gui, Settings:Add, Text, x12 y80 w0 h0
	
	;Настраиваемые команды fastReply
	LoopVar:=cmdNum/2
	Loop %LoopVar% {
		IniRead, tempVar, %configFile%, fastReply, textCmd%A_Index%, %A_Space%
		If (tempVar="") {
			If A_Index=1
				tempVar:="/hideout"
			If A_Index=2
				tempVar:="/dnd"
			If A_Index=3
				tempVar:="/invite <last>"
			If A_Index=4
				tempVar:="/kick <last>"
			If A_Index=5
				tempVar:="/tradewith <last>"
			If A_Index=6
				tempVar:="@<last> sold("
			If A_Index=7
				tempVar:="@<last> 2 minutes"
			If A_Index=8
				tempVar:="_ty & gl, exile)"
			If A_Index=9
				tempVar:="/exit"
			If A_Index=10
				tempVar:="/oos"
		}
		Gui, Settings:Add, Edit, vtextCmd%A_Index% x12 y+1 w145 h17, %tempVar%
		
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%A_Index% x+2 w90 h17, %tempVar%
		
		TwoColumn:=Round(LoopVar+A_Index)
		IniRead, tempVar, %configFile%, fastReply, textCmd%TwoColumn%, %A_Space%
		Gui, Settings:Add, Edit, vtextCmd%TwoColumn% x+4 w145 h17, %tempVar%
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%TwoColumn%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%TwoColumn% x+2 w90 h17, %tempVar%
	}
	
	helptext:="/dance - простая команда`n/whois <last> - команда к последнему игроку`n@<last> ty, gl) - сообщение последнему игроку`n_ty, gl) - сообщение в чат области`n%ty, gl) - сообщение в групповой чат`n>calc.exe - выполнить`nmy.jpg - изображение/набор/текст`n!текст - всплывающая подсказка"
	helptext2:="--- - разделитель`n;/dance - комментарий`n<configFolder> - папка настроек`n<time> - время UTC`n<inputbox> - поле ввода"
	;Gui, Settings:Add, Text, x12 y+2 w237 cTeal, %helptext%
	Gui, Settings:Add, Text, x12 y+2 w237 c7F3208, %helptext%
	Gui, Settings:Add, Text, x+2 w237 c7F3208, %helptext2%
	
	Gui, Settings:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, Settings:Show, w500 h415, %prjName% %verScript% | AHK %A_AhkVersion% - Информация и настройки ;Отобразить окно настроек
}

;Сохранить Настройки
saveSettings(){
	global
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	Gui, Settings:Submit
			
	;Настройки первой вкладки
	IniWrite, %windowLine%, %configFile%, settings, windowLine
	IniWrite, %posX%/%posY%/%posW%/%posH%, %configFile%, settings, overlayPosition
	IniWrite, %expandMyImages%, %configFile%, settings, expandMyImages
	IniWrite, %preset%, %configFile%, settings, preset
	IniWrite, %mouseDistance%, %configFile%, settings, mouseDistance
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %hotkeyGamepad%, %configFile%, hotkeys, hotkeyGamepad
	IniWrite, %hotkeyItemMenu%, %configFile%, hotkeys, hotkeyItemMenu
	
	;Настройки второй вкладки
	IniWrite, %UserAgent%, %configFile%, curl, user-agent
	IniWrite, %lr%, %configFile%, curl, limit-rate
	IniWrite, %ct%, %configFile%, curl, connect-timeout
	IniWrite, %update%, %configFile%, settings, update
	IniWrite, %useEvent%, %configFile%, settings, useEvent
	IniWrite, %loadLab%, %configFile%, settings, loadLab
	
	;Скрытые настройки
	IniWrite, %debugMode%, %configFile%, settings, debugMode
	IniWrite, %sMenu%, %configFile%, settings, sMenu
	IniWrite, %useSystemTheme%, %configFile%, settings, useSystemTheme
	IniWrite, %updateAHK%, %configFile%, settings, updateAHK

	;Настраиваемые команды fastReply
	Loop %cmdNum% {
		tempVar:=hotkeyCmd%A_Index%
		IniWrite, %tempVar%, %configFile%, fastReply, hotkeyCmd%A_Index%
		
		tempVar:=textCmd%A_Index%
		IniWrite, %tempVar%, %configFile%, fastReply, textCmd%A_Index%
	}	
	
	ReStart()
}

;Назначение клавиш
setHotkeys(){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	;Инициализация основных клавиш макроса
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, %A_Space%
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, %A_Space%
	If (hotkeyLastImg!="")
		Hotkey, % hotkeyLastImg, shLastImage, On
	If (hotkeyMainMenu!="")
		Hotkey, % hotkeyMainMenu, shMainMenu, On
	
	;Инициализация настраиваемых команд fastReply
	Loop %cmdNum% {
		IniRead, tempvar, %configFile%, fastReply, textCmd%A_Index%, %A_Space%
		textCmd%A_Index%:=tempvar
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		If (textCmd%A_Index%!="")  && (RegExMatch(textCmd%A_Index%, ";")!=1) && (tempVar!="")
			Hotkey, % tempVar, fastCmd%A_Index%, On
	}
	
	;Инициализация Игрового контроллера
	IniRead, hotkeyGamepad, %configFile%, hotkeys, hotkeyGamepad, %A_Space%
	If (hotkeyGamepad!="")
		Hotkey, % hotkeyGamepad, shGamepadMenu, On
}

;Меню области уведомлений
menuCreate(){
	If FileExist("LICENSE.md")
		Menu, Tray, Add, Лицензия, showLicense
	Menu, Tray, Add, История изменений, showUpdateHistory
	Menu, Tray, Add
	Menu, Tray, Add, Настройки, showSettings
	Menu, Tray, Default, Настройки
	Menu, Tray, Add, Очистить кэш PoE, clearPoECache
	Menu, Tray, Add, Дополнения, pkgsMgr_packagesMenu
	Menu, Tray, Add, Меню отладки, :devMenu
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить, ReStart
	Menu, Tray, Add, Выход, Exit
	Menu, Tray, NoStandard
}

;Загрузить Набор
loadPreset(){
	IniRead, preset, %configFile%, settings, preset, %A_Space%
	If (preset="")
		return
	Path:=(InStr(preset, "*")=1?configFolder "\Presets\" SubStr(preset, 2):"resources\presets\" preset)
	
	Loop, %Path%\*, 0
		If RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp|txt)$")
			Menu, mainMenu, Add, %A_LoopFileName%, shPreset
	Menu, mainMenu, Add
}

;Открыть файл набора
shPreset(FileName){
	IniRead, preset, %configFile%, settings, preset, %A_Space%
	FilePath:=(InStr(preset, "*")=1?configFolder "\Presets\" SubStr(preset, 2):"resources\presets\" preset) "\" FileName
	
	commandFastReply(FilePath)
}

;Сформировать и открыть основное меню
shMainMenu(Gamepad=false){
	removeToolTip()
	destroyOverlay()
	Menu, mainMenu, Add
	Menu, mainMenu, DeleteAll
	
	eventName:=Globals.Get("eventName")
	If (eventName!="") {
		Menu, mainMenu, Add, %eventName%, eventMenu
		Menu, mainMenu, Add
	}
	
	loadPreset()
	
	IniRead, expandMyImages, %configFile%, settings, expandMyImages, 1
	myImagesMenuCreate((expandMyImages || Gamepad)?true:false)
	
	IniRead, sMenu, %configFile%, settings, sMenu, MyMenu.fmenu
	If (expandMyImages || Gamepad) && (sMenu!="") && FileExist(configFolder "\MyFiles\" sMenu){
		fastMenu(configFolder "\MyFiles\" sMenu)
		Menu, mainMenu, Add, %sMenu%, :fastMenu
		Menu, mainMenu, Rename, %sMenu%, Избранные команды
	}
	
	Menu, mainMenu, Add, Область уведомлений, :Tray
	sleep 5
	Menu, mainMenu, Show
}

;Открыть папку настроек
openConfigFolder(){
	Run, explorer "%configFolder%"
}

;Открыть папку скрипта
openScriptFolder(){
	Run, explorer "%A_ScriptDir%"
}

;Перезапуск
ReStart(){
	Gdip_Shutdown(pToken)
	sleep 250
	;Reload
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%" %args%
	ExitApp
}

;Иногда после запуска будем предлагать поддержать проект
showDonateUIOnStart() {
	Random, randomNum, 1, 5
	If (randomNum=1)
		traytip, %prjName%, Поддержи %githubUser% <3
}

;Всплывающая подсказка
showToolTip(msg, t=0, umd=true) {
	msg:=StrReplace(msg, "/n", "`n")
	msg:=StrReplace(msg, "/t", "`t")
	ToolTip
	sleep 5
	ToolTip, %msg%
	If t!=0
		SetTimer, removeToolTip, %t%
	If umd {
		MouseGetPos, CurrX, CurrY
		Globals.Set("ttCurrStartPosX", CurrX)
		Globals.Set("ttCurrStartPosY", CurrY)
		SetTimer, timerToolTip, 50
	}
}

;Удаление всплывающей подсказки
removeToolTip() {
	ToolTip
	SetTimer, removeToolTip, Delete
	SetTimer, timerToolTip, Delete
}

;Таймер для всплывающей подсказки
timerToolTip() {
	MouseGetPos, CurrX, CurrY
	If (CurrX - Globals.Get("ttCurrStartPosX"))** 2 + (CurrY - Globals.Get("ttCurrStartPosY")) ** 2 > Globals.Get("mouseDistance") ** 2
		removeToolTip()
}

;Скачивание файла из сети
LoadFile(URL, FilePath, CheckDate=false, MD5="") {	
	;Сверим дату
	If CheckDate {
		FormatTime, CurrentDate, %A_Now%, yyyyMMdd
		FileGetTime, LoadDate, %FilePath%, M
		FormatTime, LoadDate, %LoadDate%, yyyyMMdd
		IfNotExist, %FilePath%
			LoadDate:=0
		If (LoadDate=CurrentDate)
			return false
	}
	
	FileDelete, %FilePath%
	Sleep 100
	
	If FileExist(A_WinDir "\System32\curl.exe") {
		IniRead, UserAgent, %configFile%, curl, user-agent, %A_Space%
		If (UserAgent="")
			UserAgent:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
		IniRead, lr, %configFile%, curl, limit-rate, 1000
		IniRead, ct, %configFile%, curl, connect-timeout, 10
		
		CurlLine:="curl -L -A """ UserAgent """ -o """ FilePath """" " " """" URL """"
		If ct>0
			CurlLine.=" --connect-timeout " ct
		If lr>0
			CurlLine.=" --limit-rate " lr "K"
		If RegExMatch(args, "i)/ShowCurl")
			RunWait, %CurlLine%
		Else
			RunWait, %CurlLine%, , hide
	} Else {
		UrlDownloadToFile, %URL%, %FilePath%
	}
	
	devLog(CurlLine)
	
	If (MD5!="" && MD5!=MD5_File(FilePath)) {
		FileDelete, %FilePath%
		Sleep 100
		return false
	}
	return true	
}

;Использование системной темы
systemTheme(){
	IniRead, useSystemTheme, %configFile%, settings, useSystemTheme, 1
	If !useSystemTheme
		return
	uxtheme:=DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
	SetPreferredAppMode:=DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
	FlushMenuThemes:=DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
	DllCall(SetPreferredAppMode, "int", 1)
	DllCall(FlushMenuThemes)
}

;#################################################

Exit:
; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)
	sleep 250
	ExitApp
Return

;Нужно для работы с ItemDataConverter
class Globals {
	Set(name, value) {
		Globals[name] := value
	}
	Get(name, value_default="") {
		return Globals[name]
	}
}
