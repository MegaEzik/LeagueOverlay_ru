; gdi+ ahk tutorial 3 written by tic (Tariq Porter)
; Requires Gdip.ahk either in your Lib folder as standard library or using #Include
;
; Tutorial to take make a gui from an existing image on disk
; For the example we will use png as it can handle transparencies. The image will also be halved in size

/*
	Author: Eruyome
	Tutorial used as template to show PoE UI overlay
	Overlay resources created by https://www.reddit.com/user/Musti_A, reddit post https://www.reddit.com/r/pathofexile/comments/5x9pgt/i_made_some_poe_twitch_stream_overlays_free/
*/

if not A_IsAdmin
	Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"

#SingleInstance, Force
#NoEnv
SetBatchLines, -1

Menu, Tray, Tip, League Overlay
Menu, Tray, Icon, resources\Syndicate.ico

; Uncomment if Gdip.ahk is not in your standard library
#Include, resources\Gdip_All.ahk
#Include, resources\LoaderLab.ahk

IniRead, hotkeySyndicate, settings.ini, settings, hotkeySyndicate, !f2
IniRead, hotkeyIncursion, settings.ini, settings, hotkeyIncursion, !f3
IniRead, hotkeyMaps, settings.ini, settings, hotkeyMaps, !f4
IniRead, hotkeyFossils, settings.ini, settings, hotkeyFossils, !f6
IniRead, hotkeyLabyrinth, settings.ini, settings, hotkeyLabyrinth, !f1
IniRead, hotkeyProphecy, settings.ini, settings, hotkeyProphecy, !f7
IniRead, lowResolution, settings.ini, settings, lowResolution, 0
IniRead, lvlLabyrinth, settings.ini, settings, lvlLabyrinth, "uber"
Hotkey, % hotkeySyndicate, shSyndicate, On
Hotkey, % hotkeyIncursion, shIncursion, On
Hotkey, % hotkeyMaps, shMaps, On
Hotkey, % hotkeyFossils, shFossils, On
Hotkey, % hotkeyLabyrinth, shLabyrinth, On
Hotkey, % hotkeyProphecy, shProphecy, On

DownloadLabyrinthLayout(lvlLabyrinth)

; Start gdi+
If !pToken := Gdip_Startup()
	{
	   MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	}
OnExit, Exit

global image1 := "resources\images\Syndicate.png"
global image2 := "resources\images\Incursion.png"
global image3 := "resources\images\Map.png"
global image4 := "resources\images\Fossil.png"
global image5 := "resources\images\Labyrinth.jpg"
global image6 := "resources\images\Prophecy.png"
if lowResolution {
	global image1 := "resources\images\720p\Syndicate.png"
	global image2 := "resources\images\720p\Incursion.png"
	global image6 := "resources\images\720p\Prophecy.png"
}

global GuiOn1 := 0
global GuiOn2 := 0
global GuiOn3 := 0
global GuiOn4 := 0
global GuiOn5 := 0
global GuiOn6 := 0

global poeWindowName = "Path of Exile ahk_class POEWindowClass"

; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption


Loop 6
{
    ; Create two layered windows (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
    Gui, %A_Index%: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
    ; Show the window
 
    ; Get a handle to this window we have created in order to update it later
    hwnd%A_Index% := WinExist()
}



Loop 6
{
If (GuiON%A_Index% = 0) {
	Gosub, CheckWinActivePOE
	SetTimer, CheckWinActivePOE, 100
	GuiON%A_Index% = 1
	
	; Show the window
	Gui, %A_Index%: Show, NA
}
Else {
	SetTimer, CheckWinActivePOE, Off      
	Gui, %A_Index%: Hide	
	GuiON%A_Index% = 0
}
}


; If the image we want to work with does not exist on disk, then download it...

; Get a bitmap from the image

Loop 6{
pBitmap%A_Index% := Gdip_CreateBitmapFromFile(image%A_Index%)

}

Loop 6{
If !pBitmap%A_Index%
{
	MsgBox, 48, File loading error!, Could not load the image specified
	ExitApp
}

}


; Get the width and height of the bitmap we have just created from the file
; This will be the dimensions that the file is
Loop 6{
Width%A_Index% := Gdip_GetImageWidth(pBitmap%A_Index%), Height%A_Index% := Gdip_GetImageHeight(pBitmap%A_Index%)
hbm%A_Index% := CreateDIBSection(Width%A_Index%, Height%A_Index%)
hdc%A_Index% := CreateCompatibleDC()
obm%A_Index% := SelectObject(hdc%A_Index%, hbm%A_Index%)
G%A_Index% := Gdip_GraphicsFromHDC(hdc%A_Index%)
Gdip_SetInterpolationMode(G%A_Index%, 7)
Gdip_DrawImage(G%A_Index%, pBitmap%A_Index%, 0, 0, Width%A_Index%, Height%A_Index%, 0, 0, Width%A_Index%, Height%A_Index%)
UpdateLayeredWindow(hwnd%A_Index%, hdc%A_Index%, A_ScreenWidth/2-(Width%A_Index%/2), 25, Width%A_Index%, Height%A_Index%)
SelectObject(hdc%A_Index%, obm%A_Index%)
DeleteObject(hbm%A_Index%)
DeleteDC(hdc%A_Index%)
Gdip_DeleteGraphics(G%A_Index%)
Gdip_DisposeImage(pBitmap%A_Index%)
}


Return
;#######################################################################

CheckWinActivePOE:
	GuiControlGet, focused_control, focus
	
Loop 6
{
	If(WinActive(poeWindowName))
		If (GuiON%A_Index% = 0) {
			
			GuiON%A_Index% := 0
			
		}
	If(!WinActive(poeWindowName))
		If (GuiON%A_Index% = 1)
		{
			Gui, %A_Index%: Hide
			GuiON%A_Index% := 0
		}
		
}
Return

#IfWinActive Path of Exile
shSyndicate(){
	If (GuiON1 = 1) {
		Gui, 1: Hide
		GuiON1 := 0
	}Else{
		Gui, 1: Show, NA
		GuiON1 := 1
	}
	return
}

shIncursion(){
	If (GuiON2 = 1) {
		Gui, 2: Hide
		GuiON2 := 0
	}Else{
		Gui, 2: Show, NA
		GuiON2 := 1
	}
	return
}

shMaps(){
	If (GuiON3 = 1) {
		Gui, 3: Hide
		GuiON3 := 0
	}Else{
		Gui, 3: Show, NA
		GuiON3 := 1
	}
	return
}

shFossils(){
	If (GuiON4 = 1) {
		Gui, 4: Hide
		GuiON4 := 0
	}Else{
		Gui, 4: Show, NA
		GuiON4 := 1
	}
	return
}

shLabyrinth(){
	If (GuiON5 = 1) {
		Gui, 5: Hide
		GuiON5 := 0
	}Else{
		Gui, 5: Show, NA
		GuiON5 := 1
	}
	return
}

shProphecy(){
	If (GuiON6 = 1) {
		Gui, 6: Hide
		GuiON6 := 0
	}Else{
		Gui, 6: Show, NA
		GuiON6 := 1
	}
	return
}

Exit:
; gdi+ may now be shutdown on exiting the program
Gdip_Shutdown(pToken)
ExitApp


Return
