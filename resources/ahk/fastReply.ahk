
fastCmdForceSync(){
	BlockInput On
	SendInput, {Enter}{/}oos{Enter}
	BlockInput Off
}

fastCmdExit(){
	BlockInput On
	SendInput, {Enter}{/}exit{Enter}
	BlockInput Off
}

fastCmd1(){
	commandFastReply(textCmd1)
}

fastCmd2(){
	commandFastReply(textCmd2)
}

fastCmd3(){
	commandFastReply(textCmd3)
}

fastCmd4(){
	commandFastReply(textCmd4)
}

fastCmd5(){
	commandFastReply(textCmd5)
}

fastCmd6(){
	commandFastReply(textCmd6)
}

fastCmd7(){
	commandFastReply(textCmd7)
}

fastCmd8(){
	commandFastReply(textCmd8)
}

fastCmd9(){
	commandFastReply(textCmd9)
}

fastCmd10(){
	commandFastReply(textCmd10)
}

fastCmd11(){
	commandFastReply(textCmd11)
}

fastCmd12(){
	commandFastReply(textCmd12)
}

fastCmd13(){
	commandFastReply(textCmd13)
}

fastCmd14(){
	commandFastReply(textCmd14)
}

fastCmd15(){
	commandFastReply(textCmd15)
}

customCommandsEdit() {
	textFileWindow("Редактирование 'Меню команд'", configFolder "\commands.txt", false, "run https://pathofexile.gamepedia.com/Chat_console`n---`n@<last> sure`n/global 820`n/whois <last>`n/deaths`n/passives")
}

timerCommandsEdit() {
	If !WinExist(prjName " - Редактирование 'Меню команд'") {
		SetTimer, timerCommandsEdit, Delete
		sleep 1000
		ReStart()
	}
}

createCustomCommandsMenu(){
	Menu, customCommandsMenu, Add
	Menu, customCommandsMenu, DeleteAll
	
	If FileExist(configfolder "\commands.txt") {
		FileRead, FileContent, %configfolder%\commands.txt
		FileContent:=StrReplace(FileContent, "`r", "")
		FileLines:=StrSplit(FileContent, "`n")
		For k, val in FileLines {
			Line:=FileLines[k]
			If (RegExMatch(FileLines[k], "/")=1) || (RegExMatch(FileLines[k], "@<last> ")=1) || ((RegExMatch(FileLines[k], "search ")=1) || (RegExMatch(FileLines[k], "run ")=1) || (RegExMatch(FileLines[k], "img ")=1))
				Menu, customCommandsMenu, Add, %Line%, commandFastReply
			If (FileLines[k]="---")
				Menu, customCommandsMenu, Add
		}
	}
	Menu, customCommandsMenu, Add
	Menu, customCommandsMenu, Add, Редактировать 'Меню команд', customCommandsEdit
}

commandFastReply(Line:="/dance"){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 25
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
	If (RegExMatch(Line, "search ")=1) {
		Line:=StrReplace(Line, "search ", "")
		BlockInput On
		SendInput, ^{f}%Line%
		BlockInput Off
		return
	}
	If RegExMatch(Line, "<configFolder>")
		Line:=StrReplace(Line, "<configFolder>", configFolder)
	If (RegExMatch(Line, "run ")=1) {
		Line:=StrReplace(Line, "run ", "")
		run, %Line%
		return
	}
	If (RegExMatch(Line, "img ")=1) {
		Line:=StrReplace(Line, "img ", "")
		shOverlay(Line)
		return
	}
	msgbox, 0x1010, %prjName%, Неизвестная команда!, 2
}

showCustomCommandsMenu(){
	createCustomCommandsMenu()
	sleep 5
	Menu, customCommandsMenu, Show
}
