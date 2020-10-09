
;Инициализация
devInit() {
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	devMenu()
	if debugMode
		trayUpdate("`nВключен режим отладки")
	
	if debugMode {
		IDCL_Init2()
		Hotkey, !c, showItemMenu, On
	}
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu1, Standard
	
	Menu, devMenu2, Add, Normal, devReloadLab
	Menu, devMenu2, Add, Cruel, devReloadLab
	Menu, devMenu2, Add, Merciless, devReloadLab
	Menu, devMenu2, Add, Uber, devReloadLab
	
	Menu, devMenu3, Add, Установить пакет, installPack
	Menu, devMenu3, Add
	If FileExist(configFolder "\myloader.ahk")
		Menu, devMenu3, Add, myloader.ahk, unInstallPack
	Loop, %configFolder%\*_loader.ahk, 1
		Menu, devMenu3, Add, Удалить %A_LoopFileName%, unInstallPack

	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Управление пакетами, :devMenu3
	Menu, devMenu, Add, Перезагрузить лабиринт, :devMenu2
	Menu, devMenu, Add, Перезагрузить списки IDCL, IDCL_Reload
	Menu, devMenu, Add, AutoHotkey, :devMenu1
}

;Откатиться на релизную версию
devRestoreRelease() {
	verScript:=0
	CheckUpdateFromMenu()
}

;Установить пакет
installPack(){
	FileSelectFile, ArcPath, ,,,(*.zip)
	If FileExist(ArcPath)
		unZipArchive(ArcPath, configFolder)
	ReStart()
}

;Удалить пакет
unInstallPack(packName){
	RegExMatch(packName, "Удалить (.*)", packName)
	RunWait *RunAs "%A_AhkPath%" "%configFolder%\%packName1%" "%A_ScriptDir%" "UNINSTALL"
	sleep 100
	FileDelete, %configFolder%\%packName1%
	RegExMatch(packName1, "(.*)_loader.ahk", Name)
	FileRemoveDir, %configFolder%\%Name1%, 1
	FileDelete, %configFolder%\presets\%Name1%.preset
	ReStart()
}

;Перезагрузить лабиринт
devReloadLab(LabName){
	FileDelete, %configFolder%\images\Labyrinth.jpg
	sleep 25
	LabURL:="https://www.poelab.com/wfbra"
	If (LabName="Normal")
		LabURL:="https://www.poelab.com/gtgax"
	If (LabName="Cruel")
		LabURL:="https://www.poelab.com/r8aws"
	If (LabName="Merciless")
		LabURL:="https://www.poelab.com/riikv"
	downloadLabLayout(LabURL)
}

;Ниже функционал нужный для тестирования функции "Меню предмета"

IDCL_ConvertFromGame2() {
	ItemData:=IDCL_ConvertMain(Clipboard)
	msgbox, 0x1040, Cкопировано в буфер обмена!, %ItemData%, 2
}

IDCL_Init2(){
	If (FileExist("resources\stats.json") && FileExist("resources\names.json") && FileExist("resources\presufflask.json")) {
		FileRead, stats_list, resources\stats.json
		Globals.Set("item_stats", JSON.Load(stats_list))
		FileRead, names_list, resources\names.json
		Globals.Set("item_names", JSON.Load(names_list))
		FileRead, presufflask_list, resources\presufflask.json
		Globals.Set("item_presufflask", JSON.Load(presufflask_list))
	} else {
		IDCL_DownloadJSONList("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ru_en_stats.json", "resources\stats.json")
		IDCL_DownloadJSONList("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data/ru/nameItemRuToEn.json", "resources\names.json")
		IDCL_DownloadJSONList("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ruPrefSufFlask.json", "resources\presufflask.json")
		sleep 3000
		IDCL_Init2()
	}
}

IDCL_Reload(){
	FileDelete, resources\*.json
	sleep 1000
	IDCL_Init2()
}

showItemMenu(){
	Menu, itemMenu, Add
	Menu, itemMenu, DeleteAll
	
	IDCL_loadInfo()
	
	Menu, itemMenu, Add, Конвертировать описание Ru>En, IDCL_ConvertFromGame2
	Menu, itemMenu, Add
	createHightlightMenu()
	Menu, itemMenu, Add, Подсветка с помощью тэгов, :hightlightMenu
	Menu, itemMenu, Show
}

createHightlightMenu(){
	Menu, hightlightMenu, Add
	Menu, hightlightMenu, DeleteAll
	
	ItemData:=IDCL_CleanerItem(Clipboard)
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	ItemName:=ItemDataSplit[2]
	If RegExMatch(ItemData, "Редкость: Редкий") && !RegExMatch(ItemData, "Неопознано")
		ItemName:=ItemDataSplit[3]
	Menu, hightlightMenu, add, %ItemName%, nullFunction
	
	If RegExMatch(ItemName, "(Масло|масло|Сущность|сущность|катализатор|резонатор|ископаемое|сфера Делириума|Карта|Заражённая Карта|флакон маны|флакон жизни)", findtext)
		Menu, hightlightMenu, add, %findtext%, nullFunction
	If RegExMatch(ItemName, "(Мозг|Печень|Лёгкое|Глаз|Сердце|Пробужденный|Аномальный|Искривлённый|Фантомный|Чертёж|Контракт): ", findtext)
		Menu, hightlightMenu, add, %findtext1%, nullFunction
		
	If RegExMatch(ItemData, "(это пророчество|в Лаборатории Танэ)", findtext)
		Menu, hightlightMenu, add, %findtext1%, nullFunction
	If (RegExMatch(ItemName, "(К|к)ольцо") || RegExMatch(ItemDataSplit[3], "(К|к)ольцо")) && RegExMatch(ItemData, "Редкость: Уникальный")
		Menu, hightlightMenu, add, "Кольцо" "Уник", nullFunction
		
	For k, val in ItemDataSplit {
		If RegExMatch(ItemDataSplit[k], "Область находится под влиянием (Древнего|Создателя)", findtext)
			Menu, hightlightMenu, add, %findtext%, nullFunction
		If RegExMatch(ItemDataSplit[k], "Регион Атласа: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext1%, nullFunction
		If RegExMatch(ItemDataSplit[k], "Редкость: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext1%, nullFunction
		If RegExMatch(ItemDataSplit[k], "Качество: ")
			Menu, hightlightMenu, add, Качество, nullFunction
		If RegExMatch(ItemDataSplit[k], "Уровень карты: (.*)", findtext)
			Menu, hightlightMenu, add, tier:%findtext1%, nullFunction
		If RegExMatch(ItemDataSplit[k], "Уровень предмета: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext%, nullFunction
	}
}

nullFunction(Line){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 25
	BlockInput On
	SendInput, ^{f}%Line%
	BlockInput Off
}

runNotify(){
	If (FileExist("readme.txt")) {
		FileRead, notifyMsg, readme.txt
		If (notifyMsg!="")
			msgbox, 0x1040, %prjName% - Уведомление, %notifyMsg%
		FileDelete, readme.txt
	}
}

