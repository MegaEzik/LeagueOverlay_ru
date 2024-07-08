/*
14.03.2018

������ ��� ��������� ������ � ����� ������ �����  ru_en_stats.json 

� ����� \old\  �������� ������ �������� ���� ru_en_stats.json ������� ������
� ����� \new\  �������� ����� ru_en_stats.json ���������� � ������� ������� StatsRuToEn.ahk

����������� ��� �����:
in_new.json - �� ��� ���� � ����� �����, �� ��� � ������
in_old.json - �� ��� ���� � ������ �����, �� ��� � �����

��� ������������ �������� ����, ���� ��� ��������:
- �������� � ������ ������ ����� ���������� �� in_old.json ��� �������� ������
- �������� � ������ ������� ����� ���������� �� in_new.json ��� �������� ������

������ ������� ������� ����� ����������������, �.�. ����������� ��������� ������ ����� � ��� �����������
���������� � ������ �������� �����, ����� ������� ������� � ������� � �� �����������������

� �������� ����� ��������� �������� �������
"###########���� ��������� �� ����� ���������� ������##############":"###########���� ����� ���� ������� ������##############",
����������� � ���� �������

�������� ���� ���������� � ������� \itog

*/


#Include, %A_ScriptDir%\lib\JSON.ahk

SplashTextOn, 300, 20, %A_ScriptName%, ������ ��������, ��������...

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


; ���������� ��� �������
; � ���� ��������� ��������� ����������� � ����� �������
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