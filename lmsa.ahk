;
; AHK file - UTF8 + BOM
; INI file - UTF8 (w/o BOM)
;

#NoEnv
#NoTrayIcon
#SingleInstance Ignore
SetWorkingDir, %A_ScriptDir%
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

; Global Vars
Global Title := "lmsa"
Global RefDir := A_ScriptDir
Global IniFile := RefDir . "\" . Title . ".ini"

Global WinId
Global hGui
Global hwndCtrl_Log
Global flagStop := false

Global lastx, lasty
Global targetWindow

Global searchfile := ["01.png", "02.png", "03.png", "04.png", "05.png"]
Global loopRound := 2400
; Gui Creation

Gui, New, hwndhGui MinSize ;, Resize

Gui, Font,, Malgun Gothic

Gui, Add, GroupBox, Section x10 y6 w320 h64, 공통

Gui, Add, Button, xs+12 ys+18 w60 h36 gStart, 시 작
Gui, Add, Button, x+12 w60 h36 gSaveINI, 설정 저장
Gui, Add, Button, x+72 w60 h36 gStop, 중 지

Gui, Add, GroupBox, Section xs w320 h100, 스캔 영역 설정
Gui, Add, Text, xs+12 ys+20, 좌상단
Gui, Add, Text, x+8, x
Gui, Add, Edit, x+2 yp-3 w36 Limit4 vscanL,
Gui, Add, Text, x+4 yp+3, y
Gui, Add, Edit, x+2 yp-3 w36 Limit4 vscanT,
Gui, Add, Text, x+8 yp+3, 우하단
Gui, Add, Text, x+8, x
Gui, Add, Edit, x+2 yp-3 w36 Limit4 vscanR,
Gui, Add, Text, x+4 yp+3, y
Gui, Add, Edit, x+2 yp-3 w36 Limit4 vscanB,
Gui, Add, Text, xs+12 y+6, 대상 창
Gui, Add, Edit, x+8 yp-3 w250 ReadOnly vtwt
Gui, Add, Text, xs+12 y+6, 창 좌표
Gui, Add, Text, x+8, x
Gui, Add, Edit, x+2 yp-3 w36 ReadOnly vtwx
Gui, Add, Text, x+4 yp+3, y
Gui, Add, Edit, x+2 yp-3 w36 ReadOnly vtwy
Gui, Add, Text, x+8 yp+3, 클릭 좌표
Gui, Add, Text, x+8, x
Gui, Add, Edit, x+2 yp-3 w36 Limit4 vtwcx
Gui, Add, Text, x+4 yp+3, y
Gui, Add, Edit, x+2 yp-3 w36 Limit4 vtwcy


Gui, Add, Progress, Section xs w320 h4 Range0-%loopRound% vLoopProgress, 0

Gui, Add, Text, Section xs, 로그
Gui, Add, Edit,  w320 r20 HwndhwndCtrl_Log ReadOnly vCtrl_Log

Loop, 5
{
    n := A_Index
    if (n == 1) {
        Gui, Add, GroupBox, Section x+10 y6 w320 h96, 그림%n%
    } else {
        Gui, Add, GroupBox, Section xs w320 h96, 그림%n%
    }
    Gui, Add, Picture, xs+12 ys+20 gReloadScript, % RefDir "\" searchfile[n]
    Gui, Add, Checkbox, xs+12 y+4 vrc%n%, 좌표 지정
    Gui, Add, Text, x+4, x
    Gui, Add, Edit, x+2 yp-3 w36 Limit3 vxf%n%, 10
    Gui, Add, Text, x+4 yp+3, y
    Gui, Add, Edit, x+2 yp-3 w36 Limit3 vyf%n%, 10
    Gui, Add, Text, x+2 yp+3, 투명색
    Gui, Add, ComboBox, x+2 yp-3 vtc%n% w72 Limit6, Black||White
}

GoSub ReadINI

Gui, Show,, %Title%
Winget, WinId, ID, %Title%

GetClientSize(hGui, temp)
horzMargin := temp*96//A_ScreenDPI - 320

Log("┌ 사이버연수 도우미`r`n")
Log("└ e: 대상 창/클릭 위치 지정`r`n")
Log("`r`n")

