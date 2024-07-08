
#SingleInstance Force
#NoEnv
SetWorkingDir, %A_ScriptDir%

ResultContent:=""

FileRead, FirstContent, 1.txt
FileRead, SecondContent, 2.txt

SplitFirst:=StrSplit(FirstContent, "`r`n")
SplitSecound:=StrSplit(SecondContent, "`r`n")

For k, val in SplitFirst {
	itemFirst:=SplitFirst[k]
	itemSecound:=SplitSecound[k]
	ResultContent.=" """ itemFirst """: """ itemSecound """,`r`n"
}

FileDelete, Result.txt
Sleep 500
FileAppend, %ResultContent%, Result.txt, UTF-8

ExitApp
