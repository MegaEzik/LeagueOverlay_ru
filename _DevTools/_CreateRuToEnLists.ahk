global prjName:="CreateRuToEnLists v9.0"
/*
08.07.24 v9.0 MegaEzik
*Добавлен список игнорирования для предметов resources\lib\_ignorelist.txt
*Добавлен GUI c прогрессом для StatsRuToEn.ahk и _LoadItems_v2.ahk
*Отключено формирование ru_en_stats.txt
*Окна curl.exe теперь скрыты

12.04.24 v8.1 MegaEzik
*Из списка предметов теперь исключаются устаревшие скарабеи

30.07.23 v8.0 MegaEzik - существенно уменьшен размер и зависимость от сторонних компонентов
*_create.ahk - удален
*Исправлены URL для загрузки исходных данных с GitHub
*PoEScripts_Download.ahk - пропатчена для использования системной утилиты curl.exe, вместо отдельной
*_LoadItems_v2.ahk - переведена на использование системной утилиты curl.exe, вместо отдельной wget
*_LoadItems_v2.ahk - исправлено регулярное выражение
*BaseItem_new.ahk - Удалена связанная библиотека JSON_.ahk, скрипт работает и без нее(Возможно повлияла смена кодировки, выполненная ранее)
*Удален функционал звукового сопровождения

17.05.2023 v7.1 MegaEzik
*Музыка теперь воспроизводится только во время обработки файлов и определяется галочкой в конфигураторе
*Пункт меню 'Закрытия UI' заменен на 'Перезагрузку UI', сам же UI можно закрыть крестиком)
*Все элементы управления теперь доступны из области уведомлений
*Макрос теперь умеет открывать папку по завершении работы скрипта
*Исправлена некорректная работа при вызове другим скриптом

17.01.2022 v6.1 MegaEzik
*Добавлен интерфейс
**Добавлена возможность загрузки исходных данных с GitHub
**Теперь можно по отдельности формировать списки Модов и Предметов
**Теперь возможно выполнять отдельные этапы скрипта
**Если не нравится воспроизведение темы PoE во время работы скрипта, то удалите файл resources\lib\PoEMain.mp3

02.12.2021 v5.5 MegaEzik
*_LoadItems_v2.ahk - Добавлено новое регулярное выражение для извлечения имени из текста страницы
*_LoadItems_v2.ahk - Теперь заменяет символы ':' и ',' в названиях полученных с ссылок

11.11.2021 v5.4 MegaEzik
*Из списка предметов убраны души(Торговать ими все равно нельзя!)

12.04.2021 v5.3 MegaEzik
*Принцип работы изменен для работы с LeagueOverlay_ru
**Теперь требует файлы names.json и stats.json, вместо прежних
**На выходе получаем names.txt, newLines_stats.txt, updatedLines_stats.txt

15.08.2020 v5.2 MegaEzik
*Для загрузки данных с poedb теперь используется макрос _LoadItems_v2.ahk
**Для работы _LoadItems_v2.ahk нужна утилита wget.exe, она включена в набор

27.12.2019 v3.2 MegaEzik
*Создается резервная копия полного списка отсутствующих предметов NewItem_full.txt
*Из списка предметов исключаются нерусские записи(Ни к чему лишние запросы!)
*Из списка предметов исключаются Пробужденные камни поддержки
*Обновлены компоненты из TradeMacro

10.11.2019 v2 MegaEzik
*Изменен принцип формирования ru_en_stats.json, теперь формируется набор обновленных строк updatedLines_ru_en_stats.txt, а не только новые, это позволит избежать мусора
**Файл newLines_ru_en_stats.txt будет сформирован только при наличии файла old\ru_en_stats.json, иначе этот этап будет пропущен
*Перед запросом новых предметов от poedb.tw список очищается от 'Изменённых карт'(Ни к чему лишние запросы!)
*Теперь скрипт запрашивает права администратора для свой работы

12.02.2019 MegaEzik

##########################################################################################

Скрипт для получения новой информации для файлов names.json и stats.json в кодировке UTF-8-BOM

Поместить файл старый names.json и stats.json в папку old
Запустить _CreateRuToEnLists.ahk

В результате будут сформированы:
*Список новых предметов names.txt, которые нужно добавить в names.json
*Обновленный основной список модов updatedLines_stats.txt , при помощи которого нужно обновить stats.json
*Список только новых модов newLines_stats.txt
*/

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

