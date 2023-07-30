
pkgsMgr_packagesMenu(){
	FilePath:="Data\Packages.txt"
	LoadFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/Data/Packages.txt", FilePath, true)
	
	Menu, packagesMenu, Add
	Menu, packagesMenu, DeleteAll
	Menu, packagesMenu, Add, Установка из файла, pkgsMgr_fromFile
	Menu, packagesMenu, Add, Загрузить по ссылке, pkgsMgr_fromURL
	Menu, packagesMenu, Add
	
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			PackName:=PackInfo[1]
			If (RegExMatch(PackName, ";")!=1)
				Menu, packagesMenu, Add, Загрузить '%PackName%', pkgsMgr_loadPackage
		}
	}
	
	Menu, packagesMenu, Add
	
	Loop, %configFolder%\*.ahk, 1
	{
		Menu, packagesMenu, Add, Автозапуск '%A_LoopFileName%', pkgMgr_permissionsCustomScript
		
		IniRead, AutoStart, %configFolder%\pkgsMgr.ini, pkgsMgr, %A_LoopFileName%, 0
		If AutoStart
			Menu, packagesMenu, Check, Автозапуск '%A_LoopFileName%'
	}
	
	If RegExMatch(args, "i)/EnableAutolinks") {
		Loop, %configFolder%\*.lnk, 1
		{
			Menu, packagesMenu, Add, Автозапуск '%A_LoopFileName%', pkgMgr_delLink
			Menu, packagesMenu, Check, Автозапуск '%A_LoopFileName%'
		}
		Menu, packagesMenu, Add, Создать ссылку для автозапуска, pkgsMgr_addLink
	}
	
	Menu, packagesMenu, Add
		
	Loop, %configFolder%\*.ahk, 1
		Menu, packagesMenu, Add, Удалить '%A_LoopFileName%', pkgsMgr_delPackage
	
	Menu, packagesMenu, Show
}

pkgsMgr_loadPackage(Name){
	;Name:=SubStr(Name, 3)
	Name:=searchName(Name)
	FilePath:="Data\Packages.txt"
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			If (PackInfo[1]=Name && PackInfo[2]!="") {
				If !LoadFile(PackInfo[2], A_Temp "\MegaEzik\" PackInfo[1]) {
					TrayTip, %prjName%, Ошибка загрузки '%Name%'!
					return
				}
				pkgsMgr_installPackage(A_Temp "\MegaEzik\" PackInfo[1])
			}
		}
	}
	return
}

pkgsMgr_fromFile(){
	FileSelectFile, FilePath,,,Укажите файл с дополнением, (*.zip;*.ahk;*.txt;*.fmenu;*.jpg;*.png;*jpeg;*bmp)
	pkgsMgr_installPackage(FilePath)
}

pkgsMgr_fromURL(){
	InputBox, fileURL, Укажите URL,,, 300, 100
	SplitPath, fileURL, fileName
	If (RegExMatch(fileURL, "i)https://")!=1) || !LoadFile(fileURL,  A_Temp "\MegaEzik\" fileName) {
		TrayTip, %prjName%, Ошибка загрузки '%fileName%'!
		return
	}
	pkgsMgr_installPackage(A_Temp "\MegaEzik\" fileName)
}

pkgsMgr_installPackage(FilePath){
	If (FilePath="" || !FileExist(FilePath)) {
		msgtext:="Файл не найден, операция прервана!"
		TrayTip, %prjName%, %msgtext%
		;msgbox, 0x1010, %prjName%, %msgtext%, 3
		return
	}
	SplitPath, FilePath, Name
	If RegExMatch(FilePath, "i).(jpg|jpeg|bmp|png|txt|fmenu)$") {
		FileCopy, %FilePath%, %configFolder%\MyFiles\%Name%, 1
	}
	If RegExMatch(FilePath, "i).upd.zip$") {
		unZipArchive(FilePath, A_ScriptDir)
		;ReStart()
	}
	If RegExMatch(FilePath, "i).zip$") {
		unZipArchive(FilePath, configFolder)
	}
	If RegExMatch(FilePath, "i).ahk$") {
		FileCopy, %FilePath%, %configFolder%\%Name%, 1
	}
	TrayTip, %prjName%, Дополнение '%Name%' установлено!
}

pkgsMgr_delPackage(Name){
	Name:=RegExReplace(searchName(Name), "i).ahk$", "")
	Msgbox, %Name%
	FileDelete, %configFolder%\%Name%.ahk
	FileRemoveDir, %configFolder%\%Name%, 1
	Sleep 500
	;ReStart()
}

pkgsMgr_startCustomScripts(){
	If RegExMatch(args, "i)/NoAddons")
		return
	If RegExMatch(args, "i)/EnableAutolinks")
		Loop, %configFolder%\*.lnk, 1
			Run *RunAs "%configFolder%\%A_LoopFileName%"
	Loop, %configFolder%\*.ahk, 1
		pkgMgr_runScript(configFolder "\" A_LoopFileName)
}

pkgMgr_runScript(ScriptPath){
	SplitPath, ScriptPath, ScriptName
	IniRead, AutoStart, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%, 0
	If AutoStart && RegExMatch(ScriptPath, "i).ahk$")
		RunWait *RunAs "%A_AhkPath%" "%ScriptPath%" "%A_ScriptDir%"
}

pkgMgr_permissionsCustomScript(ScriptName){
	ScriptName:=searchName(ScriptName)
	IniRead, AutoStart, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%, 0
	If AutoStart {
		IniDelete, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%
	} Else {
		IniWrite, 1, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%
	}
}

pkgsMgr_addLink(){
	FileSelectFile, TargetPath,,, Укажите путь к файлу для автозапуска
		If (TargetPath="")
			Return
		
		SplitPath, TargetPath, Name
		FileCreateShortcut, %TargetPath%, %configFolder%\%Name%.lnk
}

pkgMgr_delLink(Name){
	Name:=searchName(Name)
	FileDelete, %configFolder%\%Name%
}
