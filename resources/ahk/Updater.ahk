
;Проверка обновлений
CheckUpdate() {
	releaseinfo:=DownloadToVar("https://api.github.com/repos/" githubUser "/" prjName "/releases/latest")
	parsedJSON:=JSON.Load(releaseinfo)
	verRelease:=parsedJSON.tag_name
	if (verVar(verRelease)!="" && verVar(verScript)!="" && verVar(verRelease)>verVar(verScript)) {
		TrayTip, %prjName%, Доступна версия %verRelease%!
		return verRelease
	} else {
		return "noupdate"
	}
}

;Функция проверки из меню
CheckUpdateFromMenu(PressedBtn=""){
	statusUpdate:=CheckUpdate()
	if (statusUpdate="noupdate" && PressedBtn!="onStart") {
		TrayTip, %prjName%, Вы используете актуальную версию)
	}
	else if (statusUpdate!="noupdate" && statusUpdate!="") {
		MsgBox, 0x1024, %prjName%, Установлена версия: %verScript%`nДоступна версия: %statusUpdate%`n`nХотите выполнить обновление до версии %statusUpdate%?
		IfMsgBox Yes
			StartUpdate(statusUpdate)
	}
}

;Запуск процесса обновления
StartUpdate(verRelease) {
	SplashTextOn, 400, 20, %prjName%, Выполняется обновление...
	zipArchive:=A_Temp "\" prjName "-Update.zip"
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

;Извлечем версию из строки
verVar(vLine){
	If RegExMatch(vLine, "(\d+.\d+)", vVar)
		return vVar1
	return ""
}

;Получение данных от api в переменную
DownloadToVar(URL) {
	FilePath:=A_Temp "\" prjName "-JSONData.json"
	UrlDownloadToFile, %URL%, %FilePath%
	sleep 25
	FileRead, Result, %FilePath%
	sleep 25
	FileDelete, %FilePath%
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
