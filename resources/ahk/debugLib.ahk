
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
	Menu, devMenu, Add, Перезагрузить списки соответствий, IDCL_ReloadLists
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
IDCL_ConvertFromGame2() {
	ItemData:=IDCL_ConvertMain(ItemDataFullText)
	Clipboard:=ItemData
	showToolTip("Скопировано в буфер обмена!`n---------------------------`n" ItemData, 3000)
}

showItemMenu(){
	Menu, itemMenu, Add
	Menu, itemMenu, DeleteAll
	
	ItemDataFullText:=IDCL_loadInfo()
	sleep 25
	
	Menu, itemMenu, Add, Конвертировать описание Ru>En, IDCL_ConvertFromGame2
	Menu, itemMenu, Add
	createHightlightMenu()
	Menu, itemMenu, Add, Подсветка с помощью тэгов, :hightlightMenu
	Menu, itemMenu, Show
}

createHightlightMenu(){
	Menu, hightlightMenu, Add
	Menu, hightlightMenu, DeleteAll
	
	ItemData:=IDCL_CleanerItem(ItemDataFullText)
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	ItemName:=ItemDataSplit[2]
	If RegExMatch(ItemData, "Редкость: Редкий") && !RegExMatch(ItemData, "Неопознано")
		ItemName:=ItemDataSplit[3]
	Menu, hightlightMenu, add, %ItemName%, hightlightLine
	Menu, hightlightMenu, add
	
	tempItemName:=ItemName
	tempItemName:=strReplace(tempItemName, ":", "")
	tempItemName:=strReplace(tempItemName, ",", "")
	tempItemName:=strReplace(tempItemName, ".", "")
	splitItemName:=StrSplit(tempItemName, " ")
	For k, val in splitItemName {
		findtext:=splitItemName[k]
		If (RegExMatch(findtext, "[А-ЯЁ]+") || StrLen(findtext)>3)
			Menu, hightlightMenu, add, %findtext%, hightlightLine
	}
	Menu, hightlightMenu, add
	
	/*
	If RegExMatch(ItemName, "(Масло|масло|Сущность|сущность|катализатор|резонатор|ископаемое|сфера Делириума|Карта|Заражённая Карта|флакон маны|флакон жизни|кластерный|Копия)", findtext)
		Menu, hightlightMenu, add, %findtext%, hightlightLine
	If RegExMatch(ItemName, "(Мозг|Печень|Лёгкое|Глаз|Сердце|Пробужденный|Аномальный|Искривлённый|Фантомный|Чертёж|Контракт): ", findtext)
		Menu, hightlightMenu, add, %findtext1%, hightlightLine
	*/
		
	If RegExMatch(ItemData, "(это пророчество|в Лаборатории Танэ)", findtext)
		Menu, hightlightMenu, add, %findtext1%, hightlightLine
	If (RegExMatch(ItemName, "(К|к)ольцо") || RegExMatch(ItemDataSplit[3], "(К|к)ольцо")) && RegExMatch(ItemData, "Редкость: Уникальный")
		Menu, hightlightMenu, add, "Кольцо" "Уник", hightlightLine
		
	For k, val in ItemDataSplit {
		If RegExMatch(ItemDataSplit[k], "(Предмет Создателя|Древний предмет|Расколотый предмет|Синтезированный предмет|Предмет Вождя|Предмет Избавительницы|Предмет Крестоносца|Предмет Охотника)", findtext)
			Menu, hightlightMenu, add, %findtext%, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Область находится под влиянием (Древнего|Создателя)", findtext)
			Menu, hightlightMenu, add, %findtext%, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Регион Атласа: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext1%, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Редкость: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext1%, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Качество: ")
			Menu, hightlightMenu, add, Качество, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Уровень карты: (.*)", findtext)
			Menu, hightlightMenu, add, tier:%findtext1%, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Уровень предмета: (.*)", findtext)
			Menu, hightlightMenu, add, %findtext%, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Завуалированный", findtext)
			Menu, hightlightMenu, add, Завуалированный, hightlightLine
		If RegExMatch(ItemDataSplit[k], "Требуется (взлом|грубая сила|восприятие|взрывное дело|контрмагия|разминирование|проворство|маскировка|инженерное дело)", findtext)
			Menu, hightlightMenu, add, %findtext1%, hightlightLine
	}
}

hightlightLine(Line){
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 25
	BlockInput On
	SendInput, ^{f}%Line%
	BlockInput Off
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