IniRead, wX, % IniFile, Common, GUI_x, 600
IniRead, wY, % IniFile, Common, GUI_y, 50
WinMove, A,, wX, wY

Hotkey,IfWinActive, ahk_id %WinId%
Hotkey, e, SetClickPoint

Return

Start:
	FormatTime, timeStart, Hmmss, HH:mm:ss
	Log("`r`n   ==== START " . timeStart . " ====   `r`n")
	flagStop := false

	WaitNext()

	FormatTime, timeEnd, Hmmss, HH:mm:ss
	Log("`r`n   ==== END " . timeEnd . " ====   `r`n")
Return

Stop:
	Log("`r`n     == 중단 예약 ==   `r`n")
	flagStop := true
Return

GetClientSize(hWnd, ByRef w := "", ByRef h := "") {
	VarSetCapacity(rect, 16)
	DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
	w := NumGet(rect, 8, "int")
	h := NumGet(rect, 12, "int")
}

Log(str) {
	AppendText(hwndCtrl_Log, &str)
}

LogClear() {
	GuiControl,, Ctrl_Log,
}

WaitNext() {
	Log("[대기 중]`r`n")

	Loop, %loopRound% {
		if (flagStop) {
            GuiControl,, LoopProgress, %A_Index%
			Break
        }
        RefreshTargetWindowInfo()
        if(Mod(A_Index, 20) == 0) {
            PreventScreenSaver()
        }

        Loop, 5 {
            SearchFile(A_Index) && Break
        }

		Sleep, 2800
        GuiControl,, LoopProgress, %A_Index%
	}
}

RefreshTargetWindowInfo() {
    WinGetTitle, winTitle, ahk_id %targetWindow%
    WinGetPos, wx, wy, ww, wh, ahk_id %targetWindow%
	Gui %hGui%:Default
    GuiControl,, scanL, % wx
    GuiControl,, scanT, % wy
    GuiControl,, scanR, % wx+ww
    GuiControl,, scanB, % wy+wh
    GuiControl,, twt, %winTitle%
	GuiControl,, twx, % wx
	GuiControl,, twy, % wy
}

PreventScreenSaver() {
    MouseGetPos, cx, cy
    cx2 := cx - 1
    cy2 := cy - 1
    MouseMove, cx2, cy2
    MouseMove, cx, cy
}

SearchFile(n) {
    ; Get Scan area
    GuiControlGet, left,, scanL
    GuiControlGet, top,, scanT
    GuiControlGet, right,, scanR
    GuiControlGet, bottom,, scanB

    ; Get Transparent Color
    GuiControlGet, transColor, tc%n%

    ; Get Modified Click
    GuiControlGet, rc,, rc%n%

    imgFile := RefDir . "\" . searchfile[n]
    ImageSearch, dx, dy, left, top, right, bottom, *10 *Trans%transColor% %imgFile%
    if(dx) {
        FormatTime, timeV, Hmmss, HH:mm:ss
        Log(Format(" * [그림{1}] 발견 {2} : {3}, {4}`r`n", n, timeV, dx, dy))
        if(rc) {
            ; Get Modified Coord
            GuiControlGet, xf,, xf%n%
            GuiControlGet, yf,, yf%n%
            ClickPosition(dx+xf, dy+yf)
        } else {
            ; Get Click Coord.
            GuiControlGet, tw_x,, twx
            GuiControlGet, tw_y,, twy
            GuiControlGet, tw_cx,, twcx
            GuiControlGet, tw_cy,, twcy
            ClickPosition(tw_x + tw_cx, tw_y + tw_cy)
        }
        return true
	}
    return false
}

ClickPosition(ddx, ddy) {
	keyState := GetKeyState("LButton") + GetKeyState("RButton") + GetKeyState("Alt") + GetKeyState("Ctrl") + GetKeyState("Shift") + GetKeyState("RWin") + GetKeyState("LWin")
	if(keyState) {
		Log(" * 마우스 또는 키보드 사용 중 - 1초 후 재시도`r`n")
		Sleep, 1000
		return
	}
	WinGet, cWinId, ID, A
	WinGetTitle, cWinTitle, A
	BlockInput, On
	MouseGetPos, cx, cy
    Log(Format("  - 현재 창 : {1}`r`n", cWinTitle))
	Log(Format(" * 클릭: {1}, {2}`r`n", ddx, ddY))
	Click, %ddx%, %ddy%
	Sleep, 20
	MouseMove, cx, cy
	BlockInput, Off
	WinActivate, ahk_id %cWinId%
	Sleep, 3000
}

