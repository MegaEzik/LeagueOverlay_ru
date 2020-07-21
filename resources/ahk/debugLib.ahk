
;Инициализация
devInit() {
	devMenu()
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	if !debugMode
		return
	trayUpdate("`nВключен режим отладки")
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть файл отладки, openDebugFile
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Установить пакет, installPack
	Menu, devMenu, Add
	Menu, devMenu, Standard
}

;Сообщение отладки
debugMsg(textMsg="", Notify=false) {
	If debugMode {
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
;Установить пакет
installPack(){
	FileSelectFile, ArcPath, ,,,(*.zip)
	If FileExist(ArcPath)
		unZipArchive(ArcPath, configFolder)
}
