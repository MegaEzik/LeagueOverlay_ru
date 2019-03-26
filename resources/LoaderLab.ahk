
DownloadLabyrinthLayout(lvllab) {
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
