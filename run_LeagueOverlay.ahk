
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
		*ItemDataConverterLib.ahk - Библиотека для конвертирования описания предмета
		*itemMenu.ahk - Библиотека для формирования меню предмета
	
	Управление:
		[Alt+F1] - Последнее изображение
		[Alt+F2] - Меню быстрого доступа
		Остальные клавиши по умолчанию не назначены и определяются пользователем через настройки или файл конфигурации
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
#Include, %A_ScriptDir%\resources\ahk\itemMenu.ahk

;Список окон Path of Exile
GroupAdd, WindowGrp, Path of Exile ahk_class POEWindowClass
GroupAdd, WindowGrp, ahk_exe GeForceNOWStreamer.exe

;Объявление и загрузка основных переменных
global prjName:="LeagueOverlay_ru"
global githubUser:="MegaEzik"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
if InStr(FileExist(A_ScriptDir "\..\Profile"), "D")
	configFolder:=A_ScriptDir "\..\Profile"
global configFile:=configFolder "\settings.ini"
global trayMsg, verScript, debugMode=0
global textCmd1, textCmd2, textCmd3, textCmd4, textCmd5, textCmd6, textCmd7, textCmd8, textCmd9, textCmd10, textCmd11, textCmd12, textCmd13, textCmd14, textCmd15, cmdNum=15
global presetData, LastImg, globalOverlayPosition, OverlayStatus=0
global ItemDataFullText
FileReadLine, verScript, resources\Updates.txt, 1

;Подсказка в области уведомлений и сообщение при запуске
trayUpdate(prjName " " verScript " | AHK " A_AhkVersion)
Menu, Tray, Icon, resources\icon.png
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
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	FileDelete, %configFile%
	sleep 25
	FileCreateDir, %configFolder%\images
	IniWrite, %verScript%, %configFile%, info, verConfig
	IniWrite, %debugMode%, %configFile%, settings, debugMode
	saveSettings()
}

;Запуск gdi+
If !pToken:=Gdip_Startup()
	{
	   ;MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	   MsgBox, 48, Ошибка gdi+!, Не удалось запустить gdi+. Пожалуйста, убедитесь, что в вашей системе он есть
	}
OnExit, Exit

;Подгрузим некоторые значения
IniRead, globalOverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
IniRead, windowLine, %configFile%, settings, windowLine, %A_Space%
if (windowLine!="")
	GroupAdd, WindowGrp, %windowLine%

;Скачаем раскладку лабиринта
IniRead, loadLab, %configFile%, settings, loadLab, 0
If loadLab
	downloadLabLayout()

;Загрузим информацию набора и подготовим его
loadPresetData()

;Выполним все файлы с окончанием _loader.ahk, передав ему папку расположения скрипта
Loop, %configFolder%\*_loader.ahk, 1
	RunWait *RunAs "%A_AhkPath%" "%configFolder%\%A_LoopFileName%" "%A_ScriptDir%"
	
;Назначим последнее изображение
IniRead, lastImgC, %configFile%, info, lastImg, %A_Space%
;If (lastImgC!="" && FileExist(lastImgC))
If lastImgC!=""
	LastImg:=lastImgC

;Назначим управление и создадим меню
menuCreate()
setHotkeys()

;Скроем сообщение загрузки
closeStartUI()

;Покажем уведомление, если таковое было вложено в пакет с макросом
showStartNotify()

;Иногда после запуска будем предлагать поддержать проект
showDonateUIOnStart()

Return

;#################################################

#IfWinActive ahk_group WindowGrp

shLastImage(){
	SplitLastImg:=StrSplit(LastImg, "|")
	shOverlay(SplitLastImg[1], SplitLastImg[2], SplitLastImg[3])
}

