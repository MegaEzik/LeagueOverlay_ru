
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
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass
GroupAdd, PoEWindowGrp, ahk_exe GeForceNOWStreamer.exe

;Объявление и загрузка основных переменных
global prjName:="LeagueOverlay_ru"
global githubUser:="MegaEzik"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
if InStr(FileExist(A_ScriptDir "\profile"), "D")
	configFolder:=A_ScriptDir "\profile"
global configFile:=configFolder "\settings.ini"
global trayMsg, verScript, debugMode=0
global textCmd1, textCmd2, textCmd3, textCmd4, textCmd5, textCmd6, textCmd7, textCmd8, textCmd9, textCmd10, textCmd11, textCmd12, cmdNum=12
FileReadLine, verScript, resources\Updates.txt, 1

;Подсказка в области уведомлений и сообщение при запуске
trayUpdate(prjName " " verScript " | AHK " A_AhkVersion)
Menu, Tray, Icon, resources\Syndicate.ico
initMsgs := ["Подготовка макроса к работе..."
			,"Поддержи LeagueOverlay_ru..."
			
			,"Спасибо, AbyssSPIRIT)"
			,"Спасибо, milcart)"
			,"Спасибо, Pip4ik)"]
Random, randomNum, 1, initMsgs.MaxIndex()
initMsg:=initMsgs[randomNum]
SplashTextOn, 300, 20, %prjName%, %initMsg%

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
	GroupAdd, PoEWindowGrp, %windowLine%

;Запуск gdi+
If !pToken:=Gdip_Startup()
	{
	   ;MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	   MsgBox, 48, Ошибка gdi+!, Не удалось запустить gdi+. Пожалуйста, убедитесь, что в вашей системе он есть
	}
OnExit, Exit

;Глобальные переменные для количества изображений, самих изображений, их статуса и номера последнего
global image1, image2, image3, image4, image5
global OverlayStatus:=0
global imgNameArray:=["Incursion", "Fossil", "Syndicate", "Prophecy", "Oils"]
global NumImg:=imgNameArray.MaxIndex()
Loop %NumImg%{
	image%A_Index%:="resources\ImgError.png"
}
global LastImgPath:="resources\ImgError.png"
;Загружаем раскладку лабиринта
downloadLabLayout()
;Выполним myloader.ahk
If FileExist(configFolder "\myloader.ahk")
	runwait, "%configFolder%\myloader.ahk"
;Назначим последнее изображение
IniRead, lastImgPathC, %configFile%, settings, lastImgPath, %A_Space%
If (lastImgPathC!="" && FileExist(lastImgPathC))
	LastImgPath:=lastImgPathC

