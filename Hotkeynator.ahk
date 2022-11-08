; Notch Workflow Automation AHK Pack
; Hotkeynator v1.0


;=====================
;========== APP HEADER

#Include include\Base.ahk
#NoEnv
SetTitleMatchMode, 2 ; A window's title can contain WinTitle anywhere inside it to be a match
#SingleInstance Force ; Only allows one instance of the script to run.
SetBatchLines, -1
SetWinDelay, 0

;=== end of APP HEADER
;=====================


;==========================
;========== WELCOME MESSAGE

MsgBox, , Hotkeynator,
(
USAGE:

Hotkeys for placing pixelmaps:
Main: Ctrl+Numpad1
Back: Ctrl+Numpad2
Floor: Ctrl+Numpad3
Side: Ctrl+Numpad4
Lift: Ctrl+Numpad5
Projection: Ctrl+Numpad6

Hotkeys for setting surfaces properties:
Main: Alt+1
Back: Alt+2
Floor: Alt+3
Side: Alt+4
Lift: Alt+5
Projection: Alt+6

Ensure you have all required pixel map bins
specified in the config.cfg file.

In case of fire - press Shift + Escape, and it will reload all scripts safely : )
Also, please ensure your config.cfg file is fully configured!

Rock n' roll!
)

;=== end of WELCOME MESSAGE
;==========================


;==================
;========== HOTKEYS
; ^ is symbol of Ctrl
; ! is symbol of Alt

^Numpad1::PlacePixelmap("Main")
^Numpad2::PlacePixelmap("Back")
^Numpad3::PlacePixelmap("Floor")
^Numpad4::PlacePixelmap("Side")
^Numpad5::PlacePixelmap("Lift")
^Numpad6::PlacePixelmap("Projection")

!1::SetProperties("Main")
!2::SetProperties("Back")
!3::SetProperties("Floor")
!4::SetProperties("Side")
!5::SetProperties("Lift")
!6::SetProperties("Projection")

+Escape::Reload ; Safe button - reload script with Shift+Escape buttons combination

;=== end of HOTKEYS
;==================