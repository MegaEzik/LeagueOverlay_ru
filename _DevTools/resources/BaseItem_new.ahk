/*
v0.5 MegaEzik
30.07.2023
Удалена библиотека JSON_.ahk, скрипт работает и без нее

v0.4 MegaEzik
30.11.2021
Кодировка скрипта изменена на UTF-8-RAW, для корректного преобразования кодировки загружаемых файлов
Добавлена функция для пересохранения файлов в кодировке UTF-8-BOM
Функция ConvertUtfAnsi больше не используется

20.11.2018
v0.3
idae(iade)

Используются скрипты из оригинального POE-TradeMacro

Скрипт скачивает следующие файлы: 

en_items.json
en_static.json
en_stats.json

ru_basic.json
ru_items.json
ru_static.json
ru_stats.json

куда качаем:
\data\lang\

русские файлы имеют utf кодировку, конвертируем их 
ru_stats_.json - аффиксы
ru_static_.json - гадальные карты, карты и валюта
ru_items_.json - названия предметов

Это файлы-основа, далее они используются для создания файлов со списками соответствий

*/

FileEncoding, UTF-8-RAW
#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir, %A_ScriptDir%
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.



#Include, %A_ScriptDir%\lib\PoEScripts_DownloadLanguageFiles.ahk
#Include, %A_ScriptDir%\lib\PoEScripts_Download.ahk
#Include, %A_ScriptDir%\lib\func.ahk
#Include, %A_ScriptDir%\lib\JSON.ahk
; аналогичный предыдущему, только с другим именем класса, т.к. из-за функции PoEScripts_ConvertJSVariableFileToJSON 
; оригинальный JSON не работает
;#Include, %A_ScriptDir%\lib\JSON_.ahk

currentLocale := "ru"


; скачивает только русский и английский языки
PoEScripts_DownloadLanguageFiles(currentLocale, false, "PoE-ItemInfo", "Updating and parsing language files...", false)

; скачивает все языки
;PoEScripts_DownloadLanguageFiles(currentLocale, false, "PoE-ItemInfo", "Updating and parsing language files...", true)


; конвертируем в человекочитаемый вид
ru_name := A_ScriptDir . "\data\lang\ru_items.json"
;ConvertUtfAnsi(ru_name)
UtfConvert(ru_name)

ru_name := A_ScriptDir . "\data\lang\ru_static.json"
;ConvertUtfAnsi(ru_name)
UtfConvert(ru_name)

ru_name := A_ScriptDir . "\data\lang\ru_stats.json"
;ConvertUtfAnsi(ru_name)
UtfConvert(ru_name)

SplashTextOff

UtfConvert(fileName){
	fileName_ := RegExReplace(fileName, "\.", "_.")
	FileRead, FileData, %fileName%
	FileDelete, %fileName_%
	FileAppend, %FileData%, %fileName_%, UTF-8
}

ConvertUtfAnsi(fileName)
{

	FileRead, tData, %fileName%

	dataItem := JSON.Load(tData)

	fileName_ := RegExReplace(fileName, "\.", "_.")
	
	dumpObj := JSON.Dump(dataItem,,1)

	FileDelete, %fileName_%
	FileAppend, %dumpObj%, %fileName_%
}

