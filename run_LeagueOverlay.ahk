
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

#SingleInstance, Force
#NoEnv
SetBatchLines, -1
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
global verScript
FileReadLine, verScript, resources\Updates.txt, 4

SplashTextOn, 270, 20, %prjName%, Подготовка макроса к работе...

Menu, Tray, Tip, PoE - %prjName%
Menu, Tray, Icon, resources\Syndicate.ico

;Проверим файл конфигурации
IniRead, verConfig, %configFile%, settings, verConfig, ""
if (verConfig!=verScript) {
	If FileExist(A_MyDocuments "\LeagueOverlay_ru\") {
		FileCopyDir, %A_MyDocuments%\LeagueOverlay_ru\, %configFolder%, 0
		FileRemoveDir, %A_MyDocuments%\LeagueOverlay_ru\, 1
	}
	sleep 35
	showSettings()
	FileDelete, %configFile%
	sleep 35
	FileCreateDir, %configFolder%\images
	IniWrite, %verScript%, %configFile%, settings, verConfig
	saveSettings()
}

;Проверка обновлений
IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
if autoUpdate {
	CheckUpdateFromMenu("onStart")
	SetTimer, CheckUpdate, 3600000
}

;Создаем главное меню и меню в области уведомлений
menuCreate()

;Назначим управление в зависимости от включенной настройки 'Использования устаревших клавиш'
IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, 0
If !legacyHotkeys {
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	Hotkey, % hotkeyLastImg, shLastImage, On
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	Hotkey, % hotkeyMainMenu, shMainMenu, On
} Else {
	Hotkey, !f1, shLabyrinth, On
	Hotkey, !f2, shSyndicate, On
	Hotkey, !f3, shIncursion, On
	Hotkey, !f4, shMaps, On
	Hotkey, !f6, shFossils, On
	Hotkey, !f7, shProphecy, On
}

;Запуск gdi+
If !pToken:=Gdip_Startup()
	{
	   ;MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	   MsgBox, 48, Ошибка gdi+!, Не удалось запустить gdi+. Пожалуйста, убедитесь, что  вашей системе он есть
	}
OnExit, Exit

;Пути к изображениям
global image1:="resources\images\ImgError.png"
global image2:="resources\images\ImgError.png"
global image3:="resources\images\Incursion.png"
global image4:="resources\images\Map.png"
global image5:="resources\images\Fossil.png"
global image6:="resources\images\Syndicate.png"
global image7:="resources\images\Prophecy.png"

;Загружаем раскладку лабиринта, и если изображение получено, то устанавливаем его
IniRead, skipLoadLab, %configFile%, settings, skipLoadLab, 0
if !skipLoadLab {
	downloadLabLayout()
	If FileExist(configFolder "\Lab.jpg")
		image1:=configFolder "\Lab.jpg"
}

;Назначим новые пути изображений, если их аналоги есть в папке с настройками
If FileExist(configFolder "\images\Custom.png")
	image2:=configFolder "\images\Custom.png"
If FileExist(configFolder "\images\Incursion.png")
	image3:=configFolder "\images\Incursion.png"
If FileExist(configFolder "\images\Map.png")
	image4:=configFolder "\images\Map.png"
If FileExist(configFolder "\images\Fossil.png")
	image5:=configFolder "\images\Fossil.png"
If FileExist(configFolder "\images\Syndicate.png")
	image6:=configFolder "\images\Syndicate.png"
If FileExist(configFolder "\images\Prophecy.png")
	image7:=configFolder "\images\Prophecy.png"

;Глобальные переменные для количества изображений и номера последнего
global NumImg:=7
global LastImg:=1

;Переменные для статуса отображения изображения
global GuiOn1:=0
global GuiOn2:=0
global GuiOn3:=0
global GuiOn4:=0
global GuiOn5:=0
global GuiOn6:=0
global GuiOn7:=0

global poeWindowName="Path of Exile ahk_class POEWindowClass"

initOverlay()

SplashTextOff

Return

;#################################################

#IfWinActive Path of Exile

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
	shOverlay(2)
}

shIncursion(){
	shOverlay(3)
}

shMaps(){
	shOverlay(4)
}

shFossils(){
	shOverlay(5)
}

shSyndicate(){
	shOverlay(6)
}

shProphecy(){
	shOverlay(7)
}

