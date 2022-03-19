#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

global args
Loop, %0%
	args.=" " %A_Index%
msgbox, %args%

Menu, devMenu, Add
Menu, devMenu, DeleteAll
Menu, devMenu, Add, XBox, runGamepadXBox	
Menu, devMenu, Add, PS, runGamepadPS
Menu, devMenu, Show

runGamepadXBox(){
	Run *RunAs run_LeagueOverlay.ahk /GamepadXBox %args%
	ExitApp
}

runGamepadPS(){
	Run *RunAs run_LeagueOverlay.ahk /GamepadPS %args%
	ExitApp
}