;Перезапуск от имени администратора
if (!A_IsAdmin) {
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
	ExitApp
}

Menu, Tray, Tip, %prjName%

FileCreateDir, old
FileCreateDir, resources\data\lang
FileCreateDir, resources\old
FileCreateDir, resources\new

createTrayMenu()
Configuration()

;Sleep 5000

;Send {Volume_Mute}

Return

;################################################################################################

Configuration(){
	global
	Gui, ConfigurationUI:Destroy
	
	GVar_LoadData:=true
	GVar_CreateNames:=true
	GVar_CreateStats:=true
	GVar_OpenFolder:=true
	GVar_Exit:=true
	
	Gui, ConfigurationUI:Add, Checkbox, vGVar_LoadData x20 y10 Checked%GVar_LoadData%, Загрузить исходные данные с GitHub
	Gui, ConfigurationUI:Add, Checkbox, vGVar_CreateNames x20 y+10 Checked%GVar_CreateNames%, Обработать 'names.json'
	Gui, ConfigurationUI:Add, Checkbox, vGVar_CreateStats x20 y+5 Checked%GVar_CreateStats%, Обработать 'stats.json'
	Gui, ConfigurationUI:Add, Checkbox, vGVar_OpenFolder x20 y+10 Checked%GVar_OpenFolder%, Открыть папку скрипта после выполнения
	Gui, ConfigurationUI:Add, Checkbox, vGVar_Exit x20 y+5 Checked%GVar_Exit%, Завершить работу скрипта после выполнения
	
	Gui, ConfigurationUI:Add, Button, x20 y+10 gCreaterRun, Сформировать предварительные списки
	Gui, ConfigurationUI:Add, Button, x+2 gshowTrayMenu, ☰

	;Gui, ConfigurationUI:-SysMenu
	Gui, ConfigurationUI:-SysMenu +Theme +Border +AlwaysOnTop
	Gui, ConfigurationUI:Show,,%prjName% - Конфигурация
}

createTrayMenu(){
	Menu, Tray, DeleteAll
	
	Menu, Tray, Add, sClean
	Menu, Tray, Add, sLoadOlds
	Menu, Tray, Add, rBaseItem_new
	Menu, Tray, Add, rStatsRuToEn
	Menu, Tray, Add, sStartCopy
	Menu, Tray, Add, srNewStats
	Menu, Tray, Add, srCreateItems
	Menu, Tray, Add, r_LoadItems_v2
	Menu, Tray, Add
	Menu, Tray, Add, Перезапустить UI, Configuration
	Menu, Tray, Add, Открыть папку скрипта, OpenScriptFolder
	Menu, Tray, Add, Перезапуск скрипта, ReloadScript
	Menu, Tray, Add, Завершить работу скрипта, ExitScript
	
	Menu, Tray, Default, Перезапустить UI
	
	Menu, Tray, NoStandard
}

showTrayMenu(){
	Menu, Tray, Show
}

OpenScriptFolder(){
	run,  explorer "%A_ScriptDir%"
}

ReloadScript(){
	Reload
}

ExitScript(){
	ExitApp
}

FileLoader(Path, URL){
	If FileExist(Path)
		Return
	SplitPath, Path,, DirPath
	FileCreateDir, %DirPath%
	RunWait, curl -L -o "%Path%" "%URL%", , hide
}

;################################################################################################

;Основное выполнение скрипта
CreaterRun(){
	global
	Gui, ConfigurationUI:Submit
	
	sClean()
	If GVar_LoadData
		sLoadOlds()
	rBaseItem_new()
	sStartCopy()
	If GVar_CreateStats {
		rStatsRuToEn()
		srNewStats()
	}
	If GVar_CreateNames {
		srCreateItems()
		r_LoadItems_v2()
	}
	If GVar_OpenFolder
		OpenScriptFolder()
	If GVar_Exit
		ExitScript()
	Configuration()
}

;Очистка после предыдущего использования
sClean(){
	FileDelete, *.txt
	FileDelete, resources\data\lang\*
	FileDelete, resources\new\*
	FileDelete, resources\old\*
	FileDelete, resources\*.json
	FileDelete, resources\*.txt
	FileDelete, resources\tmpPage.*
	sleep 25
}

;Загрузка исходных списков
sLoadOlds(){
	FileDelete, old\*
	sleep 25
	FileLoader("old\names.json", "https://raw.githubusercontent.com/MegaEzik/LeagueOverlay_ru/master/Data/JSON/names.json")
	FileLoader("old\stats.json", "https://raw.githubusercontent.com/MegaEzik/LeagueOverlay_ru/master/Data/JSON/stats.json")
}

