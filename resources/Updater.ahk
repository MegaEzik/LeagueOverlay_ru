
;Проверка обновлений
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

;Функция проверки из меню
CheckUpdateFromMenu(){
	statusUpdate:=CheckUpdate()
	if (statusUpdate="noupdate") {
		MsgBox, 0x1040, %prjName%, Нет доступных обновлений!
	}
	else if (statusUpdate!="noupdate" && statusUpdate!="") {
		MsgBox, 0x1024, %prjName%, Доступно обновление %statusUpdate%!`nВыполнить обновление до этой версии?
		IfMsgBox Yes
			StartUpdate(statusUpdate)
	}
}

;Запуск процесса обновления
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

;Получение данных от api в переменную
DownloadToVar(URL) {
	FilePath:=A_Temp "\" prjName "-JSONData.json"
	UrlDownloadToFile, %URL%, %FilePath%
	sleep 35
	FileRead, Result, %FilePath%
	sleep 35
	FileDelete, %FilePath%
	sleep 35
	return Result
}

;Распаковать указанный архив в указанную папку
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