replacerImages() {
	FileSelectFile, FilePath, , , Укажите путь к новому файлу для создания замены, Изображения (*.png)
	if (FilePath="" || !FileExist(FilePath) || !RegExMatch(FilePath, "i).(png|zip)$")) {
		msgbox, 0x1040, %prjName%, Файл не найден или не соответствует файлам макроса!
		return
	}
	if RegExMatch(FilePath, "i).png$") {
		if RegExMatch(FilePath, "i)(Fossil|Incursion|Map|Prophecy|Syndicate).png$", replaceImgName) {
			FileCopy, %FilePath%, %configFolder%\images\%replaceImgName%, true
		} else {
			Msgbox, 0x1040, %prjName%, Не удалось определить тип изображения!`n`n`Указанный файл будет установлен в качестве 'Пользовательского изображения'!
			FileCopy, %FilePath%, %configFolder%\images\Custom.png, true
		}
	}
	if RegExMatch(FilePath, "i).zip$") {
		unZipArchive(FilePath, configFolder "\images\")
	}
}

delReplacedImages() {
	FileSelectFile, FilePath, , %configFolder%\images\, Выберите изображение в этой папке для удаления замены, Изображения (*.png)
	if (FilePath="" || !FileExist(FilePath) || !RegExMatch(FilePath, "i).png$") || !inStr(FilePath, configFolder "\images\")) {
		msgbox, 0x1040, %prjName%, Файл не найден или изображение указано не верно!
		return
	} else {
		FileDelete, %FilePath%
	}
}

showSettings() {
	global
	Gui, Settings:Destroy
	
	IniRead, autoUpdateS, %configFile%, settings, autoUpdate, 1
	IniRead, legacyHotkeysS, %configFile%, settings, legacyHotkeys, 0
	IniRead, lvlLabS, %configFile%, settings, lvlLab, uber
	IniRead, skipLoadLabS, %configFile%, settings, skipLoadLab, 0
	IniRead, hotkeyLastImgS, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenuS, %configFile%, hotkeys, hotkeyMainMenu, !f2
	
	
	legacyHotkeysOldPosition:=legacyHotkeysS
	lvlLabOldPosition:=lvlLabS
	
	Gui, Settings:Add, Text, x10 y5 w365 h28 cGreen, %prjName% - Макрос предоставляющий вам информацию в виде изображений наложенных поверх окна игры.
	
	Gui, Settings:Add, Picture, x405 y10 w107 h-1, resources\qiwi-logo.png
	Gui, Settings:Add, Link, x385 y+10, <a href="https://qiwi.me/megaezik">Поддержать %prjName%</a>
	Gui, Settings:Add, Link, x10 yp+0 w365, <a href="https://ru.pathofexile.com/forum/view-post/21681060">Пост на форуме</a>  |  <a href="https://raw.githubusercontent.com/MegaEzik/LeagueOverlay_ru/master/resources/Updates.txt">История изменений</a>  |  <a href="https://github.com/MegaEzik/LeagueOverlay_ru/releases">Страница на GitHub</a>
	
	Gui, Settings:Add, Text, x10 yp-22 w180, Установлена версия: %verScript%
	Gui, Settings:Add, Button, x+23 yp-5 w135 gCheckUpdateFromMenu, Выполнить обновление
	
	Gui, Settings:Add, Text, x0 y85 w555 h2 0x10
	
	/*
	FileRead, updateNotes, resources\Updates.txt
	Gui, Settings:Add, Text, x10 y+5 w270 h12, История изменений:	
	Gui, Settings:Add, Edit, r10 ReadOnly w530, %updateNotes%
	Gui, Settings:Add, Text, x0 y+5 w555 h2 0x10
	Gui, Settings:Add, Text, x10 yp+5 h20, Файл конфигурации:`n %configFile%
	*/

	Gui, Settings:Add, GroupBox, x10 y+5 w530 h185, Основные настройки
	
	Gui, Settings:Add, Checkbox, vautoUpdateS x25 yp+17 w360 h20 Checked%autoUpdateS%, Автоматически проверять и уведомлять о наличии обновлений
	
	Gui, Settings:Add, Text, x25 y+5 w505 h2 0x10
	
	Gui, Settings:Add, Checkbox, vlegacyHotkeysS x25 yp+7 w360 h20 Checked%legacyHotkeysS%, Устаревшая раскладка клавиш(использовать не рекомендуется)
	
	Gui, Settings:Add, Text, x25 yp+27 w165, Последнее изображение:
	Gui, Settings:Add, Hotkey, vhotkeyLastImgS x+24 yp-3 w135 h20 , %hotkeyLastImgS%
	
	Gui, Settings:Add, Text, x25 yp+27 w165, Меню быстрого доступа:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenuS x+24 yp-3 w135 h20 , %hotkeyMainMenuS%
	
	Gui, Settings:Add, Text, x25 y+7 w505 h2 0x10	
	
	Gui, Settings:Add, Checkbox, vskipLoadLabS x25 yp+7 w360 h20 Checked%skipLoadLabS%, Не загружать изображение раскладки лабиринта
	Gui, Settings:Add, Text, x25 yp+27 w165, Уровень лабиринта:
	Gui, Settings:Add, DropDownList, vlvlLabS x+24 yp-3 w135, normal|cruel|merciless|uber
	GuiControl,Settings:ChooseString, lvlLabS, %lvlLabS%
	Gui, Settings:Add, Link, x+15 yp+3 w165, <a href="https://www.poelab.com/">c использованием POELab.com</a>
	
	Gui, Settings:Add, GroupBox, x10 y+20 w530 h50, Замена изображений
	Gui, Settings:Add, Button, xp10 yp+17 w253 greplacerImages, Указать изображение для создания замены
	Gui, Settings:Add, Button, x+4 yp+0 w253 gdelReplacedImages, Удалить замену указав на изображение
	
	Gui, Settings:Add, Button, x10 y+25 gdelConfigFolder, Сбросить
	Gui, Settings:Add, Button, x+4 yp+0 gopenConfigFolder, Открыть папку настроек
	Gui, Settings:Add, Button, x370 yp+0 w170 gsaveSettings, Применить и перезапустить
	Gui, Settings:Show, w550, %prjName% - Информация и настройки
}

saveSettings() {
	global
	Gui, Settings:Submit
	
	IniWrite, %autoUpdateS%, %configFile%, settings, autoUpdate
	IniWrite, %legacyHotkeysS%, %configFile%, settings, legacyHotkeys
	IniWrite, %lvlLabS%, %configFile%, settings, lvlLab
	IniWrite, %skipLoadLabS%, %configFile%, settings, skipLoadLab
	IniWrite, %hotkeyLastImgS%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenuS%, %configFile%, hotkeys, hotkeyMainMenu
	
	if (lvlLabS!=lvlLabOldPosition) {
		Run, https://www.poelab.com/
	}
	
	if (legacyHotkeysS>legacyHotkeysOldPosition) {
		msgText:="Устаревшая раскладка имеет следующее управление:`n"
		msgText.="     [Alt+F1] - Лабиринт`n"
		msgText.="     [Alt+F2] - Синдикат`n"
		msgText.="     [Alt+F3] - Вмешательство`n"
		msgText.="     [Alt+F4] - Карты`n"
		msgText.="     [Alt+F6] - Ископаемые`n"
		msgText.="     [Alt+F7] - Пророчества`n`n"
		msgText.="Использовать 'Устаревшую раскладку' не рекомендуется, ведь она заменяет сочетание клавиш [Alt+F4], и вы не сможете использовать этот способ для выхода из игры!`n`n"
		msgText.="Вы уверены, что хотите переключиться на данный режим управления?"
		MsgBox, 0x1024, %prjName%,  %msgText%
		IfMsgBox No
			IniWrite, 0, %configFile%, settings, legacyHotkeys
	}
	ReStart()
}

delConfigFolder() {
	FileRemoveDir, %configFolder%, 1
	Sleep 100
	ReStart()
}

menuCreate(){
	Menu, Tray, NoStandard
	Menu, Tray, Add, Информация и настройки, showSettings
	Menu, Tray, Default, Информация и настройки
	Menu, Tray, Add, Выполнить обновление,CheckUpdateFromMenu
	Menu, Tray, Add
	Menu, Tray, Add, Отметить испытания лабиринта, showLabTrials
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить, ReStart
	Menu, Tray, Add, Завершить работу макроса, Exit
	;Menu, Tray, Standard
	
	Menu, mainMenu, Add, Раскладка лабиринта, shLabyrinth
	If FileExist(configFolder "\images\Custom.png")
		Menu, mainMenu, Add, Пользовательское изображение, shCustom
	Menu, mainMenu, Add
	Menu, mainMenu, Add, Альва - Комнаты храма Ацоатль, shIncursion
	Menu, mainMenu, Add, Джун - Награды бессмертного Синдиката, shSyndicate
	Menu, mainMenu, Add, Зана - Прогрессия карт, shMaps
	Menu, mainMenu, Add, Навали - Пророчества, shProphecy
	Menu, mainMenu, Add, Нико - Ископаемые, shFossils
	Menu, mainMenu, Add	
	Menu, mainMenu, Add, Меню области уведомлений, :Tray
}

openConfigFolder(){
	Run, explorer "%configFolder%"
}

ReStart() {
	Gdip_Shutdown(pToken)
	sleep 100
	Reload
}

;#################################################

CheckWinActivePOE:
	GuiControlGet, focused_control, focus
	
	Loop %NumImg%{
		If(WinActive(poeWindowName))
			If (GuiON%A_Index%=0){			
				GuiON%A_Index%:=0
			}
		If(!WinActive(poeWindowName ))
			If (GuiON%A_Index%=1){
				Gui, %A_Index%: Hide
				GuiON%A_Index%:=0
			}		
}
Return

Exit:
; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)
	ExitApp
Return
