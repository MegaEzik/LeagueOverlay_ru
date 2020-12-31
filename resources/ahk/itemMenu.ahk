
;Ниже функционал нужный для тестирования функции "Меню предмета"
ItemMenu_ConvertFromGame() {
	ItemData:=IDCL_ConvertMain(ItemDataFullText)
	Sleep 100
	Clipboard:=ItemData
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" ItemData, 3000)
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
		showToolTip("ОШИБКА: Буфер обмена пуст, окно не в фокусе`n`tили не удалось определить тип предмета!", 4000)
		return
	}
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	;Определим имя предмета
	ItemName:=ItemDataSplit[2]
	If (rlvl=3 && !RegExMatch(ItemData, "Неопознано"))
		ItemName:=ItemDataSplit[3]
	
	;Пункт для копирования имени предмета
	Menu, itemMenu, Add, 📄 %ItemName%, ItemMenu_CopyInBuffer
	ItemName_En:=IDCL_ConvertName(ItemName, rlvl)
	If RegExMatch(ItemName_En, " Map$")
		ItemName_En:=StrReplace(ItemName_En, " Map", "")
	If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
		Menu, itemMenu, Add, 📄 %ItemName_En%, ItemMenu_CopyInBuffer
	Menu, itemMenu, Add
	
	;Пункт меню для конвертирования описания
	Menu, itemMenu, Add, Конвертировать Ru>En, ItemMenu_ConvertFromGame
	Menu, itemMenu, Add	
	
	;Создадим меню для подсветки
	Menu, itemMenu, add, ◳ %ItemName%, ItemMenu_Hightlight
	
	tempItemName:=ItemName
	tempItemName:=strReplace(tempItemName, ":", "")
	tempItemName:=strReplace(tempItemName, ",", "")
	tempItemName:=strReplace(tempItemName, ".", "")
	splitItemName:=StrSplit(tempItemName, " ")
	For k, val in splitItemName {
		findtext:=splitItemName[k]
		If (RegExMatch(findtext, "[А-ЯЁ]+") || StrLen(findtext)>3)
			Menu, itemMenu, add, ◳ %findtext%, ItemMenu_Hightlight
	}
	
	/*
	If RegExMatch(ItemName, "(Масло|масло|Сущность|сущность|катализатор|резонатор|ископаемое|сфера Делириума|Карта|Заражённая Карта|флакон маны|флакон жизни|кластерный|Копия)", findtext)
		Menu, itemMenu, add, ◳ %findtext%, ItemMenu_Hightlight
	If RegExMatch(ItemName, "(Мозг|Печень|Лёгкое|Глаз|Сердце|Пробужденный|Аномальный|Искривлённый|Фантомный|Чертёж|Контракт): ", findtext)
		Menu, itemMenu, add, ◳ %findtext1%, ItemMenu_Hightlight
	*/
		
	If RegExMatch(ItemData, "(это пророчество|в Лаборатории Танэ)", findtext)
		Menu, itemMenu, add, ◳ %findtext1%, ItemMenu_Hightlight
	If (RegExMatch(ItemName, "(К|к)ольцо") || RegExMatch(ItemDataSplit[3], "(К|к)ольцо")) && RegExMatch(ItemData, "Редкость: Уникальный")
		Menu, itemMenu, add, ◳ "Кольцо" "Уник", ItemMenu_Hightlight
	If (RegExMatch(ItemData, "Качество: ") && RegExMatch(ItemData, "Редкость: Камень"))
		Menu, itemMenu, add, ◳ "Качество" "Камень", ItemMenu_Hightlight
	
	For k, val in ItemDataSplit {
		If RegExMatch(ItemDataSplit[k], "(Предмет Создателя|Древний предмет|Расколотый предмет|Синтезированный предмет|Предмет Вождя|Предмет Избавительницы|Предмет Крестоносца|Предмет Охотника)", findtext)
			Menu, itemMenu, add, ◳ %findtext%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Область находится под влиянием (Древнего|Создателя)", findtext)
			Menu, itemMenu, add, ◳ %findtext%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Регион Атласа: (.*)", findtext)
			Menu, itemMenu, add, ◳ %findtext1%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Редкость: (.*)", findtext)
			Menu, itemMenu, add, ◳ %findtext1%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Качество: ")
			Menu, itemMenu, add, ◳ Качество, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Уровень карты: (.*)", findtext)
			Menu, itemMenu, add, ◳ tier:%findtext1%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Уровень предмета: (.*)", findtext)
			Menu, itemMenu, add, ◳ %findtext%, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Завуалированный", findtext)
			Menu, itemMenu, add, ◳ Завуалированный, ItemMenu_Hightlight
		If RegExMatch(ItemDataSplit[k], "Требуется (взлом|грубая сила|восприятие|взрывное дело|контрмагия|разминирование|проворство|маскировка|инженерное дело)", findtext)
			Menu, itemMenu, add, ◳ %findtext1%, ItemMenu_Hightlight
	}
	
	Menu, itemMenu, Show
}

ItemMenu_CopyInBuffer(Line){
	Line:=SubStr(Line, 4)
	Clipboard:=Line
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" Line, 3000)
}

ItemMenu_Hightlight(Line){
	Line:=SubStr(Line, 3)
	DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	sleep 25
	BlockInput On
	SendInput, ^{f}%Line%
	BlockInput Off
}

ItemMenu_IDCLInit(){
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	FileGetTime, LoadDate, resources\names.json, M
	FormatTime, LoadDate, %LoadDate%, yyyyMMdd
	
	IfNotExist, resources\names.json
		LoadDate:=0
	
	If (LoadDate!=CurrentDate) {
		LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data/ru/nameItemRuToEn.json", "resources\names.json")
		LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ru_en_stats.json", "resources\stats.json")
		LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data_trade/ru/ruPrefSufFlask.json", "resources\presufflask.json")
		;LoadFile("https://raw.githubusercontent.com/MegaEzik/PoE-TradeMacro_ru/master/data/ru/sameNameItem.json", "resources\samename.json")
		sleep 500
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
