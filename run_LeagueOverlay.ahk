
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
		*Filter.ahk - Обновление фильтра предметов
	
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
#Include, %A_ScriptDir%\resources\ahk\Filter.ahk

;Список окон Path of Exile
GroupAdd, WindowGrp, Path of Exile ahk_class POEWindowClass
GroupAdd, WindowGrp, ahk_exe GeForceNOWStreamer.exe

;Объявление и загрузка основных переменных
global prjName="LeagueOverlay_ru", githubUser="MegaEzik"
global configFolder:=A_MyDocuments "\AutoHotKey\" prjName
If InStr(FileExist(A_ScriptDir "\..\Profile"), "D")
	configFolder:=A_ScriptDir "\..\Profile"
global configFile:=configFolder "\settings.ini"
global textCmd1, textCmd2, textCmd3, textCmd4, textCmd5, textCmd6, textCmd7, textCmd8, textCmd9, textCmd10, textCmd11, textCmd12, textCmd13, textCmd14, textCmd15, textCmd16, textCmd17, textCmd18, textCmd19, textCmd20, cmdNum=20
global verScript, LastImg, debugMode=0, globalOverlayPosition, OverlayStatus=0
FileReadLine, verScript, resources\Updates.txt, 1

;Установка иконки и описания в области уведомлений
If FileExist("resources\icons\icon.png")
	Menu, Tray, Icon, resources\icons\icon.png
Menu, Tray, Tip, %prjName% %verScript% | AHK %A_AhkVersion%

;Проверка требований
checkRequirements()

;UI загрузки и загрузка инструментов разработчика
showStartUI()
devInit()

;Проверка обновлений
IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
If autoUpdate {
	CheckUpdateFromMenu("onStart")
	SetTimer, CheckUpdate, 7200000
}

;Проверка версии и перенос настроек
migrateConfig()

;Подгрузим некоторые значения
IniRead, LastImg, %configFile%, info, lastImg, %A_Space%
IniRead, globalOverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
IniRead, windowLine, %configFile%, settings, windowLine, %A_Space%
If (windowLine!="")
	GroupAdd, WindowGrp, %windowLine%
IniRead, mouseDistance, %configFile%, settings, mouseDistance, 500
Globals.Set("mouseDistance", mouseDistance)

;Выполним все файлы с окончанием .ahk, передав им папку расположения скрипта
pkgsMgr_startCustomScripts()

;Назначим управление и создадим меню
menuCreate()
setHotkeys()

;Загрузка и установка данных
downloadDataAndSetTimer()

;Завершение загрузки
closeStartUI()

Return

;#################################################

#IfWinActive ahk_group WindowGrp

