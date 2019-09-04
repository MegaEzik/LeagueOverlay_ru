﻿
;Проверяет версию файла конфигурации, если не соответствует, то будет выполнена попытка восстановления
verifyConfig(){
	IniRead, verConfig, %configFile%, settings, verConfig, ""
	If (verConfig!=2) {
		MsgBox, 0x1040, %prjName%, Файл конфигурации устарел, поврежден или отсутствует!`n`nСейчас будет выполнена попытка его восстановления.
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
	
	;Выполним импорт остальных настроек
	IniRead, hotkeyMainMenu, %configFile%, hotkeys, hotkeyMainMenu, !f2
	
	;Удаляем файл
	FileDelete, %configFile%
	Sleep 25
	
	;Создаем необходимые папки, записываем значения настроек в файл конфигурации
	FileCreateDir, %configFolder%
	FileCreateDir, %configFolder%\images
	IniWrite, %hotkeyLastImg%, %configFile%, hotkeys, hotkeyLastImg
	IniWrite, %hotkeyMainMenu%, %configFile%, hotkeys, hotkeyMainMenu
	IniWrite, uber, %configFile%, settings, lvlLab
	IniWrite, %legacyHotkeys%, %configFile%, settings, legacyHotkeys
	
	;Назначим версию файла конфигурации
	IniWrite, 2, %configFile%, settings, verConfig
	Sleep 25
	Reload
}
