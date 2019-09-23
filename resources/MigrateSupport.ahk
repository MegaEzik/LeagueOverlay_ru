
;Проверяет версию файла конфигурации, если не соответствует, то будет выполнена попытка восстановления
verifyConfig(){
	IniRead, verConfig, %configFile%, settings, verConfig, ""
	If (verConfig!=3) {
		MsgBox, 0x1040, %prjName%, Файл конфигурации устарел, поврежден или отсутствует!`nПричиной может быть новая установка, недавнее обновление или ошибка при записи на диск.`n`nСейчас будет выполнена попытка его восстановления.
		updateConfig()
	}
}

;Пересоздает файл конфигурации
updateConfig() {
	;Выполним импорт сочетания клавиш для функции Последнее изображение(ранее Лабиринт)
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLabyrinth, !f1
	IniRead, hotkeyLastImg, %configFile%, hotkeys, hotkeyLastImg, %hotkeyLastImg%
	
	;Выполним импорт настройки для использования Устаревшей раскладки клавиатуры
	IniRead, legacyHotkeys, %configFile%, settings, useOldHotkeys, 0
	IniRead, legacyHotkeys, %configFile%, settings, legacyHotkeys, %legacyHotkeys%
	
	;Выполним импорт уровня лабиринта
	IniRead, lvlLab, %configFile%, settings, lvlLabyrinth, uber
	IniRead, lvlLab, %configFile%, settings, lvlLab, %lvlLab%
	lvlLab:=(lvlLab="normal" || lvlLab="cruel" || lvlLab="merciless" || lvlLab="uber")?lvlLab:"uber"
	
	;Выполним импорт остальных настроек
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	IniRead, lastImg, %configFile%, settings, lastImg, 1
	
	;Удаляем файл
	FileDelete, %configFile%
	Sleep 25
	
	;Создаем необходимые папки, записываем значения настроек в файл конфигурации
	FileCreateDir, %configFolder%
	FileCreateDir, %configFolder%\images
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, %lvlLab%, %configFile%, settings, lvlLab
	IniWrite, %legacyHotkeys%, %configFile%, settings, legacyHotkeys
	IniWrite, %lastImg%, %configFile%, settings, lastImg
	
	;Назначим версию файла конфигурации
	IniWrite, 3, %configFile%, settings, verConfig
	Sleep 25
	Reload
}
