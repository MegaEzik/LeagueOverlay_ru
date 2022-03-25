
#SingleInstance Force
#NoTrayIcon

If (%0%=0)
	ExitApp
	
Loop, %0%
	LMBHotkey:=%A_Index%
If (LMBHotkey!="")
	Hotkey, % LMBHotkey, LMBClick, On

JoyMultiplier = 0.12 ;Скорость курсора
JoyThreshold = 10 ;Уровень отклонения
InvertYAxis := false ;ИНвертирование оси Y
;ButtonLeft = 1 ;Номер кнопки отвечающей за ЛКМ
;ButtonRight = 2 ;Номер кнопки отвечающей за ПКМ
;ButtonMiddle = 3 ;Номер кнопки отвечающей за Нажатие на колесо
WheelDelay = 150 ;Задержка между реакцией на колесо
JoystickNumber = 1 ;Номер геймпада
If RegExMatch(LMBHotkey, "(\d+)Joy", JNum)
	JoystickNumber:=JNum1

JoystickPrefix = %JoystickNumber%Joy
/* ;Присвоение функций кнопкам(заблокировано, ЛКМ назначается через переданный параметр)
Hotkey, %JoystickPrefix%%ButtonLeft%, ButtonLeft
Hotkey, %JoystickPrefix%%ButtonRight%, ButtonRight
Hotkey, %JoystickPrefix%%ButtonMiddle%, ButtonMiddle
*/

; Calculate the axis displacements that are needed to start moving the cursor:
JoyThresholdUpper := 50 + JoyThreshold
JoyThresholdLower := 50 - JoyThreshold
if InvertYAxis
    YAxisMultiplier = -1
else
    YAxisMultiplier = 1

SetTimer, WatchJoystick, 10  ; Monitor the movement of the joystick.

/*  ;Отключим прокрутку мышью
GetKeyState, JoyInfo, %JoystickNumber%JoyInfo
IfInString, JoyInfo, P  ; Joystick has POV control, so use it as a mouse wheel.
    SetTimer, MouseWheel, %WheelDelay%
*/

return  ; End of auto-execute section.


; The subroutines below do not use KeyWait because that would sometimes trap the
; WatchJoystick quasi-thread beneath the wait-for-button-up thread, which would
; effectively prevent mouse-dragging with the joystick.

ButtonLeft:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, D  ; Hold down the left mouse button.
SetTimer, WaitForLeftButtonUp, 10
return

ButtonRight:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, right,,, 1, 0, D  ; Hold down the right mouse button.
SetTimer, WaitForRightButtonUp, 10
return

ButtonMiddle:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, middle,,, 1, 0, D  ; Hold down the right mouse button.
SetTimer, WaitForMiddleButtonUp, 10
return

WaitForLeftButtonUp:
if GetKeyState(JoystickPrefix . ButtonLeft)
    return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForLeftButtonUp, off
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, U  ; Release the mouse button.
return

WaitForRightButtonUp:
if GetKeyState(JoystickPrefix . ButtonRight)
    return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForRightButtonUp, off
MouseClick, right,,, 1, 0, U  ; Release the mouse button.
return

WaitForMiddleButtonUp:
if GetKeyState(JoystickPrefix . ButtonMiddle)
    return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForMiddleButtonUp, off
MouseClick, middle,,, 1, 0, U  ; Release the mouse button.
return

WatchJoystick:
MouseNeedsToBeMoved := false  ; Set default.
SetFormat, float, 03
GetKeyState, joyx, %JoystickNumber%JoyX
GetKeyState, joyy, %JoystickNumber%JoyY
if joyx > %JoyThresholdUpper%
{
    MouseNeedsToBeMoved := true
    DeltaX := joyx - JoyThresholdUpper
}
else if joyx < %JoyThresholdLower%
{
    MouseNeedsToBeMoved := true
    DeltaX := joyx - JoyThresholdLower
}
else
    DeltaX = 0
if joyy > %JoyThresholdUpper%
{
    MouseNeedsToBeMoved := true
    DeltaY := joyy - JoyThresholdUpper
}
else if joyy < %JoyThresholdLower%
{
    MouseNeedsToBeMoved := true
    DeltaY := joyy - JoyThresholdLower
}
else
    DeltaY = 0
if MouseNeedsToBeMoved
{
    SetMouseDelay, -1  ; Makes movement smoother.
    MouseMove, DeltaX * JoyMultiplier, DeltaY * JoyMultiplier * YAxisMultiplier, 0, R
}
return

MouseWheel:
GetKeyState, JoyPOV, %JoystickNumber%JoyPOV
if JoyPOV = -1  ; No angle.
    return
if (JoyPOV > 31500 or JoyPOV < 4500)  ; Forward
    Send {WheelUp}
else if JoyPOV between 13500 and 22500  ; Back
    Send {WheelDown}
return

LMBClick(){
	SetMouseDelay, -1
	MouseClick, left
}
