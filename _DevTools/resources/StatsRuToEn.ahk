/*
28.07.2024 MegaEzik
��������� ������������ ����� ru_en_stats.txt
�������� GUI � ���������� ����������

20.11.2018
v0.2
idae(iade)

������ ��������� ���� ru_en_stats.json �� ������ ���� ������
ru_stats_.json
en_stats.json

����� ������������ ��������� �� ������� ����� "�� �������!"

������ ���� ������������ � �������� �������� ��������������� � POE-TradeMacro �� �������������,
�.�. � �������� ���� ��������� ������� ���������, ������� ;)
��������� ��� ���� ������ ������� �� ������� �������� ���� � ���� ����� ����,
� ����� �� ������ ����� �������, ������� ��� ����� ������� �������� � �������� ����

15.01.2018
� �������� ���� ru_en_stats.json ���� ������� ������� ���� ��� ��������, ��������� ��� ��� �������� ������ �����


*/


#SingleInstance force
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir, %A_ScriptDir%
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.


#Include, %A_ScriptDir%\lib\JSON.ahk
global uiProgress1, uiProgress2

Gui ProgressUI:Add, Progress, w350 h25 BackgroundA9A9A9 vuiProgress2
Gui ProgressUI:Add, Progress, w350 h25 BackgroundA9A9A9 vuiProgress1
Gui, ProgressUI:-SysMenu +Theme +Border +AlwaysOnTop
Gui, ProgressUI:Show

; ������� ��� ����
FileDelete, %A_ScriptDir%\Log.txt

; ������ ������������ ������� ������������� ���������� - ���������������� ������
FileDelete, %A_ScriptDir%\data\lang\ru_en_stats.txt
; ������ ������������ ������� ������������� ���������� - ������ JSON
FileDelete, %A_ScriptDir%\data\lang\ru_en_stats.json

ru_en_stats := {}

FileRead, ru_stats, %A_ScriptDir%\data\lang\ru_stats_.json
FileRead, en_stats, %A_ScriptDir%\data\lang\en_stats.json

data_ru_stats := JSON.Load(ru_stats)
data_ru_stats := data_ru_stats["result"]

data_en_stats := JSON.Load(en_stats)
data_en_stats := data_en_stats["result"]


For key, arrStats in data_ru_stats {
	
	label_ := arrStats["label"]
	;FileAppend, ------------------------------`n----- %label_% -----`n------------------------------`n,  %A_ScriptDir%\data\lang\ru_en_stats.txt
	
	For key, item in arrStats["entries"] {
		id_ := item.id
		text_ru := item.text
		text_en := GetEnStatsId(data_en_stats,id_)
		;MsgBox %text_ru% ::: %text_en%
		;FileAppend, %text_ru% :: %text_en% :: %id_% `n,  %A_ScriptDir%\data\lang\ru_en_stats.txt
		
		ru_en_stats[text_ru] := text_en
		
		cProgress:=A_Index/arrStats["entries"].MaxIndex()*100
		GuiControl ProgressUI:, uiProgress2, %cProgress%
	}
	cProgress:=A_Index/data_ru_stats.MaxIndex()*100
	GuiControl ProgressUI:, uiProgress1, %cProgress%
}

dumpObj := JSON.Dump(ru_en_stats,,1)
FileAppend, %dumpObj%, %A_ScriptDir%\data\lang\ru_en_stats.json

;SplashTextOff
ExitApp

GetEnStatsId(arrStatsEn,id_stats)
{
	For key, arrStats in arrStatsEn {
		For key, item in arrStats["entries"] {
			;MsgBox % item.type	
			
			id_ := item.id			
			text_en := item.text
			
			If (id_ = id_stats) 
			{
				return text_en
			}
		}	
	}
	
	return "�� �������!"
}




