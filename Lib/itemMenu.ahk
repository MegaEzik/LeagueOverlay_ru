﻿
/*
[info]
version=240724.01
*/

;Ниже функционал нужный для тестирования функции "Меню предмета"
ItemMenu_ConvertFromGame() {
	ItemData:=IDCL_ConvertMain(Globals.Get("ItemDataFullText"))
	Sleep 50
	Clipboard:=ItemData
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" ItemData, 15000)
}

ItemMenu_Show(){
	sleep 50
	ToolTip
	Menu, itemMenu, Add
	Menu, itemMenu, DeleteAll
	
	Globals.Set("ItemDataFullText", IDCL_loadInfo())
	sleep 25
	ItemData:=IDCL_CleanerItem(Globals.Get("ItemDataFullText"))
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	;Если установлен свой файл для 'Избранных команд', то продублируем его в 'Меню предмета'
	IniRead, sMenu, %configFile%, settings, sMenu, MyMenu.fmenu
	If ((ItemData="") && FileExist(configFolder "\MyFiles\" sMenu)) {
		fastMenu(configFolder "\MyFiles\" sMenu, !Gamepad)
		Menu, itemMenu, Add, Избранные команды, :fastMenu
		Menu, itemMenu, Add
	}
	
	;Определим имя предмета
	ItemName:=ItemDataSplit[3]
	If ((ItemDataSplit[2]="Редкость: Редкий") && !RegExMatch(ItemData, "Неопознано"))
		ItemName:=ItemDataSplit[4]
	
	;Уголья Всепламени
	/*
	If (ItemDataSplit[1]="Класс предмета: Уголья Всепламени")
		ItemName:=ItemDataSplit[2]
	*/
	
	rlvl:=IDCL_lvlRarity(ItemData) ;Оценим тип предмета по его редкости и описанию
	
	;Попытаемся сконвертировать англоязычное название
	ItemName_En:=IDCL_ConvertName(ItemName, rlvl)
	If RegExMatch(ItemName_En, " Map$")
		ItemName_En:=StrReplace(ItemName_En, " Map", "")
	
	;If (RegExMatch(ItemDataSplit[1], "Класс предмета: (.*)", ItemClass) && (RegExMatch(ItemDataSplit[2], "Редкость: (.*)", Rarity) || (ItemClass1="Уголья Всепламени")))  {
	If (RegExMatch(ItemDataSplit[1], "Класс предмета: (.*)", ItemClass) && (RegExMatch(ItemDataSplit[2], "Редкость: (.*)", Rarity)))  {
		;devAddInList(ItemClass1) ;Временная функция разработчика для сбора классов предметов
		;Пункты для открытия на сетевых ресурсах 
		If (Rarity1!="Волшебный") {
			;ItemMenu_AddPoEDB(RegExReplace(ItemName, "(Аномальный|Искривлённый|Фантомный): ", ""))
			ItemMenu_AddPoEDB(ItemName)
			If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
				ItemMenu_AddWiki(ItemName_EN)
			
			If RegExMatch(ItemClass1, "(Валюта|Гадальные карты|Обрывки карт|Уголья Всепламени)") || RegExMatch(Rarity1, "Уникальный")
				ItemMenu_AddTrade(ItemName)
				
			If (ItemName="Начертанный Ультиматум") {
				If (RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*) x\d+", findtext) || RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*)", findtext))
					ItemMenu_AddTrade(findtext1)
				If RegExMatch(ItemDataSplit[8], "Награда: (.*)", findtext)
					If !RegExMatch(findtext1, "Удваивает")
						ItemMenu_AddTrade(findtext1)
			}
			
			If (ItemDataSplit[6]="Уровень карты: 17")
				If RegExMatch(ItemDataSplit[7], "Награда: Особ(ая|ый|ое|ые) (.*)", findtext)
					ItemMenu_AddTrade(findtext2)
			
			Menu, itemMenu, Add
		}
		
		;Пункты для копирования имени предмета
		ItemMenu_AddCopyInBuffer(ItemName)
		If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
			ItemMenu_AddCopyInBuffer(ItemName_En)
		
		/*
		;Пункт копирования жертвы в ультиматумах
		If (ItemName="Начертанный Ультиматум") {
			Menu, itemMenu, Add
			If (RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*) x\d+", findtext) || RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*)", findtext))
				ItemMenu_AddCopyInBuffer(findtext1)
			If RegExMatch(ItemDataSplit[8], "Награда: (.*)", findtext)
				If !RegExMatch(findtext1, "Удваивает")
					ItemMenu_AddCopyInBuffer(findtext1)
		}
		*/
		
		;Пункт меню для конвертирования описания
		Menu, itemMenu, Add
		Menu, itemMenu, Add, Конвертировать Ru > En, ItemMenu_ConvertFromGame
		If FileExist("Data\imgs\copy.png")
			Menu, itemMenu, Icon, Конвертировать Ru > En, Data\imgs\copy.png
		Menu, itemMenu, Add	
		
		;Создадим меню для подсветки
		ItemMenu_AddHightlight(ItemName)
		;If (ItemName_En!="" && !RegExMatch(ItemName_En, "Undefined Name"))
		;	ItemMenu_AddHightlight(ItemName_En)
		;Menu, itemMenu, Add	
		
		/*
		If (ItemName="Заполненный гроб") {
			ItemMenu_AddHightlight(ItemDataSplit[7])
			ItemMenu_AddHightlight(StrReplace(ItemDataSplit[9], " (implicit)", ""))
		}
		*/
		
		If (ItemName="Начертанный Ультиматум") {
			If (RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*) x\d+", findtext) || RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*)", findtext))
				ItemMenu_AddHightlight(findtext1)
		}
		
		ItemMenu_AddHightlight(ItemClass1)
		If (Rarity1!="")
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
		
		;If (RegExMatch(ItemClass1, "Камни") && RegExMatch(ItemName, "(Пробужденный|Аномальный|Искривлённый|Фантомный): ", findtext))
			;ItemMenu_AddHightlight(findtext1)
		If (ItemClass1="Кольца" && RegExMatch(ItemData, "Редкость: Уникальный"))
			ItemMenu_AddHightlight("""Кольца""" " " """Уник""")
		If (RegExMatch(ItemClass1, "Камни") && RegExMatch(ItemData, "Качество: "))
			ItemMenu_AddHightlight("""Камни""" " " """Качество""")
		If (RegExMatch(ItemName, "флакон") && RegExMatch(ItemData, "Качество: "))
			ItemMenu_AddHightlight("""Флакон""" " " """Качество""")
		
		For k, val in ItemDataSplit {
			If RegExMatch(ItemDataSplit[k], "(Предмет Создателя|Древний предмет|Расколотый предмет|Синтезированный предмет|Предмет Вождя|Предмет Избавительницы|Предмет Крестоносца|Предмет Охотника|Завуалированный|Качество|Область находится под влиянием Древнего|Область находится под влиянием Создателя|Предмет Пожирателя миров|Предмет Пламенного экзарха|Осквернено|Отражено|Разделено)", findtext)
				ItemMenu_AddHightlight(findtext)
			If RegExMatch(ItemDataSplit[k], "Уровень предмета: (.*)", findtext)
				ItemMenu_AddHightlight(findtext)
			If RegExMatch(ItemDataSplit[k], "Уровень карты: (.*)", findtext)
				ItemMenu_AddHightlight("tier:" findtext1)
			;If (ItemClass1="Чертежи" && RegExMatch(ItemDataSplit[k], "Предмет кражи: (.*)", findtext))
				;ItemMenu_AddHightlight(findtext1)
			If ((ItemClass1="Чертежи" || ItemClass1="Контракты") && RegExMatch(ItemDataSplit[k], "Требуется (.*) \(\d+", findtext))
				ItemMenu_AddHightlight(findtext1)
			If (ItemClass1="Журналы экспедиции" && RegExMatch(ItemDataSplit[k], "(Друиды Разомкнутого круга|Наёмники Чёрной косы|Рыцари Солнца|Орден Чаши)", findtext)=1)
				ItemMenu_AddHightlight(findtext1)
			;If (ItemName="Хроники Ацоатля" && RegExMatch(ItemDataSplit[k], "(.*) \(Уровень 3\)", findtext))
			If (ItemName="Хроники Ацоатля" && RegExMatch(ItemDataSplit[k], "(Аудитория Дориани|Очаг осквернения)", findtext))
				ItemMenu_AddHightlight(findtext)
			/*
			If RegExMatch(ItemDataSplit[k], "Регион Атласа: (.*)", findtext)
				ItemMenu_AddHightlight(findtext1)
			If (ItemName="Зеркальная табличка" && RegExMatch(ItemDataSplit[k], "Отражение (.*) \(\d+", findtext))
				ItemMenu_AddHightlight("Отражение " findtext1)
			*/
		}
		FileRead, hightlightData, %configFolder%\highlight.list
		hightlightDataSplit:=strSplit(StrReplace(hightlightData, "`r", ""), "`n")
		For k, val in hightlightDataSplit {
			If (hightlightDataSplit[k]="") || (InStr(hightlightDataSplit[k], ";")=1)
				Continue
			If RegExMatch(ItemData, hightlightDataSplit[k], findtext) {
				ItemMenu_AddHightlight(findtext)
				If FileExist("Data\imgs\favorite.png")
					Menu, itemMenu, Icon, *%findtext%, Data\imgs\favorite.png
				;Menu, itemMenu, Check, *%findtext%
			}
		}
	} Else {
		FileRead, hightlightData, %configFolder%\highlight.list
		hightlightDataSplit:=strSplit(StrReplace(hightlightData, "`r", ""), "`n")
		For k, val in hightlightDataSplit {
			If (hightlightDataSplit[k]="") || (InStr(hightlightDataSplit[k], ";")=1)
				Continue
			ItemMenu_AddHightlight(hightlightDataSplit[k])
		}
	}		
	Menu, itemMenu, Add
	Menu, itemMenu, Add, Редактировать подсветку, ItemMenu_customHightlight
	Menu, itemMenu, Show
}

