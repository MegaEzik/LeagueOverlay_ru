
/*
	Оригинальная идея https://github.com/heokor/League-Overlay
	Данный скрипт создан MegaEzik
	
	Назначение дополнительных библиотек:
		*Gdip_All.ahk - Библиотека для работы с изображениями, авторство https://www.autohotkey.com/boards/viewtopic.php?t=6517
		*JSON.ahk - Разбор данных от api, авторство https://github.com/cocobelgica/AutoHotkey-JSON
		*Overlay.ahk - Набор функций для расчета и отображения изображений оверлея
		*Labyrinth.ahk - Загрузка убер-лабиринта с poelab.com, и создание окна управления испытаниями убер-лабиринта
		*Updater.ahk - Проверка и установка обновлений
		*debugLib.ahk - Библиотека для функций отладки и тестирования новых функций
		*fastReply.ahk - Библиотека с функциями для команд
	
	Управление:
		[Alt+F1] - Последнее изображение
		[Alt+F2] - Меню быстрого доступа
*/

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

if (!A_IsAdmin) {
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
	ExitApp
}

;Подключение библиотек
#Include, %A_ScriptDir%\resources\ahk\Gdip_All.ahk
#Include, %A_ScriptDir%\resources\ahk\JSON.ahk
#Include, %A_ScriptDir%\resources\ahk\Overlay.ahk
#Include, %A_ScriptDir%\resources\ahk\Labyrinth.ahk
#Include, %A_ScriptDir%\resources\ahk\Updater.ahk
#Include, %A_ScriptDir%\resources\ahk\fastReply.ahk
#Include, %A_ScriptDir%\resources\ahk\debugLib.ahk
#Include, %A_ScriptDir%\resources\ahk\ItemDataConverterLib.ahk

;Список окон Path of Exile
GroupAdd, WindowGrp, Path of Exile ahk_class POEWindowClass
GroupAdd, WindowGrp, ahk_exe GeForceNOWStreamer.exe

;Объявление и загрузка основных переменных
global prjName:="LeagueOverlay_ru"
global githubUser:="MegaEzik"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
if InStr(FileExist(A_ScriptDir "\profile"), "D")
	configFolder:=A_ScriptDir "\profile"
global configFile:=configFolder "\settings.ini"
global trayMsg, verScript, debugMode=0
global textCmd1, textCmd2, textCmd3, textCmd4, textCmd5, textCmd6, textCmd7, textCmd8, textCmd9, textCmd10, textCmd11, textCmd12, cmdNum=12
global presetData, LastImgPath, OverlayStatus=0
FileReadLine, verScript, resources\Updates.txt, 1

;Подсказка в области уведомлений и сообщение при запуске
trayUpdate(prjName " " verScript " | AHK " A_AhkVersion)
Menu, Tray, Icon, resources\Syndicate.ico
showStartUI()

devInit()

;Проверка обновлений
IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
if autoUpdate && !debugMode {
	CheckUpdateFromMenu("onStart")
	SetTimer, CheckUpdate, 10800000
}

;Проверим файл конфигурации
IniRead, verConfig, %configFile%, info, verConfig, ""
if (verConfig!=verScript) {
	showSettings()
	FileDelete, %configFile%
	sleep 25
	FileCreateDir, %configFolder%\images
	IniWrite, %verScript%, %configFile%, info, verConfig
	saveSettings()
}

;Добавим возможность подгружать имя своего окна
IniRead, windowLine, %configFile%, settings, windowLine, %A_Space%
if (windowLine!="")
	GroupAdd, WindowGrp, %windowLine%

;Запуск gdi+
If !pToken:=Gdip_Startup()
	{
	   ;MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	   MsgBox, 48, Ошибка gdi+!, Не удалось запустить gdi+. Пожалуйста, убедитесь, что в вашей системе он есть
	}
OnExit, Exit

