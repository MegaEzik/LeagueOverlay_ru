
pkgsMgr_packagesMenu(){
	FilePath:="resources\Packages.txt"
	LoadFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/resources/Packages.txt", FilePath, true)
	
	Menu, packagesMenu, Add
	Menu, packagesMenu, DeleteAll
	Menu, packagesMenu, Add, + из файла, pkgsMgr_fromFile
	Menu, packagesMenu, Add, + по URL, pkgsMgr_fromURL
	Menu, packagesMenu, Add
	
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			PackName:=PackInfo[1]
			If (RegExMatch(PackName, ";")!=1)
				Menu, packagesMenu, Add, + %PackName%, pkgsMgr_loadPackage
		}
	}
	Menu, packagesMenu, Add
	
	Loop, %configFolder%\*.ahk, 1
	{
		Menu, packagesMenu, Add, %A_LoopFileName%, permissionsCustomScript
		
		IniRead, MD5, %configFolder%\pkgsMgr.ini, pkgsMgr, %A_LoopFileName%, %A_Space%
		MD5File:=MD5_File(configFolder "\" A_LoopFileName)
		If (MD5=MD5File)
			Menu, packagesMenu, Check, %A_LoopFileName%
	}
	Menu, packagesMenu, Add
	
	
	Loop, %configFolder%\*.ahk, 1
		Menu, packagesMenu, Add, × %A_LoopFileName%, pkgsMgr_delPackage
	
	Loop, %configFolder%\Presets\*, 2
		Menu, packagesMenu, Add, × *%A_LoopFileName%, pkgsMgr_delPackage
		
	
	Menu, packagesMenu, Show
}

pkgsMgr_loadPackage(Name){
	Name:=SubStr(Name, 3)
	FilePath:="resources\Packages.txt"
	FileRead, Data, %FilePath%
	DataSplit:=strSplit(StrReplace(Data, "`r", ""), "`n")
	For k, val in DataSplit {
		If inStr(DataSplit[k], "|") {
			PackInfo:=StrSplit(DataSplit[k], "|")
			If (PackInfo[1]=Name && PackInfo[2]!="") {
				If !LoadFile(PackInfo[2], A_Temp "\" PackInfo[1],, PackInfo[3]) {
					TrayTip, %prjName%, Ошибка загрузки '%Name%'!
					return
				}
				pkgsMgr_installPackage(A_Temp "\" PackInfo[1])
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
	If (RegExMatch(fileURL, "i)https://")!=1) || !LoadFile(fileURL,  A_Temp "\" fileName) {
		TrayTip, %prjName%, Ошибка загрузки '%fileName%'!
		return
	}
	pkgsMgr_installPackage(A_Temp "\" fileName)
}

pkgsMgr_installPackage(FilePath){
	If (FilePath="" || !FileExist(FilePath)) {
		msgtext:="Файл не найден, операция прервана!"
		msgbox, 0x1010, %prjName%, %msgtext%, 3
		return
	}
	SplitPath, FilePath, Name
	If RegExMatch(FilePath, "i).(jpg|jpeg|bmp|png|txt|fmenu)$") {
		FileCopy, %FilePath%, %configFolder%\MyFiles\%Name%, 1
	}
	If RegExMatch(FilePath, "i).upd.zip$") {
		unZipArchive(FilePath, A_ScriptDir)
		ReStart()
	}
	If RegExMatch(FilePath, "i).zip$") {
		unZipArchive(FilePath, configFolder)
	}
	If RegExMatch(FilePath, "i).ahk$") {
		FileCopy, %FilePath%, %configFolder%\%Name%, 1
	}
	AHKFile:=RegExReplace(name, "i).zip$", ".ahk")
	If RegExMatch(AHKFile, "i).ahk$") && FileExist(configFolder "\" AHKFile) {
		IniDelete, %configFolder%\pkgsMgr.ini, pkgsMgr, %AHKFile%
		Sleep 50
		permissionsCustomScript(AHKFile)
		ReStart()
	}
	TrayTip, %prjName%, Дополнение '%Name%' установлено!
}

pkgsMgr_delPackage(Name){
	If inStr(Name, "*")=3 {
		Name:=SubStr(Name, 4)
		FileRemoveDir, %configFolder%\Presets\%Name%, 1
		return
	}
	
	If RegExMatch(Name, "i).ahk$") {
		Name:=SubStr(RegExReplace(Name, "i).ahk$", ""), 3)
		IniDelete, %configFolder%\pkgsMgr.ini, pkgsMgr, %Name%.ahk
		FileDelete, %configFolder%\%Name%.ahk
		FileRemoveDir, %configFolder%\%Name%, 1
		Sleep 1000
		ReStart()
	}
}

pkgsMgr_startCustomScripts(){
	Loop, %configFolder%\*.ahk, 1
		pkgMgr_checkScript(configFolder "\" A_LoopFileName)
}

pkgMgr_checkScript(ScriptPath){
	If RegExMatch(args, "i)/NoAddons")
		return
	SplitPath, ScriptPath, ScriptName
	IniRead, MD5, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%, %A_Space%
	MD5File:=MD5_File(ScriptPath)
	If (MD5!=MD5File)
		return
	RunWait *RunAs "%A_AhkPath%" "%ScriptPath%" "%A_ScriptDir%"
}

permissionsCustomScript(ScriptName){
	IniRead, MD5, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%, %A_Space%
	MD5File:=MD5_File(configFolder "\" ScriptName)
	If (MD5!=MD5File) {
		msgbox, 0x1024, %prjName%, Разрешить автозапуск '%ScriptName%'?
		IfMsgBox No
			return
		IniWrite, %MD5File%, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%
		;RunWait *RunAs "%A_AhkPath%" "%configFolder%\%ScriptName%" "%A_ScriptDir%"
	} else {
		IniDelete, %configFolder%\pkgsMgr.ini, pkgsMgr, %ScriptName%
		TrayTip, %ScriptName%, Разрешение на автозапуск отозвано!
	}
}