ItemMenu_AddPoEDB(Line) {
	Menu, itemMenu, Add, PoEDB > '%Line%', ItemMenu_OpenOnPoEDB
	If FileExist("Data\imgs\web.png")
		Menu, itemMenu, Icon, PoEDB > '%Line%', Data\imgs\web.png
}

ItemMenu_AddWiki(Line) {
	Menu, itemMenu, Add, PoEWiki > '%Line%', ItemMenu_OpenOnWiki
	If FileExist("Data\imgs\web.png")
		Menu, itemMenu, Icon, PoEWiki > '%Line%', Data\imgs\web.png
}

ItemMenu_AddTrade(Line) {
	Menu, itemMenu, Add, PoE\trade > '%Line%', ItemMenu_OpenOnTrade
	If FileExist("Data\imgs\web.png")
		Menu, itemMenu, Icon, PoE\trade > '%Line%', Data\imgs\web.png
}


ItemMenu_AddCopyInBuffer(Line){
	Menu, itemMenu, Add, %Line%, ItemMenu_CopyInBuffer
	If FileExist("Data\imgs\copy.png")
		Menu, itemMenu, Icon, %Line%, Data\imgs\copy.png
}

ItemMenu_AddHightlight(Line){
	Line:=SubStr(Line, 1, 50)
	Menu, itemMenu, Add, *%Line%, ItemMenu_Hightlight
	If FileExist("Data\imgs\highlight.png")
		Menu, itemMenu, Icon, *%Line%, Data\imgs\highlight.png
}

