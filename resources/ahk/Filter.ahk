
loadFilter(){
	IniRead, filter, %configFile%, settings, itemFilter, %A_Space%
	If (filter="")
		return
		
	FilterPath:=A_MyDocuments "\My Games\Path of Exile\LeagueOverlay.filter"
	
	FileRead, DataFilters, resources\Filters.txt
	DataFilters:=StrReplace(DataFilters, "`r", "")
	SplitDataFilters:=StrSplit(DataFilters, "`n")
	For k, val in SplitDataFilters {
		SplitFilter:=StrSplit(SplitDataFilters[k], "|")
		If (SplitFilter[1]=filter && SplitFilter[2]!="") {
			loadFile(SplitFilter[2], FilterPath, true)
		}
	}
}

delFilter(){
	FilterPath:=A_MyDocuments "\My Games\Path of Exile\LeagueOverlay.filter"
	FileDelete, %FilterPath%
	Sleep 100
}

listFilters(){
	FileRead, DataFilters, resources\Filters.txt
	DataFilters:=StrReplace(DataFilters, "`r", "")
	SplitDataFilters:=StrSplit(DataFilters, "`n")
	For k, val in SplitDataFilters {
		SplitFilter:=StrSplit(SplitDataFilters[k], "|")
		If (SplitFilter[1]!="") && (RegExMatch(SplitFilter[1], ";")!=1) && (SplitFilter[2]!="")
			LFilters.="|" SplitFilter[1]
	}
	return %LFilters%
}

/*
loadFilterOld(FilterName="NeverSink-2semistr", FilterURL="https://raw.githubusercontent.com/NeverSinkDev/NeverSink-Filter/master/NeverSink's%20filter%20-%202-SEMI-STRICT.filter", ForceReload=false){
	FileCreateDir, %A_MyDocuments%\My Games\Path of Exile
	FilterPath:=A_MyDocuments "\My Games\Path of Exile\" FilterName ".filter"
	TmpPath:=A_Temp "\New.filter"
	
	LoadFile(FilterURL, TmpPath)
	
	verCurrentFilter:=verFilter(FilterPath)
	verNewFilter:=verFilter(TmpPath)
	
	If (verNewFilter!="") {
		If (verNewFilter!=verCurrentFilter || ForceReload) {
			FileCopy, %TmpPath%, %FilterPath%, 1
			;TrayTip, %prjName% - Обновлен фильтр, %FilterName%`n%verCurrentFilter% > %verNewFilter%
			trayMsg(FilterName "`n" verCurrentFilter " > " verNewFilter, "Обновлен фильтр")
		}
		FileSetTime, , %FilterPath%
	}
}

checkFilter(ForceReload=false){
	IniRead, filter, %configFile%, settings, itemFilter, %A_Space%
	
	If (filter="")
		return
	
	FilterPath:=A_MyDocuments "\My Games\Path of Exile\" filter ".filter"
	
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	FileGetTime, LoadDate, %FilterPath%, M
	FormatTime, LoadDate, %LoadDate%, yyyyMMdd
	If FileExist(FilterPath) && (LoadDate=CurrentDate) && !ForceReload
		return
	
	FileRead, DataFilters, resources\Filters.txt
	DataFilters:=StrReplace(DataFilters, "`r", "")
	SplitDataFilters:=StrSplit(DataFilters, "`n")
	For k, val in SplitDataFilters {
		SplitFilter:=StrSplit(SplitDataFilters[k], "|")
		If (SplitFilter[1]=filter && SplitFilter[2]!="") {
			loadFilterOld(SplitFilter[1], SplitFilter[2], ForceReload)
			return
		}
	}
}

verFilter(FilterPath){
	FileRead, FilterText, %FilterPath%
	FilterText:=StrReplace(FilterText, "`r", "")
	FilterLine:=StrSplit(FilterText, "`n")
	For k, val in FilterLine {
		If (RegExMatch(FilterLine[k], "#")=1){
			If RegExMatch(FilterLine[k], "i)Version:(.*)", verFilter)
				return Trim(verFilter1)
			If RegExMatch(FilterLine[k], "Версия:(.*)", verFilter)
				return Trim(verFilter1)
		}
	}
	return
}
*/
