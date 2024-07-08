/*
15.12.2017
v0.3
idae(iade)

Формирует файл nameItemRuToEn.json соодержащий ассоциативный массив соответствий 
базовых имен предметов на русском языке их английским вариантам

Используется оригинальный файл en_items.json полученнный с помощью скрипта BaseItem_new.ahk
Его необходимо скопировать в папку 
\data\lang\

Русские имена конвертируются с помощью сайта 
http://poedb.tw/ru/

Проверить сформированный файл nameItemRuToEn.json и файл nameItemRuToEn.txt на наличие строк !!!Ошибка!!!

Работа скрипта не гарантируется, простой запуск на другой системе отличной от той на которой он
создавался может не дать ожидаемый результат ;)
Так же и сайт http://poedb.tw/ru/ периодически обновляется и регулярное выражение, которое извлекает из тела страницы
названия, может не соответствовать структуре страницы и его необходимо корректировать

Не рекомендуется использовать данный скрипт для создания релизной версии файла nameItemRuToEn.json
т.к. релизный файл корректировался вручную. Данный скрипт применять только при пересоздании
заново файла nameItemRuToEn.json


Для получения изменений и обновления файла nameItemRuToEn.json
необходимо использовать скрипты:
- Meld_nameItemRuToEn__ru_items_.ahk
- LoadNewItem.ahk

*/

#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir, %A_ScriptDir%
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

#Include, %A_ScriptDir%\lib\JSON.ahk


;
url := "http://poedb.tw/ru/item.php?n="

nameItemRuToEn := {}

SplashTextOn, 300, 20, %A_ScriptName%, Скрипт работает, ожидайте...


IfExist, %A_ScriptDir%\Log.txt
	; удаляем лог файл
	FileDelete, %A_ScriptDir%\Log.txt

FileDelete, %A_ScriptDir%\data\lang\nameItemRuToEn.txt

FileRead, enItem, %A_ScriptDir%\data\lang\en_items.json

dataItem := JSON.Load(enItem)
dataItem := dataItem["result"]

tmpSort := {}

For key, arrItem in dataItem {
	For key, item in arrItem["entries"] {
		
		nameEn := item.type

		; для уникальных предметов будем использовать имя предмета, а не его базу		
		If (item["flags"]["unique"]) {
				nameEn := item.name				
		}

		If ( !tmpSort[nameEn] ) { 
			tmpSort[nameEn] := "Ok!"			
						
			nameRu := GetPoedbItemName(nameEn, url)

			If ( nameRu ) {
				nameItemRuToEn[nameRu] := nameEn
				FileAppend, nameItemRuToEn["%nameRu%"] := "%nameEn%"`n,  %A_ScriptDir%\data\lang\nameItemRuToEn.txt
			}
			Else {
				nameItemRuToEn["!!!Ошибка!!!"] := nameEn
				FileAppend, nameItemRuToEn["!!!Ошибка!!!"] := "%nameEn%"`n,  %A_ScriptDir%\data\lang\nameItemRuToEn.txt
			}
		}
		

	}	
}


dumpObj := JSON.Dump(nameItemRuToEn,,1)

FileDelete, %A_ScriptDir%\data\lang\nameItemRuToEn.json

FileAppend, %dumpObj%, %A_ScriptDir%\data\lang\nameItemRuToEn.json

SplashTextOff

Msgbox Фйл сформирован`nПроведите визуальный контроль



GetPoedbItemName(nameEn_, url)
{

	
	; количество попыток получения ответа от сайта  в случае ошибки
	num_err := 5
	
	err := 1
	whr :=
	
	While (err)
    {
		whr_ := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr_.Open("GET", url . nameEn_, true)	

		; отправляем запрос
		whr_.Send()
		; ждем
		whr_.WaitForResponse(10)
		err := A_LastError
		
		; если без ошибок, то выходим из цикла
		IF (!A_LastError) 
		{
			Break
		}
		
		;Msgbox % whr.ResponseText
		Msgbox Ошибка подключения к сайту!`nНевозможно получить строку:  %nameEn_% `n%A_Index%  `n %url%%nameEn_%
		
		; если привышено количество ошибочных подключений - выходим
		IF (A_Index >= num_err)
		{
			Msgbox Превышено предельное количество ошибочных подключений.`nВыход
			exit
		}
	}

	HTMLObj := ""
	
	HTMLObj := ComObjCreate( "HTMLFile" )
	HTMLObj.Write( whr_.ResponseText )


	HtmlTxt := whr_.ResponseText
	;FileAppend, %HtmlTxt% `n###################################`n, %A_ScriptDir%\Log.txt

;Msgbox % whr.ResponseText
;<span class="ItemName">Рог Абберата</span>
	
	; будем извлекать имя предмета с помощью регулярки
	RegExMatch(HtmlTxt, "<span class=.ItemName.>([а-яА-Я -ё]+)</span>", ItemNameRu)
	;Msgbox % ItemNameRu1
	
	return ItemNameRu1

/* ; почему-то на другом компе перстало работать
	teg_ := 
	
	ElementsByTagName := HTMLObj.getElementsByTagName("span")
	teg_ := ElementsByTagName[0]
	
	; в цикле пройдемся по тегам span
	While (teg_)	
    {	
		teg_ := ElementsByTagName[A_Index]
		;Msgbox % teg_.innerHTML
		;Msgbox % teg_.className
		
		; остановимся на теге содержащем класс ItemName
		if (teg_.className = "ItemName")
		{	; вернем текст внутри тега
			;Msgbox % teg_.innerHTML
			return teg_.innerHTML
        }
    }
*/
	
	
}