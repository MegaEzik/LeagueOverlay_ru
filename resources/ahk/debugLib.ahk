
;Инициализация и создание меню разработчика
devInit(){
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	
	;Menu, devMenu, Add, Мои наборы, devPresetMenuShow
	Menu, devMenu, Add, Режим отладки, switchDebugMode
	If debugMode
		Menu, devMenu, Check, Режим отладки
	Menu, devMenu, Add
	Menu, devMenu, Add, Папка макроса, openScriptFolder	
	Menu, devMenu, Add, Папка настроек, openConfigFolder
	Menu, devMenu, Add, Изменить конфиг, editConfig
	Menu, devMenu, Add
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Перезагрузить данные, devClSD
	Menu, devSubMenu1, Add, https://poelab.com/gtgax, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/r8aws, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/riikv, reloadLab
	Menu, devSubMenu1, Add, https://poelab.com/wfbra, reloadLab
	Menu, devMenu, Add, Лабиринт, :devSubMenu1
	;Menu, devMenu, Add
	;Menu, devMenu, Add, Избранные комманды, favoriteList
	Menu, devMenu, Add
	Menu, devMenu, Add, Контрольная сумма(MD5), devMD5FileCheck
	Menu, devMenu, Add
	Menu, devSubMenu2, Standard
	Menu, devMenu, Add, AutoHotkey, :devSubMenu2
}

;Переключить режим разработчика
switchDebugMode(){
	newDebugMode:=!debugMode
	IniWrite, %newDebugMode%, %configFile%, settings, debugMode
	Sleep 100
	ReStart()
}

;Подсчет MD5 файла
devMD5FileCheck(){
	FileSelectFile, FilePath
	If FileExist(FilePath){
		Clipboard:=MD5_File(FilePath)
		TrayTip, %prjName% - Контрольная сумма, Скопировано в буфер обмена:`n%Clipboard%
	}
}

;Откатиться на релизную версию
devRestoreRelease() {
	IniWrite, 0, %configFile%, info, verConfig
	verScript:=0
	CheckUpdate()
}

;Перезагрузка данных
devClSD(){
	FileDelete, resources\Packages.txt
	FileDelete, %configFolder%\MyFiles\Labyrinth.jpg
	FileDelete, resources\data\*
	Sleep 100
	ReStart()
}

;Запись отладочной информации
devLog(msg){
	If FileExist(configFolder "\dev.log") {
		FormatTime, Time, dddd MMMM, dd.MM HH:mm:ss
		FileAppend, %Time% v%verScript% - %msg%`n, %configFolder%\dev.log, UTF-8
	}
}

;Добавление в отслеживаемый список
devAddInList(Line){
	If !debugMode
		return
	FilePath:=configFolder "\devList.list"
	FileRead, DataList, %FilePath%
	DataListSplit:=strSplit(StrReplace(DataList, "`r", ""), "`n")
	For k, val in DataListSplit
		If DataListSplit[k]=Line
			return
	FileAppend, %Line%`n, %FilePath%, UTF-8
}

;Создать ярлык
createShortcut(Params){
	FileCreateShortcut, %A_ScriptFullPath%, %A_Desktop%\LeagueOverlay_ru.lnk, %A_ScriptDir%, %Params%
}

favoriteList(){
	Menu, favoriteList, Add
	Menu, favoriteList, DeleteAll
	Loop, %configFolder%\MyFiles\*.fmenu, 1
		Menu, favoriteList, Add, %A_LoopFileName%, favoriteSetFile
	Menu, favoriteList, Show
}

favoriteSetFile(Name){
	IniWrite, %Name%, %configFile%, settings, sMenu
}

editConfig(){
	;textFileWindow("", configFile, false)
	RunWait, notepad.exe "%configFile%"
	ReStart()
}

updateAutoHotkey(){
	IniRead, updateAHK, %configFile%, settings, updateAHK, 1
	If !updateAHK
		return
	filePath:=A_Temp "\ahkver.txt"
	FileDelete, %filePath%
	UrlDownloadToFile, https://www.autohotkey.com/download/1.1/version.txt, %filePath%
	FileReadLine, AHKRelVer, %filePath%, 1
	If (A_AhkVersion<AHKRelVer){
		SplitPath, A_AhkPath,,AHKDir
		If FileExist(AHKDir "\Installer.ahk")
			Run *RunAs "%AhkDir%\Installer.ahk"
	}
}

presetMenuCfgShow(){
	Menu, devPresetMenu, Add
	Menu, devPresetMenu, DeleteAll
	Menu, devPresetMenu, Add, Создать, presetCreate
	Menu, devPresetMenu, Add, Дополнения, pkgsMgr_packagesMenu
	
	Loop, %configFolder%\Presets\*, 2
	{
		Menu, devPresetMenu, Add
		Menu, devPresetMenu, Add, Открыть папку '%A_LoopFileName%', presetFolderOpen
		Menu, devPresetMenu, Add, Удалить '%A_LoopFileName%', presetFolderDelete
	}
		
	Menu, devPresetMenu, Show
}

searchName(FullText){
	If RegExMatch(FullText, "'(.*)'", Result)
		return Result1
	return FullText
}

presetFolderOpen(Name){
	Gui, Settings:Destroy
	PresetFolder:=configFolder "\Presets\" searchName(Name)
	Run, explorer "%PresetFolder%"
}

presetFolderDelete(Name){
	Gui, Settings:Destroy
	PresetFolder:=configFolder "\Presets\" searchName(Name)
	msgbox, 0x1024, %prjName%, Удалить папку '%PresetFolder%'?
	IfMsgBox No
		return
	FileRemoveDir, %PresetFolder%, 1
}

presetCreate(){
	Gui, Settings:Destroy
	InputBox, PresetName, Введите название набора,,, 300, 100,,,,, NewPreset
	PresetFolder:=configFolder "\Presets\" PresetName
	If (PresetName="") || FileExist(PresetFolder) {
		msgbox, 0x1040,, Недопустимое имя для набора!
		return
	}
	FileCreateDir, %PresetFolder%
	InputBox, wline, Укажите окно отслеживания,,, 300, 100,,,,, ahk_exe notepad.exe
	FileAppend, %wline%, %PresetFolder%\windows.list, UTF-8
	ReadMeFullText:="Вы создали шаблон для набора '" PresetName "'!`n`nОткройте папку набора и поместите в нее желаемые файлы.`nДля корректного открытия текстовых файлов требуется кодировка UTF-8-BOM!`n`nЕсли вам потребуется изменить 'Окна отслеживания', то вы можете сделать это отредактировав файл 'windows.list'."
	FileAppend, %ReadMeFullText%, %PresetFolder%\ReadMe.txt, UTF-8
	textFileWindow("", PresetFolder "\ReadMe.txt", false)
}

devVoid(){
}