checkRequirements() {
	If (!A_IsAdmin) {
		Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
		ExitApp
	}
	;RegExMatch(A_OSVersion, "(\d+)$", OSBuild)
	OSBuild:=DllCall("GetVersion") >> 16 & 0xFFFF        
	If (OSBuild<7601) {
		MsgBox, 0x1010, %prjName%, Для работы %prjName% требуется операционная система Windows 7 Service Pack 1 или выше!
		ExitApp
	}
	If (A_PtrSize!=8) {
		msgtext:="Для работы " prjName " требуется 64-разрядный интерпретатор AutoHotkey!"
		Loop, %A_AhkPath%
			AhkDir:=A_LoopFileDir
		If FileExist(AhkDir "\Installer.ahk")
			msgtext.="`n`nПосле нажатия кнопки 'ОК' откроется 'AutoHotkey Setup', выберите в нем 'Modify', а затем 'Unicode 64-bit'."
		MsgBox, 0x1010, %prjName%, %msgtext%
		If FileExist(AhkDir "\Installer.ahk")
			Run *RunAs "%AhkDir%\Installer.ahk"
		ExitApp
	}
	If !FileExist(A_WinDir "\System32\curl.exe") {
		If !FileExist(configfolder "\curl.exe") {
			FileCreateDir, %configFolder%
			SplashTextOn, 400, 20, %prjName%, Загрузка утилиты 'curl.exe'...
			If LoadFile("https://github.com/MegaEzik/LeagueOverlay_ru/releases/download/210520.5/curl.zip", A_Temp "\lo_curl.zip", "F9A76C4CC50F15506A880AB2F94634BC") {
				unZipArchive(A_Temp "\lo_curl.zip", configFolder "\")
				FileDelete, %A_Temp%\lo_curl.zip
			} Else {
				msgtext:="В вашей системе не найдена утилита 'curl.exe', без нее работа " prjName " невозможна!`n`nДля устранения этой проблемы скачайте утилиту 'curl.exe' вручную и поместите ее в папку: " configFolder
				MsgBox, 0x1010, %prjName%, %msgtext%
				ExitApp
			}
			SplashTextOff
		}
	}
	;Запуск gdi+
	If !pToken:=Gdip_Startup()
		{
		   ;MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		   MsgBox, 48, %prjName%, Не удалось запустить gdi+! Пожалуйста, убедитесь, что в вашей системе он есть!
		}
	OnExit, Exit
}

migrateConfig() {
	IniRead, verConfig, %configFile%, info, verConfig, 0
	If (verConfig!=verScript) {
		If (verConfig>0) {
			If (verConfig<210823.1) {
				FileRemoveDir, %A_MyDocuments%\LeagueOverlay_ru, 1
				FileRemoveDir, %configFolder%\cache, 1
				FileDelete, %configFolder%\Lab.jpg
				FileDelete, %configFolder%\notes.txt
				FileDelete, %configFolder%\trials.ini
			}
			If (verConfig<211022.1) {
				IniRead, lr, %configFile%, curl, limit-rate, 1000
				If (lr=0)
					IniWrite, 1000, %configFile%, curl, limit-rate
				IniRead, ct, %configFile%, curl, connect-timeout, 10
				If (ct=5)
					IniWrite, 10, %configFile%, curl, connect-timeout
			}
			If (verConfig<211112.5) {
				FileMoveDir, %configFolder%\images, %configFolder%\MyFiles, 2
			}
			If (verConvig<211217.6) {
				FileDelete, %configFolder%\pkgsMgr.ini
				IniRead, updateFilter, %configFile%, settings, updateFilter, 0
				If updateFilter
					IniWrite, NeverSink-2semistr, %configFile%, settings, itemFilter
				IniWrite, 1, %configFile%, settings, useEvent
			}
		}
		
		showSettings()
		
		IniRead, lastImg, %configFile%, info, lastImg, %A_Space%
		IniRead, labLoadDate, %configFile%, info, labLoadDate, 0
		
		FileDelete, %configFile%
		sleep 25
		FileCreateDir, %configFolder%\MyFiles
		
		IniWrite, %verScript%, %configFile%, info, verConfig
		IniWrite, %lastImg%, %configFile%, info, lastImg
		If (labLoadDate!="")
			IniWrite, %labLoadDate%, %configFile%, info, labLoadDate
		
		saveSettings()
	}
}

downloadDataAndSetTimer(){
	loadPresetData()
	ItemMenu_IDCLInit(true)
	downloadLabLayout(,true)
	checkFilter()
	
	IniRead, useLoadTimers, %configFile%, settings, useLoadTimers, 0
	If useLoadTimers
		SetTimer, loadTimer, 7200000
}

loadTimer(){
	ItemMenu_IDCLInit()
	downloadLabLayout()
	checkFilter()
}

shLastImage(){
	SplitLastImg:=StrSplit(LastImg, "|")
	shOverlay(SplitLastImg[1], SplitLastImg[2], SplitLastImg[3])
}

firstAprilJoke(){
	tmpPresetData:=""
	presetsDataSplit:=strSplit(Globals.Get("presetsData"), "`n")
	For k, val in presetsDataSplit {
		ImgSplit:=strSplit(presetsDataSplit[k], "|")
		If (ImgSplit[3]="" || ImgSplit[3]>1)
			ImgSplit[3]:=1		
		Random, randomNum, ImgSplit[3]/2.5, ImgSplit[3]
		ImgSplit[3]:=Round(randomNum, 2)
		If FileExist(StrReplace(ImgSplit[2], "<configFolder>", configFolder))
			tmpPresetData.=StrReplace(ImgSplit[2], "<configFolder>", configFolder) "|" ImgSplit[3] "|" ImgSplit[4] "`n"
	}
	presetsDataSplit:=strSplit(tmpPresetData, "`n")
	Random, randomNum, 1, presetsDataSplit.MaxIndex()-1
	ImgSplit:=strSplit(presetsDataSplit[randomNum], "|")
	If FileExist(ImgSplit[1]) {
		shOverlay(ImgSplit[1], ImgSplit[2], ImgSplit[3])
		return
	} Else {
		return
	}
}

shMainMenu(){
	destroyOverlay()
	createMainMenu()
	sleep 5
	Menu, mainMenu, Show
}

loadPreset(presetName){
	presetPath:=A_ScriptDir "\resources\presets\" presetName ".preset"
	If (presetName="Event")
		presetPath:=A_ScriptDir "\resources\data\Event.txt"
	If RegExMatch(presetName, ".preset$")
		presetPath:=configFolder "\presets\" presetName
	If FileExist(presetPath)
		FileRead, presetData, %presetPath%
	return StrReplace(presetData, "`r", "")
}

loadPresetData(){
	presetsData:=""
	
	;Подгружаем набор события
	presetDataEvent:=loadEvent()
	
	;Подгружаем первичный набор
	IniRead, preset1, %configFile%, settings, preset1, %A_Space%
	presetData1:=loadPreset(preset1)
	
	;Подгружаем вторичный набор
	IniRead, preset2, %configFile%, settings, preset2, %A_Space%
	presetData2:=loadPreset(preset2)
	
	;Склейка и установка набора
	If (presetDataEvent!="")
		presetsData.=presetDataEvent "`n---`n"
	If (presetData1!="")
		presetsData.=presetData1 "`n---`n"
	If (presetData2!="")
		presetsData.=presetData2 "`n---`n"
	
	Globals.Set("presetsData", presetsData)
	
	;Применим настройки наборов
	presetsDataSplit:=strSplit(Globals.Get("presetsData"), "`n")
	For k, val in presetsDataSplit {
		If (RegExMatch(presetsDataSplit[k], ";")=1)
			Continue
		If (RegExMatch(presetsDataSplit[k], "ahk_(exe|class)")=1) {
			WindowLine:=presetsDataSplit[k]
			GroupAdd, WindowGrp, %WindowLine%
		}
	}
}

presetInMenu(){
	If (Globals.Get("presetsData")!="") {
		presetsDataSplit:=StrSplit(Globals.Get("presetsData"), "`n")
		For k, val in presetsDataSplit {
			If InStr(presetsDataSplit[k], ";")=1
				Continue
			imageInfo:=StrSplit(presetsDataSplit[k], "|")
			ImgName:=imageInfo[1]
			
			If (imageInfo[1]="---")
				Menu, mainMenu, Add
			If (RegExMatch(imageInfo[2], ".(png|jpg|jpeg|bmp)$") && FileExist(StrReplace(imageInfo[2],"<configFolder>", configFolder)) || (RegExMatch(imageInfo[2], ">")=1) || (RegExMatch(imageInfo[2], "!")=1))
					Menu, mainMenu, Add, %ImgName%, presetCmdInMenu
		}
	}
}

presetCmdInMenu(CmdName){
	presetsDataSplit:=StrSplit(Globals.Get("presetsData"), "`n")
	For k, val in presetsDataSplit {
		imageInfo:=StrSplit(presetsDataSplit[k], "|")
		If (CmdName=imageInfo[1]) {
			presetCmd:=SubStr(presetsDataSplit[k], StrLen(imageInfo[1])+2)
			commandFastReply(presetCmd)
			return
		}
	}
}

shMyImage(imagename){
	commandFastReply(configFolder "\MyFiles\" imagename)
}

openMyImagesFolder(){
	Gui, Settings:Destroy
	If !FileExist(configFolder "\MyFiles")
		FileCreateDir, %configFolder%\MyFiles
	sleep 15
	Run, explorer "%configFolder%\MyFiles"
}

myImagesMenuCreate(selfMenu=true){
	If selfMenu {
		Menu, myImagesMenu, Add
		Menu, myImagesMenu, DeleteAll
		
		Loop, %configFolder%\MyFiles\*.*, 1
			If RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp|txt)$")
				Menu, myImagesMenu, Add, %A_LoopFileName%, shMyImage
			Menu, myImagesMenu, Add
			Menu, myImagesMenu, Add, Открыть папку, openMyImagesFolder
			Menu, mainMenu, Add, Мои файлы, :myImagesMenu
	} Else {
		Loop, %configFolder%\MyFiles\*.*, 1
			If RegExMatch(A_LoopFileName, ".(png|jpg|jpeg|bmp|txt)$")
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
	Gui, tfwGui:Show,, %prjName% - %Title%
	
	sleep 15
	BlockInput On
	If ReadOnlyStatus {
		SendInput, ^{Home}
	} Else {
		SendInput, ^{End}
	}
	BlockInput Off
}

tfwClose(){
	Gui, tfwGui:Destroy
}

tfwDelFile(){
	global
	Gui, tfwGui:Submit
	msgbox, 0x1024, %prjName%, Удалить файл '%tfwFilePath%'?
	IfMsgBox No
		return
	FileDelete, %tfwFilePath%
	Gui, tfwGui:Destroy
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
	trayMsg("Очистка кэша завершена)")
	
	/*				;Резервный способ
	tmpCmdFile:=A_Temp "\ClearPoE.cmd"
	FileDelete, %tmpCmdFile%
	sleep 100
	FileAppend, title Очистка кэша Path of Exile`n@Echo off`ncls`nrd "%PoECacheFolder%" /S /Q, %tmpCmdFile%, CP866
	RunWait "%tmpCmdFile%"
	FileDelete, %tmpCmdFile%
	*/
	/*				;Устаревший способ
	msgbox, 0x1044, %prjName%, Во время очистки кэша рекомендуется закрыть игру.`n`nХотите продолжить?
	IfMsgBox Yes
	{
		FileSelectFile, FilePath, , C:\Program Files (x86)\Grinding Gear Games\Path of Exile\Content.ggpk, Укажите путь к файлу Content.ggpk в папке с игрой, (Content.ggpk)
		SplashTextOn, 400, 20, %prjName%, Очистка кэша, пожалуйста подождите...
		If (FilePath!="" && FileExist(FilePath)) {
			SplitPath, FilePath, , PoEFolderPath
			FileRemoveDir, %PoEFolderPath%\logs, 1
			;DirectX11
			FileRemoveDir, %PoEFolderPath%\CachedHLSLShaders, 1
			FileRemoveDir, %PoEFolderPath%\ShaderCacheD3D11, 1
			FileRemoveDir, %PoEFolderPath%\ShaderCacheD3D11_GI, 1
			;Vulkan
			FileRemoveDir, %PoEFolderPath%\ShaderCacheVulkan, 1
		}
		PoEConfigFolderPath:=A_MyDocuments "\My Games\Path of Exile"
		FileRemoveDir, %PoEConfigFolderPath%\Countdown, 1
		FileRemoveDir, %PoEConfigFolderPath%\DailyDealCache, 1
		FileRemoveDir, %PoEConfigFolderPath%\Minimap, 1
		FileRemoveDir, %PoEConfigFolderPath%\MOTDCache, 1
		FileRemoveDir, %PoEConfigFolderPath%\ShopImages, 1
		FileRemoveDir, %PoEConfigFolderPath%\OnlineFilters, 1
		SplashTextOff
	}
	*/
}

copyPreset(){
	Gui, Settings:Destroy
	FileCreateDir, %configFolder%\presets
	FileSelectFile, FilePath,,, Укажите путь к файлу набора изображений, (*.preset)
	If (FilePath!="" && FileExist(FilePath)) {
		FileCopy, %FilePath%, %configFolder%\presets, 1
	} Else {
		msgbox, 0x1010, %prjName%, Файл не найден или операция прервана пользователем!, 3
	}
	Sleep 25
	showSettings()
}

editPreset(presetName){
	Gui, Settings:Destroy
	If InStr(presetName, "Изменить ")=1
		presetName:=SubStr(presetName, 10)
	FileCreateDir, %configFolder%\presets
	If !FileExist(configFolder "\presets\" presetName) {
		InputBox, presetName, Укажите имя набора,,, 300, 100,,,,, My.preset
		If (presetName="")
			presetName:="My.preset"
		If !RegExMatch(presetName, ".preset$")
			presetName.=".preset"
	}
	If (presetName="" || ErrorLevel)
		return
	textFileWindow("Изменение " presetName, configFolder "\presets\" presetName, false, loadPreset("Default"))
}

cfgPresetMenuShow(){
	Menu, delPresetMenu, Add
	Menu, delPresetMenu, DeleteAll
	Menu, delPresetMenu, Add, Создать, editPreset
	Menu, delPresetMenu, Add, Добавить из файла, copyPreset
	Menu, delPresetMenu, Add
	Loop, %configFolder%\presets\*.preset, 1
		Menu, delPresetMenu, Add, Изменить %A_LoopFileName%, editPreset
	Menu, delPresetMenu, Show
}

showStartUI(){
	Gui, StartUI:Destroy
	
	initMsgs := ["Подготовка макроса к работе"
				,"Поддержи " prjName
				,"Опускаемся на 65535 глубину в 'Бесконечном спуске'"
				,"Поиск NPC 'Борис Бритва'"
				,"Призываем Создателя на Сумрачное взморье"
				,"Шагаем сквозь непроглядное безумие"
				,"Получаем приглашение Януса на поминки Кадиро"
				,"Предсказываем... огонь, насилие, СМЕРТЬ"
				,"Входим в 820ый для поиска лаб ... а ну да"
				,"Удаляем Зеркало Каландры из вашего фильтра предметов"]
				
	FormatTime, CurrentDate, %A_NowUTC%, MMdd
	
	If (CurrentDate==1231 || CurrentDate==0101)
		initMsgs:=["Мммм, Ледники"]
	If (CurrentDate==0214)
		initMsgs:=["Похоже кто-то будет соло", "<3 <3 <3 <3 <3 <3 <3"]
	If (CurrentDate==0223)
		initMsgs:=["Все мужики любят носки", "Есть один подарок лучше, чем носки. Это пена для бритья"]
	If (CurrentDate==0308)
		initMsgs:=["Не забывайте - это праздник всех женщин. Всех на свете!", "@>->--"]
	
	Random, randomNum, 1, initMsgs.MaxIndex()
	initMsg:=initMsgs[randomNum] "..."
	
	If (CurrentDate==0401) {
		Loop % Len := StrLen(initMsg)
			NewInitMsg.= SubStr(initMsg, Len--, 1)
		initMsg:=NewInitMsg
	}
	
	dNames:=["AbyssSPIRIT", "milcart", "Pip4ik", "Данил А. Р.", "MON9", "Иван А. К.", "Роман В. К."]
	Random, randomNum, 1, dNames.MaxIndex()
	dName:="Спасибо, " dNames[randomNum] ") "
	
	Gui, StartUI:Add, Progress, w500 h26 x0 y0 Background481D05

	Gui, StartUI:Font, s12 cFEC076 bold
	
	Gui, StartUI:Add, Text, x5 y3 h20 w490 +Center BackgroundTrans, %prjName% %verScript% | AHK %A_AhkVersion%
	
	;Gui, StartUI:Color, 030405
	;Gui, StartUI:Font, cFEEAC5
	Gui, StartUI:Font, c000000
	
	Gui, StartUI:Font, s10 bold italic
	Gui, StartUI:Add, Text, x0 y+10 h18 w500 +Center BackgroundTrans, %initMsg%
	
	Gui, StartUI:Font, s8 norm italic
	Gui, StartUI:Add, Text, x5 y+3 w490 BackgroundTrans +Right, %dName%
	
	;Gui, StartUI:+AlwaysOnTop -SysMenu
	Gui, StartUI:+ToolWindow -Caption +Border +AlwaysOnTop
	Gui, StartUI:Show, w500 h70, %prjName% %VerScript% | AHK %A_AhkVersion%
}

closeStartUI(){
	sleep 200
	Gui, StartUI:Destroy
	;If debugMode && FileExist(A_WinDir "\Media\Windows Proximity Notification.wav")
		;SoundPlay, %A_WinDir%\Media\Windows Proximity Notification.wav
	IniRead, showHistory, %configFile%, info, showHistory, 1
	If showHistory {
		showUpdateHistory()
		IniWrite, 0, %configFile%, info, showHistory
	}
	showDonateUIOnStart()
	If FileExist("readme.txt") {
		FileRead, MsgText, readme.txt
		If (MsgText!="")
			Msgbox, 0x1030, %prjName% - Важное уведомление!, %MsgText%
		FileDelete, readme.txt
	}
}

showSettings(){
	global
	Gui, Settings:Destroy
	
	;Настройки первой вкладки
	IniRead, OverlayPosition, %configFile%, settings, overlayPosition, %A_Space%
	splitOverlayPosition:=strSplit(OverlayPosition, "/")
	posX:=splitOverlayPosition[1]
	posY:=splitOverlayPosition[2]
	posW:=splitOverlayPosition[3]
	posH:=splitOverlayPosition[4]
	
	IniRead, autoUpdate, %configFile%, settings, autoUpdate, 1
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	IniRead, expandMyImages, %configFile%, settings, expandMyImages, 1
	IniRead, preset1, %configFile%, settings, preset1, default
	IniRead, preset2, %configFile%, settings, preset2, %A_Space%
	IniRead, mouseDistance, %configFile%, settings, mouseDistance, 500
	IniRead, windowLine, %configFile%, settings, windowLine, %A_Space%
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, !f1
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, hotkeyItemMenu, %configFile%, hotkeys, hotkeyItemMenu, %A_Space%
	
	;Настройки второй вкладки
	IniRead, UserAgent, %configFile%, curl, user-agent, %A_Space%
	IniRead, lr, %configFile%, curl, limit-rate, 1000
	IniRead, ct, %configFile%, curl, connect-timeout, 10
	IniRead, curlProgress, %configFile%, curl, curlProgress, 0
	IniRead, useLoadTimers, %configFile%, settings, useLoadTimers, 1
	IniRead, useEvent, %configFile%, settings, useEvent, 1
	IniRead, loadLab, %configFile%, settings, loadLab, 0
	IniRead, itemFilter, %configFile%, settings, itemFilter, %A_Space%
	
	;Настройки третьей вкладки
	IniRead, hotkeyCustomCommandsMenu, %configFile%, hotkeys, hotkeyCustomCommandsMenu, %A_Space%
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	
	Gui, Settings:Font, s12
	Gui, Settings:Add, Button, x0 y385 w640 h30 gsaveSettings, Применить и перезапустить ;💾 465
	
	Gui, Settings:Font, s8 normal
	
	Gui, Settings:Add, Link, x230 y4 w405 +Right, <a href="https://www.autohotkey.com/download/">AutoHotKey</a> | <a href="https://ru.pathofexile.com/forum/view-thread/2694683">Тема на Форуме</a> | <a href="https://github.com/MegaEzik/LeagueOverlay_ru/releases">Страница на GitHub</a>
	
	Gui, Settings:Add, Tab, x0 y0 w640 h385, Основные|Загрузки|Команды ;Вкладки
	Gui, Settings:Tab, 1 ;Первая вкладка
	
	Gui, Settings:Add, Checkbox, vautoUpdate x12 y30 w525 Checked%autoUpdate%, Автоматически проверять наличие обновлений
	
	Gui, Settings:Add, Checkbox, vdebugMode x12 yp+21 w525 Checked%debugMode% disabled, Режим отладки
	
	Gui, Settings:Add, Text, x12 yp+21 w150, Другое окно для проверки:
	Gui, Settings:Add, Edit, vwindowLine x+2 yp-2 w465 h17, %windowLine%
	
	Gui, Settings:Add, Text, x10 y+3 w620 h1 0x12
	
	Gui, Settings:Add, Text, x12 yp+6 w325, Позиция области изображений(пиксели):
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
		presetList.="|" RegExReplace(A_LoopFileName, ".preset$", "")
	Loop, %configFolder%\presets\*.preset, 1
		presetList.="|" A_LoopFileName
	
	Gui, Settings:Add, Text, x12 yp+24 w390, Наборы:
	;Gui, Settings:Add, Button, x+1 yp-4 w23 h23 gcopyPreset, 📄
	;Gui, Settings:Add, Button, x+0 w23 h23 geditPreset, ✏
	Gui, Settings:Add, Button, x+1 yp-4 w23 h23 gcfgPresetMenuShow, ☰
	Gui, Settings:Add, DropDownList, vpreset1 x+1 yp+1 w100, %presetList%
	GuiControl,Settings:ChooseString, preset1, %preset1%
	
	Gui, Settings:Add, DropDownList, vpreset2 x+2 w100, %presetList%
	GuiControl,Settings:ChooseString, preset2, %preset2%
	
	Gui, Settings:Add, Text, x12 yp+26 w515, Смещение указателя(пиксели):
	Gui, Settings:Add, Edit, vmouseDistance x+2 yp-2 w100 h18 Number, %mouseDistance%
	Gui, Settings:Add, UpDown, Range5-99999 0x80, %mouseDistance%
	
	Gui, Settings:Add, Checkbox, vexpandMyImages x12 yp+24 w515 Checked%expandMyImages%, Развернуть 'Мои файлы'
	Gui, Settings:Add, Button, x+1 yp-4 w102 h23 gopenMyImagesFolder, Открыть папку
	
	Gui, Settings:Add, Text, x10 y+3 w620 h1 0x12
	
	Gui, Settings:Add, Text, x12 yp+6 w515, Последнее изображение:
	Gui, Settings:Add, Hotkey, vhotkeyLastImg x+2 yp-2 w100 h17, %hotkeyLastImg%
	
	Gui, Settings:Add, Text, x12 yp+21 w515, Меню быстрого доступа:
	Gui, Settings:Add, Hotkey, vhotkeyMainMenu x+2 yp-2 w100 h17, %hotkeyMainMenu%
	
	Gui, Settings:Add, Text, x12 yp+21 w515, Меню предмета:
	Gui, Settings:Add, Hotkey, vhotkeyItemMenu x+2 yp-2 w100 h17, %hotkeyItemMenu%
	
	Gui, Settings:Tab, 2 ;Вторая вкладка
	
	Gui, Settings:Add, Text, x12 y30 w150, cURL | User-Agent:
	Gui, Settings:Add, Edit, vUserAgent x+2 yp-2 w465 h17, %UserAgent%
	
	Gui, Settings:Add, Text, x12 yp+21 w515, cURL | Ограничение загрузки(Кб/с, 0 - без лимита):
	Gui, Settings:Add, Edit, vlr x+2 yp-2 w100 h18 Number, %lr%
	Gui, Settings:Add, UpDown, Range0-99999 0x80, %lr%
	
	Gui, Settings:Add, Text, x12 yp+22 w515, cURL | Время соединения(сек.):
	Gui, Settings:Add, Edit, vct x+2 yp-2 w100 h18 Number, %ct%
	Gui, Settings:Add, UpDown, Range3-99999 0x80, %ct%
	
	Gui, Settings:Add, Checkbox, vcurlProgress x12 yp+21 w525 Checked%curlProgress%, cURL | Отображать окно в режиме отладки
	
	Gui, Settings:Add, Text, x10 y+5 w620 h1 0x12
	
	Gui, Settings:Add, Checkbox, vuseLoadTimers x12 yp+6 w525 Checked%useLoadTimers%, Разрешить фоновую загрузку данных
	
	Gui, Settings:Add, Checkbox, vuseEvent x12 yp+21 w525 Checked%useEvent%, Загружать и устанавливать набор события
	
	Gui, Settings:Add, Checkbox, vloadLab x12 yp+21 w515 Checked%loadLab%, Скачивать лабиринт('Мои файлы'>Labyrinth.jpg)
	Gui, Settings:Add, Link, x+2 yp+0 w100 +Right, <a href="https://www.poelab.com/">POELab.com</a>
	
	LFilter:=listFilters()
	Gui, Settings:Add, Text, x12 yp+21 w515, Обновлять фильтр предметов:
	Gui, Settings:Add, DropDownList, vitemFilter x+2 yp-2 w100, %LFilter%
	GuiControl,Settings:ChooseString, itemFilter, %itemFilter%
	
	Gui, Settings:Tab, 3 ; Третья вкладка
	
	Gui, Settings:Add, Text, x12 y30 w516, Меню команд:
	Gui, Settings:Add, Hotkey, vhotkeyCustomCommandsMenu x+2 yp-2 w100 h17, %hotkeyCustomCommandsMenu%
	
	Gui, Settings:Add, Text, x10 y+3 w620 h1 0x12
	
	Gui, Settings:Add, Text, x12 yp+6 w205, /exit(к персонажам):
	Gui, Settings:Add, Hotkey, vhotkeyToCharacterSelection x+2 yp-2 w100 h17, %hotkeyToCharacterSelection%
	
	Gui, Settings:Add, Text, x+4 yp+2 w205, /oos(синхронизация):
	Gui, Settings:Add, Hotkey, vhotkeyForceSync x+2 yp-2 w100 h17, %hotkeyForceSync%
	
	;Gui, Settings:Add, Text, x12 y+3 w620 h1 0x12
	
	;Gui, Settings:Add, Text, x12 yp-14 w0 h0
	
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
		}
		Gui, Settings:Add, Edit, vtextCmd%A_Index% x12 yp+19 w205 h17, %tempVar%
		
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%A_Index% x+2 w100 h17, %tempVar%
		
		TwoColumn:=Round(LoopVar+A_Index)
		IniRead, tempVar, %configFile%, fastReply, textCmd%TwoColumn%, %A_Space%
		Gui, Settings:Add, Edit, vtextCmd%TwoColumn% x+4 w205 h17, %tempVar%
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%TwoColumn%, %A_Space%
		Gui, Settings:Add, Hotkey, vhotkeyCmd%TwoColumn% x+2 w100 h17, %tempVar%
		;Msgbox, %TwoColumn%
	}
	
	helptext:="/dance - простая команда чата`n/whois <last> - команда в отношении последнего игрока`n@<last> ty, gl) - сообщение последнему игроку`n_ty, gl) - сообщение в чат области`n%ty, gl) - сообщение в групповой чат`n>calc.exe - открытие программы или веб страницы`n<configFolder>\my.jpg - изображение или текстовый файл`n!текст - всплывающая подсказка"
	helptext2:="--- - разделитель(только в 'Меню команд')`n;/dance - комментарий(команда будет проигнорирована)`n<configFolder> - указывает папку настроек(переменная)`n<time> - время UTC(переменная)`n<inputbox> - позволяет ввести текст(переменная)"
	Gui, Settings:Add, Text, x12 y+2 w307 cTeal, %helptext%
	Gui, Settings:Add, Text, x+2 w307 cTeal, %helptext2%
	
	Gui, Settings:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, Settings:Show, w640 h415, %prjName% %VerScript% | AHK %A_AhkVersion% - Настройки ;Отобразить окно настроек
}

saveSettings(){
	global
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 100
	Gui, Settings:Submit
	
	If (preset1=preset2)
		preset2:=""
	
	;Настройки первой вкладки
	IniWrite, %posX%/%posY%/%posW%/%posH%, %configFile%, settings, overlayPosition
	
	IniWrite, %autoUpdate%, %configFile%, settings, autoUpdate
	IniWrite, %debugMode%, %configFile%, settings, debugMode
	IniWrite, %expandMyImages%, %configFile%, settings, expandMyImages
	IniWrite, %preset1%, %configFile%, settings, preset1
	IniWrite, %preset2%, %configFile%, settings, preset2
	IniWrite, %mouseDistance%, %configFile%, settings, mouseDistance
	IniWrite, %windowLine%, %configFile%, settings, windowLine
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %hotkeyItemMenu%, %configFile%, hotkeys, hotkeyItemMenu
	
	;Настройки второй вкладки
	IniWrite, %UserAgent%, %configFile%, curl, user-agent
	IniWrite, %lr%, %configFile%, curl, limit-rate
	IniWrite, %ct%, %configFile%, curl, connect-timeout
	IniWrite, %curlProgress%, %configFile%, curl, curlProgress
	IniWrite, %useLoadTimers%, %configFile%, settings, useLoadTimers
	IniWrite, %useEvent%, %configFile%, settings, useEvent
	IniWrite, %loadLab%, %configFile%, settings, loadLab
	IniWrite, %itemFilter%, %configFile%, settings, itemFilter
	
	;Настройки третьей вкладки
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
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, %A_Space%
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, %A_Space%
	IniRead, hotkeyCustomCommandsMenu, %configFile%, hotkeys, hotkeyCustomCommandsMenu, %A_Space%
	If (hotkeyLastImg!="")
		Hotkey, % hotkeyLastImg, shLastImage, On
	If (hotkeyMainMenu!="")
		Hotkey, % hotkeyMainMenu, shMainMenu, On
	If (hotkeyCustomCommandsMenu!="")
		Hotkey, % hotkeyCustomCommandsMenu, showCustomCommandsMenu, On
	
	;Инициализация встроенных команд fastReply
	IniRead, hotkeyForceSync, %configFile%, hotkeys, hotkeyForceSync, %A_Space%
	IniRead, hotkeyToCharacterSelection, %configFile%, hotkeys, hotkeyToCharacterSelection, %A_Space%
	If (hotkeyForceSync!="")
		Hotkey, % hotkeyForceSync, fastCmdForceSync, On
	If (hotkeyToCharacterSelection!="")
		Hotkey, % hotkeyToCharacterSelection, fastCmdExit, On
	
	;Инициализация настраиваемых команд fastReply
	Loop %cmdNum% {
		IniRead, tempvar, %configFile%, fastReply, textCmd%A_Index%, %A_Space%
		textCmd%A_Index%:=tempvar
		IniRead, tempVar, %configFile%, fastReply, hotkeyCmd%A_Index%, %A_Space%
		If (textCmd%A_Index%!="" && tempVar!="")
			Hotkey, % tempVar, fastCmd%A_Index%, On
	}
}

menuCreate(){
	If FileExist("LICENSE.md")
		Menu, Tray, Add, Лицензия, showLicense
	Menu, Tray, Add, Поддержать %githubUser%, showDonateUI
	Menu, Tray, Add, История изменений, showUpdateHistory
	Menu, Tray, Add
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Add, Настройки, showSettings
	Menu, Tray, Default, Настройки
	Menu, Tray, Add
	Menu, Tray, Add, Очистить кэш PoE, clearPoECache
	pkgsMgr_packagesMenu()
	Menu, Tray, Add, Управление пакетами, :packagesMenu
	Menu, Tray, Add, Меню отладки, :devMenu
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить, ReStart
	Menu, Tray, Add, Выход, Exit
	Menu, Tray, NoStandard
}

createMainMenu(){
	Menu, mainMenu, Add
	Menu, mainMenu, DeleteAll
	
	FormatTime, CurrentDate, %A_NowUTC%, MMdd
	Random, randomNum, 1, 250
	If (CurrentDate==0401 || randomNum=1) {
		Menu, mainMenu, Add, Криллсон - Самоучитель по рыбалке, firstAprilJoke
		Menu, mainMenu, Add
	}
	
	presetInMenu()
	
	IniRead, expandMyImages, %configFile%, settings, expandMyImages, 1
	myImagesMenuCreate(!expandMyImages)
	
	IniRead, hotkeyCustomCommandsMenu, %configFile%, hotkeys, hotkeyCustomCommandsMenu, %A_Space%
	IfWinActive Path of Exile ahk_class POEWindowClass
		If (hotkeyCustomCommandsMenu="") {
			createCustomCommandsMenu()
			Menu, mainMenu, Add, Меню команд, :customCommandsMenu
		}
	
	Menu, mainMenu, Add, Область уведомлений, :Tray
}

openConfigFolder(){
	Run, explorer "%configFolder%"
}

openScriptFolder(){
	Run, explorer "%A_ScriptDir%"
}

ReStart(){
	Gdip_Shutdown(pToken)
	sleep 250
	Reload
}

showDonateUIOnStart() {
	;Иногда после запуска будем предлагать поддержать проект
	Random, randomNum, 1, 15
	If (randomNum=1 && !debugMode) {
		showDonateUI()
		Sleep 10000
		Gui, DonateUI:Minimize
	}
}


showDonateUI() {
	Gui, DonateUI:Destroy
	Gui, DonateUI:Add, Edit, x0 y0 w0 h0
	Gui, DonateUI:Add, Text, x10 y7 w300 +Center, Перевод на карту Visa: 
	Gui, DonateUI:Add, Edit, x10 y+3 w300 h18 +ReadOnly, 4274 3200 7505 4976
	Gui, DonateUI:Add, Text, x10 y+7 w300 +Center, Перевод по номеру телефона для клиентов Сбербанка: 
	Gui, DonateUI:Add, Edit, x10 y+3 w300 h18 +ReadOnly, +7 900 917 25 92
	
	Gui, DonateUI:Add, Text, x0 y+10 w400 h2 0x10
	Gui, DonateUI:Add, Text, x30 y+7 w260 +Center, Спасибо за вашу поддержку) 
	Gui, DonateUI:Add, Text, x0 y+10 w400 h2 0x10
	Gui, DonateUI:Add, Link, x30 yp+7 w260 +Center, Если хотите попасть на экран загрузки, то после совершения пожертвования напишите <a href="https://ru.pathofexile.com/private-messages/compose/to/MegaEzik@pc">мне в ЛС</a>)
	
	Gui, DonateUI:+AlwaysOnTop -MinimizeBox -MaximizeBox
	Gui, DonateUI:Show, w320 h165, Поддержать/Задонатить %githubUser%
}

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

