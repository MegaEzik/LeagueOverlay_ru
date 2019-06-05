
downloadLabyrinthLayout(lvllab) {
	FileDelete, resources\images\Labyrinth.jpg

	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd
	LabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_" lvllab ".jpg"
	UrlDownloadToFile, %LabURL%, resources\images\Labyrinth.jpg

	FileReadLine, Line, resources\images\Labyrinth.jpg, 1

	if (Line=""||Line="<!DOCTYPE html>") {
		FileDelete, resources\images\Labyrinth.jpg
		MsgBox Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!
		FileCopy, resources\images\LabyrinthError.jpg, resources\images\Labyrinth.jpg
	}
}

initLabyrinth(){
	IniRead, lvlLabyrinth, %configFile%, settings, lvlLabyrinth, "uber"
	lvlLabyrinth:=(lvlLabyrinth="merc")?"merciless":lvlLabyrinth
	lvlLabyrinth:=(lvlLabyrinth="normal" || lvlLabyrinth="cruel" || lvlLabyrinth="merciless" || lvlLabyrinth="uber")?lvlLabyrinth:"uber"
	
	downloadLabyrinthLayout(lvlLabyrinth)
	
	Menu, Tray, Add, Normal, selectNormalLab
	Menu, Tray, Add, Cruel, selectCruelLab
	Menu, Tray, Add, Merciless, selectMercilessLab
	Menu, Tray, Add, Eternal, selectUberLab
	Menu, Tray, Add
	
	if (lvlLabyrinth="normal")
	Menu, Tray, Check, Normal
	if (lvlLabyrinth="cruel")
	Menu, Tray, Check, Cruel
	if (lvlLabyrinth="merciless")
	Menu, Tray, Check, Merciless
	if (lvlLabyrinth="uber")
	Menu, Tray, Check, Eternal
}

setLvlLabyrinth(lvl){
	IniWrite, %lvl%, %configFile%, settings, lvlLabyrinth
	sleep 50
	Reload
}

selectNormalLab(){
	setLvlLabyrinth("normal")
}

selectCruelLab(){
	setLvlLabyrinth("cruel")
}

selectMercilessLab(){
	setLvlLabyrinth("merc")
}

selectUberLab(){
	setLvlLabyrinth("uber")
}
