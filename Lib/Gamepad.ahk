﻿
shGamepadMenu(){
	IniRead, hotkeyGamepad, %configFile%, hotkeys, hotkeyGamepad, %A_Space%
	destroyOverlay()
	Loop 10 {
		GetKeyState, MyJoy, %hotkeyGamepad%
		If (MyJoy!="D")
			return
		Sleep 25
	}
	shLastImage()
	Loop 20 {
		GetKeyState, MyJoy, %hotkeyGamepad%
		If (MyJoy!="D")
			return
		Sleep 25
	}
	
	WinGetPos,,,PosW,,A
	MouseMove, round(PosW*0.40), 0, 0
	
	Run *RunAs "%A_AhkPath%" Data\PseudoMouse.ahk %hotkeyGamepad%,,, PseudoMousePID
	shMainMenu(true)
	Run *RunAs TASKKILL.EXE /PID %PseudoMousePID% /F,, hide
	;MouseMove, 10, 10, 0
	;Run *RunAs "%A_AhkPath%" Data\PseudoMouse.ahk
}

cfgGamepad(){
	Gui, Settings:Destroy
	SetTimer, setHotkeyGamepad, 500
}

setHotkeyGamepad(){
	Loop 16 {
		GetKeyState, JName, %A_Index%JoyName
		If (JName!="")
			JID:=A_Index
	}
	
	If (JID="") {
		SetTimer, setHotkeyGamepad, Delete
		TrayTip, %prjName%, Игровой контроллер не обнаружен!
		;msgbox, 0x1010, %prjName%, Игровой контроллер не обнаружен!, 3
		Return
	}
	
	showToolTip("Удерживайте желаемую кнопку на Игровом контроллере " JID "!`n`nРекомендую назначить кнопку View/Back/Search[Joy7]`nНа контроллере XBox можно назначить кнопку Guide[vk07]`n`nДля выхода из настройки удерживайте [Esc] на клавиатуре")
	hotkeyGamepad:=""
	Loop 32 {
		GetKeyState, currentJoy, %JID%Joy%A_Index%
		If (currentJoy="D")
			hotkeyGamepad:=JID "Joy" A_Index
	}
	GetKeyState, currentJoy, vk07
	If (currentJoy="D")
		hotkeyGamepad:="vk07"
	GetKeyState, statusEsc, Esc
		
	If ((hotkeyGamepad!="") || (statusEsc="D")) {
		SetTimer, setHotkeyGamepad, Delete
		removeToolTip()
		msgbox, 0x1024, %prjName%, Вы хотите назначить [%hotkeyGamepad%]?
		IfMSgBox Yes
		{
			IniWrite, %hotkeyGamepad%, %configFile%, hotkeys, hotkeyGamepad
			ReStart()
		}
		Return
	}
}