ItemMenu_OpenOnPoEDB(Line){
	Line:=searchName(Line)
	;run, "https://poedb.tw/ru/search.php?q=%Line%"
	run, "https://poedb.tw/ru/search?q=%Line%"
	return
}

ItemMenu_OpenOnWiki(Line){
	Line:=searchName(Line)
	run, "https://www.poewiki.net/index.php?search=%Line%"
	return
}

ItemMenu_OpenOnTrade(Line){
	Line:=searchName(Line)
	IniRead, league, %configFile%, settings, league, Standard
	ItemData:=Globals.Get("ItemDataFullText")
	urltype:=RegExMatch(Globals.Get("ItemDataFullText"), "Редкость: Уникальный") || RegExMatch(Globals.Get("ItemDataFullText"), "Уровень карты: 17") || (RegExMatch(Globals.Get("ItemDataFullText"), "Начертанный Ультиматум") && !RegExMatch(Globals.Get("ItemDataFullText"), "Требуется жертвоприношение: (.*) x\d+"))?"name":"type"
	url:="https://ru.pathofexile.com/trade/search/" league "?q={%22query%22:{%22" urltype "%22:%22" Line "%22}}"
	run,"%url%"
	return
}

ItemMenu_CopyInBuffer(Line){
	Clipboard:=Line
	showToolTip("Скопировано в буфер обмена!`n-----------------------------------`n" Line, 5000)
}

