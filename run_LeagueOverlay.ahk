
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

;Список окон Path of Exile
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass

;Объявление и загрузка основных переменных
global prjName:="LeagueOverlay_ru"
global githubUser:="MegaEzik"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
if InStr(FileExist(A_ScriptDir "\profile"), "D")
	configFolder:=A_ScriptDir "\profile"
global configFile:=configFolder "\settings.ini"
global trayMsg, verScript, debugMode=0, textMsg1, textMsg2, textMsg3
FileReadLine, verScript, resources\Updates.txt, 1

;Подсказка в области уведомлений и сообщение при запуске
trayUpdate(prjName " " verScript " | AHK " A_AhkVersion)
Menu, Tray, Icon, resources\Syndicate.ico
initMsgs := ["Подготовка макроса к работе)"
			,"Поприветствуем Кассию)"
			,"Поддержи LeagueOverlay_ru)"
			,"https://qiwi.me/megaezik"]
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
global image1, image2, image3, image4, image5, image6
global OverlayStatus:=0
global imgNameArray:=["Incursion", "Map", "Fossil", "Syndicate", "Prophecy", "Oils"]
global NumImg:=imgNameArray.MaxIndex()
Loop %NumImg%{
	image%A_Index%:="resources\ImgError.png"
}
global LastImgPath:="resources\ImgError.png"
;Загружаем раскладку лабиринта
downloadLabLayout()
;Выполним myloader.cmd
If FileExist(configFolder "\myloader.cmd")
	runwait, "%configFolder%\myloader.cmd"
;Назначим последнее изображение
IniRead, lastImgPathC, %configFile%, settings, lastImgPath, %A_Space%
If (lastImgPathC!="" && FileExist(lastImgPathC))
	LastImgPath:=lastImgPathC

