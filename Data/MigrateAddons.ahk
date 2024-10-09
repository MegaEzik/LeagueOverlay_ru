#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

configFolder:=A_MyDocuments "\AutoHotKey\LeagueOverlay_ru"
AHKPath:=A_Args[1]

If (AHKPath="")
	ExitApp
	
SplashTextOn, 200, 20,, Please wait...

RunWait, "%A_WinDir%\System32\taskkill.exe" /F /IM AutoHotkey.exe
RunWait, "%A_WinDir%\System32\taskkill.exe" /F /IM AutoHotkeyU64.exe

If InStr(FileExist(configFolder "\ruPrediction"), "D"){
	FileRemoveDir, %configFolder%\ruPrediction, 1
	FileDelete, %configFolder%\ruPrediction.ahk
}

If InStr(FileExist(configFolder "\HeistScanner"), "D"){
	FileRemoveDir, %configFolder%\HeistScanner, 1
	FileDelete, %configFolder%\HeistScanner.ahk
	UrlDownloadToFile, https://raw.githubusercontent.com/MegaEzik/PoE_HeistScanner_ru/main/HeistScanner.ahk, %configFolder%\Scripts\HeistScanner.ahk
}

Loop, %configFolder%\*.ahk, 1
{	
	ScriptName:=RegExReplace(A_LoopFileName, ".ahk$","")
	FileMoveDir, %configFolder%\%ScriptName%, %configFolder%\Scripts\%ScriptName%, 1
	FileMove, %configFolder%\%ScriptName%.ahk, %configFolder%\Scripts\%ScriptName%.ahk, 1
}

FileDelete, %configFolder%\pkgsMgr.ini

Sleep 1000

Run %AHKPath%
ExitApp
