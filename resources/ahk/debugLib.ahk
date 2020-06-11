
;Инициализация
devInit() {
	;Hotkey, !f, highlightItem, On
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	if !debugMode
		return
	trayUpdate("`nВключен режим отладки")
	devMenu()
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть файл отладки, openDebugFile
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

;Логаут
cportsLogout(){
	Run, "%configfolder%\cports.exe" /close * * * * PathOfExile_x64.exe
	Run, "%configfolder%\cports.exe" /close * * * * PathOfExile_x64Steam.exe
	Run, "%configfolder%\cports.exe" /close * * * * PathOfExile.exe
	Run, "%configfolder%\cports.exe" /close * * * * PathOfExileSteam.exe
}

;Подсветить предмет
highlightItem() {
	BlockInput On
	SendInput, ^c
	BlockInput Off

	sleep 50
	itemText:=Clipboard
	itemText:=StrReplace(itemText, "`r", "")
	itemText:=StrReplace(itemText, "You cannot use this item. Its stats will be ignored`n--------`n", "")
	itemText:=StrReplace(itemText, "Вы не можете использовать этот предмет, его параметры не будут учтены`n--------`n", "")
	itemText:=StrReplace(itemText, "Superior ", "")
	itemText:=StrReplace(itemText, " высокого качества", "")
	itemSplit:=StrSplit(itemText, "`n")

	resultString:=itemSplit[2]
	If ((inStr(itemText, "Rarity: Rare") && !inStr(itemText, "Unidentified")) || (inStr(itemText, "Редкость: Редкий") && !inStr(itemText, "Неопознано")))
		resultString:=itemSplit[3]

	sleep 50
	BlockInput On
	SendInput, ^f"%resultString%"{Enter}
	BlockInput Off
}
