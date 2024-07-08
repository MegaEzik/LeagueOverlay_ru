/*
14.03.2018

Скрипт для сравнения старой и новой версии файла  ru_en_stats.json 

В папку \old\  помещаем старый релизный файл ru_en_stats.json текущей версии
В папку \new\  помещаем новый ru_en_stats.json полученный с помощью скрипта StatsRuToEn.ahk

формируются два файла:
in_new.json - то что есть в новом файле, но нет в старом
in_old.json - то что есть в старом файле, но нет в новом

Как сформировать итоговый файл, есть два варианта:
- добавить в начало нового файла содержимое из in_old.json без фигурных скобок
- добавить в начало старого файла содержимое из in_new.json без фигурных скобок

Первый вариант кажется более предпочтительным, т.к. сохраняется структура нового файла и при последующих
сравнениях с новыми версиями файла, можно увидеть отличия в строках и их подкорректировать

В итоговом файле изменения отделены строкой
"###########выше изменения из файла предыдущей версии##############":"###########ниже новый файл текущей версии##############",
добавленной в файл вручную

Итоговый файл разместить в каталог \itog

*/


#Include, %A_ScriptDir%\lib\JSON.ahk

SplashTextOn, 300, 20, %A_ScriptName%, Скрипт работает, ожидайте...

FileDelete, %A_ScriptDir%\Log.txt

FileDelete, %A_ScriptDir%\in_new.json
FileDelete, %A_ScriptDir%\in_old.json


FileRead, ruStats, %A_ScriptDir%\old\ru_en_stats.json 
old_stats := JSON.Load(ruStats)

FileRead, ruStats, %A_ScriptDir%\new\ru_en_stats.json 
new_stats := JSON.Load(ruStats)

MeldStats(new_stats, old_stats, A_ScriptDir . "\in_new.json")
MeldStats(old_stats, new_stats, A_ScriptDir . "\in_old.json")

SplashTextOff


; сравнивает два массива
; в файл сохраняет изменения появившиеся в новом массиве
MeldStats(newS, oldS, fname)
{
	meldArr := {}
	
	For modRuNew, modEnNew in newS {
		modRuOld := oldS[modRuNew]
		If (not modRuOld){
			meldArr[modRuNew] := modEnNew
		}
	}

	dumpObj := JSON.Dump(meldArr,,1)

	FileDelete, %fname%

	FileAppend, %dumpObj%, %fname%	
}