
/*
	Данный скрипт основан на https://github.com/heokor/League-Overlay
	Данная версия модифицирована MegaEzik
	
	Назначение дополнительных библиотек:
		*Gdip_All.ahk - Библиотека отвечающая за отрисовку оверлея, авторство https://github.com/PoE-TradeMacro/PoE-CustomUIOverlay
		*JSON.ahk - Разбор данных от api, авторство https://github.com/cocobelgica/AutoHotkey-JSON
		*Labyrinth.ahk - Загрузка лабиринта с poelab.com и формирование меню по управлению
		*Updater.ahk - Проверка и установка обновлений
	
	Управление:
		Alt+F1 - Раскладка лабиринта
		Alt+F2 - Меню с остальными изображениями
		
		Вы можете переназначить клавиши для управления в конфигурационном файле %USERPROFILE%\Documents\LeagueOverlay_ru\settings.ini
*/

if not A_IsAdmin
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"

#SingleInstance, Force
#NoEnv
SetBatchLines, -1
SetWorkingDir %A_ScriptDir%

;Подключение библиотек
#Include, resources\Gdip_All.ahk
#Include, resources\JSON.ahk
#Include, resources\Labyrinth.ahk
#Include, resources\Updater.ahk

;Объявление и загрузка основных переменных
global prjName:="LeagueOverlay_ru"
global githubUser:="MegaEzik"
global configFile:=A_MyDocuments "\" prjName "\settings.ini"
global verScript
FileReadLine, verScript, resources\Updates.txt, 4

SplashTextOn, 270, 20, %prjName%, Подготовка макроса к работе...

;Создание файла конфигурации, если он отсутствует
IfNotExist %configFile%
{
	FileCreateDir, %A_MyDocuments%\%prjName%
	IniWrite, !f1, %configFile%, hotkeys, hotkeyLabyrinth
	IniWrite, !f2, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, uber, %configFile%, settings, lvlLabyrinth
	IniWrite, 0, %configFile%, settings, useOldHotkeys
	helpDialog()
}

;Копирование модифицированных изображений
IfExist %A_MyDocuments%\%prjName%\images
{
	FileCopyDir, %A_MyDocuments%\%prjName%\images, %A_ScriptDir%\resources\images\, 1
	sleep 500
}

;Проверка обновлений, загрузка лабиринта и формирование меню
CheckUpdate()
;SetTimer, CheckUpdate, 10800000

Menu, Tray, Tip, %prjName% v%verScript%
Menu, Tray, Icon, resources\Syndicate.ico

Menu, Tray, NoStandard

Menu, Tray, Add, Поддержать, openDonateURL
Menu, Tray, Add, Помощь, helpDialog
Menu, Tray, Default, Помощь
Menu, Tray, Add, Открыть на GitHub, openGitHub
Menu, Tray, Add

initCheckUpdate()

Menu, Tray, Add, Редактировать файл конфигурации, editConfigFile

initLabyrinth()

Menu, Tray, Standard

Menu, mainMenu, Add, Вмешательство, shIncursion
Menu, mainMenu, Add, Ископаемые, shFossils
Menu, mainMenu, Add, Прогрессия карт, shMaps
Menu, mainMenu, Add, Пророчества, shProphecy
Menu, mainMenu, Add, Синдикат, shSyndicate
Menu, mainMenu, Add
Menu, mainMenu, Add, Изменить уровень лабиринта, :labMenu

;Назначение горячих клавиш
IniRead, hotkeyLabyrinth, %configFile%, hotkeys, hotkeyLabyrinth, !f1
Hotkey, % hotkeyLabyrinth, shLabyrinth, On

IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
Hotkey, % hotkeyMainMenu, shMainMenu, On

;Поддержка устаревшей раскладки
IniRead, useOldHotkeys, %configFile%, settings, useOldHotkeys, 0
If useOldHotkeys {
	Hotkey, !f2, shSyndicate, On
	Hotkey, !f3, shIncursion, On
	Hotkey, !f4, shMaps, On
	Hotkey, !f6, shFossils, On
	Hotkey, !f7, shProphecy, On
}

; Start gdi+
If !pToken := Gdip_Startup()
	{
	   MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	}
OnExit, Exit

global image1 := "resources\images\Labyrinth.jpg"
global image2 := "resources\images\Incursion.png"
global image3 := "resources\images\Map.png"
global image4 := "resources\images\Fossil.png"
global image5 := "resources\images\Syndicate.png"
global image6 := "resources\images\Prophecy.png"

global GuiOn1 := 0
global GuiOn2 := 0
global GuiOn3 := 0
global GuiOn4 := 0
global GuiOn5 := 0
global GuiOn6 := 0

