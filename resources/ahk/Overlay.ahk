
shOverlay(ImgPath, MultImg=1, winPosition=""){
	if !OverlayStatus {
		/*
		WinGetPos, posX, posY, posW, posH, A
		posX:=posX+8
		posW:=posW-16
		posH:=posH-16
		If posY=-8
			posY:=0
		*/
		
		posX:=0
		posY:=0 ;+25
		posW:=A_ScreenWidth
		posH:=A_ScreenHeight ;-65
		
		if (globalOverlayPosition!="" && globalOverlayPosition!="///" && globalOverlayPosition!="0/0/0/0" && winPosition="")
			winPosition:=globalOverlayPosition
		
		if (winPosition!="") {
			winPosSplit:=StrSplit(winPosition, "/")
			if (winPosSplit[1]!="" && winPosSplit[1]!=0)
				posX:=winPosSplit[1]
			if (winPosSplit[2]!="" && winPosSplit[2]!=0)
				posY:=winPosSplit[2]
			if (winPosSplit[3]!="" && winPosSplit[3]!=0)
				posW:=winPosSplit[3]
			if (winPosSplit[4]!="" && winPosSplit[4]!=0)
				posH:=winPosSplit[4]
		}
		
		Gui, Overlay:Destroy
		Gui, Overlay:-Caption -Border +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
		Gui, Overlay:Show, NA
		Gui, Overlay:Hide
		hwndImg:=WinExist()
		
		pBitmapImg:=Gdip_CreateBitmapFromFile(ImgPath)
		
		If !pBitmapImg{
			Gdip_DisposeImage(pBitmapImg)
			SplashTextOn, 300, 20, %prjName%, Некорректный файл изображения!
			Sleep 1500
			SplashTextOff
			return
		}
		
		WidthImg:=Gdip_GetImageWidth(pBitmapImg)
		HeightImg:=Gdip_GetImageHeight(pBitmapImg)
		
		If (MultImg="" || MultImg<0.25 || MultImg>=1)
			MultImg:=calcMult(WidthImg, HeightImg, posW, posH)
		
		hbmImg:=CreateDIBSection(WidthImg, HeightImg)
		hdcImg:=CreateCompatibleDC()
		obmImg:=SelectObject(hdcImg, hbmImg)
		GImg:=Gdip_GraphicsFromHDC(hdcImg)
		Gdip_DrawImage(GImg, pBitmapImg, 0, 0, round(WidthImg*MultImg), round(HeightImg*MultImg), 0, 0, WidthImg, HeightImg)
		UpdateLayeredWindow(hwndImg, hdcImg, posX+round(posW/2)-round(WidthImg*MultImg/2), posY+round(posH/2)-round(HeightImg*MultImg/2), round(WidthImg*MultImg), round(HeightImg*MultImg))
		SelectObject(hdcImg, obmImg)
		DeleteObject(hbmImg)
		DeleteDC(hdcImg)
		Gdip_DeleteGraphics(GImg)
		Gdip_DisposeImage(pBitmapImg)
		sleep 40 ;Нужна для корректной работы с GeForce NOW
		Gui, Overlay:Show, NA
		OverlayStatus:=1
		SetTimer, checkWindowTimer, 250 ;Установим таймер на проверку активного окна
		if (LastImg!=ImgPath "|" MultImg "|" winPosition) {
			LastImg:=ImgPath "|" MultImg "|" winPosition
			IniWrite, %LastImg%, %configFile%, info, lastImg
		}
	} else {
		destroyOverlay()
	}
}

destroyOverlay(){
	Gui, Overlay:Destroy
	OverlayStatus:=0
	SetTimer, checkWindowTimer, Delete
}

checkWindowTimer(){
	IfWinNotActive ahk_group WindowGrp
		destroyOverlay()
}

;Рассчитываем множитель для уменьшения изображения
calcMult(ImageWidth, ImageHeight, ScreenWidth, ScreenHeight){
	MWidth:=ScreenWidth/ImageWidth
	MHeight:=ScreenHeight/ImageHeight
	M:=(MWidth<MHeight)?MWidth:MHeight
	M:=Round(M-0.0005, 3)
	M:=(M>1)?1:M
	M:=(M<0.1)?0.1:M
	return M
}
