
;Инициализация
devInit() {
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	devMenu()
	if debugMode
		trayUpdate("`nВключен режим отладки")
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu, Standard
	Menu, devMenu, Add
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Установить пакет, installPack
	if debugMode {
		Menu, devMenu, Add
		Menu, devMenu, Add, https://www.poelab.com/gtgax, devReloadLab
		Menu, devMenu, Add, https://www.poelab.com/r8aws, devReloadLab
		Menu, devMenu, Add, https://www.poelab.com/riikv, devReloadLab
		Menu, devMenu, Add, https://www.poelab.com/wfbra, devReloadLab
	}
}

;Откатиться на релизную версию
devRestoreRelease() {
	verScript:=0
	CheckUpdateFromMenu()
}

;Установить пакет
installPack(){
	FileSelectFile, ArcPath, ,,,(*.zip)
	If FileExist(ArcPath)
		unZipArchive(ArcPath, configFolder)
}

;Перезагрузить лабиринт
devReloadLab(LabURL){
	FileDelete, %configFolder%\images\Labyrinth.jpg
	sleep 25
	downloadLabLayout(LabURL)
}
