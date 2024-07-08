/*
26.11.2018
v0.3
14.03.2018
v0.2
22.01.2018
v0.1
idae(iade)

���������� �������(������������ � ������ ������ ��������) ���� nameItemRuToEn.json  ���������� ������ 
������������ ������� �������� ��������� �� ���������� ��������� � ����� ������� ru_items_.json 
� ��������� ��������� ��������� � ��������� ��������� ���� � ���� ������ NewItem.txt.
������ ���� NewItem.txt ����� �������������� � ������ ������� LoadNewItem.ahk ����������� ������������� 
������ ��� ���������� � ���� nameItemRuToEn.json

������ ����� ��� ����, ����� �� ������������� �������� ���� nameItemRuToEn.json, � ������� � ���� ������ ���������

��� ������ ������� ���������� ��������� � ����� \data\lang\ 
- nameItemRuToEn.json �������, ������� ����� ��������
- ru_items_.json ���������� � ������� BaseItem_new.ahk

*/

#Include, %A_ScriptDir%\lib\JSON.ahk

SplashTextOn, 300, 20, %A_ScriptName%, ������ ��������, ��������...

; ������� ��� ����
FileDelete, %A_ScriptDir%\Log.txt

; ������� ���� � ������ ����������
FileDelete, %A_ScriptDir%\NewItem.txt


FileRead, ruItemEn, %A_ScriptDir%\data\lang\nameItemRuToEn.json
nameItemRuToEn := JSON.Load(ruItemEn)


nameItemEnToRu := {}
; �������� �������� ������ ������������ ���������� �������� ��������� ������� ���������
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

		; ��� ���������� ��������� � ���������� ����� ������������ ��� ��������, � �� ��� ����		
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
				; ��������� �������, ����� ����� �� ���������� � �� ��� ���������� � ��� � ����� ������������� ����
				nameEn := nameItemEnToRu[nameRuNew]
				If (not nameEn) {
			
				; ��� ����������� ����� �������� ��������� ����� � ��� ����
				FileAppend, %nameRuNew%`n,  %A_ScriptDir%\Log.txt
				
				; � � ���� � ������ ����������
				FileAppend, %nameRuNew%`n,  %A_ScriptDir%\NewItem.txt
				}
			}
		}
	}	
}

SplashTextOff



