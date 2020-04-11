
;Инициализация
devInit() {
	trayUpdate(" (Режим разработчика)")
	devMenu()
}

;Создание меню разработчика
devMenu() {
	menu, devSubMenu1, Add, Normal, labNormal
	menu, devSubMenu1, Add, Cruel, labCruel
	menu, devSubMenu1, Add, Merciless, labMerciless
	menu, devSubMenu1, Add, Uber(Default), labDefault

	Menu, devMenu, Add, Загрузить лабиринт, :devSubMenu1
	Menu, devMenu, Add
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder

	Menu, devMenu, Add
	Menu, devMenu, Add, Создать замену, replacerImages
	Menu, devMenu, Add, Удалить замену, delReplacedImages
}

debugMsg(textMsg) {
	If devMode {
		If FileExist(configfolder "\debug.log") {
			TrayTip, %prjName% - Отладка, %textMsg%
			FormatTime, TimeString
			TextString:=TimeString " - " StrReplace(textMsg, "`n", " | ") "`n"
			FileAppend, %TextString%, %configfolder%\debug.log
		}
	}
}

labNormal() {
	FileDelete, %configFolder%\images\Lab.jpg
	sleep 25
	downloadLabLayout("normal")
	ReStart()
}

labCruel() {
	FileDelete, %configFolder%\images\Lab.jpg
	sleep 25
	downloadLabLayout("cruel")
	ReStart()
}

labMerciless() {
	FileDelete, %configFolder%\images\Lab.jpg
	sleep 25
	downloadLabLayout("merciless")
	ReStart()
}

labDefault() {
	FileDelete, %configFolder%\images\Lab.jpg
	sleep 25
	ReStart()
}

;Откатиться на релизную версию
devRestoreRelease() {
	verScript:=0
	CheckUpdateFromMenu()
}
