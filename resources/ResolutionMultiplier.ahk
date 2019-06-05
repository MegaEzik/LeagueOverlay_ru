
resolutionMultiplierInit(){
	global resolutionMultiplier

	IniRead, resolutionMultiplier, %configFile%, settings, resolutionMultiplier, 1.00
	resolutionMultiplier:=(resolutionMultiplier>1 || resolutionMultiplier<=0)?1.00:resolutionMultiplier
	
	Menu, resolutionMultiplierMenu, Add, Current - %resolutionMultiplier%, calcAndSetResMult
	Menu, resolutionMultiplierMenu, Disable, Current - %resolutionMultiplier%
	Menu, resolutionMultiplierMenu, Add
	Menu, resolutionMultiplierMenu, Add, 1.00 (1920x1080+), setResMult100
	Menu, resolutionMultiplierMenu, Add, 0.75 (1440x900), setResMult75
	Menu, resolutionMultiplierMenu, Add, 0.69 (1366x768), setResMult69
	Menu, resolutionMultiplierMenu, Add, 0.64 (1280x720), setResMult64
	Menu, resolutionMultiplierMenu, Add
	Menu, resolutionMultiplierMenu, Add, Auto Detect, calcAndSetResMult
	Menu, Tray, Add, Resolution Multiplier, :resolutionMultiplierMenu
	Menu, Tray, Add
}

setResolutionMultiplier(m){
	IniWrite, %m%, %configFile%, settings, resolutionMultiplier
	sleep 50
	Reload
}

calcAndSetResMult(){
	WinWidth:=A_ScreenWidth
	WinHeght:=A_ScreenHeight-65
	m1:=WinWidth/1920
	m2:=WinHeght/1015
	m:=(m1<m2)?m1:m2
	m:=Round(m-0.0005, 3)
	setResolutionMultiplier(m)
}

setResMult100(){
	setResolutionMultiplier(1.00)
}

setResMult75(){
	setResolutionMultiplier(0.75)
}

setResMult69(){
	setResolutionMultiplier(0.69)
}

setResMult64(){
	setResolutionMultiplier(0.64)
}