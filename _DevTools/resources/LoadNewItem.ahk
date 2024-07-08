/*
12.02.2019 MegaEzik
v0.3.1
��������� url

26.11.2018
v0.3
������������� ����������� ���������

04.06.2018
v0.2
��������� ��������� ������� � ���������� �������

14.03.2018
v0.1
idae(iade)

���������� ���� � ������ ���������� NewItem.txt  ��������� �������� Meld_nameItemRuToEn__ru_items_.ahk

���� ����� ��������� ��� �������, ��� � ���������� ��������

����� �������������� � ������� ����� 
http://poedb.tw/ru/

� ���������� ��� ������ ��������� ��������� �����:
	- \NewItemError.txt - ����� ���������, ������� �� ���� ���������������
	- \Log.txt - ������ ����� poedb.tw/ru/  ������� ����� ������������ ��� ������� ����������� ���������
	������������ �� ���� ������� ����� ��������� �������������� �� ���������� ��� �������. ���������� � ��������� ������� 
	����� ������������ �����������, ������� ���������� ��������� ���� ��������� ��������������
	- \data\lang\newNameItemRuToEn.json - ����� ��������� ������������� ������ � ������� ����� ���������,
	������� ����� ��������� � nameItemRuToEn.json


������ ����� ��� ����, ����� �� ������������� �������� ���� nameItemRuToEn.json, � ������� � ���� ������ ���������

*/



#Include, %A_ScriptDir%\lib\JSON.ahk


; ���� � ����� ���������
;url_en := "http://poedb.tw/ru/item.php?n="
;url_ru := "http://poedb.tw/ru/search.php?Search="
url_ru := "http://poedb.tw/ru/search.php?q="

SplashTextOn, 300, 20, %A_ScriptName%, ������ ��������, ��������...

FileDelete, %A_ScriptDir%\data\lang\newNameItemRuToEn.txt

; ������� ��� ����
FileDelete, %A_ScriptDir%\Log.txt

FileDelete, %A_ScriptDir%\NewItemError.txt

FileRead, newItemName, %A_ScriptDir%\NewItem.txt

nameItemRuToEn := {}


