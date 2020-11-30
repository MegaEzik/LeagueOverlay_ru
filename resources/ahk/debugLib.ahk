
;Инициализация
devInit() {
	IniRead, debugMode, %configFile%, settings, debugMode, 0
	devMenu()
	if debugMode
		trayUpdate("`nВключен режим отладки")
	
	/*
	if debugMode {
		IDCL_Init()
		Hotkey, !c, showItemMenu, On
		;showToolTip("Включен режим отладки", 2000)
	}
	*/
}

;Создание меню разработчика
devMenu() {
	Menu, devMenu1, Standard
	
	Menu, devMenu2, Add, https://poelab.com/gtgax, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/r8aws, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/riikv, devReloadLab
	Menu, devMenu2, Add, https://poelab.com/wfbra, devReloadLab
	
	Menu, devMenu3, Add, Установить пакет, installPack
	Menu, devMenu3, Add
	If FileExist(configFolder "\myloader.ahk")
		Menu, devMenu3, Add, myloader.ahk, unInstallPack
	Loop, %configFolder%\*_loader.ahk, 1
		Menu, devMenu3, Add, Удалить %A_LoopFileName%, unInstallPack

	Menu, devMenu, Add, Восстановить релиз, devRestoreRelease
	Menu, devMenu, Add, Открыть папку настроек, openConfigFolder
	Menu, devMenu, Add, Очистить кэш Path of Exile, clearPoECache
	Menu, devMenu, Add, Управление пакетами, :devMenu3
	Menu, devMenu, Add, Перезагрузить лабиринт, :devMenu2
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
	If FileExist(ArcPath) {
		unZipArchive(ArcPath, configFolder)
		sleep 1000
		ReStart()
	}
}

;Удалить пакет
unInstallPack(packName){
	RegExMatch(packName, "Удалить (.*)", packName)
	RunWait *RunAs "%A_AhkPath%" "%configFolder%\%packName1%" "%A_ScriptDir%" "UNINSTALL"
	sleep 1000
	FileDelete, %configFolder%\%packName1%
	RegExMatch(packName1, "(.*)_loader.ahk", Name)
	FileRemoveDir, %configFolder%\%Name1%, 1
	FileDelete, %configFolder%\presets\%Name1%.preset
	sleep 1000
	ReStart()
}

;Перезагрузить лабиринт
devReloadLab(LabURL){
	FileDelete, %configFolder%\images\Labyrinth.jpg
	sleep 25
	downloadLabLayout(LabURL)
}

;Ниже функционал нужный для тестирования функции "Меню предмета"
ItemMenu_ConvertFromGame() {
	ItemData:=IDCL_ConvertMain(ItemDataFullText)
	Sleep 100
	Clipboard:=ItemData
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" ItemData, 3000)
}

