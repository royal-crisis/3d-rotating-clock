#Requires AutoHotkey v2.0
#SingleInstance Force

; Initialize variables
centerX := 150
centerY := 150
radius := 120

; Theme definitions
themes := Map(
    "Classic", {
        hourHand: 0xFF0000FF,     ; Blue
        minuteHand: 0xFF00FF00,   ; Green
        secondHand: 0xFFFF0000,   ; Red
        markers: 0x77FFFFFF,      ; Semi-transparent white
        numbers: 0xFFFFFFFF       ; White
    },
    "Night", {
        hourHand: 0xFF00FF00,     ; Green
        minuteHand: 0xFF00FFFF,   ; Yellow
        secondHand: 0xFFFF00FF,   ; Purple
        markers: 0x77C0C0C0,      ; Semi-transparent gray
        numbers: 0xFFC0C0C0       ; Gray
    },
    "Neon", {
        hourHand: 0xFFFF00FF,     ; Magenta
        minuteHand: 0xFF00FFFF,   ; Cyan
        secondHand: 0xFF00FF00,   ; Bright Green
        markers: 0x77FF00FF,      ; Semi-transparent magenta
        numbers: 0xFFFF00FF       ; Magenta
    },
    "Monochrome", {
        hourHand: 0xFFFFFFFF,     ; White
        minuteHand: 0xFFCCCCCC,   ; Light Gray
        secondHand: 0xFF999999,   ; Gray
        markers: 0x77FFFFFF,      ; Semi-transparent white
        numbers: 0xFFFFFFFF       ; White
    },
    "Ocean", {
        hourHand: 0xFF0099FF,     ; Light Blue
        minuteHand: 0xFF00CCFF,   ; Cyan
        secondHand: 0xFF0066CC,   ; Dark Blue
        markers: 0x770099FF,      ; Semi-transparent light blue
        numbers: 0xFF00CCFF       ; Cyan
    },
    "Sunset", {
        hourHand: 0xFF2E0854,     ; Deep Purple
        minuteHand: 0xFFFF4500,   ; Orange Red
        secondHand: 0xFFFF1493,   ; Deep Pink
        markers: 0x77FFD700,      ; Semi-transparent Gold
        numbers: 0xFFFFD700       ; Gold
    },
    "Forest", {
        hourHand: 0xFF228B22,     ; Forest Green
        minuteHand: 0xFF32CD32,   ; Lime Green
        secondHand: 0xFF006400,   ; Dark Green
        markers: 0x7790EE90,      ; Semi-transparent Light Green
        numbers: 0xFF98FB98       ; Pale Green
    },
    "Autumn", {
        hourHand: 0xFF8B4513,     ; Saddle Brown
        minuteHand: 0xFFD2691E,   ; Chocolate
        secondHand: 0xFFCD853F,   ; Peru
        markers: 0x77DEB887,      ; Semi-transparent Burlywood
        numbers: 0xFFDEB887       ; Burlywood
    },
    "Arctic", {
        hourHand: 0xFFF0F8FF,     ; Alice Blue
        minuteHand: 0xFFE0FFFF,   ; Light Cyan
        secondHand: 0xFFB0E0E6,   ; Powder Blue
        markers: 0x77F0FFFF,      ; Semi-transparent Azure
        numbers: 0xFFF0FFFF       ; Azure
    },
    "Volcano", {
        hourHand: 0xFF800000,     ; Maroon
        minuteHand: 0xFFB22222,   ; Fire Brick
        secondHand: 0xFFFF4500,   ; Orange Red
        markers: 0x77CD5C5C,      ; Semi-transparent Indian Red
        numbers: 0xFFCD5C5C       ; Indian Red
    }
)

currentTheme := "Classic"

; Create the main GUI window with transparency
mainGui := Gui("+AlwaysOnTop -Caption +E0x80000 +LastFound")
WinSetTransparent(255)
mainGui.BackColor := "000000"  ; Black background that will be made transparent

; Create canvas with transparent background
canvas := mainGui.AddPicture("w300 h300 Background000000", "")

; Enable dragging anywhere on the window
OnMessage(0x84, WM_NCHITTEST)

; Setup Tray Menu
A_IconTip := "3D Rotating Clock"  ; Tooltip when hovering over tray icon
TraySetIcon("Shell32.dll", 240)   ; Set clock icon from system icons

; Create Themes submenu
themesMenu := Menu()
for themeName in themes {
    themesMenu.Add(themeName, ChangeTheme)
    if (themeName = currentTheme)
        themesMenu.Check(themeName)
}

; Create main tray menu
trayMenu := A_TrayMenu
trayMenu.Delete()  ; Clear default menu
trayMenu.Add("Themes", themesMenu)
trayMenu.Add()  ; Separator
trayMenu.Add("Exit", (*) => ExitApp())

