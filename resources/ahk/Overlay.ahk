
initOverlay(){
	; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
	Loop %NumImg%{
		; Create two layered windows (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
		Gui, %A_Index%: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
		; Show the window
	 
		; Get a handle to this window we have created in order to update it later
		hwnd%A_Index%:=WinExist()
	}
	
	Loop %NumImg%{
		Gui, %A_Index%: Show, NA
		Gui, %A_Index%: Hide	
		GuiON%A_Index%:=0
	}
	
	SetTimer, CheckWinActivePOE, 500

	; If the image we want to work with does not exist on disk, then download it...
	; Get a bitmap from the image

	Loop %NumImg%{
		pBitmap%A_Index%:=Gdip_CreateBitmapFromFile(image%A_Index%)
	}

	Loop %NumImg%{
		If !pBitmap%A_Index%{
			MsgBox, 48, File loading error!, Could not load the image specified
			ExitApp
		}
	}


	; Get the width and height of the bitmap we have just created from the file
	; This will be the dimensions that the file is
	Loop %NumImg%{
		Width%A_Index%:=Gdip_GetImageWidth(pBitmap%A_Index%)
		Height%A_Index%:=Gdip_GetImageHeight(pBitmap%A_Index%)
		Mult%A_Index%:=calcMult(Width%A_Index%, Height%A_Index%, A_ScreenWidth, A_ScreenHeight-65)
		hbm%A_Index%:=CreateDIBSection(Width%A_Index%, Height%A_Index%)
		hdc%A_Index%:=CreateCompatibleDC()
		obm%A_Index%:=SelectObject(hdc%A_Index%, hbm%A_Index%)
		G%A_Index%:=Gdip_GraphicsFromHDC(hdc%A_Index%)
		Gdip_SetInterpolationMode(G%A_Index%, 7)
		Gdip_DrawImage(G%A_Index%, pBitmap%A_Index%, 0, 0, round(Width%A_Index%*Mult%A_Index%), round(Height%A_Index%*Mult%A_Index%), 0, 0, Width%A_Index%, Height%A_Index%)
		UpdateLayeredWindow(hwnd%A_Index%, hdc%A_Index%, round(A_ScreenWidth/2)-round(Width%A_Index%*Mult%A_Index%/2), 25+round((A_ScreenHeight-65)/2)-round(Height%A_Index%*Mult%A_Index%/2), round(Width%A_Index%*Mult%A_Index%), round(Height%A_Index%*Mult%A_Index%))
		SelectObject(hdc%A_Index%, obm%A_Index%)
		DeleteObject(hbm%A_Index%)
		DeleteDC(hdc%A_Index%)
		Gdip_DeleteGraphics(G%A_Index%)
		Gdip_DisposeImage(pBitmap%A_Index%)
	}
}

CheckWinActivePOE(){
	IfWinNotActive ahk_group PoEWindowGrp
		Loop %NumImg%{
			Gui, %A_Index%: Hide
			GuiON%A_Index%:=0
		}
}

;Рассчитываем коэффициент для уменьшения изображения
calcMult(ImageWidth, ImageHeight, ScreenWidth, ScreenHeight){
	MWidth:=ScreenWidth/ImageWidth
	MHeight:=ScreenHeight/ImageHeight
	M:=(MWidth<MHeight)?MWidth:MHeight
	M:=Round(M-0.0005, 3)
	M:=(M>1)?1:M
	M:=(M<0.1)?0.1:M
	return M
}

shOverlay(i=1){
	sleep 50 ;Нужна для корректной работы с GeForce NOW
	If (GuiON%i%=1){
		Gui, %i%: Hide
		GuiON%i%:=0
	}Else{
		Gui, %i%: Show, NA
		GuiON%i%:=1
		if (LastImg!=i) {
			IniWrite, %i%, %configFile%, settings, lastImg
			LastImg:=i
		}
	}
}
