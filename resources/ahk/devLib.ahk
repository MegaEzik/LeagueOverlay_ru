
;Инициализация
devInit() {
	createCustomCommandsMenu()
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

customCommandsEdit() {
	textFileWindow("Редактирование 'Меню команд'", configFolder "\commands.txt", false, "https://pathofexile.gamepedia.com/Chat_console`r`n-----`r`n/global 820`r`n-----`r`n;/claim_crafting_benches`r`n/dance`r`n/deaths`r`n/passives`r`n/reset_xp`r`n/whois <character>`r`n@<character> after lab)")
}

createCustomCommandsMenu(){
	If FileExist(configfolder "\commands.txt") {
		FileRead, FileContent, %configfolder%\commands.txt
		FileLines:=StrSplit(FileContent, "`r`n")
		For k, val in FileLines {
			Line:=FileLines[k]
			If (RegExMatch(FileLines[k], "/")=1)
				Menu, customCommandsMenu, Add, %Line%, commandFromMenu
			If (RegExMatch(FileLines[k], "@<character> ")=1)
				Menu, customCommandsMenu, Add, %Line%, commandFromMenu
			If (RegExMatch(FileLines[k], "https://")=1)
				Menu, customCommandsMenu, Add, %Line%, commandFromMenu
			If (RegExMatch(FileLines[k], "-----"))
				Menu, customCommandsMenu, Add
		}
	}
	Menu, customCommandsMenu, Add
	Menu, customCommandsMenu, Add, Редактировать 'Меню команд', customCommandsEdit
}

commandFromMenu(Line:="/dance"){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 50
	If (RegExMatch(Line, "/")=1) {
		If (RegExMatch(Line, " <character>$")) {
			Line:=StrReplace(Line, " <character>", "")
			BlockInput On
			SendInput, ^{Enter}{Home}{Delete}%Line% {Enter}
			BlockInput Off
		} Else {
			BlockInput On
			SendInput, {Enter}%Line%{Enter}
			BlockInput Off
		}
	} Else If (RegExMatch(Line, "@<character> ")=1) {
		Line:=StrReplace(Line, "@<character> ", "")
		BlockInput On
		SendInput, ^{Enter}%Line%{Enter}
		BlockInput Off	
	} Else If (RegExMatch(Line, "https://")=1) {
		run %Line%
	} Else {
		msgbox, 0x1010, %prjName%, Неизвестная команда!, 2
	}
}
