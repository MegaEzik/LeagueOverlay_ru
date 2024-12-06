
fastCmd1(){
	commandFastReply(Globals.Get("fR" 1))
}

fastCmd2(){
	commandFastReply(Globals.Get("fR" 2))
}

fastCmd3(){
	commandFastReply(Globals.Get("fR" 3))
}

fastCmd4(){
	commandFastReply(Globals.Get("fR" 4))
}

fastCmd5(){
	commandFastReply(Globals.Get("fR" 5))
}

fastCmd6(){
	commandFastReply(Globals.Get("fR" 6))
}

fastCmd7(){
	commandFastReply(Globals.Get("fR" 7))
}

fastCmd8(){
	commandFastReply(Globals.Get("fR" 8))
}

fastCmd9(){
	commandFastReply(Globals.Get("fR" 9))
}

fastCmd10(){
	commandFastReply(Globals.Get("fR" 10))
}

fastCmd11(){
	commandFastReply(Globals.Get("fR" 11))
}

fastCmd12(){
	commandFastReply(Globals.Get("fR" 12))
}

fastCmd13(){
	commandFastReply(Globals.Get("fR" 13))
}

fastCmd14(){
	commandFastReply(Globals.Get("fR" 14))
}

fastCmd15(){
	commandFastReply(Globals.Get("fR" 15))
}

fastCmd16(){
	commandFastReply(Globals.Get("fR" 16))
}

fastCmd17(){
	commandFastReply(Globals.Get("fR" 17))
}

fastCmd18(){
	commandFastReply(Globals.Get("fR" 18))
}

fastCmd19(){
	commandFastReply(Globals.Get("fR" 19))
}

fastCmd20(){
	commandFastReply(Globals.Get("fR" 20))
}

/*
customCmdsEdit() {
	textFileWindow("", configFolder "\cmds.preset", false, "Список команд>>|/global 820`n/whois <last>`n/deaths`n/passives`n/atlaspassives`n/remaining`n/autoreply <inputbox>`n/autoreply`n---`n>calc`n>https://siveran.github.io/calc.html`n>https://poe.re/#/expedition`n>https://www.poewiki.net/wiki/Chat")
}
*/

