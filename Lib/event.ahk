
/*
[info]
version=240530.1
*/

;Загрузить событие
loadEvent(){
	IniRead, EventURL, %buildConfig%, settings, EventURL, %A_Space%
	IniRead, useEvent, %configFile%, settings, useEvent, 1
	If !useEvent || (EventURL="")
		return
	
	;EventPath:=A_Temp "\MegaEzik\LOEvent\event.txt"
	EventPath:=configFolder "\Event\event.txt"
	LoadFile(eventURL, EventPath, true)
	FormatTime, CurrentDate, %A_Now%, yyyyMMdd
	
	IniRead, EventName, %EventPath%, Event, EventName, %A_Space%
	IniRead, EventLogo, %EventPath%, Event, EventLogo, %A_Space%
	IniRead, EventMsg, %EventPath%, Event, EventMsg, %A_Space%
	IniRead, Require, %EventPath%, Event, Require, %A_Space%
	
	IniRead, StartDate, %EventPath%, Event, StartDate, %A_Space%
	IniRead, EndDate, %EventPath%, Event, EndDate, %A_Space%
	IniRead, MinVersion, %EventPath%, Event, MinVersion, %A_Space%
	
	If (EventName="" || MinVersion>verScript || StartDate="" || EndDate="" || CurrentDate<StartDate || CurrentDate>EndDate)
		return
	
	If (Require!="") {
		IniRead, preset, %configFile%, settings, preset, %A_Space%
		If !RegExMatch(preset, Require)
			return
	}
	
	EventName.="(" SubStr(EndDate, 7, 2) "." SubStr(EndDate, 5, 2) ")"
	
	If (EventLogo!="")
		LoadFile(EventLogo, configFolder "\Event\bg.jpg", true)
	
	showStartUI(EventName "`n" EventMsg, (EventLogo!="")?configFolder "\Event\bg.jpg":"")
	
	eventDataSplit:=StrSplit(loadFastFile(EventPath), "`n")
	For k, val in eventDataSplit
		If RegExMatch(eventDataSplit[k], "ResourceFile=(.*)$", rURL)=1
			loadEventResourceFile(rURL1)
			
	Globals.Set("eventName", EventName)
	
	Sleep 1000
	
	return
}

;Загрузить файл для события
loadEventResourceFile(URL){
	eventFileSplit:=strSplit(URL, "/")
	filePath:=configFolder "\Event\" eventFileSplit[eventFileSplit.MaxIndex()]
	LoadFile(URL, filePath, true)
}

;Меню события
eventMenu(){
	shFastMenu(configFolder "\Event\event.txt", false)
}
