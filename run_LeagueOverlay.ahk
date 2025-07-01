/*
	Оригинальная идея https://github.com/heokor/League-Overlay
	Данный скрипт создан MegaEzik
	
	Назначение дополнительных библиотек:
		*Gdip_All - Библиотека для работы с изображениями, авторство https://www.autohotkey.com/boards/viewtopic.php?t=6517
		*JSON - Разбор данных от api, авторство https://github.com/cocobelgica/AutoHotkey-JSON
		*Overlay - Набор функций для расчета и отображения изображений оверлея
		*Labyrinth - Загрузка убер-лабиринта с poelab.com
		*Updater - Проверка и установка обновлений
		*debugLib - Библиотека для функций отладки и тестирования новых функций
		*fastReply - Библиотека с функциями для команд
		*ItemDataConverterLib- Библиотека для конвертирования описания предмета
		*itemMenu - Библиотека для формирования меню предмета
		*Gamepad - Отвечает за игровой контроллер
		*pkgsMgr - Управление дополнениями
	
	Управление:
		[Alt+F1] - Последнее изображение
		[Alt+F2] - Меню быстрого доступа
		Остальные клавиши по умолчанию не назначены и определяются пользователем через настройки или файл конфигурации
*/

;#NoEnv
#Requires AutoHotkey 1.1
#SingleInstance Force
;FileEncoding, UTF-8
SetWorkingDir %A_ScriptDir%

;Подключение библиотек
#Include <Gdip_All>
#Include <JSON>
#Include <Overlay>
#Include <Labyrinth>
#Include <Updater>
#Include <fastReply>
#Include <debugLib>
#Include <ItemDataConverterLib>
#Include <itemMenu>
#Include <Gamepad>
#Include <pkgsMgr>

;Объявление и загрузка переменных
global githubUser, prjName="LeagueOverlay_ru", buildConfig:=A_ScriptDir "\Data\Build.ini"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
If InStr(FileExist(A_ScriptDir "\..\Profile"), "D") {
	SplitPath, A_ScriptDir,, configFolder
	configFolder.="\Profile"
}
global configFile:=configFolder "\settings.ini"
global tempDir:=configFolder "\Temp"
FileCreateDir, %configFolder%\Scripts
FileCreateDir, %tempDir%

global verScript, args, LastImg, globalOverlayPosition, startProgress, cpPos, OverlayStatus=0, cmdNum=20

Loop, %0%
	args.=" " %A_Index%
FileReadLine, verScript, Data\Updates.txt, 1
If RegExMatch(verScript, "(\d+\.\d+|\d+)", ver)
	verScript:=ver1

IniRead, githubUser, %buildConfig%, Settings, Author, MegaEzik
IniRead, LastImg, %configFile%, info, lastImg, %A_Space%
IniRead, globalOverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
IniRead, mouseDistance, %configFile%, settings, mouseDistance, 500
Globals.Set("mouseDistance", mouseDistance)

;Добавляем окна для отслеживания
global WindowGrp, WinGrp2, WinGrp3
addWindow("ahk_exe GeForceNOW.exe")
addWinList()
	
;Проверка требований и параметров запуска
checkRequirementsAndArgs()

;Установка иконки и описания в области уведомлений
Menu, Tray, Tip, %prjName% %verScript% | AHK %A_AhkVersion%
If FileExist("Data\imgs\icon.png")
	Menu, Tray, Icon, Data\imgs\icon.png
	
;Отображение UI загрузки, запуск инструмента переноса настроек
showStartUI()
migrateConfig()

;Инициализация инструментов отладки
suip(5)
devPreInit()

;Проверка обновлений
IniRead, update, %configFile%, settings, update, 1
suip(10)
If update {
	CheckUpdate(True)
	SetTimer, CheckUpdate, 7200000
}

;Загрузка события
suip(25)
loadEvent()

;Обновление компонентов
If update {
	;updateAutoHotkey()
	suip(30)
	updateLib("debugLib.ahk")
	suip(35)
	updateLib("Labyrinth.ahk")
	suip(40)
	updateLib("ItemDataConverterLib.ahk")
	suip(45)
	updateLib("itemMenu.ahk")
	suip(50)
	LeaguesList(false)
}

;Загрузка лабиринта, отслеживаемых и данных для IDCL
suip(80)
initLab()
suip(90)
ItemMenu_IDCLInit()

;Выполним все файлы с окончанием .ahk, передав им папку расположения скрипта
suip(95)
pkgsMgr_startCustomScripts()

;Назначим управление и создадим меню
menuCreate()
setHotkeys()

systemTheme()

;Завершение инициализаций
devPostInit()
closeStartUI()

Return

;#################################################

#IfWinActive ahk_group WindowGrp