;Загружаем раскладку лабиринта
downloadLabLayout()

;Выполним все файлы с окончанием loader.ahk, передав ему папку расположения скрипта
Loop, %configFolder%\*loader.ahk, 1
	RunWait *RunAs "%A_AhkPath%" "%configFolder%\%A_LoopFileName%" "%A_ScriptDir%"
	
;Назначим последнее изображение
IniRead, lastImgPathC, %configFile%, settings, lastImgPath, %A_Space%
If (lastImgPathC!="" && FileExist(lastImgPathC))
	LastImgPath:=lastImgPathC

;Установим таймер на проверку активного окна
SetTimer, checkWindowTimer, 250
	
;Назначим управление и создадим меню
menuCreate()
setHotkeys()

;Скроем сообщение загрузки
closeStartUI()

Return

;#################################################

#IfWinActive ahk_group WindowGrp

shLastImage(){
	shOverlay(LastImgPath)
}

shMainMenu(){
	destroyOverlay()
	Menu, mainMenu, Show
}

presetInMenu(imagesPreset){
	presetPath:="resources\presets\" imagesPreset ".preset"
	If RegExMatch(imagesPreset, "<(.*)>", imagesPreset)
		presetPath:=configFolder "\presets\" imagesPreset1 ".preset"
	if FileExist(presetPath) {
		FileRead, presetData, %presetPath%
		presetData:=StrReplace(presetData, "`r", "")
		presetDataSplit:=StrSplit(presetData, "`n")
		For k, val in presetDataSplit {
			imageInfo:=StrSplit(presetDataSplit[k], "|")
			ImgName:=imageInfo[1]
			if FileExist(StrReplace(imageInfo[2], "<configFolder>", configFolder))
				Menu, mainMenu, Add, %ImgName%, presetImgShow
		}
	}
}

presetImgShow(ImgName){
	presetDataSplit:=StrSplit(presetData, "`n")
	For k, val in presetDataSplit {
		imageInfo:=StrSplit(presetDataSplit[k], "|")
		if (ImgName=imageInfo[1]) {
			shOverlay(StrReplace(imageInfo[2], "<configFolder>", configFolder))
		}
	}
}

shMyImage(imagename){
	shOverlay(configFolder "\images\" imagename)
}

openMyImagesFolder(){
	Gui, Settings:Destroy
	If !FileExist(configFolder "\images")
		FileCreateDir, %configFolder%\images
	sleep 15
	Run, explorer "%configFolder%\images"
}

myImagesMenuCreate(selfMenu=true){
	if selfMenu {
		Loop, %configFolder%\images\*.*, 1
			if RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp)$")
				Menu, myImagesMenu, Add, %A_LoopFileName%, shMyImage
			Menu, myImagesMenu, Add
			Menu, myImagesMenu, Add, Открыть папку, openMyImagesFolder
			
			Menu, mainMenu, Add, Мои изображения, :myImagesMenu
	} else {
		Loop, %configFolder%\images\*.*, 1
			if RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp)$")
				Menu, mainMenu, Add, %A_LoopFileName%, shMyImage
		Menu, mainMenu, Add
	}
}

