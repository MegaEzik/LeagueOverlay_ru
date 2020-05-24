
FileSelectFile, FilePath, , %A_MyDocuments%\AutoHotKey\LeagueOverlay_ru\settings.ini, Укажите путь к файлу конфигурации, Файл конфигурации (settings.ini)
if (FilePath!="" && FileExist(FilePath)) {
	IniWrite, 1, %FilePath%, settings, debugMode
	sleep 10
	IniRead, debugMode, %FilePath%, settings, debugMode, 1
	If (debugMode) {
		Msgbox, 0x1040, DebugOn, Режим разработчика активирован), 2
		ExitApp
	}
}

msgbox, 0x1010, DebugOn, В процессе произошла ошибка!, 2
ExitApp