;Проверка требований
checkRequirementsAndArgs() {
	If !A_IsAdmin
		ReStart()
	If (A_PtrSize<8) {
		MsgBox, 0x1010, %prjName%, Для работы %prjName% требуется 64-разрядный интерпретатор AutoHotkey!
		ExitApp
	}
	IniRead, startArgs, %configFile%, settings, startArgs, %A_Space%
	If (startArgs!="") && !InStr(startArgs, "  ") {
		If !RegExMatch(args, Trim(startArgs)) {
			args.=" " StartArgs
			ReStart()
		}
	}
	If GetKeyState("LCtrl", P) && !RegExMatch(args, "i)/Dev") {
		args.=" /Dev"
		ReStart()
	}
	/*
	If !DllCall("Wininet\InternetCheckConnection", Str, "https://ya.ru/", UInt, FLAG_ICC_FORCE_CONNECTION := 1, UInt, 0)
		MsgBox, 0x1010, %prjName%, Не удалось проверить доступность сети интернет!`n`nОтсутствие доступа к сети не позволит обновить данные и может негативно сказаться на работе %prjName%!, 10
	*/
	If !FileExist(A_WinDir "\System32\curl.exe") {
		msgtext:="В вашей системе не найдена утилита " A_WinDir "\System32\curl.exe, без нее могут возникнуть проблемы в работе " prjName "!"
		MsgBox, 0x1010, %prjName%, %msgtext%, 7
	}
	If (A_ScreenWidth<1024 || A_ScreenHeight<720) {
		msgtext:="Разрешение основного дисплея ниже 1024x720, некоторые элементы " prjName " могут не поместиться на экран!"
		MsgBox, 0x1010, %prjName%, %msgtext%, 7
	}
	;Запуск gdi+
	If !pToken:=Gdip_Startup()
		TrayTip, %prjName%, Ошибка инициализации GDI+!
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
		If RegExMatch(args, "i)/Dev") {
			FileCreateDir, %configFolder%\Backups
			FileCopy, %configFile%, %configFolder%\Backups\%verConfig%.ini, 1
			FileDelete, %configFolder%\%prjName%.log
		}
		IniRead, AddonsConfig, %configFile%, Addons
		If (verConfig>0) {
			FileDelete, Data\Packages.txt
			FileDelete, Data\JSON\leagues.json
			FileDelete, Data\JSON\leagues2.json
			IniRead, expandMyImages, %configFile%, settings, expandMyImages, 1
			If (verConfig<221028) {
				FileRemoveDir, %A_MyDocuments%\LeagueOverlay_ru, 1
				FileRemoveDir, %configFolder%\cache, 1
				FileDelete, %configFolder%\Lab.jpg
				FileDelete, %configFolder%\notes.txt
				FileDelete, %configFolder%\trials.ini
				FileMoveDir, %configFolder%\images, %configFolder%\MyFiles, 2
				FileMove, %configFolder%\commands.txt, %configFolder%\cmds.preset, 1
				FileDelete, %configFolder%\curl.exe
				FileDelete, %configFolder%\curl-ca-bundle.crt
				FileMove, %configFolder%\highlight.txt, %configFolder%\highlight.list, 1
				FileMove, %configFolder%\cmds.preset, %configFolder%\MyFiles\MyMenu.preset, 1
				FileMove, %configFolder%\Presets\*.preset, %configFolder%\MyFiles\*.fmenu, 1
				FileMove, %configFolder%\MyFiles\*.preset, %configFolder%\MyFiles\*.fmenu, 1
			}
			If (verconfig<241206.2) {
				IniWrite, 1, %configFile%, settings, updateLib
				FileMove, %configFolder%\MyFiles\MyMenu.fmenu, %configFolder%\cmds.txt, 1
				FileDelete, %configFolder%\windows.list
			}
			If (verconfig<250131)
				FileRemoveDir, %configFolder%\Presets\PoE2EA, 1
			If (verconfig<250606.2) {
				If !FileExist(configFolder "\cookies.txt")
					IniWrite, 0, %configFile%, settings, loadLab
				IniWrite, 0, %configFile%, settings, updateLib
			}
		}
		
		showSettings()
		
		IniRead, lastImg, %configFile%, info, lastImg, %A_Space%
		
		FileDelete, %configFile%
		sleep 25
		
		IniWrite, %verScript%, %configFile%, info, verConfig
		IniWrite, %lastImg%, %configFile%, info, lastImg
		IniWrite, %AddonsConfig%, %configFile%, Addons
		
		saveSettings()
	}
}

;Формирует список окон для отслеживания
addWinList(){
	IniRead, UserWinList, %configFile%, Windows
	Window:=strSplit(StrReplace(UserWinList, "`r", ""), "`n")
	For k, val in Window
		If (Window[k]!="")
			addWindow(Window[k])
	
	Loop 3 {
		;presetNum:=(A_Index=1)?"":A_Index
		presetNum:=A_Index
		IniRead, preset, %configFile%, settings, preset%presetNum%, %A_Space%
		If (preset!="") {
			Path:=(InStr(preset, "*")=1?configFolder "\Presets\" SubStr(preset, 2):"Data\presets\" preset) "\PresetConfig.ini"
			IniRead, WindowsList, %Path%, Windows
			Window:=strSplit(StrReplace(WindowsList, "`r", ""), "`n")
			For k, val in Window
				If (Window[k]!="")
					addWindow(Window[k], presetNum)
		}
	}
}

;Добавить окно для отслеживания
addWindow(Line, GroupNum=1){
	GroupAdd, WindowGrp, %Line%
	If (GroupNum>1)
		GroupAdd, WinGrp%GroupNum%, %Line%
}

;Открыть последнее изображение
shLastImage(){
	SplitLastImg:=StrSplit(LastImg, "|")
	shOverlay(SplitLastImg[1], SplitLastImg[2], SplitLastImg[3])
}

;Формирование списка лиг
LeaguesList(showPorgress=true){
	If showPorgress
		SplashTextOn, 400, 20, %prjName%, Обновление списка Лиг, пожалуйста подождите...
	
	leagues_list:=Globals.Get("devAdditionalLeagues")
	
	File1:=A_ScriptDir "\Data\JSON\leagues.json"
	File2:=A_ScriptDir "\Data\JSON\leagues2.json"
	LoadFile("https://api.pathofexile.com/leagues?realm=pc", File1, true)
	;LoadFile("https://api.pathofexile.com/leagues?realm=poe2", File2, true)
	FileRead, DataFile1, %File1%
	FileRead, DataFile2, %File2%
	
	html:=StrReplace(DataFile1 "`n" DataFile2, "},{", "},`n{")
	
	htmlSplit:=StrSplit(html, "`n")
	For k, val in htmlSplit {
		If RegExMatch(htmlSplit[k], "U)id"":""(.*)""", res) && RegExMatch(htmlSplit[k], """realm"":""(pc|poe2)""") {
			If !RegExMatch(res1, "i)(SSF|Solo Self-Found)") && !RegExMatch(leagues_list, res1)
				leagues_list.="|" res1
		}
	}
	
	;leagues_list.=Globals.Get("devAdditionalLeagues")
	
	leagues_list:=subStr(leagues_list, 2)
	
	SplashTextOff
	
	return leagues_list
}

;Открыть мой файл
shMyFile(FileName){
	IniRead, FileName, %configFile%, SpecialNames, %FileName%, %FileName%
	If GetKeyState("LCtrl", P) {
		myFilesActions(FileName)
		return
	}
	commandFastReply(configFolder "\MyFiles\" FileName)
}

;Открыть папку с моими файлами
openMyFilesFolder(){
	Run, explorer "%configFolder%\MyFiles"
}

;Создать меню с Моими файлами
myFilesMenuCreate(expandMenu=true){
	IniRead, SpecialNamesList, %configFile%, SpecialNames
	SpecialNamesSplit:=StrSplit(SpecialNamesList, "`n")
		
	Menu, myFilesMenu, Add
	Menu, myFilesMenu, DeleteAll
	
	Loop, %configFolder%\MyFiles\*.*, 1
		If RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp|txt|fmenu|url|lnk)$") {
			If expandMenu
				Menu, mainMenu, Add, %A_LoopFileName%, shMyFile
			Menu, myFilesMenu, Add, %A_LoopFileName%, shMyFile
		}
			
	For k, val in SpecialNamesSplit {
		SplitName:=StrSplit(SpecialNamesSplit[k], "=")
		NewName:=SplitName[1]
		OldName:=SplitName[2]
		If FileExist(configFolder "\MyFiles\" OldName) {
			If expandMenu
				Menu, mainMenu, Rename, %OldName%, %NewName%
			Menu, myFilesMenu, Rename, %OldName%, %NewName%
		}
	}
	
	If expandMenu {
		Menu, mainMenu, Add
	} Else {
		Menu, myFilesMenu, Add
		Menu, myFilesMenu, Add, Действия, myFilesActions
		Menu, mainMenu, Add, Мои файлы, :myFilesMenu
	}
}

