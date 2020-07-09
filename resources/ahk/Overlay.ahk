
shOverlay(ImgPath){
	if !OverlayStatus {
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
		MultImg:=calcMult(WidthImg, HeightImg, A_ScreenWidth, A_ScreenHeight-65)
		hbmImg:=CreateDIBSection(WidthImg, HeightImg)
		hdcImg:=CreateCompatibleDC()
		obmImg:=SelectObject(hdcImg, hbmImg)
		GImg:=Gdip_GraphicsFromHDC(hdcImg)
		Gdip_DrawImage(GImg, pBitmapImg, 0, 0, round(WidthImg*MultImg), round(HeightImg*MultImg), 0, 0, WidthImg, HeightImg)
		UpdateLayeredWindow(hwndImg, hdcImg, round(A_ScreenWidth/2)-round(WidthImg*MultImg/2), 25+round((A_ScreenHeight-65)/2)-round(HeightImg*MultImg/2), round(WidthImg*MultImg), round(HeightImg*MultImg))
		SelectObject(hdcImg, obmImg)
		DeleteObject(hbmImg)
		DeleteDC(hdcImg)
		Gdip_DeleteGraphics(GImg)
		Gdip_DisposeImage(pBitmapImg)
		sleep 50 ;Нужна для корректной работы с GeForce NOW
		Gui, Overlay:Show, NA
		OverlayStatus:=1
		if (LastImgPath!=ImgPath) {
			LastImgPath:=ImgPath
			IniWrite, %ImgPath%, %configFile%, settings, lastImgPath
		}
	} else {
		destroyOverlay()
	}
}

destroyOverlay(){
	Gui, Overlay:Destroy
	OverlayStatus:=0
}

checkWindowTimer(){
	IfWinNotActive ahk_group PoEWindowGrp
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
