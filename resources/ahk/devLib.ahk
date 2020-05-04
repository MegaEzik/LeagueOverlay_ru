
;Инициализация
devInit() {
	If !FileExist(configfolder "\debug.log")
		return
	devMode:=1
	trayUpdate("`nВключен режим отладки")
	devMenu()
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Показать окно отладки, showDebugWindow
	Menu, devMenu, Add, Открыть файл отладки, openDebugFile
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add
	Menu, devMenu, Add, Создать замену, replacerImages
	Menu, devMenu, Add, Удалить замену, delReplacedImages
}

;Показать окно отладки
showDebugWindow() {
	ListLines
}

;Сообщение отладки
debugMsg(textMsg="", Notify=false) {
	If devMode {
		If Notify
			TrayTip, %prjName% - Отладка, %textMsg%
		If FileExist(configfolder "\debug.log") {
			FormatTime, TimeString
			TextString:=TimeString " - " StrReplace(textMsg, "`n", " | ") "`n"
			FileAppend, %TextString%, %configfolder%\debug.log
		}
	}
}

;Открыть файл отладки
openDebugFile() {
	textFileWindow("Файл отладки", configFolder "\debug.log", false)
}

;Откатиться на релизную версию
devRestoreRelease() {
	verScript:=0
	CheckUpdateFromMenu()
}