ItemMenu_Show(){
	Menu, hightlightMenu, Add
	Menu, hightlightMenu, DeleteAll
	Menu, itemMenu, Add
	Menu, itemMenu, DeleteAll
	
	ItemDataFullText:=IDCL_loadInfo()
	sleep 25
	
	ItemData:=IDCL_CleanerItem(ItemDataFullText)
	rlvl:=IDCL_lvlRarity(ItemData) ;Оценим тип предмета по его редкости и описанию
	If (rlvl=0 || rlvl="") {
		showToolTip("ОШИБКА: Буфер обмена пуст или не удалось определить тип предмета!" ItemData, 5000)
		return
	}
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	;Определим имя предмета
	ItemName:=ItemDataSplit[2]
	If (rlvl=3 && !RegExMatch(ItemData, "Неопознано"))
		ItemName:=ItemDataSplit[3]
	
	;Пункт для копирования имени предмета
	Menu, itemMenu, Add, %ItemName%, ItemMenu_CopyInBuffer
	ItemName_En:=IDCL_ConvertName(ItemName, rlvl)
	If RegExMatch(ItemName_En, " Map$")
		ItemName_En:=StrReplace(ItemName_En, " Map", "")
	If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
		Menu, itemMenu, Add, %ItemName_En%, ItemMenu_CopyInBuffer
	Menu, itemMenu, Add
	
	;Пункт меню для конвертирования описания
	Menu, itemMenu, Add, Конвертировать Ru>En, ItemMenu_ConvertFromGame
	Menu, itemMenu, Add	
	
	;Создадим меню для подсветки
	Menu, hightlightMenu, add, %ItemName%, ItemMenu_Hightlight
	Menu, hightlightMenu, add
	
	tempItemName:=ItemName
	tempItemName:=strReplace(tempItemName, ":", "")
	tempItemName:=strReplace(tempItemName, ",", "")
	tempItemName:=strReplace(tempItemName, ".", "")
	splitItemName:=StrSplit(tempItemName, " ")
	For k, val in splitItemName {
		findtext:=splitItemName[k]
		If (RegExMatch(findtext, "[А-ЯЁ]+") || StrLen(findtext)>3)
			Menu, hightlightMenu, add, %findtext%, ItemMenu_Hightlight
	}
	Menu, hightlightMenu, add
	
	/*
	If RegExMatch(ItemName, "(Масло|масло|Сущность|сущность|катализатор|резонатор|ископаемое|сфера Делириума|Карта|Заражённая Карта|флакон маны|флакон жизни|кластерный|Копия)", findtext)
		Menu, hightlightMenu, add, %findtext%, ItemMenu_Hightlight
	If RegExMatch(ItemName, "(Мозг|Печень|Лёгкое|Глаз|Сердце|Пробужденный|Аномальный|Искривлённый|Фантомный|Чертёж|Контракт): ", findtext)
		Menu, hightlightMenu, add, %findtext1%, ItemMenu_Hightlight
	*/
		
	If RegExMatch(ItemData, "(это пророчество|в Лаборатории Танэ)", findtext)
		Menu, hightlightMenu, add, %findtext1%, ItemMenu_Hightlight
	If (RegExMatch(ItemName, "(К|к)ольцо") || RegExMatch(ItemDataSplit[3], "(К|к)ольцо")) && RegExMatch(ItemData, "Редкость: Уникальный")
		Menu, hightlightMenu, add, "Кольцо" "Уник", ItemMenu_Hightlight
		
	For k, val in ItemDataSplit {
		If RegExMatch(ItemDataSplit[k], "(Предмет Создателя|Древний предмет|Расколотый предмет|Синтезированный предмет|Предмет Вождя|Предмет Избавительницы|Предмет Крестоносца|Предмет Охотника)", findtext)
			Menu, hightlightMenu, add, %findtext%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Область находится под влиянием (Древнего|Создателя)", findtext)
			Menu, hightlightMenu, add, %findtext%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Регион Атласа: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext1%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Редкость: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext1%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Качество: ")
			Menu, hightlightMenu, add, Качество, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Уровень карты: (.*)", findtext)
			Menu, hightlightMenu, add, tier:%findtext1%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Уровень предмета: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Завуалированный", findtext)
			Menu, hightlightMenu, add, Завуалированный, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Требуется (взлом|грубая сила|восприятие|взрывное дело|контрмагия|разминирование|проворство|маскировка|инженерное дело)", findtext)
			Menu, hightlightMenu, add, %findtext1%, ItemMenu_Hightlight
	}
	
	;Выпадающие меню для подсветки
	Menu, itemMenu, Add, Подсветить, :hightlightMenu
	
	Menu, itemMenu, Show
}

ItemMenu_CopyInBuffer(Line){
	Clipboard:=Line
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" Line, 3000)
}

ItemMenu_Hightlight(Line){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 25
	BlockInput On
	SendInput, ^{f}%Line%
	BlockInput Off
}

ItemMenu_IDCLInit(){
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	If FileExist("resources\names.json") {
		FileGetTime, LoadDate, resources\names.json, M
		FormatTime, LoadDate, %LoadDate%, yyyyMMdd
	}
	
	If (LoadDate!=CurrentDate) {
		LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data/ru/nameItemRuToEn.json", "resources\names.json")
		LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ru_en_stats.json", "resources\stats.json")
		LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ruPrefSufFlask.json", "resources\presufflask.json")
		;LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data/ru/sameNameItem.json", "resources\samename.json")
		sleep 2000
	}
	
	FileRead, stats_list, resources\stats.json
	Globals.Set("item_stats", JSON.Load(stats_list))
	FileRead, names_list, resources\names.json
	Globals.Set("item_names", JSON.Load(names_list))
	FileRead, presufflask_list, resources\presufflask.json
	Globals.Set("item_presufflask", JSON.Load(presufflask_list))
	;FileRead, samename_list, resources\samename.json
	;Globals.Set("item_samename", JSON.Load(samename_list))
}

showToolTip(msg, t=0) {
	ToolTip
	sleep 5
	ToolTip, %msg%
	if t!=0
		SetTimer, removeToolTip, %t%
}

removeToolTip() {
	ToolTip
	SetTimer, removeToolTip, Delete
}
