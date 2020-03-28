
/*
	Данный скрипт основан на https://github.com/heokor/League-Overlay
	Данная версия модифицирована MegaEzik
	
	Назначение дополнительных библиотек:
		*Gdip_All.ahk - Библиотека отвечающая за отрисовку оверлея, авторство https://github.com/PoE-TradeMacro/PoE-CustomUIOverlay
		*JSON.ahk - Разбор данных от api, авторство https://github.com/cocobelgica/AutoHotkey-JSON
		*Overlay.ahk - Набор функций вынесенных из основного скрипта LeagueOverlay
		*Labyrinth.ahk - Загрузка лабиринта с poelab.com и формирование меню по управлению
		*Updater.ahk - Проверка и установка обновлений
	
	Управление:
		[Alt+F1] - Последнее изображение
		[Alt+F2] - Меню с изображениями
		
		Эти сочетания клавиш и другие настройки вы можете изменить вручную в файле конфигурации %USERPROFILE%\Documents\LeagueOverlay_ru\settings.ini
*/

if (!A_IsAdmin) {
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
	ExitApp
}

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

;Подключение библиотек
#Include, %A_ScriptDir%\resources\Gdip_All.ahk
#Include, %A_ScriptDir%\resources\JSON.ahk
#Include, %A_ScriptDir%\resources\Overlay.ahk
#Include, %A_ScriptDir%\resources\Labyrinth.ahk
#Include, %A_ScriptDir%\resources\Updater.ahk

;Объявление и загрузка основных переменных
global prjName:="LeagueOverlay_ru"
global githubUser:="MegaEzik"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
global configFile:=configFolder "\settings.ini"
global trayMsg, verScript, textMsg1, textMsg2, textMsg3
FileReadLine, verScript, resources\Updates.txt, 4

;Подсказка в области уведомлений и сообщение при запуске
trayUpdate("PoE-" prjName " v" verScript)
Menu, Tray, Icon, resources\Syndicate.ico
initMsgs := ["Подготовка макроса к работе)"
			,"Поприветствуем Кассию)"
			,"Поддержи LeagueOverlay_ru)"
			,"https://qiwi.me/megaezik"]
Random, randomNum, 1, initMsgs.MaxIndex()
initMsg:=initMsgs[randomNum]
SplashTextOn, 300, 20, %prjName%, %initMsg%

;Проверка обновлений
IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
if autoUpdate {
	CheckUpdateFromMenu("onStart")
	SetTimer, CheckUpdate, 10800000
}

;Проверим файл конфигурации
IniRead, verConfig, %configFile%, info, verConfig, ""
if (verConfig!=verScript) {
	If FileExist(A_MyDocuments "\LeagueOverlay_ru\") {
		FileCopyDir, %A_MyDocuments%\LeagueOverlay_ru\, %configFolder%, 0
		FileRemoveDir, %A_MyDocuments%\LeagueOverlay_ru\, 1
		sleep 25
	}
	showSettings()
	FileDelete, %configFile%
	sleep 25
	FileCreateDir, %configFolder%\images
	IniWrite, %verScript%, %configFile%, info, verConfig
	saveSettings()
}

;Запуск gdi+
If !pToken:=Gdip_Startup()
	{
	   ;MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	   MsgBox, 48, Ошибка gdi+!, Не удалось запустить gdi+. Пожалуйста, убедитесь, что в вашей системе он есть
	}
OnExit, Exit

;Глобальные переменные для количества изображений, самих изображений, их статуса и номера последнего
global GuiOn1, GuiOn2, GuiOn3, GuiOn4, GuiOn5, GuiOn6, GuiOn7, GuiOn8, GuiOn9
global image1, image2, image3, image4, image5, image6, image7, image8, image9
global imgNameArray:=["", "", "Custom", "Incursion", "Map", "Fossil", "Syndicate", "Prophecy", "Oils"]
global NumImg:=imgNameArray.MaxIndex()
global LastImg:=1
Loop %NumImg%{
	GuiOn%A_Index%:=0
	image%A_Index%:="resources\images\ImgError.png"
}