;Обработка команды
commandFastReply(Line:="/dance"){
	If (Line="") || RegExMatch(Line, ";")=1
		return
	;DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	;sleep 25
	
	;Замена переменных
	If InStr(Line, "<configFolder>")
		Line:=StrReplace(Line, "<configFolder>", configFolder)
	If InStr(Line, "<presetFolder>")
		Line:=StrReplace(Line, "<presetFolder>", Globals.Get("presetFolder"))
	If InStr(Line, "<eventFolder>")
		Line:=StrReplace(Line, "<eventFolder>", configFolder "\Event")
	If InStr(Line, "<time>") {
		FormatTime, currentTime, %A_NowUTC%, HH:mm
		Line:=StrReplace(Line, "<time>", currentTime)
	}
	If InStr(Line, "<inputbox>") {
		InputBox, inputLine, Введите текст,,, 300, 100
		sleep 50
		Line:=StrReplace(Line, "<inputbox>", inputLine)
	}
	
	;Чат
	If (InStr(Line, "/")=1) || (InStr(Line, "%")=1) || (InStr(Line, "_")=1) {
		If (InStr(Line, "/")=1) && RegExMatch(Line, " <last>$") {
			Line:=StrReplace(Line, " <last>", " ")
			Clipboard:=Line
			Sleep 10
			BlockInput On
			SendInput, ^{Enter}{Home}{Delete}^{v}{Enter}
			BlockInput Off
			Sleep 1500
			return
		}
		If (InStr(Line, "_")=1)
			Line:=SubStr(Line, 2)
		Clipboard:=Line
		Sleep 10
		BlockInput On
		SendInput, {Enter}^{a}^{v}{Enter}
		BlockInput Off
		Sleep 1500
		return
	}
	
	/*
	If (InStr(Line, "/")=1) || (InStr(Line, "%")=1) {
		If (!InStr(Line, "%")=1 && RegExMatch(Line, " <last>$")) {
			Line:=StrReplace(Line, " <last>", "")
			BlockInput On
			SendInput, ^{Enter}{Home}{Delete}%Line% {Enter}
			BlockInput Off
		} Else {
			BlockInput On
			SendInput, {Enter}^a{Backspace}%Line%{Enter}
			BlockInput Off
		}
		return
	}
	If (InStr(Line, "_")=1) {
		Line:=SubStr(Line, 2)
		BlockInput On
		SendInput, {Enter}^a{Backspace}%Line%{Enter}
		BlockInput Off
		return
	}
	*/
	
	If (InStr(Line, "@<last> ")=1) {
		Line:=SubStr(Line, 9)
		Clipboard:=Line
		Sleep 10
		BlockInput On
		;SendInput, ^{Enter}%Line%{Enter}
		SendInput, ^{Enter}^{v}{Enter}
		BlockInput Off
		Sleep 1500
		return
	}
	
	;Всплывающая подсказка
	If (InStr(Line, "!")=1) {
		Line:=SubStr(Line, 2)
		showToolTip(Line, 120000)
		return
	}
	
	;Другое
	If (InStr(Line, ">")=1) {
		Line:=SubStr(Line, 2)
		run, %Line%
		return
	}
	If RegExMatch(Line, ".(png|jpg|jpeg|bmp|txt|list|fmenu)") {
		SplitImg:=StrSplit(Line, "|")
		if RegExMatch(SplitImg[1], ".(png|jpg|jpeg|bmp)$") {
			shOverlay(SplitImg[1], SplitImg[2], SplitImg[3])
			return
		}
		If RegExMatch(SplitImg[1], ".(txt|list)$") {
			textFileWindow("", SplitImg[1], false)
			return
		}
		If RegExMatch(SplitImg[1], ".fmenu$") {
			shFastMenu(SplitImg[1])
			return
		}
	}
	If RegExMatch(Line, ".(url|lnk)$") {
		;msgbox, %Line%
		Run "%Line%"
		return
	}
	TrayTip, %prjName% - Неизвестная команда!, %Line%
	;msgbox, 0x1010, %prjName%, %Line%`nНеизвестная команда!, 3
}

;Создание быстрого меню
shFastMenu(fastPath, editBtn=true) {
	destroyOverlay()
	fastMenu(fastPath, editBtn)
	Menu, fastMenu, Show
}

;Быстрое меню
fastMenu(fastPath, editBtn=true){
	destroyOverlay()
	Sleep 50
	Globals.Set("fastPath", fastPath)
	Globals.Set("fastData", loadFastFile(fastPath))
	Menu, fastMenu, Add
	Menu, fastMenu, DeleteAll
	dataSplit:=StrSplit(Globals.Get("fastData"), "`n")
	For k, val in dataSplit {
		If InStr(dataSplit[k], ";")=1
			Continue
		If InStr(dataSplit[k], "=") && !InStr(dataSplit[k], "|") || InStr(dataSplit[k], "[")=1
			Continue
		If (dataSplit[k]="---") {
			Menu, fastMenu, Add
			Continue
		}
		cmdInfo:=StrSplit(dataSplit[k], "|")
		cmdName:=cmdInfo[1]
		If (cmdInfo[1]!="")
			Menu, fastMenu, Add, %cmdName%, fastMenuCmd
	}
	If editBtn {
		SplitPath, fastPath, sName
		Menu, fastMenu, Add
		Menu, fastMenu, Add, Редактировать '%sName%', fastMenuEdit
	}
}

;Редактирование быстрого меню
fastMenuEdit(){
	filePath:=Globals.Get("fastPath")
	textFileWindow("", filePath, false)
}

;Выполнение команды из быстрого меню
fastMenuCmd(cmdName){
	Sleep 50
	dataSplit:=StrSplit(Globals.Get("fastData"), "`n")
	For k, val in dataSplit {
		cmdInfo:=StrSplit(dataSplit[k], "|")
		If (cmdName=cmdInfo[1] && cmdInfo[2]!="") {
			fastCmd:=SubStr(dataSplit[k], StrLen(cmdInfo[1])+2)
			commandFastReply(fastCmd)
			return
		}
	}
	commandFastReply(cmdName)
}

;Загрузить данные быстрого файла
loadFastFile(path){
	If !FileExist(path)
		return
	FileRead, fastData, %path%
	return StrReplace(fastData, "`r", "")
}