global poeWindowName = "Path of Exile ahk_class POEWindowClass"


; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption


Loop 6{
    ; Create two layered windows (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
    Gui, %A_Index%: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
    ; Show the window
 
    ; Get a handle to this window we have created in order to update it later
    hwnd%A_Index% := WinExist()
}


Loop 6{
	If (GuiON%A_Index% = 0){
		Gosub, CheckWinActivePOE
		SetTimer, CheckWinActivePOE, 100
		GuiON%A_Index% = 1
	
		; Show the window
		Gui, %A_Index%: Show, NA
	} Else {
		SetTimer, CheckWinActivePOE, Off      
		Gui, %A_Index%: Hide	
		GuiON%A_Index% = 0
	}
	Gui, %A_Index%: Hide	
	GuiON%A_Index% = 0
}


; If the image we want to work with does not exist on disk, then download it...

; Get a bitmap from the image

Loop 6{
	pBitmap%A_Index% := Gdip_CreateBitmapFromFile(image%A_Index%)
}

Loop 6{
	If !pBitmap%A_Index%{
		MsgBox, 48, File loading error!, Could not load the image specified
		ExitApp
	}
}


; Get the width and height of the bitmap we have just created from the file
; This will be the dimensions that the file is
Loop 6{
	Width%A_Index% := Gdip_GetImageWidth(pBitmap%A_Index%)
	Height%A_Index% := Gdip_GetImageHeight(pBitmap%A_Index%)
	Mult%A_Index%:=calcMult(Width%A_Index%, Height%A_Index%, A_ScreenWidth, A_ScreenHeight-65)
	hbm%A_Index% := CreateDIBSection(Width%A_Index%, Height%A_Index%)
	hdc%A_Index% := CreateCompatibleDC()
	obm%A_Index% := SelectObject(hdc%A_Index%, hbm%A_Index%)
	G%A_Index% := Gdip_GraphicsFromHDC(hdc%A_Index%)
	Gdip_SetInterpolationMode(G%A_Index%, 7)
	Gdip_DrawImage(G%A_Index%, pBitmap%A_Index%, 0, 0, round(Width%A_Index%*Mult%A_Index%), round(Height%A_Index%*Mult%A_Index%), 0, 0, Width%A_Index%, Height%A_Index%)
	UpdateLayeredWindow(hwnd%A_Index%, hdc%A_Index%, round(A_ScreenWidth/2)-round(Width%A_Index%*Mult%A_Index%/2), 25, round(Width%A_Index%*Mult%A_Index%), round(Height%A_Index%*Mult%A_Index%))
	SelectObject(hdc%A_Index%, obm%A_Index%)
	DeleteObject(hbm%A_Index%)
	DeleteDC(hdc%A_Index%)
	Gdip_DeleteGraphics(G%A_Index%)
	Gdip_DisposeImage(pBitmap%A_Index%)
}

SplashTextOff

Return
;#######################################################################

CheckWinActivePOE:
	GuiControlGet, focused_control, focus
	
Loop 6{
	If(WinActive(poeWindowName))
		If (GuiON%A_Index% = 0){			
			GuiON%A_Index% := 0
		}
	If(!WinActive(poeWindowName))
		If (GuiON%A_Index% = 1){
			Gui, %A_Index%: Hide
			GuiON%A_Index% := 0
		}		
}
Return

#IfWinActive Path of Exile
shOverlay(i){
	If (GuiON%i% = 1){
		Gui, %i%: Hide
		GuiON%i% := 0
	}Else{
		Gui, %i%: Show, NA
		GuiON%i% := 1
	}
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

openGitHub(){
	URL:="https://github.com/" githubUser "/" prjName "/releases/latest"
	Run, %URL%
}

openDonateURL(){
	URL:="https://money.yandex.ru/to/410018859988844"
	Run, %URL%
}

helpDialog(){
	helpMsg:=prjName " - Макрос предоставляющий вам информацию в виде изображений наложенных поверх окна игры Path of Exile.`n`n"
	helpMsg.="Управление(по умолчанию):`n"
	helpMsg.="     Alt+F1 - Раскладка лабиринта`n"
	helpMsg.="     Alt+F2 - Меню с остальными изображениями`n"
	helpMsg.="`nРасширенные настройки можно изменить`nв файле конфигурации.`n"
	msgbox, 0x1040, %prjName%, %helpMsg%
}

editConfigFile(){
	RunWait, %configFile%
	sleep 250
	Reload
}

shMainMenu(){
	Loop 6{
		Gui, %A_Index%: Hide
		GuiON%A_Index% := 0
	}
	Menu, mainMenu, Show
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