;Установим изображения
setPreset("resources\images\")

;Если установлен пресет, то установим его изображения
IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
if (imagesPreset!="default" && imagesPreset!="") {
	setPreset("resources\images\" imagesPreset "\")
}

;Назначим новые пути изображений, если их аналоги есть в папке с настройками
setPreset(configFolder "\images\")
	
;Загружаем раскладку лабиринта, и если изображение получено, то устанавливаем его
IniRead, loadLab, %configFile%, settings, loadLab, 0
if (loadLab) {
	run, https://www.poelab.com/
	sleep 1000
	downloadLabLayout()
	If FileExist(configFolder "\Lab.jpg") {
		image1:=configFolder "\Lab.jpg"
		Menu, mainMenu, Add, POELab.com - Раскладка лабиринта, shLabyrinth
	}
}
	
;Назначим управление и создадим меню
setHotkeys()
menuCreate()

;Инициализируем оверлей
global poeWindowName="Path of Exile ahk_class POEWindowClass"
initOverlay()

SplashTextOff

Return

;#################################################

#IfWinActive Path of Exile

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
	shOverlay(LastImg)
}

shMainMenu(){
	Loop %NumImg%{
		Gui, %A_Index%: Hide
		GuiON%A_Index%:=0
	}
	Menu, mainMenu, Show
}

shLabyrinth(){
	shOverlay(1)
}

shCustom(){
	shOverlay(3)
}

shIncursion(){
	shOverlay(4)
}

shMaps(){
	shOverlay(5)
}

shFossils(){
	shOverlay(6)
}

shSyndicate(){
	shOverlay(7)
}

shProphecy(){
	shOverlay(8)
}

shOils(){
	shOverlay(9)
}

forceSync(){
	BlockInput On
	SendInput, {Enter}{/}oos{Enter}
	BlockInput Off
}

toCharacterSelection(){
	BlockInput On
	SendInput, {Enter}{/}exit{Enter}
	BlockInput Off
}

goHideout(){
	BlockInput On
	SendInput, {Enter}{/}hideout{Enter}
	BlockInput Off
}

dndMode(){
	BlockInput On
	SendInput, {Enter}{/}dnd{Enter}
	BlockInput Off
}

chatMsg1(){
	chatReply(textMsg1)
}

chatMsg2(){
	chatReply(textMsg2)
}

chatMsg3(){
	chatReply(textMsg3)
}

chatReply(msg){
	BlockInput On
	SendInput, ^{Enter}%msg%{Enter}
	BlockInput Off
}

chatInvite(){
	BlockInput On
	SendInput, ^{Enter}{Home}{Delete}/invite {Enter}
	BlockInput Off
}

chatKick(){
	BlockInput On
	SendInput, ^{Enter}{Home}{Delete}/kick {Enter}
	BlockInput Off
}

chatTradeWith(){
	BlockInput On
	SendInput, ^{Enter}{Home}{Delete}/tradewith {Enter}
	BlockInput Off
}

textFileWindow(Title, FilePath, ReadOnlyStatus=true, contentDefault=""){
	global
	tfwFilePath:=FilePath
	Gui, tfwGui:Destroy
	Gui, tfwGui:Font, s10, Consolas
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
	FileSelectFile, FilePath, , , Укажите путь к исполняемому файлу игры, (PathOfExile.exe;PathOfExileSteam.exe)
	if (FilePath="") {
		msgbox, 0x1040, %prjName%, Операция прервана пользователем!
		return
	} else {
		SplashTextOn, 300, 20, %prjName%, Очистка кэша, пожалуйста подождите...
		
		SplitPath, FilePath, , PoEFolderPath
		FileRemoveDir, %PoEFolderPath%\CachedHLSLShaders, 1
		FileRemoveDir, %PoEFolderPath%\logs, 1
		FileRemoveDir, %PoEFolderPath%\ShaderCacheD3D11, 1
		
		PoEConfigFolderPath:=A_MyDocuments "\My Games\Path of Exile"
		FileRemoveDir, %PoEConfigFolderPath%\Countdown, 1
		FileRemoveDir, %PoEConfigFolderPath%\DailyDealCache, 1
		FileRemoveDir, %PoEConfigFolderPath%\Minimap, 1
		FileRemoveDir, %PoEConfigFolderPath%\MOTDCache, 1
		FileRemoveDir, %PoEConfigFolderPath%\ShopImages, 1
		FileRemoveDir, %PoEConfigFolderPath%\OnlineFilters, 1
		
		SplashTextOff
	}
}

replacerImages(){
	FileSelectFile, FilePath, , , Укажите путь к новому файлу для создания замены, Изображения (*.jpg;*.png)
	if (FilePath="" || !FileExist(FilePath) || !RegExMatch(FilePath, "i).(jpg|png|zip)$")) {
		msgbox, 0x1040, %prjName%, Неподходящий тип файла!
	} else {
		if RegExMatch(FilePath, "i).(jpg|png)$", typeFile) {
			SplitPath, FilePath, replaceImgName
			if RegExMatch(replaceImgName, "i)(Fossil|Incursion|Map|Oils|Prophecy|Syndicate)", replaceImgType) {
				StringLower, replaceImgType, replaceImgType, T
			} else {
				replaceImgType:="Custom"
			}
			FileCopy, %FilePath%, %configFolder%\images\%replaceImgType%.%typeFile1%, true
			Msgbox, 0x1040, %prjName%, Создана новая замена - %replaceImgType%!, 2
		}
		if RegExMatch(FilePath, "i).zip$") {
			unZipArchive(FilePath, configFolder "\images\")
		}
	}
}

delReplacedImages(){
	FileSelectFile, FilePath, , %configFolder%\images\, Выберите изображение в этой папке для удаления замены, Изображения (*.jpg;*.png)
	if (FilePath="" || !FileExist(FilePath) || !RegExMatch(FilePath, "i).(jpg|png)$") || !inStr(FilePath, configFolder "\images\")) {
		msgbox, 0x1040, %prjName%, Изображение указано не верно!
		return
	} else {
		FileDelete, %FilePath%
	}
}

showSettings(){
	global
	Gui, Settings:Destroy
	Gui, Settings:Font, s8, Consolas
	
	IniRead, autoUpdateS, %configFile%, settings, autoUpdate, 1
	IniRead, devModeS, %configFile%, settings, devMode, 0
	IniRead, imagesPresetS, %configFile%, settings, imagesPreset, default
	IniRead, loadLabS, %configFile%, settings, loadLab, 0
	IniRead, legacyHotkeysS, %configFile%, settings, legacyHotkeys, 0
	IniRead, hotkeyLastImgS, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenuS, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyForceSyncS, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyDndS, %configFile%, hotkeys, hotkeyDnd, %A_Space%
	IniRead, hotkeyToCharacterSelectionS, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	IniRead, hotkeyHideoutS, %configFile%, hotkeys, hotkeyHideout, %A_Space%
	
	IniRead, hotkeyMsg1S, %configFile%, hotkeys, hotkeyMsg1, %A_Space%
	IniRead, hotkeyMsg2S, %configFile%, hotkeys, hotkeyMsg2, %A_Space%
	IniRead, hotkeyMsg3S, %configFile%, hotkeys, hotkeyMsg3, %A_Space%
	IniRead, textMsg1S, %configFile%, settings, textMsg1, sold(
	IniRead, textMsg2S, %configFile%, settings, textMsg2, 2 minutes
	IniRead, textMsg3S, %configFile%, settings, textMsg3, ty & gl exile)
	IniRead, hotkeyInviteS, %configFile%, hotkeys, hotkeyInvite, %A_Space%
	IniRead, hotkeyKickS, %configFile%, hotkeys, hotkeyKick, %A_Space%
	IniRead, hotkeyTradeWithS, %configFile%, hotkeys, hotkeyTradeWith, %A_Space%
	
	legacyHotkeysOldPosition:=legacyHotkeysS
	lvlLabOldPosition:=lvlLabS
	
	Menu, settingsSubMenu2, Add, Указать изображение для создания замены, replacerImages
	Menu, settingsSubMenu2, Add, Удалить замену указав на изображение, delReplacedImages
	Menu, settingsMenuBar, Add, Замена изображений, :settingsSubMenu2
	Menu, settingsMenuBar, Add, История изменений, showUpdateHistory
	Gui, Settings:Menu, settingsMenuBar
	
	Gui, Settings:Add, Text, x10 y5 w330 h28 cGreen, %prjName% - макрос содержащий несколько нужных функций и отображающий полезные изображения.
	
	Gui, Settings:Add, Picture, x370 y7 w107 h-1, resources\qiwi-logo.png
	Gui, Settings:Add, Link, x345 y+7, <a href="https://qiwi.me/megaezik">Поддержать %prjName%</a>
	Gui, Settings:Add, Link, x10 yp+0 w250, <a href="https://ru.pathofexile.com/forum/view-thread/2694683">Тема на форуме</a> | <a href="https://github.com/MegaEzik/LeagueOverlay_ru/releases">Страница на GitHub</a>
	
	Gui, Settings:Add, Text, x10 yp-18 w184, Установлена версия: %verScript%
	Gui, Settings:Add, Button, x+2 yp-5 w135 gCheckUpdateFromMenu, Выполнить обновление
	
	Gui, Settings:Add, Button, x10 y360 gdelConfigFolder, Сбросить
	Gui, Settings:Add, Button, x+2 yp+0 gopenConfigFolder, Папка настроек
	Gui, Settings:Add, Button, x340 yp+0 w165 gsaveSettings, Применить и перезапустить

	Gui, Settings:Add, Tab, x10 y75 w495 h280, Основные настройки|Быстрые команды ;Вкладки
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Checkbox, vautoUpdateS x25 y105 w370 Checked%autoUpdateS%, Автоматически проверять и уведомлять о наличии обновлений
	Gui, Settings:Add, Checkbox, vdevModeS x25 yp+22 w370 disabled Checked%devModeS%, Режим разработчика
	Gui, Settings:Add, Checkbox, vloadLabS x25 yp+22 w370 Checked%loadLabS%, Загружать раскладку лабиринта(POELab.com)
	
	presetListS:="default"
	Loop, resources\images\*, 2
		presetListS.="|" A_LoopFileName
	Gui, Settings:Add, Text, x25 yp+22 w170, Набор изображений:
	Gui, Settings:Add, DropDownList, vimagesPresetS x+2 yp-3 w135, %presetListS%
	GuiControl,Settings:ChooseString, imagesPresetS, %imagesPresetS%
	
	Gui, Settings:Add, Text, x25 y+5 w470 h2 0x10
	
	Gui, Settings:Add, Checkbox, vlegacyHotkeysS x25 yp+10 w370 Checked%legacyHotkeysS%, Режим Устаревшей раскладки(использовать не рекомендуется)
	
	Gui, Settings:Add, Text, x25 yp+22 w170, Последнее изображение*:
	Gui, Settings:Add, Hotkey, vhotkeyLastImgS x+2 yp-3 w135 h20, %hotkeyLastImgS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Меню изображений*:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenuS x+2 yp-3 w135 h20, %hotkeyMainMenuS%
	
	Gui, Settings:Add, Text, x25 y335 w400 cGray, * - Недоступно при использовании режима Устаревшей раскладки
	
	Gui, Settings:Tab, 2 ; Вторая вкладка
	
	Gui, Settings:Add, Text, x25 y105 w170, Синхронизировать(/oos):
	Gui, Settings:Add, Hotkey, vhotkeyForceSyncS x+2 yp-3 w135 h20, %hotkeyForceSyncS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, К выбору персонажа(/exit):
	Gui, Settings:Add, Hotkey, vhotkeyToCharacterSelectionS x+2 yp-3 w135 h20, %hotkeyToCharacterSelectionS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, В убежище(/hideout):
	Gui, Settings:Add, Hotkey, vhotkeyHideoutS x+2 yp-3 w135 h20, %hotkeyHideoutS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Не беспокоить(/dnd):
	Gui, Settings:Add, Hotkey, vhotkeyDndS x+2 yp-3 w135 h20, %hotkeyDndS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Пригласить(/invite)*:
	Gui, Settings:Add, Hotkey, vhotkeyInviteS x+2 yp-3 w135 h20, %hotkeyInviteS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Выгнать(/kick)*:
	Gui, Settings:Add, Hotkey, vhotkeyKickS x+2 yp-3 w135 h20, %hotkeyKickS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Торговать(/tradewith)*:
	Gui, Settings:Add, Hotkey, vhotkeyTradeWithS x+2 yp-3 w135 h20, %hotkeyTradeWithS%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Быстрый ответ 1*:
	Gui, Settings:Add, Hotkey, vhotkeyMsg1S x+2 yp-3 w135 h20, %hotkeyMsg1S%
	Gui, Settings:Add, Edit, vtextMsg1S x+5 w155 h20, %textMsg1S%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Быстрый ответ 2*:
	Gui, Settings:Add, Hotkey, vhotkeyMsg2S x+2 yp-3 w135 h20, %hotkeyMsg2S%
	Gui, Settings:Add, Edit, vtextMsg2S x+5 w155 h20, %textMsg2S%
	
	Gui, Settings:Add, Text, x25 yp+26 w170, Быстрый ответ 3*:
	Gui, Settings:Add, Hotkey, vhotkeyMsg3S x+2 yp-3 w135 h20, %hotkeyMsg3S%
	Gui, Settings:Add, Edit, vtextMsg3S x+5 w155 h20, %textMsg3S%
	
	Gui, Settings:Add, Text, x25 y335 w400 cGray, * - Применяется по отношению к игроку в последнем диалоге
	
	Gui, Settings:Show, w515, %prjName% - Информация и настройки ;Отобразить окно настроек
}

saveSettings(){
	global
	Gui, Settings:Submit
	
	if (imagesPresetS="")
		imagesPresetS:="default"
	
	IniWrite, %autoUpdateS%, %configFile%, settings, autoUpdate
	IniWrite, %devModeS%, %configFile%, settings, devMode
	IniWrite, %imagesPresetS%, %configFile%, settings, imagesPreset
	IniWrite, %loadLabS%, %configFile%, settings, loadLab
	IniWrite, %legacyHotkeysS%, %configFile%, settings, legacyHotkeys
	IniWrite, %hotkeyLastImgS%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenuS%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %hotkeyForceSyncS%, %configFile%, hotkeys, hotkeyForceSync
	IniWrite, %hotkeyDndS%, %configFile%, hotkeys, hotkeyDnd
	IniWrite, %hotkeyToCharacterSelectionS%, %configFile%, hotkeys, hotkeyToCharacterSelection
	IniWrite, %hotkeyHideoutS%, %configFile%, hotkeys, hotkeyHideout
	
	IniWrite, %hotkeyKickS%, %configFile%, hotkeys, hotkeyKick
	IniWrite, %hotkeyInviteS%, %configFile%, hotkeys, hotkeyInvite
	IniWrite, %hotkeyTradeWithS%, %configFile%, hotkeys, hotkeyTradeWith
	IniWrite, %hotkeyMsg1S%, %configFile%, hotkeys, hotkeyMsg1
	IniWrite, %hotkeyMsg2S%, %configFile%, hotkeys, hotkeyMsg2
	IniWrite, %hotkeyMsg3S%, %configFile%, hotkeys, hotkeyMsg3
	IniWrite, %textMsg1S%, %configFile%, settings, textMsg1
	IniWrite, %textMsg2S%, %configFile%, settings, textMsg2
	IniWrite, %textMsg3S%, %configFile%, settings, textMsg3
	
	if (legacyHotkeysS>legacyHotkeysOldPosition) {
		msgText:="Устаревшая раскладка имеет следующее управление:`n"
		msgText.="`t[Alt+F1] - Лабиринт`n`t[Alt+F2] - Синдикат`n`t[Alt+F3] - Вмешательство`n`t[Alt+F4] - Атлас`n`t[Alt+F5] - Масла`n`t[Alt+F6] - Ископаемые`n`t[Alt+F7] - Пророчества`n`t[Alt+F11] - Пользовательское изображение`n"
		msgText.="`nИспользовать не рекомендуется, поскольку заменяется сочетание клавиш [Alt+F4], и вы не сможете выйти из игры используя его!`n"
		msgText.="`nВы все еще хотите использовать эту раскладку?"
		MsgBox, 0x1024, %prjName%,  %msgText%
		IfMsgBox No
			IniWrite, 0, %configFile%, settings, legacyHotkeys
	}
	ReStart()
}

delConfigFolder(){
	MsgBox, 0x1024, %prjName%, Это удалит все настройки макроса и закроет его!`n`nПродолжить?
	IfMsgBox No
		return																																	   
	FileRemoveDir, %configFolder%, 1
	Gosub, Exit
}

setHotkeys(){
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
		Hotkey, !f4, shMaps, On
		Hotkey, !f5, shOils, On
		Hotkey, !f6, shFossils, On
		Hotkey, !f7, shProphecy, On
		Hotkey, !f11, shCustom, On
	}
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	IniRead, hotkeyHideout, %configFile%, hotkeys, hotkeyHideout, %A_Space%
	IniRead, hotkeyDnd, %configFile%, hotkeys, hotkeyDnd, %A_Space%
	IniRead, hotkeyMsg1, %configFile%, hotkeys, hotkeyMsg1, %A_Space%
	IniRead, hotkeyMsg2, %configFile%, hotkeys, hotkeyMsg2, %A_Space%
	IniRead, hotkeyMsg3, %configFile%, hotkeys, hotkeyMsg3, %A_Space%
	IniRead, textMsg1, %configFile%, settings, textMsg1, sold(
	IniRead, textMsg2, %configFile%, settings, textMsg2, 2 min
	IniRead, textMsg3, %configFile%, settings, textMsg3, ty)
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
	Menu, Tray, Add, Информация и настройки, showSettings
	Menu, Tray, Default, Информация и настройки
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Add
	Menu, Tray, Add, Отметить испытания лабиринта, showLabTrials
	Menu, Tray, Add, Пользовательские заметки, showUserNotes
	Menu, Tray, Add
	Menu, Tray, Add, Очистить кэш Path of Exile, clearPoECache
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить, ReStart
	Menu, Tray, Add, Завершить работу макроса, closeMacros
	Menu, Tray, NoStandard

	If FileExist(configFolder "\images\Custom.jpg") || FileExist(configFolder "\images\Custom.png")
		Menu, mainMenu, Add, Пользовательское изображение, shCustom
	Menu, mainMenu, Add, Альва - Комнаты храма Ацоатль, shIncursion
	Menu, mainMenu, Add, Джун - Награды бессмертного Синдиката, shSyndicate
	Menu, mainMenu, Add, Зана - Карты, shMaps
	Menu, mainMenu, Add, Кассия - Масла, shOils
	Menu, mainMenu, Add, Навали - Пророчества, shProphecy
	Menu, mainMenu, Add, Нико - Ископаемые, shFossils
	Menu, mainMenu, Add	
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
	sleep 35
	Reload
}

closeMacros(){
	MsgBox, 0x1024, %prjName%, Завершить работу %prjName%?
	IfMsgBox No
		return
	Gosub, Exit
}

;#################################################

Exit:
; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)
	sleep 35
	ExitApp
Return
