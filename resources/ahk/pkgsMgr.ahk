
pkgsMgr_packagesMenu(){
	Menu, packagesMenu, Add, Добавить из файла, pkgsMgr_fromFile
	Menu, packagesMenu, Add
	
	FilePath:="resources\Packages.txt"
	IniRead, updateResources, %configFile%, settings, updateResources, 0
	If updateResources
		LoadFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/resources/Packages.txt", FilePath, true)
	
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
		PackName:=RegExReplace(A_LoopFileName, ".ahk$", "")
		Menu, packagesMenu, Add, × %PackName%, pkgsMgr_delPackage
	}
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
					msgbox, 0x1010, %prjName%, Ошибка загрузки '%Name%'!, 3
					return
				}
				pkgsMgr_installPackage(A_Temp "\" PackInfo[1])
			}
		}
	}
	return
}

pkgsMgr_fromFile(){
	FileSelectFile, FilePath,,,Укажите файл с дополнением, (*.zip;*.ahk;*.txt;*.preset;*.jpg;*.png;*jpeg;*bmp)
	pkgsMgr_installPackage(FilePath)
}

pkgsMgr_installPackage(FilePath){
	If (FilePath="" || !FileExist(FilePath)) {
		msgtext:="Файл не найден, операция прервана!"
		msgbox, 0x1010, %prjName%, %msgtext%, 3
		return
	}
	SplitPath, FilePath, Name
	If RegExMatch(FilePath, "i).(jpg|jpeg|bmp|png|txt)$") {
		FileCopy, %FilePath%, %configFolder%\MyFiles\%Name%, 1
	}
	If RegExMatch(FilePath, "i).preset$") {
		FileCopy, %FilePath%, %configFolder%\presets\%Name%, 1
	}
	If RegExMatch(FilePath, "i).ahk$") {
		FileCopy, %FilePath%, %configFolder%\%Name%, 1
		ReStart()
	}
	If RegExMatch(FilePath, "i).zip$") {
		unZipArchive(FilePath, configFolder)
		NameAHK:=RegExReplace(Name, "i).zip$", ".ahk")
		If FileExist(configFolder "\" NameAHK)
			ReStart()
	}
	TrayTip, %prjName%, Дополнение '%Name%' установлено!
}

pkgsMgr_delPackage(Name){
	Name:=SubStr(Name, 3)
	IniWrite, %A_Space%, %configFile%, pkgsMgr, %Name%.ahk
	FileDelete, %configFolder%\%Name%.ahk
	FileDelete, %configFolder%\presets\%Name%.preset
	FileRemoveDir, %configFolder%\%Name%, 1
	FileRemoveDir, %configFolder%\presets\%Name%, 1
	Sleep 1000
	ReStart()
}

pkgsMgr_startCustomScripts(){
	If RegExMatch(args, "i)/NoAddons")
		return
	Loop, %configFolder%\*.ahk, 1
	{
		IniRead, MD5, %configFile%, pkgsMgr, %A_LoopFileName%, %A_Space%
		MD5File:=MD5_File(configFolder "\" A_LoopFileName)
		If (MD5!=MD5File)
			msgbox, 0x1024, %prjName%, Разрешить выполнять '%A_LoopFileName%'?
			IfMsgBox No
				Continue
		IniWrite, %MD5File%, %configFile%, pkgsMgr, %A_LoopFileName%
		RunWait *RunAs "%A_AhkPath%" "%configFolder%\%A_LoopFileName%" "%A_ScriptDir%"
	}
}
