
pkgsMgr_packagesMenu(){
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
				Name:=RegExReplace(Name, ".(pkg|zip|img|txt)$", "")
				If RegExMatch(PackInfo[2], ".(jpg|jpeg|bmp|png|txt)$", ftype){
					LoadFile(PackInfo[2], configFolder "\MyFiles\" Name ftype)
					TrayTip, %prjName%, Файл '%Name%%ftype%' загружен!
					return
				}
				If RegExMatch(Name, ".ahk$") && RegExMatch(PackInfo[2], ".ahk$"){
					LoadFile(PackInfo[2], configFolder "\" Name)
					ReStart()
					return
				}
				If (PackInfo[3]!="") {
					If LoadFile(PackInfo[2], A_Temp "\Package.zip", false, PackInfo[3]) {
						unZipArchive(A_Temp "\Package.zip", configFolder)
						If FileExist(configFolder "\" Name ".ahk")
							ReStart()
						Sleep 500
						TrayTip, %prjName%, Пакет '%Name%' установлен!
						return
					} else {
						TrayTip, %prjName%, Возникла ошибка при установке пакета!
						return
					}
				}
			}
		}
	}
	return
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
	If RegExMatch(args, "i)/DisableAddons")
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
