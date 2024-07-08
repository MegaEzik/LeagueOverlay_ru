/*
12.02.2019 MegaEzik
v0.3.1
Исправлен url

26.11.2018
v0.3
корректировка регулярного выражения

04.06.2018
v0.2
добавлена обработка страниц с гадальными картами

14.03.2018
v0.1
idae(iade)

Использует файл с новыми предметами NewItem.txt  созданный скриптом Meld_nameItemRuToEn__ru_items_.ahk

Файл может содержать как русские, так и английские названия

имена конвертируются с помощью сайта 
http://poedb.tw/ru/

В результате его работы создаются следующие файлы:
	- \NewItemError.txt - имена предметов, которые не были сконвертированы
	- \Log.txt - ответы сайта poedb.tw/ru/  которые можно использовать для отладки регулярного выражения
	извлекающего из этих ответов имена предметов соответственно на английском или русском. Содержимое и структура страниц 
	сайта периодически обновляются, поэтому регулярное выражение тоже требуется корректировать
	- \data\lang\newNameItemRuToEn.json - будет содержать ассоциативный массив с именами новых предметов,
	которые затем добавляем в nameItemRuToEn.json


Скрипт нужен для того, чтобы не пересоздавать релизный файл nameItemRuToEn.json, а вносить в него только изменения

*/



#Include, %A_ScriptDir%\lib\JSON.ahk


; сайт с базой предметов
;url_en := "http://poedb.tw/ru/item.php?n="
;url_ru := "http://poedb.tw/ru/search.php?Search="
url_ru := "http://poedb.tw/ru/search.php?q="

SplashTextOn, 300, 20, %A_ScriptName%, Скрипт работает, ожидайте...

FileDelete, %A_ScriptDir%\data\lang\newNameItemRuToEn.txt

; удаляем лог файл
FileDelete, %A_ScriptDir%\Log.txt

FileDelete, %A_ScriptDir%\NewItemError.txt

FileRead, newItemName, %A_ScriptDir%\NewItem.txt

nameItemRuToEn := {}


Loop, Parse, newItemName, `n, `r
{
	newName := Trim(A_LoopField, " `t`n`r")
	
	If (newName ) {
		If RegExMatch(newName, "[а-яА-ЯёЁIV\- ,]+") 
		{		
;msgbox ru %newName%		
			nameEn := GetPoedbItemNameRuToEn(newName, url_ru)
			
			If ( nameEn ) {
				nameItemRuToEn[newName] := nameEn
				FileAppend, nameItemRuToEn["%newName%"] := "%nameEn%"`n,  %A_ScriptDir%\data\lang\newNameItemRuToEn.txt
			}
			Else {
				;nameItemRuToEn[newName] := "!!!Ошибка!!!"
				FileAppend, nameItemRuToEn["%newName%"] := "!!!Ошибка!!!"`n,  %A_ScriptDir%\data\lang\newNameItemRuToEn.txt
				FileAppend, %newName%`n,  %A_ScriptDir%\NewItemError.txt
			}			
		

		} Else {
;msgbox en %newName%			
			nameRu := GetPoedbItemNameEnToRu(newName, url_ru)
			
			If ( nameRu ) {
				nameItemRuToEn[nameRu] := newName
				FileAppend, nameItemRuToEn["%nameRu%"] := "%newName%"`n,  %A_ScriptDir%\data\lang\newNameItemRuToEn.txt
			}
			Else {
				;nameItemRuToEn[newName] := "!!!Ошибка!!!"
				FileAppend, nameItemRuToEn["%nameRu%"] := "!!!Ошибка!!!"`n,  %A_ScriptDir%\data\lang\newNameItemRuToEn.txt
				FileAppend, %nameRu%`n,  %A_ScriptDir%\NewItemError.txt
			}	
		}
	}


}


dumpObj := JSON.Dump(nameItemRuToEn,,1)

FileDelete, %A_ScriptDir%\data\lang\newNameItemRuToEn.json

FileAppend, %dumpObj%, %A_ScriptDir%\data\lang\newNameItemRuToEn.json

SplashTextOff


GetPoedbItemNameEnToRu(nameEn_, url)
{

	
	; количество попыток получения ответа от сайта вики в случае ошибки
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
	FileAppend, %HtmlTxt% `n###################################`n, %A_ScriptDir%\Log.txt

 	; <ul class="list-group"><li class="list-group-item"><a href='mon.php?n=The+Great+White+Beast'>Великий белый зверь(The Great White Beast)</a></li><li class="list-group-item"><a href='quest.php?n=The+Great+White+Beast'>Великий белый зверь</a>(The Great White Beast)</li></ul>
	; <ul class="list-group"><li class="list-group-item"><a href='mon.php?n=Corrupted+Beast'>Искажённый зверь(Corrupted Beast)</a></li></ul>

	
	;RegExMatch(HtmlTxt, ">" . nameEn_ . ".([a-zA-Z0-9_' ]+).</a></li></ul>", ItemNameEn)
	
	
	RegExMatch(HtmlTxt, ">([а-яА-ЯёЁIV\- ,]+)." . nameEn_ . ".</a></li>", ItemNameEn)
	
	
	
	;Msgbox % ItemNameEn1
	
	return ItemNameEn1
}


GetPoedbItemNameRuToEn(nameEn_, url)
{

	
	; количество попыток получения ответа от сайта вики в случае ошибки
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
	FileAppend, %HtmlTxt% `n###################################`n, %A_ScriptDir%\Log.txt

 	; это работало в предыдущей версии
	;RegExMatch(HtmlTxt, ">" . nameEn_ . ".([a-zA-Z0-9_' ,]+).</a></li></ul>", ItemNameEn)
	
	;<span class="itemboxstatsgroup">Ahkeli's Mountain</span>
	RegExMatch(HtmlTxt, "<span class=.itemboxstatsgroup.>([a-zA-Z0-9_' ,]+)</span>", ItemNameEn)
	
	If (not ItemNameEn) {		
		RegExMatch(HtmlTxt, ">" . nameEn_ . ".([a-zA-Z0-9_' ,]+).</a></li><li", ItemNameEn)
	}
	
	;<ul class="list-group"><li class="list-group-item"><a class='gem_green' href='gem.php?n=Flamethrower+Trap'><img src='http://web.poecdn.com/image/Art/2DItems/Gems/DexterityGem.png' width='16'/>Ловушка-огнемёт</a></li></ul>
	If (not ItemNameEn) {
		RegExMatch(HtmlTxt, " href=.gem.php.n=([a-zA-Z0-9_+' ,]+).><img src=.*>" . nameEn_ . "</a></li></ul", ItemNameEn)
	}
	
	; <a href='item.php?n=The+Celestial+Stone'>Небесный камень</a></li></ul>
	If (not ItemNameEn) {
		RegExMatch(HtmlTxt, "<a href=.item.php.n=([a-zA-Z0-9_+' ,]+).>" . nameEn_ . "</a></li></ul", ItemNameEn)
	}
	

	ItemNameEn1 := StrReplace(ItemNameEn1, "+", " ")


	return ItemNameEn1	
}