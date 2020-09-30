
;Инициализация
devInit() {
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	devMenu()
	if debugMode
		trayUpdate("`nВключен режим отладки")
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu1, Standard
	
	Menu, devMenu2, Add, Normal, devReloadLab
	Menu, devMenu2, Add, Cruel, devReloadLab
	Menu, devMenu2, Add, Merciless, devReloadLab
	Menu, devMenu2, Add, Uber, devReloadLab
	
	Menu, devMenu3, Add, Установить пакет, installPack
	Menu, devMenu3, Add
	If FileExist(configFolder "\myloader.ahk")
		Menu, devMenu3, Add, myloader.ahk, unInstallPack
	Loop, %configFolder%\*_loader.ahk, 1
		Menu, devMenu3, Add, Удалить %A_LoopFileName%, unInstallPack

	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Управление пакетами, :devMenu3
	Menu, devMenu, Add, Перезагрузить лабиринт, :devMenu2
	Menu, devMenu, Add, AutoHotkey, :devMenu1
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
	ReStart()
}

;Удалить пакет
unInstallPack(packName){
	RegExMatch(packName, "Удалить (.*)", packName)
	RunWait *RunAs "%A_AhkPath%" "%configFolder%\%packName1%" "%A_ScriptDir%" "UNINSTALL"
	sleep 100
	FileDelete, %configFolder%\%packName1%
	RegExMatch(packName1, "(.*)_loader.ahk", Name)
	FileRemoveDir, %configFolder%\%Name1%, 1
	FileDelete, %configFolder%\presets\%Name1%.preset
	ReStart()
}

;Перезагрузить лабиринт
devReloadLab(LabName){
	FileDelete, %configFolder%\images\Labyrinth.jpg
	sleep 25
	LabURL:="https://www.poelab.com/wfbra"
	If (LabName="Normal")
		LabURL:="https://www.poelab.com/gtgax"
	If (LabName="Cruel")
		LabURL:="https://www.poelab.com/r8aws"
	If (LabName="Merciless")
		LabURL:="https://www.poelab.com/riikv"
	downloadLabLayout(LabURL)
}