;Установим изображения
setPreset("resources\images\")

;Если установлен пресет, то установим его изображения
IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
if (imagesPreset!="default" && imagesPreset!="")
	setPreset("resources\images\" imagesPreset "\")

;Установим таймер на проверку активного окна
SetTimer, checkWindowTimer, 250
	
;Назначим управление и создадим меню
setHotkeys()
menuCreate()

;Скроем сообщение загрузки и воспроизведем звук, при его наличии в системе
if FileExist(A_WinDir "\Media\Speech On.wav")
	SoundPlay, %A_WinDir%\Media\Speech On.wav
SplashTextOff

;Иногда после запуска будем предлагать поддержать проект
Random, randomNum, 1, 10
if (randomNum=1 && !debugMode) {
	MsgText:="Нравится " prjName ", хотите поддержать автора?"
	MsgBox, 0x1024, %prjName%, %MsgText%, 10
	IfMsgBox Yes
		run, https://qiwi.me/megaezik
}

Return

;#################################################

#IfWinActive ahk_group PoEWindowGrp

setPreset(path){
	Loop %NumImg% {
		If imgNameArray[A_Index]!="" {
			If FileExist(path imgNameArray[A_Index] ".jpg")
				image%A_Index%:=path imgNameArray[A_Index] ".jpg"
			If FileExist(path imgNameArray[A_Index] ".png")
				image%A_Index%:=path imgNameArray[A_Index] ".png"
		}
	}
}

shLastImage(){
	shOverlay(LastImgPath)
}

shMainMenu(){
	destroyOverlay()
	Menu, mainMenu, Show
}

shLabyrinth(){
	shOverlay(configFolder "\images\Labyrinth.jpg")
}

shIncursion(){
	shOverlay(image1)
}

shFossils(){
	shOverlay(image2)
}

shSyndicate(){
	shOverlay(image3)
}

shProphecy(){
	shOverlay(image4)
}

shOils(){
	shOverlay(image5)
}

shRandom(){
	Random, randomNum, 1, NumImg
	shOverlay(image%randomNum%)
}

shMyImage(imagename){
	shOverlay(configFolder "\images\" imagename)
}

openMyImagesFolder(){
	If !FileExist(configFolder "\images")
		FileCreateDir, %configFolder%\images
	sleep 15
	Run, explorer "%configFolder%\images"
}

myImagesMenuCreate(){
	Loop, %configFolder%\images\*.*, 1
		if RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp)$")
			Menu, myImagesMenu, Add, %A_LoopFileName%, shMyImage
	Menu, myImagesMenu, Add
	Menu, myImagesMenu, Add, Открыть папку, openMyImagesFolder
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
	Gui, tfwGui:+AlwaysOnTop
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
	IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, 0
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyConverter, %configFile%, hotkeys, hotkeyConverter, %A_Space%
	
	;Настройки второй вкладки
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	
	legacyHotkeysOldPosition:=legacyHotkeys
	
	Gui, Settings:Add, Text, x10 y10 w300 h28 cGreen, %prjName% - макрос содержащий несколько нужных функций и отображающий полезные изображения.
	
	Gui, Settings:Add, Picture, x340 y2 w107 h-1, resources\qiwi-logo.png
	Gui, Settings:Add, Link, x315 y+2, <a href="https://qiwi.me/megaezik">Поддержать %prjName%</a>
	Gui, Settings:Add, Link, x10 yp+0 w300, <a href="https://www.autohotkey.com/download/">AutoHotkey</a> | <a href="https://ru.pathofexile.com/forum/view-thread/2694683">Тема на форуме</a> | <a href="https://github.com/MegaEzik/LeagueOverlay_ru/releases">Страница на GitHub</a>
	
	Gui, Settings:Add, Button, x315 y385 w162 gsaveSettings, Применить и перезапустить

	Gui, Settings:Add, Tab, x10 y65 w465 h315, Основные|Быстрые команды ;Вкладки
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Checkbox, vautoUpdate x20 y92 w450 Checked%autoUpdate%, Автоматически проверять и уведомлять о наличии обновлений
	
	Gui, Settings:Add, Text, x20 yp+20 w155, Другое окно для проверки:
	Gui, Settings:Add, Edit, vwindowLine x+2 yp-2 w290 h18, %windowLine%
	
	Gui, Settings:Add, Checkbox, vloadLab x20 yp+22 w370 Checked%loadLab%, Загружать убер-лабиринт(Мои изображения>Labyrinth.jpg)
	Gui, Settings:Add, Link, x400 yp+0, <a href="https://www.poelab.com/">POELab.com</a>
	
	presetList:="default"
	Loop, resources\images\*, 2
		presetList.="|" A_LoopFileName
	Gui, Settings:Add, Text, x20 yp+22 w295, Набор изображений:
	Gui, Settings:Add, DropDownList, vimagesPreset x+2 yp-3 w150, %presetList%
	GuiControl,Settings:ChooseString, imagesPreset, %imagesPreset%
	
	Gui, Settings:Add, Text, x20 y+4 w450 h2 0x10
	
	Gui, Settings:Add, Checkbox, vlegacyHotkeys x20 yp+7 w450 Checked%legacyHotkeys%, Устаревшая раскладка(использовать не рекомендуется)
	
	Gui, Settings:Add, Text, x20 yp+20 w295, Последнее изображение*:
	Gui, Settings:Add, Hotkey, vhotkeyLastImg x+2 yp-2 w150 h18, %hotkeyLastImg%
	
	Gui, Settings:Add, Text, x20 yp+22 w295, Меню быстрого доступа*:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenu x+2 yp-2 w150 h18, %hotkeyMainMenu%
	
	Gui, Settings:Add, Text, x20 y+4 w450 h2 0x10
	
	Gui, Settings:Add, Text, x20 yp+7 w295, Конвертировать описание предмета Ru>En:
	Gui, Settings:Add, Hotkey, vhotkeyConverter x+2 yp-2 w150 h18, %hotkeyConverter%
	
	Gui, Settings:Add, Text, x20 y360 w400 cGray, * Недоступно в режиме Устаревшей раскладки
	
	Gui, Settings:Tab, 2 ; Вторая вкладка
	
	Gui, Settings:Add, Text, x20 y95 w295, Синхронизировать(/oos):
	Gui, Settings:Add, Hotkey, vhotkeyForceSync x+2 yp-2 w150 h18, %hotkeyForceSync%
	
	Gui, Settings:Add, Text, x20 yp+22 w295, К выбору персонажа(/exit):
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
		Gui, Settings:Add, Edit, vtextCmd%A_Index% x20 yp+20 w295 h18, %tempVar%
		
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%A_Index% x+2 w150 h18, %tempVar%
	}
	
	Gui, Settings:+AlwaysOnTop
	Gui, Settings:Show, w485, %prjName% %VerScript% - Информация и настройки ;Отобразить окно настроек
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
	IniWrite, %legacyHotkeys%, %configFile%, settings, legacyHotkeys
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %hotkeyConverter%, %configFile%, hotkeys, hotkeyConverter
	
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
	
	if (legacyHotkeys>legacyHotkeysOldPosition) {
		msgText:="Устаревшая раскладка имеет следующее управление:`n"
		msgText.="`t[Alt+F1] - Лабиринт`n`t[Alt+F2] - Синдикат`n`t[Alt+F3] - Вмешательство`n`t[Alt+F6] - Ископаемые`n`t[Alt+F7] - Пророчества`n`t[Alt+F8] - Масла`n"
		msgText.="`nВы все еще хотите использовать эту раскладку?"
		MsgBox, 0x1024, %prjName%,  %msgText%
		IfMsgBox No
			IniWrite, 0, %configFile%, settings, legacyHotkeys
	}
	ReStart()
}

setHotkeys(){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	;Инициализация основных клавиш макроса
	IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, 0
	If !legacyHotkeys {
		IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
		IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
		if (hotkeyLastImg!="")
			Hotkey, % hotkeyLastImg, shLastImage, On
		if (hotkeyMainMenu!="")
			Hotkey, % hotkeyMainMenu, shMainMenu, On
	} Else {
		Hotkey, !f1, shLabyrinth, On
		Hotkey, !f2, shSyndicate, On
		Hotkey, !f3, shIncursion, On
		Hotkey, !f6, shFossils, On
		Hotkey, !f7, shProphecy, On
		Hotkey, !f8, shOils, On
	}
	
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
	myImagesMenuCreate()
	createCustomCommandsMenu()
	
	Menu, Tray, Add, История изменений, showUpdateHistory
	Menu, Tray, Add, Информация и настройки, showSettings
	Menu, Tray, Default, Информация и настройки
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Add
	Menu, Tray, Add, Открыть папку настроек, openConfigFolder
	Menu, Tray, Add, Очистить кэш Path of Exile, clearPoECache
	If debugMode
		Menu, Tray, Add, Инструменты разработчика, :devMenu
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить, ReStart
	Menu, Tray, Add, Завершить работу макроса, Exit
	Menu, Tray, NoStandard
	
	Menu, mainMenu, Add, Мои изображения, :myImagesMenu
	Menu, mainMenu, Add
	Menu, mainMenu, Add, Альва - Комнаты храма Ацоатль, shIncursion
	Menu, mainMenu, Add, Джун - Награды бессмертного Синдиката, shSyndicate
	Menu, mainMenu, Add, Кассия - Масла, shOils
	FormatTime, Month, %A_Now%, MM
	Random, randomNum, 1, 50
	if (Month=4 || randomNum=1)
		Menu, mainMenu, Add, Криллсон - Руководство по рыбалке, shRandom
	Menu, mainMenu, Add, Навали - Пророчества, shProphecy
	Menu, mainMenu, Add, Нико - Ископаемые, shFossils
	Menu, mainMenu, Add
	Menu, mainMenu, Add, Меню команд, :customCommandsMenu
	Menu, mainMenu, Add, Испытания лабиринта, showLabTrials
	Menu, mainMenu, Add
	Menu, mainMenu, Add, Область уведомлений, :Tray
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
