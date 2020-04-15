
;Инициализация
devInit() {
	trayUpdate("`nРежим разработчика")
	devMenu()
}

;Создание меню разработчика
devMenu() {
	;menu, devSubMenu1, Add, normal, devLab
	;menu, devSubMenu1, Add, cruel, devLab
	menu, devSubMenu1, Add, merciless, devLab
	menu, devSubMenu1, Add, uber, devLab

	Menu, devMenu, Add, Лабиринт, :devSubMenu1
	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть файл отладки, openDebugFile
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add
	Menu, devMenu, Add, Создать замену, replacerImages
	Menu, devMenu, Add, Удалить замену, delReplacedImages
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

;Лабиринт
devLab(lvlLab="uber"){
	FileDelete, %configFolder%\images\Lab.jpg
	sleep 25
	downloadLabLayout(lvlLab)
	ReStart()
}

;Откатиться на релизную версию
devRestoreRelease() {
	verScript:=0
	CheckUpdateFromMenu()
}

;Найти предметы
findItem() {
	BlockInput On
	SendInput, ^c
	BlockInput Off
	
	sleep 100
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
	
	sleep 100
	BlockInput On
	SendInput, ^f"%resultString%"{Enter}
	BlockInput Off
}