textFileWindow(Title, FilePath, ReadOnlyStatus=true, contentDefault=""){
	global
	tfwFilePath:=FilePath
	Gui, tfwGui:Destroy
	FileRead, tfwContentFile, %tfwFilePath%
	if ReadOnlyStatus {
		Gui, tfwGui:Add, Edit, w580 h400 +ReadOnly, %tfwContentFile%
	} else {
		if (tfwContentFile="" && contentDefault!="")
			tfwContentFile:=contentDefault
		Menu, tfwMenuBar, Add, Сохранить `tCtrl+S, tfwSave
		Gui, tfwGui:Menu, tfwMenuBar
		Gui, tfwGui:Add, Edit, w580 h400 vtfwContentFile, %tfwContentFile%
	}
	Gui, tfwGui:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, tfwGui:Show,, %prjName% - %Title%
	
	sleep 15
	BlockInput On
	if ReadOnlyStatus {
		SendInput, ^{Home}
	} else {
		SendInput, ^{End}
	}
	BlockInput Off
}

tfwSave(){
	global
	Gui, tfwGui:Submit
	FileDelete, %tfwFilePath%
	sleep 100
	FileAppend, %tfwContentFile%, %tfwFilePath%, UTF-8
	Gui, tfwGui:Destroy
}

showUpdateHistory(){
	textFileWindow("История изменений", "resources\Updates.txt")
}

clearPoECache(){
	FileSelectFile, FilePath, , C:\Program Files (x86)\Grinding Gear Games\Path of Exile\Content.ggpk, Укажите путь к файлу Content.ggpk в папке с игрой, (Content.ggpk)
	if (FilePath!="" && FileExist(FilePath)) {
		SplashTextOn, 300, 20, %prjName%, Очистка кэша, пожалуйста подождите...
		
		SplitPath, FilePath, , PoEFolderPath
		FileRemoveDir, %PoEFolderPath%\logs, 1
		;DirectX11
		FileRemoveDir, %PoEFolderPath%\CachedHLSLShaders, 1
		FileRemoveDir, %PoEFolderPath%\ShaderCacheD3D11, 1
		FileRemoveDir, %PoEFolderPath%\ShaderCacheD3D11_GI, 1
		;Vulkan
		FileRemoveDir, %PoEFolderPath%\ShaderCacheVulkan, 1
		
		PoEConfigFolderPath:=A_MyDocuments "\My Games\Path of Exile"
		FileRemoveDir, %PoEConfigFolderPath%\Countdown, 1
		FileRemoveDir, %PoEConfigFolderPath%\DailyDealCache, 1
		FileRemoveDir, %PoEConfigFolderPath%\Minimap, 1
		FileRemoveDir, %PoEConfigFolderPath%\MOTDCache, 1
		FileRemoveDir, %PoEConfigFolderPath%\ShopImages, 1
		FileRemoveDir, %PoEConfigFolderPath%\OnlineFilters, 1
		
		SplashTextOff
	} else {
		msgbox, 0x1010, %prjName%, Файл не найден или операция прервана пользователем!, 3
		return		
	}
}

editPreset(){
	Gui, Settings:Destroy
	FileCreateDir, %configFolder%\presets
	InputBox, namePreset, Укажите имя набора,,, 300, 100,,,,, custom
	namePreset:=StrReplace(namePreset, ".preset", "")
	if (namePreset="" || ErrorLevel)
		return
	textFileWindow("Редактирование " namePreset ".preset", configFolder "\presets\" namePreset ".preset", false, presetData)
}

delPresetMenuShow(){
	Menu, delPresetMenu, Add
	Menu, delPresetMenu, DeleteAll
	Menu, delPresetMenu, Add
	Loop, %configFolder%\presets\*.preset, 1
		Menu, delPresetMenu, Add, %A_LoopFileName%, delPreset
	Menu, delPresetMenu, Show
}

delPreset(presetName){
	FileDelete, %configFolder%\presets\%presetName%
	Gui, Settings:Destroy
	Sleep 25
	showSettings()
}

showStartUI(){
	Gui, StartUI:Destroy
	initMsgs := ["Подготовка макроса к работе..."
				,"Поддержи " prjName "..."
				,"Поприветствуем Кассию..."
				,"Да начнется лига ""Спиздили""..."
				,"Поиск NPC ""Борис Бритва""..."]
	Random, randomNum, 1, initMsgs.MaxIndex()
	initMsg:=initMsgs[randomNum]
	
	dNames:=["AbyssSPIRIT", "milcart", "Pip4ik"]
	Random, randomNum, 1, dNames.MaxIndex()
	dName:="Спасибо, " dNames[randomNum] ")"
	
	Gui, StartUI:Add, Progress, w500 h26 x0 y0 Background1A7F5B

	Gui, StartUI:Font, s10 cFFFFFF bold
	Gui, StartUI:Add, Text, x5 y5 h18 w390 +Center BackgroundTrans, %prjName% %verScript% | AHK %A_AhkVersion%
	
	Gui, StartUI:Font, c000000 bold italic
	Gui, StartUI:Add, Text, x5 y+10 h18 w390 +Center BackgroundTrans, %initMsg%
	
	Gui, StartUI:Font, s8 norm italic
	Gui, StartUI:Add, Text, x5 y+3 w290 BackgroundTrans, %dName%
	
	Gui, StartUI:Font, s8 norm
	Gui, StartUI:Add, Link, x+0 yp+0 w100 +Right, <a href="https://qiwi.me/megaezik">Поддержать</a>
	
	Gui, StartUI:+ToolWindow -Caption +Border +AlwaysOnTop
	Gui, StartUI:Show, w400 h70, %prjName% %VerScript%
}

closeStartUI(){
	sleep 1000
	Gui, StartUI:Destroy
	If debugMode && FileExist(A_WinDir "\Media\Windows Proximity Notification.wav")
		SoundPlay, %A_WinDir%\Media\Windows Proximity Notification.wav
}

showSettings(){
	global
	Gui, Settings:Destroy
	
	IniRead, lastImgPath, %configFile%, settings, lastImgPath, %A_Space%
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	
	;Настройки первой вкладки
	IniRead, windowLine, %configFile%, settings, windowLine, %A_Space%
	IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
	IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	IniRead, expandMyImages, %configFile%, settings, expandMyImages, 0
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyConverter, %configFile%, hotkeys, hotkeyConverter, %A_Space%
	IniRead, hotkeyCustomCommandsMenu, %configFile%, hotkeys, hotkeyCustomCommandsMenu, %A_Space%
	
	;Настройки второй вкладки
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%

	Gui, Settings:Add, Button, x306 y0 w159 h21 gsaveSettings, Применить и перезапустить ;💾 465
	
	Gui, Settings:Add, Tab, x0 y0 w465 h315, Основные|Быстрые команды ;Вкладки
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Checkbox, vautoUpdate x10 y30 w450 Checked%autoUpdate%, Автоматически проверять и уведомлять о наличии обновлений
	
	Gui, Settings:Add, Text, x10 yp+20 w155, Другое окно для проверки:
	Gui, Settings:Add, Edit, vwindowLine x+2 yp-2 w290 h18, %windowLine%
	
	Gui, Settings:Add, Text, x10 y+4 w450 h2 0x10
	
	presetList:=""
	Loop, resources\presets\*.preset, 1
		presetList.="|" StrReplace(A_LoopFileName, ".preset", "")
	Loop, %configFolder%\presets\*.preset, 1
		presetList.="|<" StrReplace(A_LoopFileName, ".preset", "") ">"
	presetList:=SubStr(presetList, 2)
	
	Gui, Settings:Add, Text, x10 yp+8 w249, Набор изображений:
	Gui, Settings:Add, Button, x+1 yp-4 w23 h23 geditPreset, ✏
	Gui, Settings:Add, Button, x+0 w23 h23 gdelPresetMenuShow, ✕
	Gui, Settings:Add, DropDownList, vimagesPreset x+1 yp+1 w150, %presetList%
	GuiControl,Settings:ChooseString, imagesPreset, %imagesPreset%
	
	
	Gui, Settings:Add, Checkbox, vexpandMyImages x10 yp+25 w295 Checked%expandMyImages%, Развернуть 'Мои изображения'
	Gui, Settings:Add, Button, x+1 yp-2 w152 h23 gopenMyImagesFolder, Открыть папку
	
	Gui, Settings:Add, Checkbox, vloadLab x10 yp+25 w295 Checked%loadLab%, Скачивать лабиринт(Мои изображения>Labyrinth.jpg)
	Gui, Settings:Add, Link, x+2 yp+0, <a href="https://www.poelab.com/">POELab.com</a>
	
	Gui, Settings:Add, Text, x10 y+4 w450 h2 0x10
	
	Gui, Settings:Add, Text, x10 yp+7 w295, Последнее изображение:
	Gui, Settings:Add, Hotkey, vhotkeyLastImg x+2 yp-2 w150 h18, %hotkeyLastImg%
	
	Gui, Settings:Add, Text, x10 yp+22 w295, Меню быстрого доступа:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenu x+2 yp-2 w150 h18, %hotkeyMainMenu%
	
	Gui, Settings:Add, Text, x10 y+4 w450 h2 0x10
	
	Gui, Settings:Add, Text, x10 yp+7 w295, Меню команд:
	Gui, Settings:Add, Hotkey, vhotkeyCustomCommandsMenu x+2 yp-2 w150 h18, %hotkeyCustomCommandsMenu%
	
	Gui, Settings:Add, Text, x10 yp+22 w295, Конвертировать описание предмета Ru>En:
	Gui, Settings:Add, Hotkey, vhotkeyConverter x+2 yp-2 w150 h18, %hotkeyConverter%
	
	Gui, Settings:Tab, 2 ; Вторая вкладка
	
	Gui, Settings:Add, Text, x10 y30 w295, Синхронизировать(/oos):
	Gui, Settings:Add, Hotkey, vhotkeyForceSync x+2 yp-2 w150 h18, %hotkeyForceSync%
	
	Gui, Settings:Add, Text, x10 yp+22 w295, К выбору персонажа(/exit):
	Gui, Settings:Add, Hotkey, vhotkeyToCharacterSelection x+2 yp-2 w150 h18, %hotkeyToCharacterSelection%
	
	;Настраиваемые команды fastReply
	Loop %cmdNum% {
		IniRead, tempVar, %configFile%, fastReply, textCmd%A_Index%, %A_Space%
		if (tempVar="") {
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
				tempVar:="@<last> ty & gl, exile)"
		}
		Gui, Settings:Add, Edit, vtextCmd%A_Index% x10 yp+20 w295 h18, %tempVar%
		
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%A_Index% x+2 w150 h18, %tempVar%
	}
	
	Gui, Settings:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, Settings:Show, w465 h315, %prjName% %VerScript% | AHK %A_AhkVersion% - Настройки ;Отобразить окно настроек
}

saveSettings(){
	global
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	Gui, Settings:Submit
	
	if (imagesPreset="")
		imagesPreset:="default"
		
	IniWrite, %lastImgPath%, %configFile%, settings, lastImgPath
	IniWrite, %debugMode%, %configFile%, settings, debugMode
	
	;Настройки первой вкладки
	IniWrite, %windowLine%, %configFile%, settings, windowLine
	IniWrite, %autoUpdate%, %configFile%, settings, autoUpdate
	IniWrite, %imagesPreset%, %configFile%, settings, imagesPreset
	IniWrite, %loadLab%, %configFile%, settings, loadLab
	IniWrite, %expandMyImages%, %configFile%, settings, expandMyImages
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %hotkeyConverter%, %configFile%, hotkeys, hotkeyConverter
	IniWrite, %hotkeyCustomCommandsMenu%, %configFile%, hotkeys, hotkeyCustomCommandsMenu
	
	;Настройки второй вкладки
	IniWrite, %hotkeyForceSync%, %configFile%, hotkeys, hotkeyForceSync
	IniWrite, %hotkeyToCharacterSelection%, %configFile%, hotkeys, hotkeyToCharacterSelection
	
	;Настраиваемые команды fastReply
	Loop %cmdNum% {
		tempVar:=hotkeyCmd%A_Index%
		IniWrite, %tempVar%, %configFile%, fastReply, hotkeyCmd%A_Index%
		
		tempVar:=textCmd%A_Index%
		IniWrite, %tempVar%, %configFile%, fastReply, textCmd%A_Index%
	}
	
	ReStart()
}

setHotkeys(){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	;Инициализация основных клавиш макроса
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyCustomCommandsMenu, %configFile%, hotkeys, hotkeyCustomCommandsMenu, %A_Space%
	if (hotkeyLastImg!="")
		Hotkey, % hotkeyLastImg, shLastImage, On
	if (hotkeyMainMenu!="")
		Hotkey, % hotkeyMainMenu, shMainMenu, On
	if (hotkeyCustomCommandsMenu!="")
		Hotkey, % hotkeyCustomCommandsMenu, showCustomCommandsMenu, On

	;Инициализация ItemDataConverterLib
	IniRead, hotkeyConverter, %configFile%, hotkeys, hotkeyConverter, %A_Space%
	if (hotkeyConverter!="") {
		IDCL_Init()
		Hotkey, % hotkeyConverter, IDCL_ConvertFromGame, On
	}
	
	;Инициализация встроенных команд fastReply
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	if (hotkeyForceSync!="")
		Hotkey, % hotkeyForceSync, fastCmdForceSync, On
	if (hotkeyToCharacterSelection!="")
		Hotkey, % hotkeyToCharacterSelection, fastCmdExit, On
	
	;Инициализация настраиваемых команд fastReply
	Loop %cmdNum% {
		IniRead, tempvar, %configFile%, fastReply, textCmd%A_Index%, %A_Space%
		textCmd%A_Index%:=tempvar
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		if (textCmd%A_Index%!="" && tempVar!="")
			Hotkey, % tempVar, fastCmd%A_Index%, On
	}
}

menuCreate(){
	Menu, Tray, Add, Поддержать, openDonateURL
	Menu, Tray, Add, История изменений, showUpdateHistory
	Menu, Tray, Add, Настройки, showSettings
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Default, Настройки
	Menu, Tray, Add
	Menu, Tray, Add, Испытания лабиринта, showLabTrials
	Menu, Tray, Add, Очистить кэш Path of Exile, clearPoECache
	Menu, Tray, Add, Меню разработчика, :devMenu
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить, ReStart
	Menu, Tray, Add, Завершить работу макроса, Exit
	Menu, Tray, NoStandard
	
	IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
	presetInMenu(imagesPreset)
	
	FormatTime, CurrentDate, %A_NowUTC%, MMdd
	Random, randomNum, 1, 100
	if (CurrentDate==0401 || randomNum=1)
		Menu, mainMenu, Add, Krillson, shLastImage
	
	Menu, mainMenu, Add
	
	IniRead, expandMyImages, %configFile%, settings, expandMyImages, 0
	myImagesMenuCreate(!expandMyImages)
	
	createCustomCommandsMenu()
	IniRead, hotkeyCustomCommandsMenu, %configFile%, hotkeys, hotkeyCustomCommandsMenu, %A_Space%
	if (hotkeyCustomCommandsMenu="")
		Menu, mainMenu, Add, Меню команд, :customCommandsMenu
	
	if !сompletionLabTrials()
		Menu, mainMenu, Add, Испытания лабиринта, showLabTrials
		
	Menu, mainMenu, Add, Область уведомлений, :Tray
}

openDonateURL(){
	Run, "https://qiwi.me/megaezik"
}

openConfigFolder(){
	Run, explorer "%configFolder%"
}

trayUpdate(nLine=""){
	trayMsg.=nLine
	Menu, Tray, Tip, %trayMsg%
}

ReStart(){
	Gdip_Shutdown(pToken)
	sleep 250
	Reload
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
		result := Globals[name]
		If (result == "") {
			result := value_default
		}
		return result
	}
}
