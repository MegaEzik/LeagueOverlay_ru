
;Ниже функционал нужный для тестирования функции "Меню предмета"
ItemMenu_ConvertFromGame() {
	ItemData:=IDCL_ConvertMain(Globals.Get("ItemDataFullText"))
	Sleep 100
	Clipboard:=ItemData
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" ItemData, 10000)
}

ItemMenu_Show(){
	sleep 100
	ToolTip
	Menu, itemMenu, Add
	Menu, itemMenu, DeleteAll
	
	Globals.Set("ItemDataFullText", IDCL_loadInfo())
	sleep 25
	ItemData:=IDCL_CleanerItem(Globals.Get("ItemDataFullText"))
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	;Определим имя предмета
	ItemName:=ItemDataSplit[3]
	If (((ItemDataSplit[2]="Редкость: Редкий") || (ItemDataSplit[2]="Rarity: Rare")) && (!RegExMatch(ItemData, "Неопознано") && !RegExMatch(ItemData, "Undefined")))
		ItemName:=ItemDataSplit[4]
	
	If (RegExMatch(ItemDataSplit[1], "Класс предмета: (.*)", ItemClass) && RegExMatch(ItemDataSplit[2], "Редкость: (.*)", Rarity)) {
		devAddInList(ItemClass1) ;Временная функция разработчика для сбора классов предметов
		;Пункт для открытия на PoEDB
		If (Rarity1!="Волшебный") {
			ItemMenu_AddPoEDB(ItemName)
			Menu, itemMenu, Add
		}
		;Пункт для копирования имени предмета
		ItemMenu_AddCopyInBuffer(ItemName)
		rlvl:=IDCL_lvlRarity(ItemData) ;Оценим тип предмета по его редкости и описанию
		ItemName_En:=IDCL_ConvertName(ItemName, rlvl)
		If RegExMatch(ItemName_En, " Map$")
			ItemName_En:=StrReplace(ItemName_En, " Map", "")
		If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
			ItemMenu_AddCopyInBuffer(ItemName_En)
		
		;Пункт копирования жертвы в ультиматумах
		If (ItemName="Начертанный Ультиматум") {
			Menu, itemMenu, Add
			If (RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*) x\d+", findtext) || RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*)", findtext))
				ItemMenu_AddCopyInBuffer(findtext1)
			If RegExMatch(ItemDataSplit[8], "Награда: (.*)", findtext)
				If !RegExMatch(findtext1, "Удваивает")
					ItemMenu_AddCopyInBuffer(findtext1)
		}
		
		;Пункт меню для конвертирования описания
		Menu, itemMenu, Add
		Menu, itemMenu, Add, Конвертировать Ru>En, ItemMenu_ConvertFromGame
		If FileExist("resources\imgs\copy.png")
			Menu, itemMenu, Icon, Конвертировать Ru>En, resources\imgs\copy.png
		Menu, itemMenu, Add	
		
		;Создадим меню для подсветки
		ItemMenu_AddHightlight(ItemName)
		If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
			ItemMenu_AddHightlight(ItemName_En)
		ItemMenu_AddHightlight(ItemClass1)
		ItemMenu_AddHightlight(Rarity1)
		
		If RegExMatch(ItemClass1, "Валюта") {
			tempItemName:=ItemName
			tempItemName:=strReplace(tempItemName, ":", "")
			tempItemName:=strReplace(tempItemName, ",", "")
			tempItemName:=strReplace(tempItemName, ".", "")
			splitItemName:=StrSplit(tempItemName, " ")
			For k, val in splitItemName
				If StrLen(splitItemName[k])>=3
					ItemMenu_AddHightlight(splitItemName[k])
		}
		
		/*
		If RegExMatch(ItemName, "(Масло|масло|Сущность|сущность|катализатор|резонатор|ископаемое|сфера Делириума|Карта|Заражённая Карта|флакон маны|флакон жизни|кластерный|Копия)", findtext)
			ItemMenu_AddHightlight(findtext%, ItemMenu_Hightlight
		*/
		
		If (RegExMatch(ItemClass1, "Камни") && RegExMatch(ItemName, "(Пробужденный|Аномальный|Искривлённый|Фантомный): ", findtext))
			ItemMenu_AddHightlight(findtext1)
		If (ItemClass1="Кольца" && RegExMatch(ItemData, "Редкость: Уникальный"))
			ItemMenu_AddHightlight("""Кольца""" " " """Уник""")
		If (RegExMatch(ItemClass1, "Камни") && RegExMatch(ItemData, "Качество: "))
			ItemMenu_AddHightlight("""Камни""" " " """Качество""")
		
		For k, val in ItemDataSplit {
			If RegExMatch(ItemDataSplit[k], "(Предмет Создателя|Древний предмет|Расколотый предмет|Синтезированный предмет|Предмет Вождя|Предмет Избавительницы|Предмет Крестоносца|Предмет Охотника|Завуалированный|Качество|Область находится под влиянием Древнего|Область находится под влиянием Создателя)", findtext)
				ItemMenu_AddHightlight(findtext)
			If RegExMatch(ItemDataSplit[k], "Уровень предмета: (.*)", findtext)
				ItemMenu_AddHightlight(findtext)
			If RegExMatch(ItemDataSplit[k], "Регион Атласа: (.*)", findtext)
				ItemMenu_AddHightlight(findtext1)
			If RegExMatch(ItemDataSplit[k], "Уровень карты: (.*)", findtext)
				ItemMenu_AddHightlight("tier:" findtext1)
			If ((ItemClass1="Чертежи" || ItemClass1="Контракты") && RegExMatch(ItemDataSplit[k], "Требуется (.*) \(", findtext))
				ItemMenu_AddHightlight(findtext1)
			;If (ItemName="Хроники Ацоатля" && RegExMatch(ItemDataSplit[k], "(.*) \(Уровень \d+\)", findtext))
			If (ItemName="Хроники Ацоатля" && RegExMatch(ItemDataSplit[k], "(.*) \(Уровень 3\)", findtext))
				ItemMenu_AddHightlight(findtext1)
		}
		FileRead, hightlightData, %configFolder%\highlight.list
		hightlightDataSplit:=strSplit(StrReplace(hightlightData, "`r", ""), "`n")
		For k, val in hightlightDataSplit
			If RegExMatch(ItemData, hightlightDataSplit[k])
				ItemMenu_AddHightlight(hightlightDataSplit[k])
	} Else {
		;showToolTip("ОШИБКА: Буфер обмена пуст, окно не в фокусе`n`tили не удалось определить тип предмета!", 5000)
		FileRead, hightlightData, %configFolder%\highlight.list
		hightlightDataSplit:=strSplit(StrReplace(hightlightData, "`r", ""), "`n")
		For k, val in hightlightDataSplit
			If (InStr(hightlightDataSplit[k], ";")!=1)
				ItemMenu_AddHightlight(hightlightDataSplit[k])
	}		
	Menu, itemMenu, Add
	Menu, itemMenu, Add, Добавить подсветку, ItemMenu_customHightlight
	Menu, itemMenu, Show
}