ItemMenu_Hightlight(Line){
	Line:=SubStr(Line, 2, 50)
	;DllCall("PostMessage", "Ptr", A_ScriptHWND, "UInt", 0x50, "UInt", 0x4090409, "UInt", 0x4090409)
	;sleep 25
	clipboard:=Line
	sleep 10
	BlockInput On
	;SendInput, ^{f}%Line%
	SendInput, ^{f}^{v}
	BlockInput Off
}

ItemMenu_customHightlight() {
	textFileWindow("Редактирование подсветки", configFolder "\highlight.list", false, "к максимуму здоровья`nк сопротивлению`nповышение скорости передвижения`nВосприятие|Маскировка`n""nt ro|fien|r be|vy b|amp|ian""")
}

ItemMenu_IDCLInit(){
	IniRead, hotkeyItemMenu, %configFile%, hotkeys, hotkeyItemMenu, %A_Space%
	If (hotkeyItemMenu="")
		return
	Hotkey, % hotkeyItemMenu, ItemMenu_Show, On
	
	FileCreateDir, Data\JSON
	ResultNames:=ItemMenu_LoadDataFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/Data/JSON/names.json", "Data\JSON\names.json")
	ResultStats:=ItemMenu_LoadDataFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/Data/JSON/stats.json", "Data\JSON\stats.json")
	sleep 100
	
	FileRead, stats_list, Data\JSON\stats.json
	Globals.Set("item_stats", JSON.Load(stats_list))
	FileRead, names_list, Data\JSON\names.json
	Globals.Set("item_names", JSON.Load(names_list))
	
	If (ResultNames || ResultStats)
		MsgBox,  0x1040, %prjName%, Обновлены списки соответствий, 3
}

ItemMenu_LoadDataFile(URL, Path){
	;return false ;Отключение обновления данных
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	FileGetTime, LoadDate, %Path%, M
	FormatTime, LoadDate, %LoadDate%, yyyyMMdd
	
	IfNotExist, %Path%
		LoadDate:=0
	
	If (LoadDate=CurrentDate)
		return false
	
	tmpPath:=tempDir "\file.tmp"
	LoadFile(URL, tmpPath)
	FileRead, CurrentFileData, %Path%
	FileRead, NewFileData, %tmpPath%
	If (RegExMatch(NewFileData, "{") && RegExMatch(NewFileData, "}") && !RegExMatch(NewFileData, "<") && !RegExMatch(NewFileData, ">")) {
		If (NewFileData!=CurrentFileData) {
			FileDelete, %Path%
			Sleep 50
			FileCopy, %tmpPath%, %Path%, 1
			return true
		}
		FileSetTime, , %Path%
	} else {
		TrayTip, %prjName%, Ошибка загрузки файла соответствий!`n%Path%
		devLog("IDCL Load Error - " Path)
	}
	return false
}
