
forceSync(){
	BlockInput On
	SendInput, {Enter}{/}oos{Enter}
	BlockInput Off
}

toCharacterSelection(){
	BlockInput On
	SendInput, {Enter}{/}exit{Enter}
	BlockInput Off
}

goHideout(){
	BlockInput On
	SendInput, {Enter}{/}hideout{Enter}
	BlockInput Off
}

dndMode(){
	BlockInput On
	SendInput, {Enter}{/}dnd{Enter}
	BlockInput Off
}

chatMsg1(){
	commandFastReply("@<last> " textMsg1)
}

chatMsg2(){
	commandFastReply("@<last> " textMsg2)
}

chatMsg3(){
	commandFastReply("@<last> " textMsg3)
}

chatInvite(){
	commandFastReply("/invite <last>")
}

chatKick(){
	commandFastReply("/kick <last>")
}

chatTradeWith(){
	commandFastReply("/tradewith <last>")
}

customCommandsEdit() {
	textFileWindow("Редактирование 'Меню команд'", configFolder "\commands.txt", false, "run https://pathofexile.gamepedia.com/Chat_console`n-----`n/global 820`n/dance`n/deaths`n/passives`n/reset_xp`n/hideout <last>`n/whois <last>`n@<last> after lab)")
	SetTimer, timerCommandsEdit, 500
}

timerCommandsEdit() {
	If !WinExist(prjName " - Редактирование 'Меню команд'")
		ReStart()
}

createCustomCommandsMenu(){
	If FileExist(configfolder "\commands.txt") {
		FileRead, FileContent, %configfolder%\commands.txt
		FileContent:=StrReplace(FileContent, "`r", "")
		FileLines:=StrSplit(FileContent, "`n")
		For k, val in FileLines {
			Line:=FileLines[k]
			If (RegExMatch(FileLines[k], "/")=1) || (RegExMatch(FileLines[k], "@<last> ")=1) || (RegExMatch(FileLines[k], "run ")=1)
				Menu, customCommandsMenu, Add, %Line%, commandFastReply
			If (RegExMatch(FileLines[k], "-----"))
				Menu, customCommandsMenu, Add
		}
	}
	Menu, customCommandsMenu, Add
	Menu, customCommandsMenu, Add, Редактировать 'Меню команд', customCommandsEdit
}

commandFastReply(Line:="/dance"){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 50
	If (RegExMatch(Line, "/")=1) {
		If (RegExMatch(Line, " <last>$")) {
			Line:=StrReplace(Line, " <last>", "")
			BlockInput On
			SendInput, ^{Enter}{Home}{Delete}%Line% {Enter}
			BlockInput Off
		} Else {
			BlockInput On
			SendInput, {Enter}%Line%{Enter}
			BlockInput Off
		}
		return
	}
	If (RegExMatch(Line, "@<last> ")=1) {
		Line:=StrReplace(Line, "@<last> ", "")
		BlockInput On
		SendInput, ^{Enter}%Line%{Enter}
		BlockInput Off
		return
	}
	If (RegExMatch(Line, "run ")=1) {
		Line:=StrReplace(Line, "run ", "")
		run, %Line%
		return
	}
	msgbox, 0x1010, %prjName%, Неизвестная команда!, 2
}