ReportError() {
	Log("실패!`r`n`r`n == 진행 불가! 스크립트 중지 ==`r`n")
	Pause, On
}

AppendText(hEdit, ptrText) {
	SendMessage, 0x000E, 0, 0,, ahk_id %hEdit% ;WM_GETTEXTLENGTH
	SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hEdit% ;EM_SETSEL
	SendMessage, 0x00C2, False, ptrText,, ahk_id %hEdit% ;EM_REPLACESEL
}

GuiSize:
	Gui %hGui%:Default
	if !horzMargin
		return
	ctrlW := A_GuiWidth - horzMargin
	list = Title,Status,VisText,AllText,Freeze
	Loop, Parse, list, `,
		GuiControl, Move, Ctrl_%A_LoopField%, w%ctrlW%
Return

ReloadScript:
	WinGetPos, wX, wY
	IniWrite, % wX, % IniFile, Common, GUI_x
	IniWrite, % wY, % IniFile, Common, GUI_y
	Reload
Return

GuiClose:
GuiEscape:
	WinGetPos, wX, wY
	IniWrite, % wX, % IniFile, Common, GUI_x
	IniWrite, % wY, % IniFile, Common, GUI_y
ExitApp

ReadINI:
    IniRead, tempVar, %IniFile%, Common, targetWindow, %A_Space%
    targetWindow := tempVar
    IniRead, tempVar, %IniFile%, Common, targetWindowClickX, %A_Space%
	GuiControl,, twcx, %tempVar%
    IniRead, tempVar, %IniFile%, Common, targetWindowClickY, %A_Space%
	GuiControl,, twcy, %tempVar%
    RefreshTargetWindowInfo()
	Loop, 5 {
        n := A_Index
		IniRead, tempVar, %IniFile%, Picture%n%, relativeCoord%n%, %A_Space%
		GuiControl,, rc%n%, %tempVar%
		IniRead, tempVar, %IniFile%, Picture%n%, transparentColor%n%, %A_Space%
		GuiControl,, tc%n%, %tempVar%
		IniRead, tempVar, %IniFile%, Picture%n%, xf%n%, %A_Space%
		GuiControl,, xf%n%, %tempVar%
		IniRead, tempVar, %IniFile%, Picture%n%, yf%n%, %A_Space%
		GuiControl,, yf%n%, %tempVar%
	}
Return

SaveINI:
    IniWrite, %targetWindow%, %IniFile%, Common, targetWindow
    GuiControlGet, tempVar,, twcx
    IniWrite, %tempVar%, %IniFile%, Common, targetWindowClickX
    GuiControlGet, tempVar,, twcy
    IniWrite, %tempVar%, %IniFile%, Common, targetWindowClickY
	Loop, 5 {
        n := A_Index
		GuiControlGet, tempVar,, rc%n%
		IniWrite, %tempVar%, %IniFile%, Picture%n%, relativeCoord%n%
		GuiControlGet, tempVar,, tc%n%
		IniWrite, %tempVar%, %IniFile%, Picture%n%, transparentColor%n%
		GuiControlGet, tempVar,, xf%n%
		IniWrite, %tempVar%, %IniFile%, Picture%n%, xf%n%
		GuiControlGet, tempVar,, yf%n%
		IniWrite, %tempVar%, %IniFile%, Picture%n%, yf%n%
	}
	GoSub ReadINI
Return

Set:
	n := A_ThisHotkey
	if (n == "q")
		n := 1
	if (n == "w")
		n := 2
	Gui %hGui%:Default
	MouseGetPos, mX, mY
	GuiControl,, x%n%, %mX%
	GuiControl,, y%n%, %mY%
Return

SetClickPoint:
    MouseGetPos, cx, cy, targetWindow
    WinGetPos, wx, wy, ww, wh, ahk_id %targetWindow%
	Gui %hGui%:Default
	GuiControl,, twcx, % cx - wx
	GuiControl,, twcy, % cy - wy
    RefreshTargetWindowInfo()
Return
