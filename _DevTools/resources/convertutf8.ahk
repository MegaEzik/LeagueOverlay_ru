/*
08.07.2024 MegaEzik
Небольшой скрипт для преобразования кодировки скачанной страницы
*/

#NoEnv
#SingleInstance Force
#NoTrayIcon
SetWorkingDir %A_ScriptDir%
FileEncoding, UTF-8-RAW

FileRead, Page, %A_ScriptDir%\tmpPage.html
FileDelete, %A_ScriptDir%\tmpPage.html
Sleep 10
FileAppend, %Page%, %A_ScriptDir%\tmpPage.html, UTF-8

ExitApp