Loop, Parse, newItemName, `n, `r
{
	newName := Trim(A_LoopField, " `t`n`r")
	
	If (newName ) {
		If RegExMatch(newName, "[�-��-߸�IV\- ,]+") 
		{		
;msgbox ru %newName%		
			nameEn := GetPoedbItemNameRuToEn(newName, url_ru)
			
			If ( nameEn ) {
				nameItemRuToEn[newName] := nameEn
				FileAppend, nameItemRuToEn["%newName%"] := "%nameEn%"`n,  %A_ScriptDir%\data\lang\newNameItemRuToEn.txt
			}
			Else {
				;nameItemRuToEn[newName] := "!!!������!!!"
				FileAppend, nameItemRuToEn["%newName%"] := "!!!������!!!"`n,  %A_ScriptDir%\data\lang\newNameItemRuToEn.txt
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
				;nameItemRuToEn[newName] := "!!!������!!!"
				FileAppend, nameItemRuToEn["%nameRu%"] := "!!!������!!!"`n,  %A_ScriptDir%\data\lang\newNameItemRuToEn.txt
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

	
	; ���������� ������� ��������� ������ �� ����� ���� � ������ ������
	num_err := 5
	
	err := 1
	whr :=
	
	While (err)
    {
		whr_ := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr_.Open("GET", url . nameEn_, true)	

		; ���������� ������
		whr_.Send()
		; ����
		whr_.WaitForResponse(10)
		err := A_LastError
		
		; ���� ��� ������, �� ������� �� �����
		IF (!A_LastError) 
		{
			Break
		}
		
		;Msgbox % whr.ResponseText
		Msgbox ������ ����������� � �����!`n���������� �������� ������:  %nameEn_% `n%A_Index%  `n %url%%nameEn_%
		
		; ���� ��������� ���������� ��������� ����������� - �������
		IF (A_Index >= num_err)
		{
			Msgbox ��������� ���������� ���������� ��������� �����������.`n�����
			exit
		}
	}

	HTMLObj := ""
	
	HTMLObj := ComObjCreate( "HTMLFile" )
	HTMLObj.Write( whr_.ResponseText )


	HtmlTxt := whr_.ResponseText
	FileAppend, %HtmlTxt% `n###################################`n, %A_ScriptDir%\Log.txt

 	; <ul class="list-group"><li class="list-group-item"><a href='mon.php?n=The+Great+White+Beast'>������� ����� �����(The Great White Beast)</a></li><li class="list-group-item"><a href='quest.php?n=The+Great+White+Beast'>������� ����� �����</a>(The Great White Beast)</li></ul>
	; <ul class="list-group"><li class="list-group-item"><a href='mon.php?n=Corrupted+Beast'>��������� �����(Corrupted Beast)</a></li></ul>

	
	;RegExMatch(HtmlTxt, ">" . nameEn_ . ".([a-zA-Z0-9_' ]+).</a></li></ul>", ItemNameEn)
	
	
	RegExMatch(HtmlTxt, ">([�-��-߸�IV\- ,]+)." . nameEn_ . ".</a></li>", ItemNameEn)
	
	
	
	;Msgbox % ItemNameEn1
	
	return ItemNameEn1
}


GetPoedbItemNameRuToEn(nameEn_, url)
{

	
	; ���������� ������� ��������� ������ �� ����� ���� � ������ ������
	num_err := 5
	
	err := 1
	whr :=
	
	While (err)
    {
		whr_ := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr_.Open("GET", url . nameEn_, true)	

		; ���������� ������
		whr_.Send()
		; ����
		whr_.WaitForResponse(10)
		err := A_LastError
		
		; ���� ��� ������, �� ������� �� �����
		IF (!A_LastError) 
		{
			Break
		}
		
		;Msgbox % whr.ResponseText
		Msgbox ������ ����������� � �����!`n���������� �������� ������:  %nameEn_% `n%A_Index%  `n %url%%nameEn_%
		
		; ���� ��������� ���������� ��������� ����������� - �������
		IF (A_Index >= num_err)
		{
			Msgbox ��������� ���������� ���������� ��������� �����������.`n�����
			exit
		}
	}

	HTMLObj := ""
	
	HTMLObj := ComObjCreate( "HTMLFile" )
	HTMLObj.Write( whr_.ResponseText )


	HtmlTxt := whr_.ResponseText
	FileAppend, %HtmlTxt% `n###################################`n, %A_ScriptDir%\Log.txt

 	; ��� �������� � ���������� ������
	;RegExMatch(HtmlTxt, ">" . nameEn_ . ".([a-zA-Z0-9_' ,]+).</a></li></ul>", ItemNameEn)
	
	;<span class="itemboxstatsgroup">Ahkeli's Mountain</span>
	RegExMatch(HtmlTxt, "<span class=.itemboxstatsgroup.>([a-zA-Z0-9_' ,]+)</span>", ItemNameEn)
	
	If (not ItemNameEn) {		
		RegExMatch(HtmlTxt, ">" . nameEn_ . ".([a-zA-Z0-9_' ,]+).</a></li><li", ItemNameEn)
	}
	
	;<ul class="list-group"><li class="list-group-item"><a class='gem_green' href='gem.php?n=Flamethrower+Trap'><img src='http://web.poecdn.com/image/Art/2DItems/Gems/DexterityGem.png' width='16'/>�������-������</a></li></ul>
	If (not ItemNameEn) {
		RegExMatch(HtmlTxt, " href=.gem.php.n=([a-zA-Z0-9_+' ,]+).><img src=.*>" . nameEn_ . "</a></li></ul", ItemNameEn)
	}
	
	; <a href='item.php?n=The+Celestial+Stone'>�������� ������</a></li></ul>
	If (not ItemNameEn) {
		RegExMatch(HtmlTxt, "<a href=.item.php.n=([a-zA-Z0-9_+' ,]+).>" . nameEn_ . "</a></li></ul", ItemNameEn)
	}
	

	ItemNameEn1 := StrReplace(ItemNameEn1, "+", " ")


	return ItemNameEn1	
}