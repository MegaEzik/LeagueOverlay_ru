﻿
/*
[info]
version=240831.02
*/

;Ниже функционал нужный для тестирования функции "Меню предмета"
ItemMenu_ConvertFromGame() {
	ItemData:=IDCL_ConvertItem(Globals.Get("IDCL_ItemData"))
	Sleep 35
	Clipboard:=ItemData
	showToolTip(ItemData, 15000)
}

ItemMenu_ConvertFromGamePlus() {
	ItemData:=IDCL_ConvertItem(Globals.Get("IDCL_ItemData"), False)
	Sleep 35
	Clipboard:=ItemData
	showToolTip(ItemData, 15000)
}

ItemMenu_Show(){
	sleep 50
	ToolTip
	Menu, itemMenu, Add
	Menu, itemMenu, DeleteAll
	
	;ItemData:=IDCL_CleanerItem(IDCL_loadInfo())
	;Globals.Set("IDCL_ItemData", ItemData)
	;sleep 25
	IDCL_LoadItemInfo()
	ItemData:=Globals.Get("IDCL_ItemData")
	iName:=Globals.Get("IDCL_Name")
	iClass:=Globals.Get("IDCL_Class")
	iRarity:=Globals.Get("IDCL_Rarity")
	
	ItemDataSplit:=StrSplit(ItemData, "`n")
	
	;Если установлен свой файл для 'Избранных команд', то продублируем его в 'Меню предмета'
	IniRead, sMenu, %configFile%, settings, sMenu, MyMenu.fmenu
	If ((ItemData="") && FileExist(configFolder "\MyFiles\" sMenu)) {
		fastMenu(configFolder "\MyFiles\" sMenu, !Gamepad)
		Menu, itemMenu, Add, Избранные команды, :fastMenu
		Menu, itemMenu, Add
	}
	
	If (iClass!=""){
		;Пункты для открытия на сетевых ресурсах 
		If (ItemData!="") {
			ItemMenu_AddPoEDB(iName)
			ItemMenu_AddWiki(iName)
			
			If RegExMatch(iClass, "(Валюта|Гадальные карты|Обрывки карт|Уголья Всепламени|Камни поддержки|Камни умений)") || (iRarity="Уникальный")
				ItemMenu_AddTrade(iName)
				
			If (iName="Inscribed Ultimatum") {
				If (RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*) x\d+", findtext) || RegExMatch(ItemDataSplit[7], "Требуется жертвоприношение: (.*)", findtext)) {
					Menu, itemMenu, Add
					ItemMenu_AddReward(findtext1)
					If RegExMatch(ItemDataSplit[8], "Награда: (.*)", findtext)
						If !RegExMatch(findtext1, "Удваивает")
								ItemMenu_AddReward(findtext1)
				}
			}
			
			If (ItemDataSplit[6]="Уровень карты: 17")
				If RegExMatch(ItemDataSplit[7], "Награда: Особ(ая|ый|ое|ые) (.*)", findtext) {
					Menu, itemMenu, Add
					ItemMenu_AddReward(findtext2)
				}
			
			Menu, itemMenu, Add
		}
		
		;Пункты для копирования имени предмета
		ItemMenu_AddCopyInBuffer(iName)
		
		;Пункт меню для конвертирования описания
		;Menu, itemMenu, Add
		Menu, itemMenu, Add, Ru>En Конвертер(Основной), ItemMenu_ConvertFromGame
		If FileExist("Data\imgs\copy.png")
			Menu, itemMenu, Icon, Ru>En Конвертер(Основной), Data\imgs\copy.png
		If (iRarity="Редкий") {
			Menu, itemMenu, Add, Ru>En Конвертер(Расширенный), ItemMenu_ConvertFromGamePlus
			If FileExist("Data\imgs\copy.png")
				Menu, itemMenu, Icon, Ru>En Конвертер(Расширенный), Data\imgs\copy.png
		}
		Menu, itemMenu, Add	
		
		;Создадим меню для подсветки
		ItemMenu_AddHightlight(iName)
		
		ItemMenu_AddHightlight(iClass)
		If (iRarity!=""){
			ItemMenu_AddHightlight(iRarity)
			If (iRarity!=iClass)
				ItemMenu_AddHightlight("""" iClass """ """ iRarity """")
		}
		
		If (iClass="Валюта") &&& RegExMatch(iName, "Essence") {
			splitItemName:=StrSplit(iName, " ")
			For k, val in splitItemName
				If StrLen(splitItemName[k])>2
					ItemMenu_AddHightlight(splitItemName[k])
		}
		
		If RegExMatch(iClass, "Камни"){
			If RegExMatch(iName, "^Awakened")
				ItemMenu_AddHightlight("Awakened")
			If RegExMatch(ItemData, "U)Уровень: (.*) \(макс.\)`n", res)
				ItemMenu_AddHightlight("""" res """")
			If RegExMatch(ItemData, "U)Качество: +(.*)% \(augmented\)`n", res)
				If (res1>=20)
					ItemMenu_AddHightlight("""" StrReplace(res, " (augmented)", "") """")
		}
		
		If (RegExMatch(iClass, "(Камни|Микстуры|Флакон|флакон)", res) && RegExMatch(ItemData, "Качество: "))
			ItemMenu_AddHightlight("""" res1 """ ""Качество""")

		
		For k, val in ItemDataSplit {
			If RegExMatch(ItemDataSplit[k], "Уровень (предмета|карты): (.*)", findtext)
				ItemMenu_AddHightlight(findtext)
			If RegExMatch(ItemDataSplit[k], "(Предмет Создателя|Древний предмет|Расколотый предмет|Синтезированный предмет|Предмет Вождя|Предмет Избавительницы|Предмет Крестоносца|Предмет Охотника|Завуалированный|Область находится под влиянием Древнего|Область находится под влиянием Создателя|Предмет Пожирателя миров|Предмет Пламенного экзарха|Неопознано|Осквернено|Отражено|Разделено)", findtext)
				ItemMenu_AddHightlight(findtext)
			If ((iClass="Чертежи" || iClass="Контракты") && RegExMatch(ItemDataSplit[k], "Требуется (.*) \(\d+", findtext))
				ItemMenu_AddHightlight(findtext1)
			If (iClass="Журналы экспедиции" && RegExMatch(ItemDataSplit[k], "(Друиды Разомкнутого круга|Наёмники Чёрной косы|Рыцари Солнца|Орден Чаши)", findtext)=1)
				ItemMenu_AddHightlight(findtext1)
			If (iName="Chronicle of Atzoatl" && RegExMatch(ItemDataSplit[k], "(Аудитория Дориани|Очаг осквернения)", findtext))
				ItemMenu_AddHightlight(findtext)
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

ItemMenu_AddReward(Line) {
	Menu, itemMenu, Add, PoE\trade > '%Line%', ItemMenu_OpenRewardOnTrade
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
	urltype:=(Globals.Get("IDCL_Rarity")="Уникальный")?"name":"type"
	url:="https://www.pathofexile.com/trade/search/" league "?q={%22query%22:{%22" urltype "%22:%22" Line "%22}}"
	run,"%url%"
	return
}

ItemMenu_OpenRewardOnTrade(Line){
	Line:=searchName(Line)
	IniRead, league, %configFile%, settings, league, Standard
	ItemData:=Globals.Get("ItemDataFullText")
	urltype:=(RegExMatch(Globals.Get("IDCL_ItemData"), "Уровень карты: 17") || ((Globals.Get("IDCL_Name")="Inscribed Ultimatum") && !RegExMatch(Globals.Get("IDCL_ItemData"), "Требуется жертвоприношение: (.*) x\d+")))?"name":"type"
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
	ResultExtension:=ItemMenu_LoadDataFile("https://raw.githubusercontent.com/" githubUser "/" prjName "/master/Data/JSON/extension.json", "Data\JSON\extension.json")
	sleep 100
	
	FileRead, stats_list, Data\JSON\stats.json
	Globals.Set("item_stats", JSON.Load(stats_list))
	FileRead, names_list, Data\JSON\names.json
	Globals.Set("item_names", JSON.Load(names_list))
	
	If (ResultNames || ResultStats || ResultExtension)
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
