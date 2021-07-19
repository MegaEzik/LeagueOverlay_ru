
;Инициализация
devInit() {
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	Globals.Set("debugMode", debugMode)
	devMenu()
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu1, Standard
	
	Menu, devMenu2, Add, https://poelab.com/gtgax, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/r8aws, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/riikv, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/wfbra, devReloadLab
	
	Menu, devMenu, Add, Режим отладки, switchDebugMode
	If Globals.Get("debugMode")
		Menu, devMenu, Check, Режим отладки
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Перезагрузить данные, devReloadData
	Menu, devMenu, Add, Перезагрузить лабиринт, :devMenu2
	Menu, devMenu, Add, AutoHotkey, :devMenu1
}

switchDebugMode() {
	if Globals.Get("debugMode") {
		IniWrite, 0, %configFile%, settings, debugMode
	} else {
		MsgBox, 0x1024, %prjName%, Включение режима отладки может сделать работу %prjName% нестабильной!`n`nВы уверены, что хотите продолжить?
		IfMsgBox No
			return
		IniWrite, 1, %configFile%, settings, debugMode
	}
	Sleep 500
	Reload
}

;Откатиться на релизную версию
devRestoreRelease() {
	IniWrite, 0, %configFile%, info, verConfig
	verScript:=0
	CheckUpdateFromMenu()
}

;Перезагрузить лабиринт
devReloadLab(LabURL){
	FileDelete, %configFolder%\images\Labyrinth.jpg
	sleep 25
	downloadLabLayout(LabURL)
}

;Перезагрузить данные
devReloadData(){
	FileRemoveDir, resources\data, 1
	Sleep 500
	Reload
}
