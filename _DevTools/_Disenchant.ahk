#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

FileRead, DataText, Disenchant.txt

DataText:=StrReplace(DataText, "`r", "")

FileDelete, NewDisenchant.txt
Sleep 500

SplitData:=StrSplit(DataText, "`n")
For k, val in SplitData {
	curtext:=SplitData[k]
	If RegExMatch(SplitData[k], "U)(.*)`t(.*)`t", res) {
		NewLine:=" """ res1 """: """ res2 """,`n"
		FileAppend, %NewLine%, NewDisenchant.txt, UTF-8
		;msgbox, %curtext%`n%res1%`n%res2%
	}
}

ExitApp
