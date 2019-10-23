
/*
	Данный скрипт основан на https://github.com/heokor/League-Overlay
	Данная версия модифицирована MegaEzik
	
	Назначение дополнительных библиотек:
		*Gdip_All.ahk - Библиотека отвечающая за отрисовку оверлея, авторство https://github.com/PoE-TradeMacro/PoE-CustomUIOverlay
		*JSON.ahk - Разбор данных от api, авторство https://github.com/cocobelgica/AutoHotkey-JSON
		*Overlay.ahk - Набор функций вынесенных из основного скрипта LeagueOverlay
		*Labyrinth.ahk - Загрузка лабиринта с poelab.com и формирование меню по управлению
		*Updater.ahk - Проверка и установка обновлений
		*MigrateSupport.ahk - Проверка и исправление конфигурационного файла
	
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
#Include, resources\Gdip_All.ahk
#Include, resources\JSON.ahk
#Include, resources\Overlay.ahk
#Include, resources\Labyrinth.ahk
#Include, resources\Updater.ahk
#Include, resources\MigrateSupport.ahk

;Объявление и загрузка основных переменных
global prjName:="LeagueOverlay_ru"
global githubUser:="MegaEzik"
global configFolder:=A_MyDocuments "\" prjName
global configFile:=configFolder "\settings.ini"
global verScript
FileReadLine, verScript, resources\Updates.txt, 4

SplashTextOn, 270, 20, %prjName%, Подготовка макроса к работе...

Menu, Tray, Tip, Path of Exile - %prjName% v%verScript%
Menu, Tray, Icon, resources\Syndicate.ico

;Проверим файл конфигурации
verifyConfig()

;Проверка обновлений
CheckUpdate()
SetTimer, CheckUpdate, 10800000

;Создаем главное меню и меню в области уведомлений
menuCreate()

;Назначение горячих клавиш
IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
Hotkey, % hotkeyLastImg, shLastImage, On
IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
Hotkey, % hotkeyMainMenu, shMainMenu, On

;Поддержка устаревшей раскладки
IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, 0
If legacyHotkeys {
	Menu, Tray, Check, Использовать устаревшую раскладку
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
global image2:="resources\images\Incursion.png"
global image3:="resources\images\Map.png"
global image4:="resources\images\Fossil.png"
global image5:="resources\images\Syndicate.png"
global image6:="resources\images\Prophecy.png"

;Загружаем раскладку лабиринта, и если изображение получено, то устанавливаем его
downloadLabLayout()
If FileExist(configFolder "\Lab.jpg")
	image1:=configFolder "\Lab.jpg"

;Назначим новые пути изображений, если их аналоги есть в папке с настройками
If FileExist(configFolder "\images\Incursion.png")
	image2:=configFolder "\images\Incursion.png"
If FileExist(configFolder "\images\Map.png")
	image3:=configFolder "\images\Map.png"
If FileExist(configFolder "\images\Fossil.png")
	image4:=configFolder "\images\Fossil.png"
If FileExist(configFolder "\images\Syndicate.png")
	image5:=configFolder "\images\Syndicate.png"
If FileExist(configFolder "\images\Prophecy.png")
	image6:=configFolder "\images\Prophecy.png"

;Глобальные переменные для количества изображений и номера последнего
global NumImg:=6
global LastImg:=1

;Переменные для статуса отображения изображения
global GuiOn1:=0
global GuiOn2:=0
global GuiOn3:=0
global GuiOn4:=0
global GuiOn5:=0
global GuiOn6:=0

global poeWindowName="Path of Exile ahk_class POEWindowClass"

initOverlay()

SplashTextOff


CheckWinActivePOE:
	GuiControlGet, focused_control, focus
	
Loop %NumImg%{
	If(WinActive(poeWindowName))
		If (GuiON%A_Index%=0){			
			GuiON%A_Index%:=0
		}
	If(!WinActive(poeWindowName))
		If (GuiON%A_Index%=1){
			Gui, %A_Index%: Hide
			GuiON%A_Index%:=0
		}		
}
Return


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

shIncursion(){
	shOverlay(2)
}

shMaps(){
	shOverlay(3)
}

shFossils(){
	shOverlay(4)
}

shSyndicate(){
	shOverlay(5)
}

shProphecy(){
	shOverlay(6)
}

menuCreate(){
	Menu, Tray, NoStandard

	Menu, Tray, Add, О %prjName%..., helpDialog
	Menu, Tray, Default, О %prjName%...
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Add
	Menu, Tray, Add, Открыть папку настроек, goConfigFolder
	Menu, Tray, Add, Использовать устаревшую раскладку, setLegacyHotkeys

	menuLabCreate()

	Menu, Tray, Standard

	Menu, mainMenu, Add, Раскладка лабиринта, shLabyrinth
	Menu, mainMenu, Add
	Menu, mainMenu, Add, Альва - Комнаты храма Ацоатль, shIncursion
	Menu, mainMenu, Add, Джун - Награды бессмертного Синдиката, shSyndicate
	Menu, mainMenu, Add, Зана - Прогрессия карт, shMaps
	Menu, mainMenu, Add, Навали - Пророчества, shProphecy
	Menu, mainMenu, Add, Нико - Ископаемые, shFossils
	Menu, mainMenu, Add
	Menu, mainMenu, Add, Изменить уровень лабиринта, :labMenu
}

goConfigFolder(){
	Run, explorer "%configFolder%"
}

helpDialog(){
	msgText:=prjName " - Макрос предоставляющий вам информацию в виде изображений наложенных поверх окна игры.`n`n"
	msgText.="Управление(по умолчанию):`n"
	msgText.="     [Alt+F1] - Последнее изображение`n"
	msgText.="     [Alt+F2] - Меню с изображениями`n`n"
	msgText.="Эти сочетания клавиш и другие настройки вы можете изменить вручную в файле конфигурации:`n" configFile
	msgText.="`n`nХотите открыть веб страницу, чтоб поддержать " prjName "?"
	msgbox, 0x1044, %prjName%, %msgText%
	IfMsgBox Yes
		Run, https://qiwi.me/megaezik
}

setLegacyHotkeys(){
	IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, 0
	If legacyHotkeys {
		IniWrite, 0, %configFile%, settings, legacyHotkeys
	} Else {
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
			return
		IniWrite, 1, %configFile%, settings, legacyHotkeys
	}
	Sleep 25
	Reload
}

;Рассчитываем коэффициент для уменьшения изображения
calcMult(ImageWidth, ImageHeight, ScreenWidth, ScreenHeight){
	MWidth:=ScreenWidth/ImageWidth
	MHeight:=ScreenHeight/ImageHeight
	M:=(MWidth<MHeight)?MWidth:MHeight
	M:=Round(M-0.0005, 3)
	M:=(M>1)?1:M
	M:=(M<0.1)?0.1:M
	return M
}

Exit:
; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)
	ExitApp

Return