;Получаем данные от api.pathofexile.com
rBaseItem_new(){
	RunWait *RunAs "%A_AhkPath%" resources\BaseItem_new.ahk
}

;Создаем предварительный файл ru_en_stats.json
rStatsRuToEn(){
	RunWait *RunAs "%A_AhkPath%" resources\StatsRuToEn.ahk
}

;Размещаем файлы
sStartCopy(){
	FileCopy, old\names.json, resources\data\lang\nameItemRuToEn.json
	FileCopy, old\stats.json, resources\old\ru_en_stats.json
}

;Формируем файлы для модов
srNewStats(){
	;Если файл будет найден, проведем сравнение и сформируем список новых строк
	If FileExist("old\stats.json") {
		;Файлы для сравнения должны быть в одной кодировке, в макросе теперь используется UTF-8-BOM,
		;поэтому считываем полученный файл ru_en_stats.json и сохраняем в новой кодировке 
		FileRead, FileContent, resources\data\lang\ru_en_stats.json
		FileAppend, %FileContent%, resources\new\ru_en_stats.json, UTF-8
		sleep 50

		;Формируем выписку новых строк для файла ru_en_stats.json
		RunWait *RunAs "%A_AhkPath%" resources\Meld_ru_en_stats.ahk

		;Чистим файл in_new.json и сохраняем в новой кодировке
		FileRead, FileContent, resources\in_new.json
		ResultContent:=""
		FileLines:=StrSplit(FileContent, "`r`n")
		For k, val in FileLines {
			If (!RegExMatch(FileLines[k], "{") and !RegExMatch(FileLines[k], "}")) {
				ResultContent.=FileLines[k] "`r`n"
			}
		}
		FileAppend, %ResultContent%, newLines_stats.txt, UTF-8
	}

	;Очистим ru_en_stats.json и сохраним в новой кодировке
	FileRead, FileContent, resources\data\lang\ru_en_stats.json
	ResultContent:=""
	FileLines:=StrSplit(FileContent, "`r`n")
	For k, val in FileLines {
		If (!RegExMatch(FileLines[k], "{") and !RegExMatch(FileLines[k], "}") and !RegExMatch(FileLines[k], "<") and !RegExMatch(FileLines[k], ">")) {
			ResultContent.=FileLines[k] "`r`n"
		}
	}
	FileAppend, %ResultContent%, updatedLines_stats.txt, UTF-8
}

;Подготовка списка отсутствующих предметов
srCreateItems(){
	;Формируем список отсутствующих имен предметов
	RunWait *RunAs "%A_AhkPath%" resources\Meld_nameItemRuToEn__ru_items_.ahk

	;Сделаем резервную копию NewItem.txt
	ResultContent:=""
	FileRead, ResultContent, resources\NewItem.txt
	FileAppend, %ResultContent%, resources\NewItem_full.txt, UTF-8
	sleep 25

	;Уберем нерусские записи  и 'Изменённые карты'(и другие ненужные предметы) из списка отсутствующих предметов
	FileRead, FileContent, resources\NewItem.txt
	FileDelete, resources\NewItem.txt
	sleep 25
	ResultContent:="`r`n"
	FileLines:=StrSplit(FileContent, "`r`n")
	For k, val in FileLines {
		If (RegExMatch(FileLines[k], "[А-Яа-яЁё]+") && !RegExMatch(FileLines[k], "Пробужд(е|ё)нный: ") && !RegExMatch(FileLines[k], "Захваченная душа ")) {
			ResultContent.=FileLines[k] "`r`n"
		}
	}
	;Удалим записи из игнорлиста
	FileRead, FileContent, resources\lib\_ignorelist.txt
	FileLines:=StrSplit(FileContent, "`r`n")
	For k, val in FileLines {
		cName:=FileLines[k]
		ResultContent:=StrReplace(ResultContent, "`r`n" cName "`r`n", "`r`n")
	}
	FileAppend, %ResultContent%, resources\NewItem.txt
	sleep 25
}

;Получаем от poedb.tw/ru информацию о английском наименовании и формируем выписку новых строк
r_LoadItems_v2(){
	RunWait *RunAs "%A_AhkPath%" resources\_LoadItems_v2.ahk
	FileCopy, resources\new_itemEquality.txt, names.txt
}
