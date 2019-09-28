
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabLayout() {
	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd
	
	IniRead, lvlLab, %configFile%, settings, lvlLab, uber
	
	FileDelete, %configFolder%\Lab.jpg
	LabURL:="https://poelab.com/wp-content/labfiles/" Year "-" Month "-" Day "_" lvlLab ".jpg"
	UrlDownloadToFile, %LabURL%, %configFolder%\Lab.jpg

	FileReadLine, Line, %configFolder%\Lab.jpg, 1
	if (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\Lab.jpg
		LabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_" lvlLab ".jpg"
		UrlDownloadToFile, %LabURL%, %configFolder%\Lab.jpg
	}
	
	FileReadLine, Line, %configFolder%\Lab.jpg, 1
	if (Line="" || (InStr(Line, "<") && InStr(Line, ">")) || InStr(Line, "ban") || InStr(Line, "error")) {
		FileDelete, %configFolder%\Lab.jpg
		MsgBox, 0x1040, %prjName%, Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!
	}
}

;Меню
menuLabCreate(){
	Menu, labMenu, Add, Лабиринт, selectNormalLab
	Menu, labMenu, Add, Жестокий Лабиринт, selectCruelLab
	Menu, labMenu, Add, Безжалостный Лабиринт, selectMercilessLab
	Menu, labMenu, Add, Лабиринт Вечных, selectUberLab
	Menu, Tray, Add, Изменить уровень лабиринта, :labMenu
	Menu, Tray, Add
	
	IniRead, lvlLab, %configFile%, settings, lvlLab, uber
	if (lvlLab="normal")
	Menu, labMenu, Check, Лабиринт
	if (lvlLab="cruel")
	Menu, labMenu, Check, Жестокий Лабиринт
	if (lvlLab="merciless")
	Menu, labMenu, Check, Безжалостный Лабиринт
	if (lvlLab="uber")
	Menu, labMenu, Check, Лабиринт Вечных
}

;Запись уровня лабиринта в файл конфигурации
setLvlLab(lvl){
	IniWrite, %lvl%, %configFile%, settings, lvlLab
	Run, https://www.poelab.com/
	Sleep 50
	Reload
}

;Применение настроек - Лабиринт
selectNormalLab(){
	setLvlLab("normal")
}

;Применение настроек - Жестокий Лабиринт
selectCruelLab(){
	setLvlLab("cruel")
}

;Применение настроек - Безжалостный Лабиринт
selectMercilessLab(){
	setLvlLab("merciless")
}

;Применение настроек - Лабиринт Вечных
selectUberLab(){
	setLvlLab("uber")
}
