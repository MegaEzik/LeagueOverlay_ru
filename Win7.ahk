
#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

If !A_IsAdmin {
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%" %args%
	ExitApp
}

OSBuild:=DllCall("GetVersion") >> 16 & 0xFFFF        
If (OSBuild!=7601) {
	MsgBox, 0x1010, %prjName%, У вас не Windows 7 Service Pack 1!
	ExitApp
}

If !FileExist(A_WinDir "\System32\curl.exe") {
	SplashTextOn, 400, 20,, Загрузка утилиты 'curl.exe'...
	FileDelete, %A_Temp%\curl.zip
	UrlDownloadToFile, https://github.com/MegaEzik/LeagueOverlay_ru/releases/download/210520.5/curl32.zip, %A_Temp%\curl.zip
	unZipArchive(A_Temp "\curl.zip", A_WinDir "\System32\")
	FileDelete, %A_Temp%\curl.zip
	Sleep 1000
	Reload
}

If FileExist("run_LeagueOverlay.ahk")
	Run *RunAs "%A_AhkPath%" run_LeagueOverlay.ahk /BypassSystemCheck

Return

unZipArchive(ArcPath, OutPath) {
	Shell := ComObjCreate("Shell.Application")
	Items := Shell.NameSpace(ArcPath).Items
	Items.Filter(73952, "*")
	Shell.NameSpace(OutPath).CopyHere(Items, 16)
}
