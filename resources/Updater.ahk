
;Проверка обновлений
CheckUpdate() {
	releaseinfo:=DownloadToVar("https://api.github.com/repos/" githubUser "/" prjName "/releases/latest")
	parsedJSON:=JSON.Load(releaseinfo)
	verRelease:=parsedJSON.tag_name
	if (verRelease!="" && verScript!="" && verRelease>verScript) {
		TrayTip, %prjName%, Доступна новая версия!
		return verRelease
	} else {
		return "noupdate"
	}
}

;Функция проверки из меню
CheckUpdateFromMenu(PressedBtn=""){
	statusUpdate:=CheckUpdate()
	if (statusUpdate="noupdate" && PressedBtn!="onStart") {
		MsgBox, 0x1040, %prjName%, Новых версий %prjName% не найдено!
	}
	else if (statusUpdate!="noupdate" && statusUpdate!="") {
		MsgBox, 0x1024, %prjName%, Установленная версия не совпадает с тэгом на GitHub!`n`nУстановлена версия: %verScript%`nВерсия на GitHub: %statusUpdate%`n`nУстановить последнюю версию с GitHub?
		IfMsgBox Yes
			StartUpdate(statusUpdate)
	}
}

;Запуск процесса обновления
StartUpdate(verRelease) {
	SplashTextOn, 250, 20, %prjName%, Выполняется обновление...
	zipArchive:=A_Temp "\" prjName "-Update.zip"
	FileDelete, %zipArchive%
	sleep 35
	newVersionURL:="https://github.com/" githubUser "/" prjName "/releases/download/" verRelease "/" prjName ".zip"
	UrlDownloadToFile, %newVersionURL%, %zipArchive%
	sleep 35	
	IfExist %zipArchive%
	{
		FileRemoveDir, %A_ScriptDir%, 1
		sleep 1000
		FileCreateDir, %A_ScriptDir%
		sleep 35
		unZipArchive(zipArchive, A_ScriptDir "\")
		sleep 500
		FileDelete, %zipArchive%
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
