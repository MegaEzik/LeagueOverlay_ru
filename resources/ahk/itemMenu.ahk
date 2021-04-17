
;Ниже функционал нужный для тестирования функции "Меню предмета"
ItemMenu_ConvertFromGame() {
	ItemData:=IDCL_ConvertMain(ItemDataFullText)
	Sleep 100
	Clipboard:=ItemData
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" ItemData, 10000)
}

ItemMenu_Show(){
	ToolTip
	Menu, itemMenu, Add
	Menu, itemMenu, DeleteAll
	
	ItemDataFullText:=IDCL_loadInfo()
	sleep 25
	
	ItemData:=IDCL_CleanerItem(ItemDataFullText)
	rlvl:=IDCL_lvlRarity(ItemData) ;Оценим тип предмета по его редкости и описанию
	If (rlvl=0 || rlvl="") {
		showToolTip("ОШИБКА: Буфер обмена пуст, окно не в фокусе`n`tили не удалось определить тип предмета!", 5000)
		return
	}
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	;Определим имя предмета
	ItemName:=ItemDataSplit[3]
	If (rlvl=3 && !RegExMatch(ItemData, "Неопознано"))
		ItemName:=ItemDataSplit[4]
	
	;Пункт для копирования имени предмета
	ItemMenu_AddCopyInBuffer(ItemName)
	ItemName_En:=IDCL_ConvertName(ItemName, rlvl)
	If RegExMatch(ItemName_En, " Map$")
		ItemName_En:=StrReplace(ItemName_En, " Map", "")
	If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
		ItemMenu_AddCopyInBuffer(ItemName_En)
	Menu, itemMenu, Add
	
	;Пункт меню для конвертирования описания
	Menu, itemMenu, Add, Конвертировать Ru>En, ItemMenu_ConvertFromGame
	If FileExist("resources\icons\copy.png")
		Menu, itemMenu, Icon, Конвертировать Ru>En, resources\icons\copy.png
	Menu, itemMenu, Add	
	
	;Создадим меню для подсветки
	RegExMatch(ItemDataSplit[1], "Класс предмета: (.*)", class_item)
		ItemMenu_AddHightlight(class_item1)
		
	ItemMenu_AddHightlight(ItemName)
	
	tempItemName:=ItemName
	tempItemName:=strReplace(tempItemName, ":", "")
	tempItemName:=strReplace(tempItemName, ",", "")
	tempItemName:=strReplace(tempItemName, ".", "")
	splitItemName:=StrSplit(tempItemName, " ")
	For k, val in splitItemName {
		findtext:=splitItemName[k]
		If (RegExMatch(findtext, "[А-ЯЁ]+") || StrLen(findtext)>=3)
			ItemMenu_AddHightlight(findtext)
	}
	
	/*
	If RegExMatch(ItemName, "(Масло|масло|Сущность|сущность|катализатор|резонатор|ископаемое|сфера Делириума|Карта|Заражённая Карта|флакон маны|флакон жизни|кластерный|Копия)", findtext)
		ItemMenu_AddHightlight(findtext%, ItemMenu_Hightlight
	If RegExMatch(ItemName, "(Мозг|Печень|Лёгкое|Глаз|Сердце|Пробужденный|Аномальный|Искривлённый|Фантомный|Чертёж|Контракт): ", findtext)
		ItemMenu_AddHightlight(findtext1%, ItemMenu_Hightlight
	*/
		
	If RegExMatch(ItemData, "(это пророчество|в Лаборатории Танэ)", findtext)
		ItemMenu_AddHightlight(findtext1)
	If (RegExMatch(ItemName, "(К|к)ольцо") || RegExMatch(ItemDataSplit[3], "(К|к)ольцо")) && RegExMatch(ItemData, "Редкость: Уникальный")
		ItemMenu_AddHightlight("""Кольцо""" " " """Уник""")
	If (RegExMatch(ItemData, "Качество: ") && RegExMatch(ItemData, "Редкость: Камень"))
		ItemMenu_AddHightlight("""Качество""" " " """Камень""")
	
	For k, val in ItemDataSplit {
		If RegExMatch(ItemDataSplit[k], "(Предмет Создателя|Древний предмет|Расколотый предмет|Синтезированный предмет|Предмет Вождя|Предмет Избавительницы|Предмет Крестоносца|Предмет Охотника)", findtext)
			ItemMenu_AddHightlight(findtext)
		If RegExMatch(ItemDataSplit[k], "Область находится под влиянием (Древнего|Создателя)", findtext)
			ItemMenu_AddHightlight(findtext)
		If RegExMatch(ItemDataSplit[k], "Регион Атласа: (.*)", findtext)
			ItemMenu_AddHightlight(findtext1)
		If RegExMatch(ItemDataSplit[k], "Редкость: (.*)", findtext)
			ItemMenu_AddHightlight(findtext1)
		If RegExMatch(ItemDataSplit[k], "Качество: ")
			ItemMenu_AddHightlight("Качество")
		If RegExMatch(ItemDataSplit[k], "Уровень карты: (.*)", findtext)
			ItemMenu_AddHightlight("tier:" findtext1)
		If RegExMatch(ItemDataSplit[k], "Уровень предмета: (.*)", findtext)
			ItemMenu_AddHightlight(findtext)
		If RegExMatch(ItemDataSplit[k], "Завуалированный", findtext)
			ItemMenu_AddHightlight("Завуалированный")
		If RegExMatch(ItemDataSplit[k], "Требуется (взлом|грубая сила|восприятие|взрывное дело|контрмагия|разминирование|проворство|маскировка|инженерное дело)", findtext)
			ItemMenu_AddHightlight(findtext1)
	}
	
	Menu, itemMenu, Show
}

