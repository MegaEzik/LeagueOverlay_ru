/*
08.07.2024 MegaEzik
Добавлен GUI с общим прогрессом выполнения
Окна curl.exe теперь скрыты
Сокращены таймауты, что должно ускорить работу скрипта

30.07.2023 MegaEzik
Скрипт переведен на использование системной утилиты curl, вместо wget
Исправлено регулярное выражение

02.12.2021 MegaEzik
Добавлено новое регулярное выражение для извлечения имени из текста страницы
Теперь заменяет символы ':' и ',' в названиях полученных с ссылок

01.08.2021 MegaEzik
Исправлен URL

25.07.2020 v2 MegaEzik
Скрипт создает список новых соответствий new_itemEquality.txt, на основе списка из файла NewItem.txt и сайта https://poedb.tw/ru/
*/

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
global uiProgress, NewEquality=""

FileDelete, %A_ScriptDir%\new_itemEquality.txt

FileRead, newItemsData, %A_ScriptDir%\NewItem.txt
newItemsRu:=StrSplit(StrReplace(newItemsData, "`r", ""), "`n")

Run, https://poedb.tw/ru/
Sleep 3000

Gui ProgressUI:Add, Progress, w350 h25 BackgroundA9A9A9 vuiProgress
Gui, ProgressUI:-SysMenu +Theme +Border +AlwaysOnTop
Gui, ProgressUI:Show

numItems:=newItemsRu.maxIndex()
loop %numItems% {
	loadItem(newItemsRu[A_Index])
	cProgress:=A_Index/numItems*100
	GuiControl ProgressUI:, uiProgress, %cProgress% 
}

FileAppend, %NewEquality%, %A_ScriptDir%\new_itemEquality.txt, UTF-8

ExitApp

;==============================================

loadItem(itemNameRu){
	if (itemNameRu="")
		return
		
	FileDelete, %A_ScriptDir%\tmpPage.html
	FileDelete, %A_ScriptDir%\tmpPage.log
	sleep 15

	;WGetLine:="""" A_ScriptDir "\lib\wget.exe"" -o """ A_ScriptDir "\tmpPage.log"" -O """ A_ScriptDir "\tmpPage.html"" ""https://poedb.tw/ru/search?q=" itemNameRu ""
	;RunWait, %WGetLine%
	
	URLLine:="https://poedb.tw/ru/search?q=" StrReplace(itemNameRu, " ", "_")
	CurlLine:="curl.exe -L -A ""Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"" -o """ A_ScriptDir "\tmpPage.html"" --trace-ascii """  A_ScriptDir "\tmpPage.log"" """ URLLine """ --connect-timeout 10"
	;Clipboard:=CurlLine
	Run, "%URLLine%"
	;RunWait, %CurlLine%
	
	Sleep 50
	
	RunWait, %A_ScriptDir%\convertutf8.ahk
	FileRead, Page, %A_ScriptDir%\tmpPage.html
	
	PageSplit:=StrSplit(StrReplace(Page, "`r", ""), "`n")
	For k, val in PageSplit {
		If !RegExMatch(PageSplit[k], "{") && !RegExMatch(PageSplit[k], "}") && !RegExMatch(PageSplit[k], "[А-Яа-яЁё]+") {
			If RegExMatch(PageSplit[k], "<span class=""itemboxstatsgroup"">(.*)</span>$", itemNameEn)
				break
		}
		If RegExMatch(PageSplit[k], "BaseType <span class='fas fa-info-circle' data-toggle='tooltip' title='Item Filter'></span></td><td>(.*)</td></tr><tr><td>BaseType", itemNameEn)
			If !RegExMatch(itemNameEn1, "[А-Яа-яЁё]+")
				break
		If RegExMatch(PageSplit[k], "BaseType <span class='fas fa-info-circle' data-bs-toggle='tooltip' title='Item Filter'></span></td><td>(.*)</td></tr><tr><td>BaseType", itemNameEn)
			If !RegExMatch(itemNameEn1, "[А-Яа-яЁё]+")
				break
		If RegExMatch(PageSplit[k], "U)href='/ru/(.*)'>" itemNameRu "</a></li><li class=", itemNameEn)
			If !RegExMatch(itemNameEn1, "[А-Яа-яЁё]+")
				break
	}
	
	if (itemNameEn1="") {
		FileRead, Page, %A_ScriptDir%\tmpPage.log
		/*
		If InStr(Page, "HTTP request sent, awaiting response... 200 OK"){
			PageSplit:=StrSplit(StrReplace(Page, "`r", ""), "`n")
			For k, val in PageSplit
				If !RegExMatch(PageSplit[k], "search")
					If RegExMatch(PageSplit[k],"--  https://poedb.tw/ru/(.*)$", itemNameEn)
						break
		}
		*/
		RegExMatch(Page, "== Info: Issue another request to this URL: 'https://poedb.tw/ru/(.*)'`r`n", itemNameEn)
	}
	If (itemNameEn1!="") {
		itemNameEn1:=StrReplace(itemNameEn1, "%2C", ",")
		itemNameEn1:=StrReplace(itemNameEn1, "%3A", ":")
		;itemNameEn1:=StrReplace(itemNameEn1, "_", " ")
	}
	
	NewEquality.=" """ itemNameRu """: """ itemNameEn1 """,`r`n"
}