;Окно с текстом
textFileWindow(Title, FilePath="", ReadOnlyStatus=true, contentDefault=""){
	global
	tfwFilePath:=FilePath
	Gui, tfwGui:Destroy
	
	tfwTitle:=prjName
	If (Title!="")
		tfwTitle.=" - " Title
	If (Title="") && (tfwFilePath!="")
		tfwTitle.=" - " tfwFilePath
		
	
	IniRead, fSize, %configFile%, settings, tfwFontSize, 12
	Gui, tfwGui:Font, s%fSize%, Consolas
	tfwContentFile:=contentDefault
	If (tfwFilePath!="") && FileExist(tfwFilePath) {
		FileRead, tfwContentFile, %tfwFilePath%
		If (StrLen(tfwContentFile)>65535) {
			Run *RunAs notepad.exe "%tfwFilePath%"
			return
		}
	}
	Gui, tfwGui:+AlwaysOnTop -MaximizeBox
	If ReadOnlyStatus {
		Gui, tfwGui:Add, Edit, x0 y0 w1000 h640 +ReadOnly, %tfwContentFile%
		Gui, tfwGui: -MinimizeBox
	} Else {
		Menu, tfwFontMenu, Add
		Menu, tfwFontMenu, DeleteAll
		Menu, tfwFontMenu, Add, 8,tfwSetFontSize
		Menu, tfwFontMenu, Add, 10,tfwSetFontSize
		Menu, tfwFontMenu, Add, 11,tfwSetFontSize
		Menu, tfwFontMenu, Add, 12,tfwSetFontSize
		Menu, tfwFontMenu, Add, 14,tfwSetFontSize
		Menu, tfwFontMenu, Add, 16,tfwSetFontSize
		Menu, tfwFontMenu, Add, 18,tfwSetFontSize
		Menu, tfwFontMenu, Add, %fSize%,tfwSetFontSize
		Menu, tfwFontMenu, Check, %fSize%
		Menu, tfwMenuBar, Add
		Menu, tfwMenuBar, DeleteAll
		Menu, tfwMenuBar, Add, Сохранить `tCtrl+S, tfwSave
		If FileExist(tfwFilePath)
			Menu, tfwMenuBar, Add, Удалить `tCtrl+Del, tfwDelFile
		If (tfwFilePath!="")
			Menu, tfwMenuBar, Add, Размер шрифта, :tfwFontMenu
		Menu, tfwMenuBar, Add, Закрыть `tEsc, tfwClose
		Gui, tfwGui:Menu, tfwMenuBar
		Gui, tfwGui:Add, Edit, x0 y0 w1000 h640 vtfwContentFile, %tfwContentFile%
	}
	
	Gui, tfwGui:Show, w1000 h640, %tfwTitle%
	
	sleep 15
	BlockInput On
	If ReadOnlyStatus {
		SendInput, ^{Home}
	} Else {
		SendInput, ^{End}
	}
	BlockInput Off
	
	WinSet, Transparent, 220, %tfwTitle%
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
	If (tfwFilePath="") {
		Globals.Set("tfwContent", tfwContentFile)
		Return
	}
	Globals.Set("tfwLast", tfwFilePath)
	FileDelete, %tfwFilePath%
	sleep 50
	FileAppend, %tfwContentFile%, %tfwFilePath%, UTF-8
	Gui, tfwGui:Destroy
}

;Изменить размер шрифта
tfwSetFontSize(FontSize){
	tfwSave()
	;tfwClose()
	IniWrite, %FontSize%, %configFile%, settings, tfwFontSize
	sleep 50
	textFileWindow("", Globals.Get("tfwLast"), false)
}

;Редактировать отслеживаемые окна
editWinList(){
	Gui, Settings:Destroy
	IniRead, WindowsData, %configFile%, Windows
	Globals.Set("tfwContent", " ")
	textFileWindow("Список дополнительных окон для отслеживания",, false, WindowsData)
	WinWaitClose, LeagueOverlay_ru - Список дополнительных окон для отслеживания
	tfwContent:=Globals.Get("tfwContent")
	If (tfwContent=" ") || (WindowsData=tfwContent)
		Return
	IniDelete, %configFile%, Windows
	Sleep 50
	IniWrite, %tfwContent%, %configFile%, Windows
	Sleep 50
	ReStart()
}

;Создание заметки
createNewNote(){
	InputBox, fileName, Введите название для заметки,,, 500, 100,,,,, NewNote
	filePath:=configFolder "\MyFiles\" fileName ".txt"
	If (FileExist(filePath) || fileName="" || ErrorLevel) {
		traytip, %prjName%, Что-то пошло не так(
		return
	}
	textFileWindow("", filePath, false, "Здесь могла быть ваша реклама")
}

;Создание нового меню
createNewMenu(){
	InputBox, fileName, Введите название для файла меню,,, 500, 100,,,,, MyMenu
	filePath:=configFolder "\MyFiles\" fileName ".fmenu"
	If (FileExist(filePath) || fileName="" || ErrorLevel) {
		traytip, %prjName%, Что-то пошло не так(
		return
	}
	textFileWindow("", filePath, false, ">https://www.poewiki.net/wiki/Chat")
}

;Создание нового ярлыка
createNewLink(){
	FileSelectFile, TargetPath,,, Укажите путь к файлу
		If (TargetPath="")
			Return
	SplitPath, TargetPath, NameLink
	InputBox, NameLink, Введите имя для ссылки,,, 500, 100,,,,, %NameLink%
	FileCreateShortcut, %TargetPath%, %configFolder%\MyFiles\%NameLink%.lnk
}

;История изменений
showUpdateHistory(){
	textFileWindow("История изменений", "Data\Updates.txt")
}

;Лицензия
showLicense(){
	textFileWindow("Лицензия", "LICENSE.md")
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
	FileRemoveDir, %PoEConfigFolderPath%\release, 1
	FileDelete, %PoEConfigFolderPath%\*.dmp
	
	IniRead, PoECacheFolder, %PoEConfigFolderPath%\production_Config.ini, GENERAL, cache_directory, %A_Space%
	If (PoECacheFolder="")
		PoECacheFolder:=A_AppData "\Path of Exile\"
	FileRemoveDir, %PoECacheFolder%, 1
	
	FileRemoveDir, %A_AppData%\Path of Exile 2, 1
	
	SplashTextOff
	TrayTip, %prjName%, Очистка кэша завершена)
}

;Окно запуска
showStartUI(SpecialText="", LogoPath="", BGColor="", TColor="000000"){
	Gui, StartUI:Destroy
	
	initMsgs := ["Здесь могла быть ваша реклама"
				,"Выполняется подготовка к работе"
				,"Нанимаем NPC 'Борис Бритва'"
				,"Удаляем Зеркало Каландры из вашего фильтра предметов"
				,"Удаляем Волшебную кровь из вашего фильтра предметов"
				,"Усугубляем проблему с C-States в 3.21.2"
				,"x2.5 урон в голове... БАМА"
				,"Expedition 26"
				;,"Вас приветствуют поселенцы Калуги"
				;,"Добро пожаловать в Калугу"
				,"Поддержи " githubUser " <3"]
	
	Random, randomNum, 1, initMsgs.MaxIndex()
	initMsg:=initMsgs[randomNum] "..."
	
	If (SpecialText!="")
		initMsg:=SpecialText
	
	initMsg:=StrReplace(initMsg, "/n", "`n")
	initMsg:=StrReplace(initMsg, "/t", "`t")
	
	IniRead, Supporters, %buildConfig%, Donation, Supporters, %githubUser%
	
	dNames:=strSplit(Supporters, "|")
	Random, randomNum, 1, dNames.MaxIndex()
	dName:="@" dNames[randomNum] " ty) "
	
	If (LogoPath="") && FileExist("Data\imgs\bg.jpg")
		LogoPath:="Data\imgs\bg.jpg"
	
	If FileExist(LogoPath)
		Gui, StartUI:Add, Picture, x0 y0 w500 h70, %LogoPath%
	
	If (BGColor="")
		BGColor:="7F3208"
	
	;Gui StartUI:Add, Progress, x0 y24 w500 h4 cFDBD75 BackgroundFFFFFF vstartProgress
	Gui StartUI:Add, Progress, x0 y22 w500 h4 c%BGColor% BackgroundFFFFFF vstartProgress
	;If (SpecialText="") {
	If (Globals.Get("vProgress")="") {
		Globals.Set("vProgress", 0)
		suip(5)
	}
	SetTimer, updStartProgress, 15

	Gui, StartUI:Font, s12 c%BGColor% bold
	
	Gui, StartUI:Add, Text, x5 y2 h20 w490 +Center BackgroundTrans, %prjName% %verScript% | AHK %A_AhkVersion%
	
	;Gui, StartUI:Add, Text, x-5 y+2 w510 h1 0x12
	
	Gui, StartUI:Font, c%TColor%
	
	;Gui, StartUI:Font, s10 bold italic
	Gui, StartUI:Font, s10 bold
	Gui, StartUI:Add, Text, x0 y+5 h30 w500 +Center BackgroundTrans, %initMsg%
	
	Gui, StartUI:Font, s8 norm
	Gui, StartUI:Add, Text, x4 y55 w150 BackgroundTrans, %dName%
	
	Gui, StartUI:Add, Text, x+2 w340 BackgroundTrans +Right, %args%
	
	Gui, StartUI:+ToolWindow -Caption +Border +AlwaysOnTop
	Gui, StartUI:Show, w500 h70, StartUI
	Sleep 15
	WinSet, Transparent, 220, StartUI
}

;Закрыть окно запуска
closeStartUI(){
	Menu, Tray, Tip, %prjName% %verScript% | AHK %A_AhkVersion%
	Globals.Set("vProgress", 100)
	suip(100)
	sleep 150
	SetTimer, updStartProgress, Delete
	Gui, StartUI:Destroy
	IniRead, showHistory, %configFile%, info, showHistory, 1
	If showHistory {
		showUpdateHistory()
		IniWrite, 0, %configFile%, info, showHistory
	}
	If !RegExMatch(args, "i)/Dev")
		traytip, %prjName%, Поддержи %githubUser% <3
}

;Текущее значение прогресса
suip(num){
	Globals.Set("pProgress", num)
}

;Обновление прогресс бара запуска
updStartProgress(){
	If(Globals.Get("pProgress")>Globals.Get("vProgress")) {
		Globals.Set("vProgress", Globals.Get("vProgress")+1)
	}
	ProgressNum:=Globals.Get("vProgress")
	GuiControl StartUI:, startProgress, %ProgressNum%
}

;Интерфейс дополнительного прогресса
customProgress(ProgressPosition=0, WinName="Progress"){
	If (ProgressPosition=0) {
		Gui, CustomProgressUI:Add, Progress, w400 h25 BackgroundA9A9A9 vcpPos
		Gui, CustomProgressUI:-SysMenu +Theme +Border +AlwaysOnTop
		If (WinName="Progress")
			Gui, CustomProgressUI:-Caption
		Gui, CustomProgressUI:Show,, %WinName%
		Sleep 35
		WinSet, Transparent, 200, %WinName%
		Sleep 1000
	} Else {
		GuiControl CustomProgressUI:, cpPos, %ProgressPosition%
	}
}

;Настройки
showSettings(){
	global
	Gui, Settings:Destroy
	
	IniRead, dMsg, %buildConfig%, Donation, Msg, %A_Space%
	IniRead, dEdit1, %buildConfig%, Donation, Edit1, %A_Space%
	IniRead, dEdit2, %buildConfig%, Donation, Edit2, %A_Space%
	IniRead, dInfo1, %buildConfig%, Donation, Info1, %A_Space%
	IniRead, dInfo2, %buildConfig%, Donation, Info2, %A_Space%
	dMsg:=StrReplace(dMsg, "/n", "`n")
	
	;Информация о подмене имен и отслеживаемых окнах
	IniRead, SpecialNamesData, %configFile%, SpecialNames
	IniRead, WindowsData, %configFile%, Windows
	
	;Настройки первой вкладки
	RegRead, AutoStartLine, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %prjName%
	autoStartEnabled:=(InStr(AutoStartLine, A_ScriptFullPath))?True:False
	
	IniRead, OverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
	splitOverlayPosition:=strSplit(OverlayPosition, "/")
	posX:=splitOverlayPosition[1]
	posY:=splitOverlayPosition[2]
	posW:=splitOverlayPosition[3]
	posH:=splitOverlayPosition[4]
	
	IniRead, startArgs, %configFile%, settings, startArgs, %A_Space%
	oldStartArgs:=startArgs
	IniRead, preset1, %configFile%, settings, preset1, PoE
	IniRead, preset2, %configFile%, settings, preset2, %A_Space%
	IniRead, preset3, %configFile%, settings, preset3, %A_Space%
	IniRead, mouseDistance, %configFile%, settings, mouseDistance, 500
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyGamepad, %configFile%, hotkeys, hotkeyGamepad, vk07
	IniRead, hotkeyItemMenu, %configFile%, hotkeys, hotkeyItemMenu, !c
	IniRead, league, %configFile%, settings, league, Standard
	IniRead, hotkeyHeistScanner, %configFile%, hotkeys, hotkeyHeistScanner, %A_Space%
	
	;Настройки второй вкладки
	IniRead, UserAgent, %configFile%, curl, user-agent, %A_Space%
	IniRead, lr, %configFile%, curl, limit-rate, 2000
	IniRead, ct, %configFile%, curl, connect-timeout, 5
	IniRead, update, %configFile%, settings, update, 1
	IniRead, updateLib, %configFile%, settings, updateLib, 0
	IniRead, updateItemData, %configFile%, settings, updateItemData, 0
	IniRead, updateAHK, %configFile%, settings, updateAHK, 0
	IniRead, useEvent, %configFile%, settings, useEvent, 1
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	
	;Настройки третьей вкладки
	IniRead, hotkeyCmdsMenu, %configFile%, hotkeys, hotkeyCmdsMenu, %A_Space%
	
	;Скрытые настройки
	IniRead, expandMyFiles, %configFile%, settings, expandMyFiles, 1
	IniRead, tfwFontSize, %configFile%, settings, tfwFontSize, 12
	
	If FileExist("Data\imgs\bg.jpg")
		Gui, Settings:Add, Picture, x0 y0 w500 h70, Data\imgs\bg.jpg
	
	Gui, Settings:Font, s8 normal
	
	Gui, Settings:Add, Text, x320 y2 w170 +Right BackgroundTrans, %dInfo1%: 
	Gui, Settings:Add, Edit, x320 y+1 w170 h18 +ReadOnly +Right, %dEdit1%
	Gui, Settings:Add, Text, x320 y+2 w170 +Right BackgroundTrans, %dInfo2%: 
	Gui, Settings:Add, Edit, x320 y+1 w170 h18 +ReadOnly +Right, %dEdit2%
	
	Gui, Settings:Add, Text, x12 y8 w300 BackgroundTrans, %dMsg%
	
	;Gui, Settings:Font, s11
	Gui, Settings:Add, Button, x305 y432 w195 h23 gsaveSettings, Применить и перезапустить
	
	Gui, Settings:Add, Tab3, x0 y70 w500 h385 Bottom, Основные|Загрузки|Команды
	;Gui, Settings:Add, Tab, x0 y75 w640 h385 Bottom, Основные|Загрузки|Команды ;Вкладки
	;Gui, Settings:Font, s8 normal
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Checkbox, vautoStartEnabled x12 y80 w480 Checked%autoStartEnabled%, Запустить %prjName% при запуске Windows
	
	Gui, Settings:Add, Text, x12 yp+22 w110, Параметры запуска:
	Gui, Settings:Add, Edit, vstartArgs x+2 yp-2 w346 h17, %startArgs%
	Gui, Settings:Add, Button, x+1 yp-1 w19 h19 gshowArgsInfo, ?
	
	Gui, Settings:Add, Text, x12 yp+24 w385, Список дополнительных окон для отслеживания:
	Gui, Settings:Add, Button, x+1 yp-3 w92 h23 geditWinList, Изменить
	
	Gui, Settings:Add, Text, x10 y+3 w480 h1 0x12
	
	Gui, Settings:Add, Text, x12 y+7 w185, Позиция изображений(пиксели):
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
	Loop, Data\presets\*, 2
		presetList.="|" A_LoopFileName
	Loop, %configFolder%\Presets\*, 2
		presetList.="|*" A_LoopFileName
	preset1List:=SubStr(presetList, 2)
	
	Gui, Settings:Add, Text, x12 yp+25 w178, Наборы:
	Gui, Settings:Add, Button, x+3 yp-4 w23 h23 gpresetMenuCfgShow, ☰
	Gui, Settings:Add, DropDownList, vpreset1 x+1 yp+1 w90, %preset1List%
	GuiControl,Settings:ChooseString, preset1, %preset1%
	Gui, Settings:Add, DropDownList, vpreset2 x+1 w90, %presetList%
	GuiControl,Settings:ChooseString, preset2, %preset2%
	Gui, Settings:Add, DropDownList, vpreset3 x+1 w90, %presetList%
	GuiControl,Settings:ChooseString, preset3, %preset3%
	
	Gui, Settings:Add, Text, x12 yp+27 w385, Смещение указателя(пиксели):
	Gui, Settings:Add, Edit, vmouseDistance x+2 yp-2 w90 h18 Number, %mouseDistance%
	Gui, Settings:Add, UpDown, Range5-99999 0x80, %mouseDistance%
	
	Gui, Settings:Add, Checkbox, vexpandMyFiles x12 yp+24 w385 Checked%expandMyFiles%, Развернуть 'Мои файлы'
	Gui, Settings:Add, Button, x+1 yp-3 w92 h23 gmyFilesActions, Действия
	
	Gui, Settings:Add, Text, x10 y+3 w480 h1 0x12
	
	Gui, Settings:Add, Text, x12 yp+7 w203, Меню быстрого доступа:
		Gui, Settings:Add, Button, x+1 yp-3 w182 h19 gcfgGamepad, Геймпад - Удерживать [%hotkeyGamepad%]
	Gui, Settings:Add, Hotkey, vhotkeyMainMenu x+1 yp+1 w90 h17, %hotkeyMainMenu%
	
	Gui, Settings:Add, Text, x12 yp+22 w385, Последнее изображение:
	Gui, Settings:Add, Hotkey, vhotkeyLastImg x+2 yp-2 w90 h17, %hotkeyLastImg%
	
	Gui, Settings:Add, Text, x12 yp+22 w385, Меню предмета:
	Gui, Settings:Add, Hotkey, vhotkeyItemMenu x+2 yp-2 w90 h17, %hotkeyItemMenu%
	
	Gui, Settings:Add, Text, x10 y+3 w480 h1 0x12
	
	LeaguesList:=LeaguesList()
	If !RegExMatch(LeaguesList, league)
		LeaguesList.="|" league
	
	Gui, Settings:Add, Text, x12 yp+7 w203, Лига испытаний:
	Gui, Settings:Add, ComboBox, vleague x+2 yp-3 w272, %LeaguesList%
	GuiControl,Settings:ChooseString, league, %league%
	
	If FileExist(configFolder "/Scripts/HeistScanner.ahk"){
		Gui, Settings:Add, Text, x12 yp+26 w385, Сканер витрин Кражи(HeistScanner):
		Gui, Settings:Add, Hotkey, vhotkeyHeistScanner x+2 yp-2 w90 h17, %hotkeyHeistScanner%
	}
	
	Gui, Settings:Tab, 2 ;Вторая вкладка
	
	Gui, Settings:Add, Text, x12 y80 w120, cURL | User-Agent:
	Gui, Settings:Add, Edit, vUserAgent x+2 yp-2 w355 h17, %UserAgent%
	
	Gui, Settings:Add, Text, x12 yp+24 w385, cURL | Ограничение загрузки(Кб/с, 0 - без лимита):
	Gui, Settings:Add, Edit, vlr x+2 yp-2 w90 h18 Number, %lr%
	Gui, Settings:Add, UpDown, Range0-99999 0x80, %lr%
	
	Gui, Settings:Add, Text, x12 yp+24 w385, cURL | Время соединения(сек.):
	Gui, Settings:Add, Edit, vct x+2 yp-2 w90 h18 Number, %ct%
	Gui, Settings:Add, UpDown, Range1-99999 0x80, %ct%
	
	Gui, Settings:Add, Text, x10 y+4 w480 h1 0x12
	
	Gui, Settings:Add, Checkbox, vupdate x12 y+6 w480 Checked%update%, Автоматическая проверка обновлений
	
	Gui, Settings:Add, Checkbox, vupdateLib x27 yp+18 w465 Checked%updateLib% disabled, Обновлять библиотеки, если это возможно
	;Gui, Settings:Add, Checkbox, vupdateAHK x27 yp+18 w465 Checked%updateAHK% disabled, Предлагать обновления для AutoHotkey
	If update {
		GuiControl, Settings:Enable, updateLib
		;GuiControl, Settings:Enable, updateAHK
	}
	
	Gui, Settings:Add, Checkbox, vupdateItemData x12 yp+18 w480 Checked%updateItemData%, Обновлять списки соответствий
	
	Gui, Settings:Add, Checkbox, vloadLab x12 yp+18 w345 Checked%loadLab% disabled, Скачивать раскладку лабиринта('Мои файлы'>Labyrinth.jpg)
	Gui, Settings:Add, Link, x+2 yp+0 w130 +Right, <a href="https://www.poelab.com/">PoELab.com</a>
	If FileExist(configFolder "\cookies.txt")
		GuiControl, Settings:Enable, loadLab
	
	Gui, Settings:Add, Checkbox, vuseEvent x12 yp+18 w480 Checked%useEvent%, Разрешить события
	
	Gui, Settings:Tab, 3 ; Третья вкладка
	
	Gui, Settings:Add, Text, x12 y80 w385, Избранные команды:
	Gui, Settings:Add, Hotkey, vhotkeyCmdsMenu x+2 yp-2 w90 h17, %hotkeyCmdsMenu%
	
	Gui, Settings:Add, Text, x10 y+2 w480 h2 0x12
	
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
				tempVar:="/leave"
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
		Gui, Settings:Add, Hotkey, vhotkeyCmd%A_Index% x+1 w90 h17, %tempVar%
		
		TwoColumn:=Round(LoopVar+A_Index)
		IniRead, tempVar, %configFile%, fastReply, textCmd%TwoColumn%, %A_Space%
		Gui, Settings:Add, Edit, vtextCmd%TwoColumn% x+6 w145 h17, %tempVar%
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%TwoColumn%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%TwoColumn% x+1 w90 h17, %tempVar%
	}
	
	helptext:="/dance - простая команда`n/whois <last> - команда к последнему игроку`n@<last> ty, gl) - сообщение последнему игроку`n_ty, gl) - сообщение в чат области`n%ty, gl) - сообщение в чат группы`n>calc - выполнить`nmy.jpg - изображение/набор/текст`n!текст - всплывающая подсказка"
	helptext2:="--- - разделитель`n;/kick player - комментарий`n<configFolder> - папка настроек`n<presetFolder> - папка набора`n<eventFolder> - папка события`n<time> - время UTC`n<inputbox> - поле ввода"
	Gui, Settings:Add, Text, x12 y+2 w237 c7F3208, %helptext%
	Gui, Settings:Add, Text, x+6 w237 c7F3208, %helptext2%
	
	Gui, Settings:-MinimizeBox -MaximizeBox
	Gui, Settings:Show, w500 h455, %prjName% %verScript% | AHK %A_AhkVersion% - Информация и настройки ;Отобразить окно настроек
}

;Сохранить Настройки
saveSettings(){
	global
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 50
	Gui, Settings:Submit
	
	If autoStartEnabled
		RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %prjName%, "%A_ScriptFullPath%"
	If !autoStartEnabled
		RegDelete, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Run, %prjName%
	
	;Настройки первой вкладки
	IniWrite, %posX%/%posY%/%posW%/%posH%, %configFile%, settings, overlayPosition
	IniWrite, %startArgs%, %configFile%, settings, startArgs
	IniWrite, %preset1%, %configFile%, settings, preset1
	IniWrite, %preset2%, %configFile%, settings, preset2
	IniWrite, %preset3%, %configFile%, settings, preset3
	IniWrite, %mouseDistance%, %configFile%, settings, mouseDistance
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %hotkeyGamepad%, %configFile%, hotkeys, hotkeyGamepad
	IniWrite, %hotkeyItemMenu%, %configFile%, hotkeys, hotkeyItemMenu
	
	IniWrite, %league%, %configFile%, settings, league
	IniWrite, %hotkeyHeistScanner%, %configFile%, hotkeys, hotkeyHeistScanner
	
	;Настройки второй вкладки
	IniWrite, %UserAgent%, %configFile%, curl, user-agent
	IniWrite, %lr%, %configFile%, curl, limit-rate
	IniWrite, %ct%, %configFile%, curl, connect-timeout
	IniWrite, %update%, %configFile%, settings, update
	IniWrite, %updateLib%, %configFile%, settings, updateLib
	IniWrite, %updateItemData%, %configFile%, settings, updateItemData
	IniWrite, %updateAHK%, %configFile%, settings, updateAHK
	IniWrite, %useEvent%, %configFile%, settings, useEvent
	IniWrite, %loadLab%, %configFile%, settings, loadLab
	
	;Настройки третьей вкладки
	IniWrite, %hotkeyCmdsMenu%, %configFile%, hotkeys, hotkeyCmdsMenu
	
	;Скрытые настройки
	IniWrite, %expandMyFiles%, %configFile%, settings, expandMyFiles
	IniWrite, %tfwFontSize%, %configFile%, settings, tfwFontSize

	;Настраиваемые команды fastReply
	Loop %cmdNum% {
		tempVar:=hotkeyCmd%A_Index%
		IniWrite, %tempVar%, %configFile%, fastReply, hotkeyCmd%A_Index%
		
		tempVar:=textCmd%A_Index%
		IniWrite, %tempVar%, %configFile%, fastReply, textCmd%A_Index%
	}
	
	;Информация о подмене имен и отслеживаемых окнах
	IniDelete, %configFile%, SpecialNames
	If (SpecialNamesData="")
		SpecialNamesData:="Лабиринт(PoELab.com)=Labyrinth.jpg"
	IniWrite, %SpecialNamesData%, %configFile%, SpecialNames
	IniDelete, %configFile%, Windows
	IniWrite, %WindowsData%, %configFile%, Windows
	
	If (oldStartArgs!=StartArgs)
		args:=""
	
	ReStart()
}

;Назначение клавиш
setHotkeys(){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	;Инициализация основных клавиш макроса
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, %A_Space%
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, %A_Space%
	IniRead, hotkeyCmdsMenu, %configFile%, hotkeys, hotkeyCmdsMenu, %A_Space%
	If (hotkeyLastImg!="")
		Hotkey, % hotkeyLastImg, shLastImage, On
	If (hotkeyMainMenu!="")
		Hotkey, % hotkeyMainMenu, shMainMenu, On
	If (hotkeyCmdsMenu!="")
		Hotkey, % hotkeyCmdsMenu, shСmdsMenu, On
	
	;Инициализация настраиваемых команд fastReply
	Loop %cmdNum% {
		IniRead, tempvar, %configFile%, fastReply, textCmd%A_Index%, %A_Space%
		;textCmd%A_Index%:=tempvar
		Globals.Set("fR" A_Index, tempvar)
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		If (tempVar!="")
			Hotkey, % tempVar, fastCmd%A_Index%, On
	}
	
	;Инициализация Игрового контроллера
	IniRead, hotkeyGamepad, %configFile%, hotkeys, hotkeyGamepad, %A_Space%
	If (hotkeyGamepad!="")
		Hotkey, % hotkeyGamepad, shGamepadMenu, On
}

;Проверка обновления AHK
updateAutoHotkey(){
	IniRead, updateAHK, %configFile%, settings, updateAHK, 0
	If !updateAHK
		return
	filePath:=tempDir "\ahkver.txt"
	LoadFile("https://www.autohotkey.com/download/1.1/version.txt", filePath, true)
	;FileDelete, %filePath%
	;UrlDownloadToFile, https://www.autohotkey.com/download/1.1/version.txt, %filePath%
	FileReadLine, AHKRelVer, %filePath%, 1
	If !RegExMatch(AHKRelVer, "^(\d+.\d+.\d+.\d+)$", res)
		return
	If (A_AhkVersion<AHKRelVer){
		SplitPath, A_AhkPath,,AHKDir
		If FileExist(AHKDir "\Installer.ahk")
			Run *RunAs "%AhkDir%\Installer.ahk"
	}
}


;Меню управления наборами
presetMenuCfgShow(){
	;Gui, Settings:Destroy
	Menu, settingsPresetMenu, Add
	Menu, settingsPresetMenu, DeleteAll
	Menu, settingsPresetMenu, Add, Создать, presetCreate
	Menu, settingsPresetMenu, Add, Дополнения, pkgsMgr_packagesMenu
	Loop, %configFolder%\Presets\*, 2
	{
		Menu, settingsPresetMenu, Add
		Menu, settingsPresetMenu, Add, Открыть папку '%A_LoopFileName%', presetFolderOpen
		Menu, settingsPresetMenu, Add, Удалить '%A_LoopFileName%', presetFolderDelete
	}
	Menu, settingsPresetMenu, Show
}

;Меню управления для 'Мои файлы'
myFilesActions(FileName="") {
	Menu, settingsMyFilesMenu, Add
	Menu, settingsMyFilesMenu, DeleteAll
	If (FileName!="") && FileExist(configFolder "\MyFiles\" FileName) {
		Menu, settingsMyFilesMenu, Add, Удалить '%FileName%', removeMyFile
		Menu, settingsMyFilesMenu, Add
	}
	Menu, settingsMyFilesMenu, Add, Добавить 'Ярлык', createNewLink
	Menu, settingsMyFilesMenu, Add, Добавить 'Заметку', createNewNote
	Menu, settingsMyFilesMenu, Add, Добавить 'Меню команд', createNewMenu
	Menu, settingsMyFilesMenu, Add
	Menu, settingsMyFilesMenu, Add, Открыть папку 'Мои файлы', openMyFilesFolder
	Menu, settingsMyFilesMenu, Show
}

;Удаление файла из 'Моих файлов'
removeMyFile(FileName) {
	FileName:=searchName(FileName)
	FileDelete, %configFolder%\MyFiles\%FileName%
}

;Поиск имени
searchName(FullText){
	If RegExMatch(FullText, "'(.*)'", Result)
		return Result1
	return FullText
}

;Открыть папку набора
presetFolderOpen(Name){
	PresetFolder:=configFolder "\Presets\" searchName(Name)
	Run, explorer "%PresetFolder%"
}

;Удалить папку набора
presetFolderDelete(Name){
	PresetFolder:=configFolder "\Presets\" searchName(Name)
	msgbox, 0x1024, %prjName%, Удалить папку '%PresetFolder%'?
	IfMsgBox No
		return
	FileRemoveDir, %PresetFolder%, 1
	Sleep 300
	showSettings()
}

;Менеджер создания нового набора
presetCreate(){
	InputBox, PresetName, Введите название набора,,, 500, 100,,,,, NewPreset
	PresetFolder:=configFolder "\Presets\" PresetName
	If (PresetName="") || FileExist(PresetFolder) {
		msgbox, 0x1040,, Недопустимое имя для набора!
		return
	}
	FileCreateDir, %PresetFolder%
	InputBox, wline, Укажите окно отслеживания,,, 500, 100,,,,, ahk_exe notepad.exe
	;FileAppend, %wline%, %PresetFolder%\windows.list, UTF-8
	IniWrite, %wline%, %PresetFolder%\PresetConfig.ini, Windows
	IniWrite, ReadMe.txt, %PresetFolder%\PresetConfig.ini, SpecialNames, Read Me
	ReadMeFullText:="Вы создали шаблон для набора '" PresetName "'!`n`nПоместите в папку набора желаемые файлы.`nДля корректного открытия текстовых файлов требуется кодировка UTF-8-BOM!`n`nЕсли вам потребуется изменить 'Окна отслеживания', то вы можете сделать это отредактировав файл 'PresetConfig.ini'."
	FileAppend, %ReadMeFullText%, %PresetFolder%\ReadMe.txt, UTF-8
	showSettings()
	presetFolderOpen(PresetName)
	textFileWindow("", PresetFolder "\ReadMe.txt", false)
}

;Меню области уведомлений
menuCreate(){
	If FileExist("LICENSE.md")
		Menu, Tray, Add, Лицензия, showLicense
	Menu, Tray, Add, История изменений, showUpdateHistory
	Menu, Tray, Add
	Menu, Tray, Add, Настройки, showSettings
	Menu, Tray, Default, Настройки
	Menu, Tray, Add, Открыть папку 'Мои файлы', openMyFilesFolder
	Menu, Tray, Add, Список 'Избранных команд', editCmdsList
	Menu, Tray, Add, Условия для 'Меню предмета', ItemMenu_customHightlight
	Menu, Tray, Add
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
	IniRead, preset, %configFile%, settings, preset1, %A_Space%
	IfWinActive ahk_group WinGrp2
		IniRead, preset, %configFile%, settings, preset2, %A_Space%
	IfWinActive ahk_group WinGrp3
		IniRead, preset, %configFile%, settings, preset3, %A_Space%
		
	If (preset="")
		return
	
	Path:=(InStr(preset, "*")=1?configFolder "\Presets\" SubStr(preset, 2):"Data\presets\" preset)
	Globals.Set("presetFolder", Path)
	
	Loop, %Path%\*, 0
		If RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp|txt|fmenu|url|lnk)$")
			Menu, mainMenu, Add, %A_LoopFileName%, shPreset
	Menu, mainMenu, Add
	
	IniRead, SpecialNamesList, %Path%\PresetConfig.ini, SpecialNames
	;MsgBox, %SpecialNamesList%
	SpecialNamesSplit:=StrSplit(SpecialNamesList, "`n")
	For k, val in SpecialNamesSplit {
		SplitName:=StrSplit(SpecialNamesSplit[k], "=")
		NewName:=SplitName[1]
		OldName:=SplitName[2]
		If FileExist(Path "\" OldName)
			Menu, mainMenu, Rename, %OldName%, %NewName%
	}
}

;Открыть файл набора
shPreset(TargetName){
	PresetPath:=Globals.Get("presetFolder")
	IniRead, FileName, %PresetPath%\PresetConfig.ini, SpecialNames, %TargetName%, %TargetName%
	commandFastReply(PresetPath "\" FileName)
}

;Сформировать и открыть основное меню
shMainMenu(Gamepad=false){
	If RegExMatch(args, "i)/Gamepad")
		Gamepad:=true
	
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
	
	IniRead, expandMyFiles, %configFile%, settings, expandMyFiles, 1
	myFilesMenuCreate(expandMyFiles || Gamepad)
	
	IniRead, hotkeyCmdsMenu, %configFile%, hotkeys, hotkeyCmdsMenu, %A_Space%
	If (hotkeyCmdsMenu="") {
		fastMenu(configFolder "\cmds.txt", False)
		Menu, fastMenu, Add
		Menu, fastMenu, Add, Список 'Избранных команд', editCmdsList
		Menu, mainMenu, Add, Избранные команды, :fastMenu
	}
	
	If Gamepad {
		ItemMenu_Show(False, False)
		Menu, mainMenu, Add, Подсветка, :itemMenu
	}
	
	Menu, mainMenu, Add, Область уведомлений, :Tray
	sleep 5
	Menu, mainMenu, Show
}

;Избранные команды
shСmdsMenu(){
	shFastMenu(configFolder "\cmds.txt")
}

;Изменить 'Избранные команды'
editCmdsList(){
	textFileWindow("Избранные команды", configFolder "\cmds.txt", false, "/global 820`n/whois <last>`n/deaths`n/passives`n/atlaspassives`n/remaining`n/autoreply <inputbox>`n/autoreply`n---`n>calc`n>https://siveran.github.io/calc.html`n>https://poe.re/#/expedition`n>https://www.poewiki.net/wiki/Chat")
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
	sleep 50
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%" %args%
	ExitApp
}

;Всплывающая подсказка
showToolTip(msg, t=0, umd=true) {
	msg:=StrReplace(msg, "/n", "`n")
	msg:=StrReplace(msg, "/t", "`t")
	
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
LoadFile(URL, FilePath, CheckDate=false, UseCookies=false) {	
	;Сверим дату
	If CheckDate {
		FormatTime, CurrentDate, %A_Now%, yyyyMMdd
		FileGetTime, LoadDate, %FilePath%, M
		FormatTime, LoadDate, %LoadDate%, yyyyMMdd
		IfNotExist, %FilePath%
			LoadDate:=0
		If (LoadDate=CurrentDate)
			Return false
	}
	
	SplitPath, FilePath,, DirPath
	FileCreateDir, %DirPath%
	
	FileDelete, %FilePath%
	Sleep 50
	
	IniRead, UserAgent, %configFile%, curl, user-agent, %A_Space%
	If (UserAgent="")
		UserAgent:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"
	
	If FileExist(A_WinDir "\System32\curl.exe") && !RegExMatch(args, "i)/NoCurl") {
		IniRead, lr, %configFile%, curl, limit-rate, 1000
		IniRead, ct, %configFile%, curl, connect-timeout, 10
		FileRead, Cookies, %configFolder%\cookies.txt
		
		CurlLine:="curl -L -A """ UserAgent """ -o """ FilePath """" " " """" URL """"
		If ct>0
			CurlLine.=" --connect-timeout " ct
		If lr>0
			CurlLine.=" --limit-rate " lr "K"
		
		If UseCookies && (Cookies!="")
			CurlLine.=" -b """ Cookies """"
		
		If RegExMatch(args, "i)/ShowCurl")
			RunWait, %CurlLine%
		Else
			RunWait, %CurlLine%, , hide
		devLog(CurlLine)
	} Else {
		UrlDownloadToFile, %URL%, %FilePath%
	}
	Return true
}

;Использование системной темы
systemTheme(){
	If RegExMatch(args, "i)/NoTheme")
		Return
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
	sleep 50
	ExitApp
Return

;Нужно для работы с ItemDataConverter
class Globals {
	Set(name, value) {
		Globals[name]:=value
	}
	Add(name, value) {
		Globals[name].=value
	}
	Get(name, value_default="") {
		return Globals[name]
	}
}
