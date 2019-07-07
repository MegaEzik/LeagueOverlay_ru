
;Загрузка изображения с раскладкой лабиринта соответствующего уровня
downloadLabyrinthLayout(lvllab) {
	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd
	
	FileDelete, resources\images\Labyrinth.jpg
	LabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_" lvllab ".jpg"
	UrlDownloadToFile, %LabURL%, resources\images\Labyrinth.jpg

	FileReadLine, Line, resources\images\Labyrinth.jpg, 1
	if (Line="" || (InStr(Line, "<") && InStr(Line, ">"))) {
		FileDelete, resources\images\Labyrinth.jpg
		LabURL:="https://poelab.com/wp-content/labfiles/" Year "-" Month "-" Day "_" lvllab ".jpg"
		UrlDownloadToFile, %LabURL%, resources\images\Labyrinth.jpg
	}
	
	FileReadLine, Line, resources\images\Labyrinth.jpg, 1
	if (Line="" || (InStr(Line, "<") && InStr(Line, ">"))) {
		FileDelete, resources\images\Labyrinth.jpg
		MsgBox, 0x1040, %prjName%, Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!
		FileCopy, resources\images\LabyrinthError.jpg, resources\images\Labyrinth.jpg
	}
}

;Инициализация в теле скрипта - добавление пунктов меню
initLabyrinth(){
	IniRead, lvlLabyrinth, %configFile%, settings, lvlLabyrinth, "uber"
	lvlLabyrinth:=(lvlLabyrinth="normal" || lvlLabyrinth="cruel" || lvlLabyrinth="merciless" || lvlLabyrinth="uber")?lvlLabyrinth:"uber"
	
	downloadLabyrinthLayout(lvlLabyrinth)
	
	Menu, labMenu, Add, Лабиринт, selectNormalLab
	Menu, labMenu, Add, Жестокий Лабиринт, selectCruelLab
	Menu, labMenu, Add, Безжалостный Лабиринт, selectMercilessLab
	Menu, labMenu, Add, Лабиринт Вечных, selectUberLab
	Menu, Tray, Add, Изменить уровень лабиринта, :labMenu
	Menu, Tray, Add
	
	if (lvlLabyrinth="normal")
	Menu, labMenu, Check, Лабиринт
	if (lvlLabyrinth="cruel")
	Menu, labMenu, Check, Жестокий Лабиринт
	if (lvlLabyrinth="merciless")
	Menu, labMenu, Check, Безжалостный Лабиринт
	if (lvlLabyrinth="uber")
	Menu, labMenu, Check, Лабиринт Вечных
}

;Запись уровня лабиринта в файл конфигурации
setLvlLabyrinth(lvl){
	IniWrite, %lvl%, %configFile%, settings, lvlLabyrinth
	sleep 50
	Reload
}

;Применение настроек - Лабиринт
selectNormalLab(){
	setLvlLabyrinth("normal")
}

;Применение настроек - Жестокий Лабиринт
selectCruelLab(){
	setLvlLabyrinth("cruel")
}

;Применение настроек - Безжалостный Лабиринт
selectMercilessLab(){
	setLvlLabyrinth("merciless")
}

;Применение настроек - Лабиринт Вечных
selectUberLab(){
	setLvlLabyrinth("uber")
}
