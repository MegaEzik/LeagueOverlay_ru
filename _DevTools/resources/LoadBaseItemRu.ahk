/*
15.12.2017
v0.3
idae(iade)

��������� ���� nameItemRuToEn.json ����������� ������������� ������ ������������ 
������� ���� ��������� �� ������� ����� �� ���������� ���������

������������ ������������ ���� en_items.json ����������� � ������� ������� BaseItem_new.ahk
��� ���������� ����������� � ����� 
\data\lang\

������� ����� �������������� � ������� ����� 
http://poedb.tw/ru/

��������� �������������� ���� nameItemRuToEn.json � ���� nameItemRuToEn.txt �� ������� ����� !!!������!!!

������ ������� �� �������������, ������� ������ �� ������ ������� �������� �� ��� �� ������� ��
���������� ����� �� ���� ��������� ��������� ;)
��� �� � ���� http://poedb.tw/ru/ ������������ ����������� � ���������� ���������, ������� ��������� �� ���� ��������
��������, ����� �� ��������������� ��������� �������� � ��� ���������� ��������������

�� ������������� ������������ ������ ������ ��� �������� �������� ������ ����� nameItemRuToEn.json
�.�. �������� ���� ��������������� �������. ������ ������ ��������� ������ ��� ������������
������ ����� nameItemRuToEn.json


��� ��������� ��������� � ���������� ����� nameItemRuToEn.json
���������� ������������ �������:
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

SplashTextOn, 300, 20, %A_ScriptName%, ������ ��������, ��������...


IfExist, %A_ScriptDir%\Log.txt
	; ������� ��� ����
	FileDelete, %A_ScriptDir%\Log.txt

FileDelete, %A_ScriptDir%\data\lang\nameItemRuToEn.txt

FileRead, enItem, %A_ScriptDir%\data\lang\en_items.json

dataItem := JSON.Load(enItem)
dataItem := dataItem["result"]

tmpSort := {}

For key, arrItem in dataItem {
	For key, item in arrItem["entries"] {
		
		nameEn := item.type

		; ��� ���������� ��������� ����� ������������ ��� ��������, � �� ��� ����		
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
				nameItemRuToEn["!!!������!!!"] := nameEn
				FileAppend, nameItemRuToEn["!!!������!!!"] := "%nameEn%"`n,  %A_ScriptDir%\data\lang\nameItemRuToEn.txt
			}
		}
		

	}	
}


dumpObj := JSON.Dump(nameItemRuToEn,,1)

FileDelete, %A_ScriptDir%\data\lang\nameItemRuToEn.json

FileAppend, %dumpObj%, %A_ScriptDir%\data\lang\nameItemRuToEn.json

SplashTextOff

Msgbox ��� �����������`n��������� ���������� ��������



GetPoedbItemName(nameEn_, url)
{

	
	; ���������� ������� ��������� ������ �� �����  � ������ ������
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
	;FileAppend, %HtmlTxt% `n###################################`n, %A_ScriptDir%\Log.txt

;Msgbox % whr.ResponseText
;<span class="ItemName">��� ��������</span>
	
	; ����� ��������� ��� �������� � ������� ���������
	RegExMatch(HtmlTxt, "<span class=.ItemName.>([�-��-� -�]+)</span>", ItemNameRu)
	;Msgbox % ItemNameRu1
	
	return ItemNameRu1

/* ; ������-�� �� ������ ����� �������� ��������
	teg_ := 
	
	ElementsByTagName := HTMLObj.getElementsByTagName("span")
	teg_ := ElementsByTagName[0]
	
	; � ����� ��������� �� ����� span
	While (teg_)	
    {	
		teg_ := ElementsByTagName[A_Index]
		;Msgbox % teg_.innerHTML
		;Msgbox % teg_.className
		
		; ����������� �� ���� ���������� ����� ItemName
		if (teg_.className = "ItemName")
		{	; ������ ����� ������ ����
			;Msgbox % teg_.innerHTML
			return teg_.innerHTML
        }
    }
*/
	
	
}