ItemMenu_AddCopyInBuffer(Line){
	Menu, itemMenu, Add, %Line%, ItemMenu_CopyInBuffer
	If FileExist("resources\icons\copy.png")
		Menu, itemMenu, Icon, %Line%, resources\icons\copy.png
}

ItemMenu_AddHightlight(Line){
	Menu, itemMenu, Add, *%Line%, ItemMenu_Hightlight
	If FileExist("resources\icons\highlight.png")
		Menu, itemMenu, Icon, *%Line%, resources\icons\highlight.png
}

ItemMenu_CopyInBuffer(Line){
	Clipboard:=Line
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" Line, 3000)
}

ItemMenu_Hightlight(Line){
	Line:=SubStr(Line, 2)
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 25
	BlockInput On
	SendInput, ^{f}%Line%
	BlockInput Off
}

ItemMenu_IDCLInit(){
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	FileGetTime, LoadDate, resources\data\names.json, M
	FormatTime, LoadDate, %LoadDate%, yyyyMMdd
	
	IfNotExist, resources\data\names.json
		LoadDate:=0
	
	If (LoadDate!=CurrentDate) {
		FileCreateDir, resources\data
		LoadFile("https://raw.githubusercontent.com/MegaEzik/LeagueOverlay_ru/master/resources/data/names.json", "resources\data\names.json")
		LoadFile("https://raw.githubusercontent.com/MegaEzik/LeagueOverlay_ru/master/resources/data/stats.json", "resources\data\stats.json")
		IfNotExist, resources\data\presufflask.json
			LoadFile("https://raw.githubusercontent.com/MegaEzik/LeagueOverlay_ru/master/resources/data/presufflask.json", "resources\data\presufflask.json")
		;LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/resources/data/samename.json", "resources\data\samename.json")
		sleep 500
	}
	
	FileRead, stats_list, resources\data\stats.json
	Globals.Set("item_stats", JSON.Load(stats_list))
	FileRead, names_list, resources\data\names.json
	Globals.Set("item_names", JSON.Load(names_list))
	FileRead, presufflask_list, resources\data\presufflask.json
	Globals.Set("item_presufflask", JSON.Load(presufflask_list))
	;FileRead, samename_list, resources\data\samename.json
	;Globals.Set("item_samename", JSON.Load(samename_list))
}