trayMsg(MsgText, Title:=""){
	FullTitle:=prjName
	If (Title!="")
		FullTitle.=" - " Title
	TrayTip, %FullTitle%, %MsgText%
}

removeToolTip() {
	ToolTip
	SetTimer, removeToolTip, Delete
	SetTimer, timerToolTip, Delete
}

timerToolTip() {
	MouseGetPos, CurrX, CurrY
	If (CurrX - Globals.Get("ttCurrStartPosX"))** 2 + (CurrY - Globals.Get("ttCurrStartPosY")) ** 2 > Globals.Get("mouseDistance") ** 2
		removeToolTip()
}

LoadFile(URL, FilePath, MD5="") {
	FileDelete, %FilePath%
	Sleep 100
	
	;Проверка наличия утилиты Curl
	If FileExist(A_WinDir "\System32\curl.exe") {
		CurlLine:="curl "
	} Else If FileExist(configfolder "\curl.exe") {
		CurlLine:="""" configFolder "\curl.exe"" "
	}
	
	If (CurlLine!="") {
		IniRead, curlProgress, %configFile%, curl, curlProgress, 0
		IniRead, UserAgent, %configFile%, curl, user-agent, %A_Space%
		If (UserAgent="")
			UserAgent:="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36"
		IniRead, lr, %configFile%, curl, limit-rate, 1000
		IniRead, ct, %configFile%, curl, connect-timeout, 10
		
		CurlLine.="-L -A """ UserAgent """ -o """ FilePath """" " " """" URL """"
		If ct>0
			CurlLine.=" --connect-timeout " ct
		If lr>0
			CurlLine.=" --limit-rate " lr "K"
		If curlProgress && debugMode
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