firstAprilJoke(){
	tmpPresetData:=""
	presetDataSplit:=strSplit(presetData, "`n")
	For k, val in presetDataSplit {
		ImgSplit:=strSplit(presetDataSplit[k], "|")
		If (ImgSplit[3]="" || ImgSplit[3]>1)
			ImgSplit[3]:=1		
		Random, randomNum, ImgSplit[3]/2.5, ImgSplit[3]
		ImgSplit[3]:=Round(randomNum, 2)
		If FileExist(StrReplace(ImgSplit[2], "<configFolder>", configFolder))
			tmpPresetData.=StrReplace(ImgSplit[2], "<configFolder>", configFolder) "|" ImgSplit[3] "|" ImgSplit[4] "`n"
	}
	presetDataSplit:=strSplit(tmpPresetData, "`n")
	Random, randomNum, 1, presetDataSplit.MaxIndex()-1
	ImgSplit:=strSplit(presetDataSplit[randomNum], "|")
	If FileExist(ImgSplit[1]) {
		shOverlay(ImgSplit[1], ImgSplit[2], ImgSplit[3])
		return
	} else {
		return
	}
}

shMainMenu(){
	destroyOverlay()
	createMainMenu()
	sleep 5
	Menu, mainMenu, Show
}

loadPresetData(){
	IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
	presetPath:=A_ScriptDir "\resources\presets\" imagesPreset ".preset"
	If RegExMatch(imagesPreset, "<(.*)>", imagesPreset)
		presetPath:=configFolder "\presets\" imagesPreset1 ".preset"
	/*
	If RegExMatch(imagesPreset, ".preset$")
		presetPath:=configFolder "\presets\" imagesPreset
	*/
	if FileExist(presetPath)
		FileRead, presetData, %presetPath%
		presetData:=StrReplace(presetData, "`r", "")
	
	;Подготовим набор
	presetDataSplit:=strSplit(presetData, "`n")
	For k, val in presetDataSplit {
		If RegExMatch(presetDataSplit[k], ";")=1
			Continue
		If RegExMatch(presetDataSplit[k], "OverlayPosition=(.*)", line) {
			globalOverlayPosition:=line1
		}
		If RegExMatch(presetDataSplit[k], "ahk_(class|exe)") && RegExMatch(presetDataSplit[k], "WindowLine=(.*)", line) {
			GroupAdd, WindowGrp, %line1%
		}
	}
}

presetInMenu(imagesPreset){
	if (presetData!="") {
		presetDataSplit:=StrSplit(presetData, "`n")
		For k, val in presetDataSplit {
			If RegExMatch(presetDataSplit[k], ";")=1
				Continue
			imageInfo:=StrSplit(presetDataSplit[k], "|")
			ImgName:=imageInfo[1]
			if FileExist(StrReplace(imageInfo[2], "<configFolder>", configFolder))
				Menu, mainMenu, Add, %ImgName%, presetImgShow
			If RegExMatch(imageInfo[2], "http")=1
				Menu, mainMenu, Add, %ImgName%, presetLink
			if (ImgName="---")
				Menu, mainMenu, Add
		}
	}
}

presetImgShow(ImgName){
	presetDataSplit:=StrSplit(presetData, "`n")
	For k, val in presetDataSplit {
		imageInfo:=StrSplit(presetDataSplit[k], "|")
		if (ImgName=imageInfo[1]) {
			shOverlay(StrReplace(imageInfo[2], "<configFolder>", configFolder), imageInfo[3], imageInfo[4])
		}
	}
}