; Show the GUI
mainGui.Show("w300 h300")

; Make the window click-through but still visible
WinSetTransColor("000000", mainGui)

; Function to make the entire window draggable
WM_NCHITTEST(wParam, lParam, msg, hwnd) {
    static HTCAPTION := 2
    if (hwnd = mainGui.Hwnd)
        return HTCAPTION
}

ChangeTheme(ItemName, ItemPos, MenuName) {
    global currentTheme, themesMenu
    ; Uncheck previous theme
    themesMenu.Uncheck(currentTheme)
    ; Set and check new theme
    currentTheme := ItemName
    themesMenu.Check(currentTheme)
}

; Create GDI+ startup token
pToken := 0
si := Buffer(24, 0)
NumPut("uint", 1, si)
DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken, "ptr", si, "ptr", 0)

; Create graphics buffer
width := 300, height := 300
hdc := DllCall("GetDC", "ptr", canvas.Hwnd)
hbm := DllCall("CreateCompatibleBitmap", "ptr", hdc, "int", width, "int", height)
hdc2 := DllCall("CreateCompatibleDC", "ptr", hdc)
obm := DllCall("SelectObject", "ptr", hdc2, "ptr", hbm)
DllCall("ReleaseDC", "ptr", canvas.Hwnd, "ptr", hdc)
DllCall("gdiplus\GdipCreateFromHDC", "ptr", hdc2, "ptr*", &graphics:=0)
DllCall("gdiplus\GdipSetSmoothingMode", "ptr", graphics, "int", 4)

; Create font for numbers
DllCall("gdiplus\GdipCreateFontFamilyFromName", "str", "Arial", "ptr", 0, "ptr*", &fontFamily:=0)
DllCall("gdiplus\GdipCreateFont", "ptr", fontFamily, "float", 20, "int", 1, "int", 0, "ptr*", &font:=0)
DllCall("gdiplus\GdipCreateStringFormat", "int", 0, "int", 0, "ptr*", &stringFormat:=0)
DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", stringFormat, "int", 1)  ; Center alignment
DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", stringFormat, "int", 1)  ; Center line alignment

; Set up timer for animation
SetTimer(UpdateClock, 16)