ItemMenu_AddPoEDB(Line) {
	Menu, itemMenu, Add, PoEDB>%Line%, ItemMenu_OpenOnPoEDB
	If FileExist("resources\imgs\web.png")
		Menu, itemMenu, Icon, PoEDB>%Line%, resources\imgs\web.png
}


ItemMenu_AddCopyInBuffer(Line){
	Menu, itemMenu, Add, %Line%, ItemMenu_CopyInBuffer
	If FileExist("resources\imgs\copy.png")
		Menu, itemMenu, Icon, %Line%, resources\imgs\copy.png
}

ItemMenu_AddHightlight(Line){
	Menu, itemMenu, Add, *%Line%, ItemMenu_Hightlight
	If FileExist("resources\imgs\highlight.png")
		Menu, itemMenu, Icon, *%Line%, resources\imgs\highlight.png
}

ItemMenu_OpenOnPoEDB(Line){
	Line:=SubStr(Line, 7)
	;run, "https://poedb.tw/ru/search.php?q=%Line%"
	run, "https://poedb.tw/ru/search?q=%Line%"
	return
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

ItemMenu_customHightlight() {
	textFileWindow("Редактирование подсветки", configFolder "\highlight.list", false, "к максимуму здоровья`nк сопротивлению`nповышение скорости передвижения`nВосприятие|Контрмагия|Маскировка")
}

ItemMenu_IDCLInit(){
	IniRead, hotkeyItemMenu, %configFile%, hotkeys, hotkeyItemMenu, %A_Space%
	If (hotkeyItemMenu="")
		return
	Hotkey, % hotkeyItemMenu, ItemMenu_Show, On
	
	FileCreateDir, resources\data
	ResultNames:=ItemMenu_LoadDataFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/resources/data/names.json", "resources\data\names.json")
	ResultStats:=ItemMenu_LoadDataFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/resources/data/stats.json", "resources\data\stats.json")
	;IfNotExist, resources\data\presufflask.json
		;ItemMenu_LoadDataFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/resources/data/presufflask.json", "resources\data\presufflask.json")
	sleep 500
	
	FileRead, stats_list, resources\data\stats.json
	Globals.Set("item_stats", JSON.Load(stats_list))
	FileRead, names_list, resources\data\names.json
	Globals.Set("item_names", JSON.Load(names_list))
	;FileRead, presufflask_list, resources\data\presufflask.json
	;Globals.Set("item_presufflask", JSON.Load(presufflask_list))
	;FileRead, samename_list, resources\data\samename.json
	;Globals.Set("item_samename", JSON.Load(samename_list))
	
	If (ResultNames || ResultStats)
		trayMsg("Списки соответствий обновлены)")
}

ItemMenu_LoadDataFile(URL, Path){
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	FileGetTime, LoadDate, %Path%, M
	FormatTime, LoadDate, %LoadDate%, yyyyMMdd
	
	IfNotExist, %Path%
		LoadDate:=0
	
	If (LoadDate=CurrentDate)
		return false
	
	tmpPath:=A_Temp "\file.tmp"
	LoadFile(URL, tmpPath)
	FileRead, CurrentFileData, %Path%
	FileRead, NewFileData, %tmpPath%
	If (RegExMatch(NewFileData, "{") && RegExMatch(NewFileData, "}") && !RegExMatch(NewFileData, "<") && !RegExMatch(NewFileData, ">")) {
		If (NewFileData!=CurrentFileData) {
			FileDelete, %Path%
			Sleep 100
			;FileAppend, %NewFileData%, %Path%, UTF-8
			FileCopy, %tmpPath%, %Path%, 1
			return true
		}
		FileSetTime, , %Path%
	} else {
		trayMsg("Ошибка загрузки файла соответствий!`n" Path)
		devLog("IDCL Load Error - " Path)
	}
	return false
}
