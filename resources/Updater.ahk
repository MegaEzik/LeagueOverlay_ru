
CheckUpdate() {
	releaseinfo:=DownloadToVar("https://api.github.com/repos/" githubUser "/" prjName "/releases/latest")
	parsedJSON:=JSON.Load(releaseinfo)
	verRelease:=parsedJSON.tag_name	
	if (verRelease!="" && verScript!="" && verRelease>verScript) {
		TrayTip, %prjName%, Доступно обновление!
		return verRelease
	} else {
		return "noupdate"
	}
}

initCheckUpdate() {
	Menu, Tray, Add, Выполнить обновление, CheckUpdateFromMenu
	Menu, Tray, Add
}

CheckUpdateFromMenu(){
	statusUpdate:=CheckUpdate()
	if (statusUpdate="noupdate") {
		MsgBox, 0x40, %prjName%, Нет доступных обновлений!
	}
	else if (statusUpdate!="noupdate" && statusUpdate!="") {
		MsgBox, 0x24, %prjName%, Доступно обновление %statusUpdate%!`nВыполнить обновление до этой версии?
		IfMsgBox Yes
			StartUpdate(statusUpdate)
	}
}

StartUpdate(verRelease) {
	SplashTextOn, 250, 20, %prjName%, Выполняется обновление...
	zipArchive:=A_Temp "\" prjName ".zip"
	FileDelete, %zipArchive%
	sleep 50
	newVersionURL:="https://github.com/" githubUser "/" prjName "/releases/download/" verRelease "/" prjName ".zip"
	UrlDownloadToFile, %newVersionURL%, %A_Temp%\%prjName%.zip
	sleep 50	
	IfExist %zipArchive%
	{
		FileRemoveDir, %A_ScriptDir%, 1
		sleep 3000
		FileCreateDir, %A_ScriptDir%
		sleep 50
		unZipArchive(A_Temp "\" prjName ".zip", A_ScriptDir "\")
		sleep 2000
		Reload
	}
	SplashTextOff
}

DownloadToVar(URL) {
	HTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")	; https://msdn.microsoft.com/en-us/library/windows/desktop/aa384106(v=vs.85).aspx
	HTTP.Open("GET", URL)
	HTTP.Send()
	HTTP.WaitForResponse()
	Return HTTP.ResponseText
}

unZipArchive(ArcPath, OutPath) {
	IfNotExist %OutPath%
	{
		FileCreateDir, %OutPath%
	}	
	Shell := ComObjCreate("Shell.Application")
	Items := Shell.NameSpace(ArcPath).Items
	Items.Filter(73952, "*")
	Shell.NameSpace(OutPath).CopyHere(Items, 16)
}