UpdateClock() {
    global
    
    ; Get current theme colors
    theme := themes[currentTheme]
    
    ; Clear background
    DllCall("gdiplus\GdipGraphicsClear", "ptr", graphics, "uint", 0x00FFFFFF)
    
    ; Draw minute markers (thinner, shorter lines)
    Loop 60 {
        if (Mod(A_Index - 1, 5) != 0) {  ; Skip positions where hour markers will be
            markerAngle := (A_Index - 1) * 6
            x1 := centerX + radius * 0.95 * Sin(markerAngle * 0.0174533)
            y1 := centerY - radius * 0.95 * Cos(markerAngle * 0.0174533)
            x2 := centerX + radius * Sin(markerAngle * 0.0174533)
            y2 := centerY - radius * Cos(markerAngle * 0.0174533)
            
            ; Create themed pen for minute markers
            DllCall("gdiplus\GdipCreatePen1", "uint", theme.markers, "int", 1, "int", 2, "ptr*", &pen:=0)
            DllCall("gdiplus\GdipDrawLine", "ptr", graphics, "ptr", pen, "float", x1, "float", y1, "float", x2, "float", y2)
            DllCall("gdiplus\GdipDeletePen", "ptr", pen)
        }
    }
    
    ; Draw hour markers and numbers
    Loop 12 {
        ; Map each index to the correct hour position
        positions := Map(
            1, 12,   ; Top
            2, 1,    ; 1 o'clock
            3, 2,    ; 2 o'clock
            4, 3,    ; Right
            5, 4,    ; 4 o'clock
            6, 5,    ; 5 o'clock
            7, 6,    ; Bottom
            8, 7,    ; 7 o'clock
            9, 8,    ; 8 o'clock
            10, 9,   ; Left
            11, 10,  ; 10 o'clock
            12, 11   ; 11 o'clock
        )
        
        currentHour := positions[A_Index]
        hourAngle := (A_Index - 1) * 30
        
        ; Draw hour markers
        x1 := centerX + radius * 0.9 * Sin(hourAngle * 0.0174533)
        y1 := centerY - radius * 0.9 * Cos(hourAngle * 0.0174533)
        x2 := centerX + radius * Sin(hourAngle * 0.0174533)
        y2 := centerY - radius * Cos(hourAngle * 0.0174533)
        
        ; Create themed pen for hour markers
        DllCall("gdiplus\GdipCreatePen1", "uint", theme.markers, "int", 2, "int", 2, "ptr*", &pen:=0)
        DllCall("gdiplus\GdipDrawLine", "ptr", graphics, "ptr", pen, "float", x1, "float", y1, "float", x2, "float", y2)
        DllCall("gdiplus\GdipDeletePen", "ptr", pen)
        
        ; Draw hour numbers
        hourNum := currentHour
        textX := centerX + radius * 0.75 * Sin(hourAngle * 0.0174533) - 15
        textY := centerY - radius * 0.75 * Cos(hourAngle * 0.0174533) - 15
        
        ; Create themed brush for text
        DllCall("gdiplus\GdipCreateSolidFill", "uint", theme.numbers, "ptr*", &brush:=0)
        
        ; Create rectangle for text
        rectF := Buffer(16, 0)
        NumPut("float", textX, rectF, 0)
        NumPut("float", textY, rectF, 4)
        NumPut("float", 30, rectF, 8)
        NumPut("float", 30, rectF, 12)
        
        ; Draw number
        DllCall("gdiplus\GdipDrawString"
            , "ptr", graphics
            , "str", hourNum
            , "int", StrLen(hourNum)
            , "ptr", font
            , "ptr", rectF
            , "ptr", stringFormat
            , "ptr", brush)
        
        DllCall("gdiplus\GdipDeleteBrush", "ptr", brush)
    }
    
    ; Get current time using Windows API
    ST := Buffer(16)  ; SYSTEMTIME structure
    DllCall("GetLocalTime", "ptr", ST)
    
    ; Extract time components from SYSTEMTIME structure
    hours := NumGet(ST, 8, "UShort")      ; wHour offset = 8
    minutes := NumGet(ST, 10, "UShort")   ; wMinute offset = 10
    seconds := NumGet(ST, 12, "UShort")   ; wSecond offset = 12
    msecs := NumGet(ST, 14, "UShort")     ; wMilliseconds offset = 14
    
    ; Convert to 12-hour format
    hours := Mod(hours, 12)
    if (hours = 0)
        hours := 12
    
    ; Calculate angles for hands
    hourAngle := hours * 30 + minutes * 0.5  ; Each hour = 30 degrees, each minute adds 0.5 degrees
    minuteAngle := minutes * 6 + seconds * 0.1  ; Each minute = 6 degrees, each second adds 0.1 degrees
    secondAngle := seconds * 6 + msecs * 0.006  ; Each second = 6 degrees, each millisecond adds 0.006 degrees
    
    ; Draw hands
    DrawHand(hourAngle, radius * 0.5, 3, theme.hourHand)      ; Hour hand
    DrawHand(minuteAngle, radius * 0.7, 2, theme.minuteHand)  ; Minute hand
    DrawHand(secondAngle, radius * 0.9, 1, theme.secondHand)  ; Second hand
    
    ; Copy to screen
    hdc := DllCall("GetDC", "ptr", canvas.Hwnd)
    DllCall("BitBlt", "ptr", hdc, "int", 0, "int", 0, "int", width, "int", height, "ptr", hdc2, "int", 0, "int", 0, "uint", 0x00CC0020)
    DllCall("ReleaseDC", "ptr", canvas.Hwnd, "ptr", hdc)
}

DrawHand(angle, length, width, color) {
    global graphics, centerX, centerY
    
    ; Convert angle to radians and adjust to start from 12 o'clock
    angle := (angle - 90) * 0.0174533
    
    ; Calculate hand position
    x := centerX + length * Cos(angle)
    y := centerY + length * Sin(angle)
    
    DllCall("gdiplus\GdipCreatePen1", "uint", color, "float", width, "int", 2, "ptr*", &pen:=0)
    DllCall("gdiplus\GdipDrawLine", "ptr", graphics, "ptr", pen, "float", centerX, "float", centerY, "float", x, "float", y)
    DllCall("gdiplus\GdipDeletePen", "ptr", pen)
}

; Cleanup on exit
OnExit(Cleanup)

Cleanup(*) {
    global graphics, hdc2, obm, hbm, pToken, font, fontFamily, stringFormat
    DllCall("gdiplus\GdipDeleteStringFormat", "ptr", stringFormat)
    DllCall("gdiplus\GdipDeleteFont", "ptr", font)
    DllCall("gdiplus\GdipDeleteFontFamily", "ptr", fontFamily)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", graphics)
    DllCall("SelectObject", "ptr", hdc2, "ptr", obm)
    DllCall("DeleteObject", "ptr", hbm)
    DllCall("DeleteDC", "ptr", hdc2)
    DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
}

; Exit button
#HotIf WinActive("ahk_class AutoHotkeyGUI")
Escape::ExitApp
#HotIf
