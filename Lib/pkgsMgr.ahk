﻿
pkgsMgr_packagesMenu(){
	Gui, Settings:Destroy
	
	Menu, packagesMenu, Add
	Menu, packagesMenu, DeleteAll
	Menu, packagesMenu, Add, Установка из файла, pkgsMgr_fromFile
	Menu, packagesMenu, Add, Загрузить по ссылке, pkgsMgr_fromURL
	Menu, packagesMenu, Add
	
	FilePath:="Data\Addons.ini"
	IniRead, AddonsURL, %buildConfig%, settings, AddonsURL, %A_Space%
	If (AddonsURL!="")
		LoadFile(AddonsURL, FilePath, true)
	
	IniRead, AddonsData, %FilePath%, AddonsList
	;MsgBox, %SpecialNamesList%
	NewAddons:=StrSplit(AddonsData, "`n")
	For k, val in NewAddons {
		If RegExMatch(NewAddons[k], "^;")
			Continue
		AddonInfo:=StrSplit(NewAddons[k], "=")
		AddonName:=AddonInfo[1]
		Menu, packagesMenu, Add, Загрузить '%AddonName%', pkgsMgr_loadAddon
	}
	
	Loop, %configFolder%\Scripts\*.ahk, 1
		pkgsMgr_addonMenu(A_LoopFileName)
	
	Menu, packagesMenu, Show
}

pkgsMgr_addonMenu(FileName){
	Menu, packagesMenu, Add
	Menu, packagesMenu, Add, Выполнить '%FileName%', pkgsMgr_runPackage
	Menu, packagesMenu, Add, Автозапуск '%FileName%', pkgMgr_permissionsCustomScript
	IniRead, AutoStart, %configFile%, Addons, %FileName%, 0
	If AutoStart
		Menu, packagesMenu, Check, Автозапуск '%FileName%'
	Menu, packagesMenu, Add, Удалить '%FileName%', pkgsMgr_delPackage
}

pkgsMgr_loadAddon(AddonName) {
	AddonName:=searchName(AddonName)
	AddonsListPath:="Data\Addons.ini"
	IniRead, AddonURL, %AddonsListPath%, AddonsList, %AddonName%, %A_Space%
	IniRead, Description, %AddonsListPath%, Description, %AddonName%, %A_Space%
	
	MsgText:=(Description!="")?StrReplace(Description, "/n", "`n") "`n`n":""
	MsgText.="Установить дополнение '" AddonName "'?"
	
	MsgBox, 0x1044, %prjName% - %AddonName%, %MsgText%
	IfMsgBox No
		Return
	
	If !LoadFile(AddonURL, tempDir "\" AddonName) {
		TrayTip, %prjName%, Ошибка загрузки '%Name%'!
		return
	}
	pkgsMgr_installPackage(tempDir "\" AddonName)
	
	/*
	AHKName:=RegExReplace(AddonName, ".(ahk|zip)$", ".ahk")
	If RegExMatch(AHKName, ".ahk$") && FileExist(configFolder "\Scripts\" AHKName) {
		IniWrite, 1, %configFile%, Addons, %AHKName%
		pkgsMgr_runPackage(AHKName)
		;Msgbox, %AHKName%`n%AddonName%
	}
	*/
	
	FileDelete, %tempDir%\%AddonName%
}

pkgsMgr_fromFile(){
	FileSelectFile, FilePath,,,Укажите файл с дополнением, (*.zip;*.ahk;*.txt;*.fmenu;*.jpg;*.png;*jpeg;*bmp)
	pkgsMgr_installPackage(FilePath)
}

pkgsMgr_fromURL(){
	InputBox, fileURL, Укажите URL,,, 500, 100
	SplitPath, fileURL, fileName
	If (RegExMatch(fileURL, "i)https://")!=1) || !LoadFile(fileURL,  tempDir "\" fileName) {
		TrayTip, %prjName%, Ошибка загрузки '%fileName%'!
		return
	}
	pkgsMgr_installPackage(tempDir "\" fileName)
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
		ReStart()
	}
	If RegExMatch(FilePath, "i).zip$") {
		;unZipArchive(FilePath, configFolder "\Scripts")
		FileRemoveDir, %tempDir%\NewAddon, 1
		Sleep 100
		newPresetName:=RegExReplace(Name, ".zip$", "")
		unZipArchive(FilePath, tempDir "\NewAddon")
		If FileExist(tempDir "\NewAddon\PresetConfig.ini") {
			FileCopyDir, %tempDir%\NewAddon, %configFolder%\Presets\%newPresetName%, 1
		} else {
			FileCopyDir, %tempDir%\NewAddon, %configFolder%\Scripts, 1
		}
		FileRemoveDir, %tempDir%\NewAddon, 1
	}
	If RegExMatch(FilePath, "i).ahk$") {
		FileCopy, %FilePath%, %configFolder%\Scripts\%Name%, 1
	}
	TrayTip, %prjName%, Дополнение '%Name%' установлено!
}

pkgsMgr_delPackage(Name){
	Name:=RegExReplace(searchName(Name), "i).ahk$", "")
	msgbox, 0x1024, %prjName%, Удалить дополнение '%Name%'?
	IfMsgBox No
		return
	IniDelete, %configFile%, Addons, %Name%.ahk
	FileDelete, %configFolder%\Scripts\%Name%.ahk
	FileRemoveDir, %configFolder%\Scripts\%Name%, 1
	Sleep 500
	;ReStart()
}

pkgsMgr_runPackage(Name){
	ScriptName:=searchName(Name)
	If RegExMatch(ScriptName, ".ahk$")
		Run *RunAs "%A_AhkPath%" "%configFolder%\Scripts\%ScriptName%" "%A_ScriptDir%"
}

pkgsMgr_startCustomScripts(){
	If RegExMatch(args, "i)/NoAddons")
		return
	Loop, %configFolder%\Scripts\*.ahk, 1
		pkgMgr_runScript(configFolder "\Scripts\" A_LoopFileName)
}

pkgMgr_runScript(ScriptPath){
	SplitPath, ScriptPath, ScriptName
	IniRead, AutoStart, %configFile%, Addons, %ScriptName%, 0
	If AutoStart && RegExMatch(ScriptPath, "i).ahk$")
		RunWait *RunAs "%A_AhkPath%" "%ScriptPath%" "%A_ScriptDir%"
}



pkgMgr_permissionsCustomScript(ScriptName){
	ScriptName:=searchName(ScriptName)
	/*
	If GetKeyState("Ctrl", P) {
		Run *RunAs "%A_AhkPath%" "%configFolder%\Scripts\%ScriptName%" "%A_ScriptDir%"
		Return
	}
	*/
	IniRead, AutoStart, %configFile%, Addons, %ScriptName%, 0
	If AutoStart {
		IniDelete, %configFile%, Addons, %ScriptName%
	} Else {
		IniWrite, 1, %configFile%, Addons, %ScriptName%
	}
}
