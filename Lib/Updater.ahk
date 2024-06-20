
;Проверка обновлений
StatusUpdate() {
	releaseinfo:=DownloadToVar("https://api.github.com/repos/" githubUser "/" prjName "/releases/latest")
	parsedJSON:=JSON.Load(releaseinfo)
	verRelease:=parsedJSON.tag_name
	If (verRelease="" || verScript="" || verRelease<=verScript)
		Return False
	TrayTip, %prjName%, Доступно обновление %verRelease%!
	Return verRelease
}

CheckUpdate(onStart=False){
	ReadyUpdate:=StatusUpdate()
	If (ReadyUpdate && onStart) {
		MsgBox, 0x1024, %prjName%, Установлена версия: %verScript%`nДоступна версия: %ReadyUpdate%`n`nХотите выполнить обновление до версии %ReadyUpdate%?
		IfMsgBox Yes
			StartUpdate(ReadyUpdate)
	}
}

;Запуск процесса обновления
StartUpdate(verRelease) {
	SplashTextOn, 400, 20, %prjName%, Выполняется обновление, пожалуйста подождите...
	FileCreateDir, %A_Temp%\MegaEzik
	zipArchive:=A_Temp "\MegaEzik\" prjName ".zip"
	FileDelete, %zipArchive%
	sleep 25
	newVersionURL:="https://github.com/" githubUser "/" prjName "/releases/download/" verRelease "/" prjName ".zip"
	UrlDownloadToFile, %newVersionURL%, %zipArchive%
	sleep 25	
	IfExist %zipArchive%
	{
		FileRemoveDir, %A_ScriptDir%, 1
		sleep 1000
		FileCreateDir, %A_ScriptDir%
		sleep 25
		unZipArchive(zipArchive, A_ScriptDir "\")
		sleep 500
		FileDelete, %zipArchive%
		Reload
	}
	SplashTextOff
}

;Получение данных от api в переменную
DownloadToVar(URL) {
	FileCreateDir, %A_Temp%\MegaEzik
	FilePath:=A_Temp "\MegaEzik\JSONData.json"
	UrlDownloadToFile, %URL%, %FilePath%
	sleep 25
	FileRead, Result, %FilePath%
	sleep 25
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
