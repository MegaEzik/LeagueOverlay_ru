/*
26.11.2018
v0.3
14.03.2018
v0.2
22.01.2018
v0.1
idae(iade)

Сравнивает рабочий(используемый в текущй версии скриптов) файл nameItemRuToEn.json  содержащий массив 
соответствий русских названий предметов их английским вариантам с новой версией ru_items_.json 
и сохраняет найденные изменения в отдельный текстовый файл в виде списка NewItem.txt.
Данный файл NewItem.txt будет использоваться в другом скрипте LoadNewItem.ahk формирующем ассоциативный 
массив для добавления в файл nameItemRuToEn.json

Скрипт нужен для того, чтобы не пересоздавать релизный файл nameItemRuToEn.json, а вносить в него только изменения

Для работы скрипта необходимо поместить в папку \data\lang\ 
- nameItemRuToEn.json текущий, который хотим обновить
- ru_items_.json полученный с помощью BaseItem_new.ahk

*/

#Include, %A_ScriptDir%\lib\JSON.ahk

SplashTextOn, 300, 20, %A_ScriptName%, Скрипт работает, ожидайте...

; удаляем лог файл
FileDelete, %A_ScriptDir%\Log.txt

; удаляем файл с новыми предметами
FileDelete, %A_ScriptDir%\NewItem.txt


FileRead, ruItemEn, %A_ScriptDir%\data\lang\nameItemRuToEn.json
nameItemRuToEn := JSON.Load(ruItemEn)


nameItemEnToRu := {}
; создадим обратный массив соответствий английских названий предметов русским названиям
For ItemRuName,ItemEnName in nameItemRuToEn
{
	nameItemEnToRu[ItemEnName] := ItemRuName
}


FileRead, ruItem, %A_ScriptDir%\data\lang\ru_items_.json
dataItem := JSON.Load(ruItem)
dataItem := dataItem["result"]

tmpSort := {}

For key, arrItem in dataItem {
	For key, item in arrItem["entries"] {
		;MsgBox % item.type	
		
		nameRuNew := item.type

		; для уникальных предметов и пророчеств будем использовать имя предмета, а не его базу		
		If (item["flags"]["unique"] or item["flags"]["prophecy"]) {
				nameRuNew := item.name				
		}
		
		nameRuNew := Trim(nameRuNew)

		If ( !tmpSort[nameRuNew] ) { 
			tmpSort[nameRuNew] := "Ok!"			
						
			nameEn := nameItemRuToEn[nameRuNew]

			If ( nameEn ) {
				;nameItemRuToEn[nameEn] := nameRuNew
				;FileAppend, nameItemRuToEn["%nameEn%"] := "%nameRuNew%"`n,  %A_ScriptDir%\data\lang\nameItemRuToEn.txt
			}
			Else {
				; проявился вариант, когда имена на английском и их уже обработали и они в файле сооответствий есть
				nameEn := nameItemEnToRu[nameRuNew]
				If (not nameEn) {
			
				; все ненайденные новые названия предметов пишем в лог файл
				FileAppend, %nameRuNew%`n,  %A_ScriptDir%\Log.txt
				
				; и в файл с новыми предметами
				FileAppend, %nameRuNew%`n,  %A_ScriptDir%\NewItem.txt
				}
			}
		}
	}	
}

SplashTextOff



