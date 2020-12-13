
;Инициализация
devInit() {
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	devMenu()
	;if debugMode
	;	trayUpdate("`nВключен режим отладки")
	
	/*
	if debugMode {
		IDCL_Init()
		Hotkey, !c, showItemMenu, On
		;showToolTip("Включен режим отладки", 2000)
	}
	*/
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu1, Standard
	
	Menu, devMenu2, Add, https://poelab.com/gtgax, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/r8aws, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/riikv, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/wfbra, devReloadLab
	
	Menu, devMenu3, Add, Установить пакет, installPack
	Menu, devMenu3, Add
	If FileExist(configFolder "\myloader.ahk")
		Menu, devMenu3, Add, myloader.ahk, unInstallPack
	Loop, %configFolder%\*_loader.ahk, 1
		Menu, devMenu3, Add, Удалить %A_LoopFileName%, unInstallPack
	
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Режим отладки, switchDebugMode
	If debugMode
		Menu, devMenu, Check, Режим отладки
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Очистить кэш Path of Exile, clearPoECache
	Menu, devMenu, Add, Управление пакетами, :devMenu3
	Menu, devMenu, Add, Перезагрузить лабиринт, :devMenu2
	Menu, devMenu, Add, AutoHotkey, :devMenu1
}

switchDebugMode() {
	if debugMode {
		IniWrite, 0, %configFile%, settings, debugMode
	} else {
		IniWrite, 1, %configFile%, settings, debugMode
	}
	Sleep 500
	Reload
}

;Откатиться на релизную версию
devRestoreRelease() {
	verScript:=0
	CheckUpdateFromMenu()
}

;Установить пакет
installPack(){
	FileSelectFile, ArcPath, ,,,(*.zip)
	If FileExist(ArcPath) {
		unZipArchive(ArcPath, configFolder)
		sleep 1000
		ReStart()
	}
}

;Удалить пакет
unInstallPack(packName){
	RegExMatch(packName, "Удалить (.*)", packName)
	RunWait *RunAs "%A_AhkPath%" "%configFolder%\%packName1%" "%A_ScriptDir%" "UNINSTALL"
	sleep 1000
	FileDelete, %configFolder%\%packName1%
	RegExMatch(packName1, "(.*)_loader.ahk", Name)
	FileRemoveDir, %configFolder%\%Name1%, 1
	FileDelete, %configFolder%\presets\%Name1%.preset
	sleep 1000
	ReStart()
}

;Перезагрузить лабиринт
devReloadLab(LabURL){
	FileDelete, %configFolder%\images\Labyrinth.jpg
	sleep 25
	downloadLabLayout(LabURL)
}

showToolTip(msg, t=0) {
	ToolTip
	sleep 5
	ToolTip, %msg%
	if t!=0
		SetTimer, removeToolTip, %t%
}

removeToolTip() {
	ToolTip
	SetTimer, removeToolTip, Delete
}
