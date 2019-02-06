
DownloadUberLabyrinthLayout() {
	FileDelete, resources\Labyrinth.jpg

	FormatTime, Year, %A_NowUTC%, yyyy
	FormatTime, Month, %A_NowUTC%, MM
	FormatTime, Day, %A_NowUTC%, dd
	UberLabURL:="https://poelab.com/wp-content/uploads/" Year "/" Month "/" Year "-" Month "-" Day "_uber.jpg"
	UrlDownloadToFile, %UberLabURL%, resources\Labyrinth.jpg

	FileReadLine, Line, resources\Labyrinth.jpg, 1

	if (Line=""||Line="<!DOCTYPE html>") {
		FileDelete, resources\Labyrinth.jpg
		MsgBox Не удалось получить файл с раскладкой лабиринта,`nвозможно еще нет информации на текущую дату!`n`nПопробуйте перезапустить скрипт позднее!
		FileCopy, resources\LabyrinthError.jpg, resources\Labyrinth.jpg
	}
}