;Установим изображения
setPreset("resources\images\")

;Если установлен пресет, то установим его изображения
IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
if (imagesPreset!="default" && imagesPreset!="") {
	setPreset("resources\images\" imagesPreset "\")
}

;Установим таймер на проверку активного окна
SetTimer, checkWindowTimer, 250
	
;Назначим управление и создадим меню
setHotkeys()
menuCreate()

;Скроем сообщение загрузки и воспроизведем звук, при его наличии в системе
SplashTextOff
if FileExist(A_WinDir "\Media\Speech On.wav")
	SoundPlay, %A_WinDir%\Media\Speech On.wav

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
	Gui, Overlay:Destroy
	OverlayStatus:=0
	Menu, mainMenu, Show
}

shIncursion(){
	shOverlay(image1)
}

shMaps(){
	shOverlay(image2)
}

shFossils(){
	shOverlay(image3)
}

shSyndicate(){
	shOverlay(image4)
}

shProphecy(){
	shOverlay(image5)
}

shOils(){
	shOverlay(image6)
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

showUserNotes(){
	textFileWindow("Пользовательские заметки", configFolder "\notes.txt", false, "Здесь вы можете оставить для себя заметки)")
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
	
	;Настройки первой вкладки
	IniRead, windowLine, %configFile%, settings, windowLine, ahk_exe GeForceNOWStreamer.exe
	IniRead, alternativeRender, %configFile%, settings, alternativeRender, 0
	IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
	IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, 0
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	
	;Настройки второй вкладки
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyDnd, %configFile%, hotkeys, hotkeyDnd, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	IniRead, hotkeyHideout, %configFile%, hotkeys, hotkeyHideout, %A_Space%
	
	IniRead, hotkeyMsg1, %configFile%, hotkeys, hotkeyMsg1, %A_Space%
	IniRead, hotkeyMsg2, %configFile%, hotkeys, hotkeyMsg2, %A_Space%
	IniRead, hotkeyMsg3, %configFile%, hotkeys, hotkeyMsg3, %A_Space%
	IniRead, textMsg1, %configFile%, settings, textMsg1, sold(
	IniRead, textMsg2, %configFile%, settings, textMsg2, 2 minutes
	IniRead, textMsg3, %configFile%, settings, textMsg3, ty & gl exile)
	IniRead, hotkeyInvite, %configFile%, hotkeys, hotkeyInvite, %A_Space%
	IniRead, hotkeyKick, %configFile%, hotkeys, hotkeyKick, %A_Space%
	IniRead, hotkeyTradeWith, %configFile%, hotkeys, hotkeyTradeWith, %A_Space%
	
	legacyHotkeysOldPosition:=legacyHotkeys
	
	Gui, Settings:Add, Text, x10 y10 w330 h28 cGreen, %prjName% - макрос содержащий несколько нужных функций и отображающий полезные изображения.
	
	Gui, Settings:Add, Picture, x370 y2 w107 h-1, resources\qiwi-logo.png
	Gui, Settings:Add, Link, x345 y+2, <a href="https://qiwi.me/megaezik">Поддержать %prjName%</a>
	Gui, Settings:Add, Link, x10 yp+0 w250, <a href="https://ru.pathofexile.com/forum/view-thread/2694683">Тема на форуме</a> | <a href="https://github.com/MegaEzik/LeagueOverlay_ru/releases">Страница на GitHub</a>
	
	Gui, Settings:Add, Button, x317 y325 w190 gsaveSettings, Применить и перезапустить

	Gui, Settings:Add, Tab, x10 y65 w495 h255, Основные|Быстрые команды ;Вкладки
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Checkbox, vautoUpdate x20 y92 w450 Checked%autoUpdate%, Автоматически проверять и уведомлять о наличии обновлений
	
	Gui, Settings:Add, Text, x20 yp+20 w185, Другое окно для проверки:
	Gui, Settings:Add, Edit, vwindowLine x+2 yp-2 w290 h18, %windowLine%
	
	Gui, Settings:Add, Checkbox, valternativeRender x20 yp+22 w450 Checked%alternativeRender%, Альтернативная отрисовка(используйте при проблемах с Vulkan)
	
	Gui, Settings:Add, Checkbox, vloadLab x20 yp+22 w370 Checked%loadLab%, Загружать убер-лабиринт(Labyrinth.jpg) в 'Мои изображения'
	Gui, Settings:Add, Link, x430 yp+0, <a href="https://www.poelab.com/">POELab.com</a>
	
	presetList:="default"
	Loop, resources\images\*, 2
		presetList.="|" A_LoopFileName
	Gui, Settings:Add, Text, x20 yp+22 w185, Набор изображений:
	Gui, Settings:Add, DropDownList, vimagesPreset x+2 yp-3 w110, %presetList%
	GuiControl,Settings:ChooseString, imagesPreset, %imagesPreset%
	
	Gui, Settings:Add, Text, x20 y+5 w478 h2 0x10
	
	Gui, Settings:Add, Checkbox, vlegacyHotkeys x20 yp+10 w450 Checked%legacyHotkeys%, Устаревшая раскладка(не рекомендуется использовать)
	
	Gui, Settings:Add, Text, x20 yp+20 w185, Последнее изображение*:
	Gui, Settings:Add, Hotkey, vhotkeyLastImg x+2 yp-2 w110 h18, %hotkeyLastImg%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, Меню быстрого доступа*:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenu x+2 yp-2 w110 h18, %hotkeyMainMenu%
	
	Gui, Settings:Add, Text, x20 y300 w400 cGray, * Недоступно в режиме Устаревшей раскладки
	
	Gui, Settings:Tab, 2 ; Вторая вкладка
	
	Gui, Settings:Add, Text, x20 y95 w185, Синхронизировать(/oos):
	Gui, Settings:Add, Hotkey, vhotkeyForceSync x+2 yp-2 w110 h18, %hotkeyForceSync%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, К выбору персонажа(/exit):
	Gui, Settings:Add, Hotkey, vhotkeyToCharacterSelection x+2 yp-2 w110 h18, %hotkeyToCharacterSelection%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, В свое убежище(/hideout):
	Gui, Settings:Add, Hotkey, vhotkeyHideout x+2 yp-2 w110 h18, %hotkeyHideout%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, Не беспокоить(/dnd):
	Gui, Settings:Add, Hotkey, vhotkeyDnd x+2 yp-2 w110 h18, %hotkeyDnd%
	
	Gui, Settings:Add, Text, x20 y+2 w478 h2 0x10
	
	Gui, Settings:Add, Text, x20 yp+5 w185, Пригласить(/invite)*:
	Gui, Settings:Add, Hotkey, vhotkeyInvite x+2 yp-2 w110 h18, %hotkeyInvite%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, Выгнать(/kick)*:
	Gui, Settings:Add, Hotkey, vhotkeyKick x+2 yp-2 w110 h18, %hotkeyKick%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, Торговать(/tradewith)*:
	Gui, Settings:Add, Hotkey, vhotkeyTradeWith x+2 yp-2 w110 h18, %hotkeyTradeWith%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, Быстрый ответ 1*:
	Gui, Settings:Add, Hotkey, vhotkeyMsg1 x+2 yp-2 w110 h18, %hotkeyMsg1%
	Gui, Settings:Add, Edit, vtextMsg1 x+2 w178 h18, %textMsg1%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, Быстрый ответ 2*:
	Gui, Settings:Add, Hotkey, vhotkeyMsg2 x+2 yp-2 w110 h18, %hotkeyMsg2%
	Gui, Settings:Add, Edit, vtextMsg2 x+2 w178 h18, %textMsg2%
	
	Gui, Settings:Add, Text, x20 yp+22 w185, Быстрый ответ 3*:
	Gui, Settings:Add, Hotkey, vhotkeyMsg3 x+2 yp-2 w110 h18, %hotkeyMsg3%
	Gui, Settings:Add, Edit, vtextMsg3 x+2 w178 h18, %textMsg3%
	
	Gui, Settings:Add, Text, x20 y300 w400 cGray, * Выполняется по отношению к игроку в последнем диалоге
	
	Gui, Settings:+AlwaysOnTop
	Gui, Settings:Show, w515, %prjName% %VerScript% - Информация и настройки ;Отобразить окно настроек
}

saveSettings(){
	global
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	Gui, Settings:Submit
	
	if (imagesPreset="")
		imagesPreset:="default"
	if alternativeRender
		windowLine:=prjName " - Overlay ahk_class AutoHotkeyGUI"
	
	;Настройки первой вкладки
	IniWrite, %windowLine%, %configFile%, settings, windowLine
	IniWrite, %alternativeRender%, %configFile%, settings, alternativeRender
	IniWrite, %autoUpdate%, %configFile%, settings, autoUpdate
	IniWrite, %imagesPreset%, %configFile%, settings, imagesPreset
	IniWrite, %loadLab%, %configFile%, settings, loadLab
	IniWrite, %legacyHotkeys%, %configFile%, settings, legacyHotkeys
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	
	;Настройки второй вкладки
	IniWrite, %hotkeyForceSync%, %configFile%, hotkeys, hotkeyForceSync
	IniWrite, %hotkeyDnd%, %configFile%, hotkeys, hotkeyDnd
	IniWrite, %hotkeyToCharacterSelection%, %configFile%, hotkeys, hotkeyToCharacterSelection
	IniWrite, %hotkeyHideout%, %configFile%, hotkeys, hotkeyHideout
	
	IniWrite, %hotkeyKick%, %configFile%, hotkeys, hotkeyKick
	IniWrite, %hotkeyInvite%, %configFile%, hotkeys, hotkeyInvite
	IniWrite, %hotkeyTradeWith%, %configFile%, hotkeys, hotkeyTradeWith
	IniWrite, %hotkeyMsg1%, %configFile%, hotkeys, hotkeyMsg1
	IniWrite, %hotkeyMsg2%, %configFile%, hotkeys, hotkeyMsg2
	IniWrite, %hotkeyMsg3%, %configFile%, hotkeys, hotkeyMsg3
	IniWrite, %textMsg1%, %configFile%, settings, textMsg1
	IniWrite, %textMsg2%, %configFile%, settings, textMsg2
	IniWrite, %textMsg3%, %configFile%, settings, textMsg3
	
	if (legacyHotkeys>legacyHotkeysOldPosition) {
		msgText:="Устаревшая раскладка имеет следующее управление:`n"
		msgText.="`t[Alt+F2] - Синдикат`n`t[Alt+F3] - Вмешательство`n`t[Alt+F4] - Атлас`n`t[Alt+F6] - Ископаемые`n`t[Alt+F7] - Пророчества`n"
		msgText.="`nИспользовать не рекомендуется, поскольку заменяется сочетание клавиш [Alt+F4], и вы не сможете выйти из игры используя его!`n"
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
	IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, 0
	If !legacyHotkeys {
		IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
		IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
		if (hotkeyLastImg!="")
			Hotkey, % hotkeyLastImg, shLastImage, On
		if (hotkeyMainMenu!="")
			Hotkey, % hotkeyMainMenu, shMainMenu, On
	} Else {
		Hotkey, !f2, shSyndicate, On
		Hotkey, !f3, shIncursion, On
		Hotkey, !f4, shMaps, On
		Hotkey, !f6, shFossils, On
		Hotkey, !f7, shProphecy, On
	}
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	IniRead, hotkeyHideout, %configFile%, hotkeys, hotkeyHideout, %A_Space%
	IniRead, hotkeyDnd, %configFile%, hotkeys, hotkeyDnd, %A_Space%
	IniRead, hotkeyMsg1, %configFile%, hotkeys, hotkeyMsg1, %A_Space%
	IniRead, hotkeyMsg2, %configFile%, hotkeys, hotkeyMsg2, %A_Space%
	IniRead, hotkeyMsg3, %configFile%, hotkeys, hotkeyMsg3, %A_Space%
	IniRead, textMsg1, %configFile%, settings, textMsg1, %A_Space%
	IniRead, textMsg2, %configFile%, settings, textMsg2, %A_Space%
	IniRead, textMsg3, %configFile%, settings, textMsg3, %A_Space%
	IniRead, hotkeyInvite, %configFile%, hotkeys, hotkeyInvite, %A_Space%
	IniRead, hotkeyKick, %configFile%, hotkeys, hotkeyKick, %A_Space%
	IniRead, hotkeyTradeWith, %configFile%, hotkeys, hotkeyTradeWith, %A_Space%
	if (hotkeyForceSync!="")
		Hotkey, % hotkeyForceSync, forceSync, On
	if (hotkeyToCharacterSelection!="")
		Hotkey, % hotkeyToCharacterSelection, toCharacterSelection, On
	if (hotkeyHideout!="")
		Hotkey, % hotkeyHideout, goHideout, On
	if (hotkeyDnd!="")
		Hotkey, % hotkeyDnd, dndMode, On
	if (hotkeyMsg1!="")
		Hotkey, % hotkeyMsg1, chatMsg1, On
	if (hotkeyMsg2!="")
		Hotkey, % hotkeyMsg2, chatMsg2, On
	if (hotkeyMsg3!="")
		Hotkey, % hotkeyMsg3, chatMsg3, On
	if (hotkeyInvite!="")
		Hotkey, % hotkeyInvite, chatInvite, On
	if (hotkeyKick!="")
		Hotkey, % hotkeyKick, chatKick, On
	if (hotkeyTradeWith!="")
		Hotkey, % hotkeyTradeWith, chatTradeWith, On
}

menuCreate(){
	myImagesMenuCreate()
	createCustomCommandsMenu()
	
	Menu, Tray, Add, История изменений, showUpdateHistory
	Menu, Tray, Add, Информация и настройки, showSettings
	Menu, Tray, Default, Информация и настройки
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Add
	Menu, Tray, Add, Отметить испытания лабиринта, showLabTrials
	Menu, Tray, Add, Пользовательские заметки, showUserNotes
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
	Menu, mainMenu, Add, Зана - Карты, shMaps
	Menu, mainMenu, Add, Кассия - Масла, shOils
	FormatTime, Month, %A_Now%, MM
	Random, randomNum, 1, 100
	if (Month=4 || randomNum=1)
		Menu, mainMenu, Add, Криллсон - Руководство по рыбалке, shRandom
	Menu, mainMenu, Add, Навали - Пророчества, shProphecy
	Menu, mainMenu, Add, Нико - Ископаемые, shFossils
	Menu, mainMenu, Add
	Menu, mainMenu, Add, Меню команд, :customCommandsMenu
	Menu, mainMenu, Add, Меню области уведомлений, :Tray
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