presetLink(Name){
	presetDataSplit:=StrSplit(presetData, "`n")
	For k, val in presetDataSplit {
		pLink:=StrSplit(presetDataSplit[k], "|")
		if (Name=pLink[1]) {
			oLink:=pLink[2]
			run %oLink%
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
		Menu, myImagesMenu, Add
		Menu, myImagesMenu, DeleteAll
		
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

showLicense(){
	textFileWindow("Лицензия", "LICENSE.md")
}

clearPoECache(){
	msgbox, 0x1014, %prjName%, Во время очистки кэша лучше закрыть игру!`n`nВы закрыли и хотите продолжить?
	IfMsgBox Yes
	{
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
}

copyPreset(){
	Gui, Settings:Destroy
	FileCreateDir, %configFolder%\presets
	FileSelectFile, FilePath,,, Укажите путь к файлу набора изображений, (*.preset)
	if (FilePath!="" && FileExist(FilePath)) {
		FileCopy, %FilePath%, %configFolder%\presets, 1
	} else {
		msgbox, 0x1010, %prjName%, Файл не найден или операция прервана пользователем!, 3
	}
	Sleep 25
	showSettings()
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

cfgPresetMenuShow(){
	Menu, delPresetMenu, Add
	Menu, delPresetMenu, DeleteAll
	Menu, delPresetMenu, Add, Создать/Редактировать, editPreset
	Menu, delPresetMenu, Add, Добавить из файла, copyPreset
	Menu, delPresetMenu, Add
	Loop, %configFolder%\presets\*.preset, 1
		Menu, delPresetMenu, Add, Удалить %A_LoopFileName%, delPreset
	Menu, delPresetMenu, Show
}

delPreset(presetName){
	presetName:=SubStr(presetName, 9)
	msgbox, 0x1024, %prjName%, Удалить набор изображений '%presetName%'?
	IfMsgBox No
		return
	FileDelete, %configFolder%\presets\%presetName%
	Gui, Settings:Destroy
	Sleep 25
	showSettings()
}

showStartUI(){
	Gui, StartUI:Destroy
	
	initMsgs := ["Подготовка макроса к работе"
				,"Поддержи " prjName
				,"Поиск NPC 'Борис Бритва'"
				,"Переносим 3.13, чтобы Крис поиграл в Cyberpunk 2077"
				,"Опускаемся на 65535 глубину в 'Бесконечном спуске'"]
				
	FormatTime, CurrentDate, %A_NowUTC%, MMdd
	
	If (CurrentDate==1231 || CurrentDate==0101)
		initMsgs:=["Тебя весь год ждет PoE)"]
	If (CurrentDate==0107)
		initMsgs:=["Санта-Клаус vs Иисус"]
	If (CurrentDate==0214)
		initMsgs:=["Похоже кто-то будет соло", "<3 <3 <3 <3 <3 <3 <3"]
	If (CurrentDate==0223)
		initMsgs:=["Все мужики любят носки", "Есть один подарок лучше, чем носки. Это пена для бритья"]
	If (CurrentDate==0308)
		initMsgs:=["Не забывайте - это праздник всех женщин. Всех на свете!", "@>->--"]
	If (CurrentDate==0501)
		initMsgs:=["Мир, Труд, Май"]
	If (CurrentDate==0509)
		initMsgs:=["Все должны это помнить, чтобы не совершить тех же ошибок"]
	
	Random, randomNum, 1, initMsgs.MaxIndex()
	initMsg:=initMsgs[randomNum] "..."
	
	If (CurrentDate==0401) {
		Loop % Len := StrLen(initMsg)
			NewInitMsg.= SubStr(initMsg, Len--, 1)
		initMsg:=NewInitMsg
	}
	
	dNames:=["AbyssSPIRIT", "milcart", "Pip4ik", "Данил А. Р."]
	Random, randomNum, 1, dNames.MaxIndex()
	dName:="Спасибо, " dNames[randomNum] ")"
	
	Gui, StartUI:Add, Progress, w500 h26 x0 y0 Background1496A0

	Gui, StartUI:Font, s10 cFFFFFF bold
	Gui, StartUI:Add, Text, x5 y5 h18 w490 +Center BackgroundTrans, %prjName% %verScript% | AHK %A_AhkVersion%
	
	Gui, StartUI:Font, s11 c000000 bold italic
	Gui, StartUI:Add, Text, x0 y+10 h18 w500 +Center BackgroundTrans, %initMsg%
	
	Gui, StartUI:Font, s8 norm italic
	Gui, StartUI:Add, Text, x5 y+3 w390 BackgroundTrans, %dName%
	
	Gui, StartUI:Font, s8 norm
	Gui, StartUI:Add, Link, x+0 yp+0 w100 +Right, <a href="https://qiwi.me/megaezik">Поддержать</a>
	
	Gui, StartUI:+ToolWindow -Caption +Border +AlwaysOnTop
	Gui, StartUI:Show, w500 h70, %prjName% %VerScript% 
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
	
	IniRead, lastImg, %configFile%, info, lastImg, %A_Space%
	
	;Настройки первой вкладки
	IniRead, OverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
	splitOverlayPosition:=strSplit(OverlayPosition, "/")
	posX:=splitOverlayPosition[1]
	posY:=splitOverlayPosition[2]
	posW:=splitOverlayPosition[3]
	posH:=splitOverlayPosition[4]
	
	IniRead, windowLine, %configFile%, settings, windowLine, %A_Space%
	IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
	IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	IniRead, expandMyImages, %configFile%, settings, expandMyImages, 0
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyItemMenu, %configFile%, hotkeys, hotkeyItemMenu, %A_Space%
	
	;Настройки второй вкладки
	IniRead, hotkeyCustomCommandsMenu, %configFile%, hotkeys, hotkeyCustomCommandsMenu, %A_Space%
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	
	Gui, Settings:Add, Button, x0 y400 w500 h25 gsaveSettings, Применить и перезапустить ;💾 465
	Gui, Settings:Add, Link, x200 y4 w295 +Right, <a href="https://www.autohotkey.com/download/">AutoHotKey</a> | <a href="https://ru.pathofexile.com/forum/view-thread/2694683">Тема на Форуме</a> | <a href="https://github.com/MegaEzik/LeagueOverlay_ru/releases">Страница на GitHub</a>
	
	Gui, Settings:Add, Tab, x0 y0 w500 h400, Общие|Команды ;Вкладки
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Checkbox, vautoUpdate x10 y30 w295 Checked%autoUpdate%, Автоматически проверять наличие обновлений
	Gui, Settings:Add, Text, x10 yp+22 w150, Другое окно для проверки:
	Gui, Settings:Add, Edit, vwindowLine x+2 yp-2 w330 h18, %windowLine%
	
	Gui, Settings:Add, Text, x10 y+4 w485 h2 0x10

	Gui, Settings:Add, Text, x10 yp+8 w190, Позиция области под изображения:
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
	Loop, resources\presets\*.preset, 1
		presetList.="|" StrReplace(A_LoopFileName, ".preset", "")
	Loop, %configFolder%\presets\*.preset, 1
		presetList.="|<" StrReplace(A_LoopFileName, ".preset", "") ">"
		;presetList.="|" A_LoopFileName
	presetList:=SubStr(presetList, 2)
	
	Gui, Settings:Add, Text, x10 yp+24 w327, Набор изображений:
	;Gui, Settings:Add, Button, x+1 yp-4 w23 h23 gcopyPreset, 📄
	;Gui, Settings:Add, Button, x+0 w23 h23 geditPreset, ✏
	Gui, Settings:Add, Button, x+1 yp-4 w23 h23 gcfgPresetMenuShow, ☰
	Gui, Settings:Add, DropDownList, vimagesPreset x+1 yp+1 w130, %presetList%
	GuiControl,Settings:ChooseString, imagesPreset, %imagesPreset%
	
	
	Gui, Settings:Add, Checkbox, vexpandMyImages x10 yp+27 w350 Checked%expandMyImages%, Развернуть 'Мои изображения'
	Gui, Settings:Add, Button, x+1 yp-4 w132 h23 gopenMyImagesFolder, Открыть папку
	
	Gui, Settings:Add, Checkbox, vloadLab x10 yp+25 w350 Checked%loadLab%, Скачивать лабиринт(Мои изображения>Labyrinth.jpg)
	Gui, Settings:Add, Link, x+2 yp+0, <a href="https://www.poelab.com/">POELab.com</a>
	
	Gui, Settings:Add, Text, x10 y+4 w485 h2 0x10
	
	Gui, Settings:Add, Text, x10 yp+7 w350, Последнее изображение:
	Gui, Settings:Add, Hotkey, vhotkeyLastImg x+2 yp-2 w130 h18, %hotkeyLastImg%
	
	Gui, Settings:Add, Text, x10 yp+22 w350, Меню быстрого доступа:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenu x+2 yp-2 w130 h18, %hotkeyMainMenu%
	
	Gui, Settings:Add, Text, x10 y+4 w485 h2 0x10
	
	Gui, Settings:Add, Text, x10 yp+7 w350, Меню предмета:
	Gui, Settings:Add, Hotkey, vhotkeyItemMenu x+2 yp-2 w130 h18, %hotkeyItemMenu%
	
	Gui, Settings:Tab, 2 ; Вторая вкладка
	
	Gui, Settings:Add, Text, x10 y30 w350, Меню команд:
	Gui, Settings:Add, Hotkey, vhotkeyCustomCommandsMenu x+2 yp-2 w130 h18, %hotkeyCustomCommandsMenu%
	
	Gui, Settings:Add, Text, x10 y+4 w485 h2 0x10
	
	Gui, Settings:Add, Text, x10 yp+7 w350, Синхронизировать(/oos):
	Gui, Settings:Add, Hotkey, vhotkeyForceSync x+2 yp-2 w130 h18, %hotkeyForceSync%
	
	Gui, Settings:Add, Text, x10 yp+22 w350, К выбору персонажа(/exit):
	Gui, Settings:Add, Hotkey, vhotkeyToCharacterSelection x+2 yp-2 w130 h18, %hotkeyToCharacterSelection%
	
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
		Gui, Settings:Add, Edit, vtextCmd%A_Index% x10 yp+20 w350 h18, %tempVar%
		
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%A_Index% x+2 w130 h18, %tempVar%
	}
	
	Gui, Settings:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, Settings:Show, w500 h425, %prjName% %VerScript% | AHK %A_AhkVersion% - Настройки ;Отобразить окно настроек
}

saveSettings(){
	global
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	Gui, Settings:Submit
	
	if (imagesPreset="")
		imagesPreset:="default"
	
	IniWrite, %lastImg%, %configFile%, info, lastImg
	
	;Настройки первой вкладки
	IniWrite, %windowLine%, %configFile%, settings, windowLine
	IniWrite, %posX%/%posY%/%posW%/%posH%, %configFile%, settings, overlayPosition
	IniWrite, %autoUpdate%, %configFile%, settings, autoUpdate
	IniWrite, %imagesPreset%, %configFile%, settings, imagesPreset
	IniWrite, %loadLab%, %configFile%, settings, loadLab
	IniWrite, %expandMyImages%, %configFile%, settings, expandMyImages
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %hotkeyItemMenu%, %configFile%, hotkeys, hotkeyItemMenu
	
	;Настройки второй вкладки
	IniWrite, %hotkeyCustomCommandsMenu%, %configFile%, hotkeys, hotkeyCustomCommandsMenu
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
	IniRead, hotkeyItemMenu, %configFile%, hotkeys, hotkeyItemMenu, %A_Space%
	if (hotkeyItemMenu!="") {
		ItemMenu_IDCLInit()
		Hotkey, % hotkeyItemMenu, ItemMenu_Show, On
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
	Menu, Tray, Add, Поддержать, showDonateUI
	If FileExist("LICENSE.md")
		Menu, Tray, Add, Лицензия, showLicense
	Menu, Tray, Add, История изменений, showUpdateHistory
	Menu, Tray, Add
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Add, Настройки, showSettings
	Menu, Tray, Default, Настройки
	Menu, Tray, Add
	Menu, Tray, Add, Испытания лабиринта, showLabTrials
	Menu, Tray, Add, Очистить кэш Path of Exile, clearPoECache
	Menu, Tray, Add, Меню разработчика, :devMenu
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить, ReStart
	Menu, Tray, Add, Завершить работу макроса, Exit
	Menu, Tray, NoStandard
}

createMainMenu(){
	Menu, mainMenu, Add
	Menu, mainMenu, DeleteAll
	
	IniRead, imagesPreset, %configFile%, settings, imagesPreset, default
	presetInMenu(imagesPreset)
	
	FormatTime, CurrentDate, %A_NowUTC%, MMdd
	Random, randomNum, 1, 250
	If (CurrentDate==0401 || randomNum=1)
		Menu, mainMenu, Add, Криллсон - Самоучитель по рыбалке, firstAprilJoke
	
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

openConfigFolder(){
	Run, explorer "%configFolder%"
}

trayUpdate(nLine=""){
	trayMsg.=nLine
	Menu, Tray, Tip, %trayMsg%
}

LoadFile(URL, FilePath) {
	FileDelete, %FilePath%
	Sleep 100
	
	;Проверка наличия утилиты Curl
	If FileExist(A_WinDir "\System32\curl.exe") {
		CurlLine:="curl "
	} Else If FileExist(configfolder "\curl.exe") {
		CurlLine:="""" configFolder "\curl.exe"" "
	} Else {
		UrlDownloadToFile, %URL%, %FilePath%
		return
	}
	
	UserAgent:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36"
	CurlLine.="-L -A """ UserAgent """ -o "
	
	CurlLine.="""" FilePath """" " " """" URL """"
	RunWait, %CurlLine%
}

ReStart(){
	Gdip_Shutdown(pToken)
	sleep 250
	Reload
}

showStartNotify(){
	If (FileExist("readme.txt")) {
		FileRead, notifyMsg, readme.txt
		If (notifyMsg!="")
			msgbox, 0x1040, %prjName% - Уведомление, %notifyMsg%
		FileDelete, readme.txt
	}
}

showDonateUIOnStart() {
	;Иногда после запуска будем предлагать поддержать проект
	Random, randomNum, 1, 10
	if (randomNum=1 && !debugMode) {
		showDonateUI()
		Sleep 10000
		Gui, DonateUI:Minimize
	}
}


showDonateUI() {
	Gui, DonateUI:Destroy
	Gui, DonateUI:Add, Edit, x0 y0 w0 h0
	Gui, DonateUI:Add, Text, x10 y7 w300 +Center, Перевод на карту Visa: 
	Gui, DonateUI:Add, Edit, x10 y+3 w300 h18 +ReadOnly, 4276 0400 2866 1739
	Gui, DonateUI:Add, Text, x10 y+7 w300 +Center, Перевод по номеру телефона для клиентов Сбербанка: 
	Gui, DonateUI:Add, Edit, x10 y+3 w300 h18 +ReadOnly, +7 965 731 83 13
	
	Gui, DonateUI:Add, Text, x0 y+10 w400 h2 0x10
	Gui, DonateUI:Add, Text, x30 y+7 w260 +Center, Спасибо за вашу поддержку) 
	Gui, DonateUI:Add, Text, x0 y+10 w400 h2 0x10
	Gui, DonateUI:Add, Link, x30 yp+7 w260 +Center, Если хотите попасть на экран загрузки, то после совершения пожертвования напишите <a href="https://ru.pathofexile.com/private-messages/compose/to/MegaEzik@pc">мне в ЛС</a>)
	
	Gui, DonateUI:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, DonateUI:Show, w320 h165, Поддержать/Задонатить
}

;#################################################

Exit:
; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)
	sleep 250
	ExitApp
Return

/*
OnClipBoardChange:
	ItemData:=Clipboard
	If RegExMatch(ItemData, "Редкость: ") && debugMode {
		showItemMenu()
	}
Return
*/

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
