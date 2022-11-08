; Notch Workflow Automation AHK Pack
; Renovator v1.0


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

MsgBox, , Renovator,
(
USAGE:
Drag and drop old .dfx files you want to update - fix resolutions, NDI name, relink files, and so on...
A final pop-up message will appear at the end of script execution!

In case of fire - press Shift + Escape, and it will reload all scripts safely : )
Also, please ensure your config.cfg file is fully configured!

Rock n' roll!
)

;=== end of WELCOME MESSAGE
;==========================


;================================
;==== INITIALIZE GLOBAL VARIABLES

SurfacesToRenovate := []

;==== end of INITIALIZE GLOBAL VARIABLES
;=======================================


;===============================
;=========== INITIALIZE MAIN GUI

Gui Margin, 0,0
Gui add, Text, w250 r5 0x201 Border, Drag old .dfx file(s) here

Gui Show, w250 h60, Renovator

;==== end of INITIALIZE MAIN GUI
;===============================


	RETURN


;==================
;========== HOTKEYS

+Escape::Reload ; Safe button - reload script with Shift+Escape buttons combination

;=== end of HOTKEYS
;==================


;====================
;========== FUNCTIONS

GuiClose:
ExitApp


; Mechanism behind dropping file onto GUI
GuiDropFiles:
	Gui, Submit, NoHide
	
	DroppedFiles := []
	
	Loop, parse, A_GuiEvent, `n
	{
		DroppedFiles.Push(A_LoopField)
	}
	
	GoSub, DetectSurfaceFiles
return


DetectSurfaceFiles:
	SurfacesToRenovate := []

	for Index, ReceivedFile in DroppedFiles {
		SplitPath, ReceivedFile, name, dir, ext, name_no_ext

		; For each surface
		for Index, Surface in CFG.Surfaces {
			if InStr(name_no_ext, Surface.FilenameMark) {
				SurfacesToRenovate.Push({"Path": ReceivedFile, "Name": Surface.Name})
				break
			}
		}
	}

	GoSub, ProcessEveryFile
Return


ProcessEveryFile:
	Loop, % SurfacesToRenovate.MaxIndex() {
		CurrentPath := SurfacesToRenovate[A_Index].Path
		CurrentSurfaceName := SurfacesToRenovate[A_Index].Name

		SplitPath, CurrentPath, name, dir, ext, name_no_ext
		
		Run, % CurrentPath
		
		; Wait for project file to open
		WinWaitActive, % name_no_ext
		Sleep, % CFG.Slowness * 10
		
		WindowName = %name% - Notch Builder
		
		WinMaximize, % WindowName
		Sleep, % CFG.Slowness * 10
		
		GoSub, RemoveOldPixelmap
		Sleep, % CFG.Slowness * 1
		GoSub, RecenterNodegraph
		Sleep, % CFG.Slowness * 1
		GoSub, SetResolutionNDIAndPixelmap
		Sleep, % CFG.Slowness * 10
		GoSub, FindMissingResources
		Sleep, % CFG.Slowness * 10
		GoSub, RemoveUnusedResources
	}
	
	MsgBox, , Renovator, FINISHED! `nCHECK, SAVE and CLOSE.
Return


RemoveOldPixelmap:
	GoSub, MakeSureNotchIsFocused ; Make sure Notch window is active

	; Positon mouse cursor on nodegraph
	MouseMove, % CFG.Coords.GraphCenter.X, % CFG.Coords.GraphCenter.Y, 1
	Sleep, % CFG.Slowness * 1
	
	; Find old pixelmap and remove it
	Send, ^f
	ClipBackup := clipboard
	clipboard := "PixelMap"
	ClipWait
	Sleep, % CFG.Slowness * 1
	Send, ^v
	Sleep, % CFG.Slowness * 1
	Send, {Enter}
	Sleep, % CFG.Slowness * 1

	clipboard := ClipBackup
	
	GoSub, MakeSureNotchIsFocused ; Make sure Notch window is active
	Send, {Delete}
Return


RecenterNodegraph:
	GoSub, MakeSureNotchIsFocused ; Make sure Notch window is active

	Send, ^a
	Sleep, % CFG.Slowness * 1
	Send, +a
	Sleep, % CFG.Slowness * 1
	Send, i
Return


SetResolutionNDIAndPixelmap:
	GoSub, MakeSureNotchIsFocused ; Make sure Notch window is active

	; Set resolution and NDI
	SetProperties(CurrentSurfaceName)
	Sleep, % CFG.Slowness * 10
	
	; Focus on Notch window
	MouseClick, Right
	
	; Summon pixelmap
	PlacePixelmap(CurrentSurfaceName)
	Sleep, % CFG.Slowness * 10

	; Find new pixelmap and connect it to root
	Send, ^f
	ClipBackup := clipboard
	clipboard := "PixelMap"
	ClipWait
	Sleep, % CFG.Slowness * 1
	Send, ^v
	Sleep, % CFG.Slowness * 1
	Send, {Enter}
	Sleep, % CFG.Slowness * 1

	clipboard := ClipBackup

	Send, ^r
	Sleep, % CFG.Slowness * 1
Return


FindMissingResources:
	GoSub, MakeSureNotchIsFocused ; Make sure Notch window is active
	
	FootageDirectories := []
	
	CurrentFootageDir := SubStr(dir, 1, StrLen(dir) - 6)
	CurrentFootageDir = %CurrentFootageDir%\Footage
	if not (FileExist(CurrentFootageDir)) {
		CurrentFootageDir := SubStr(dir, 1, StrLen(dir) - 6)
		CurrentFootageDir = %CurrentFootageDir%\footage
	}
	
	if not (FileExist(CurrentFootageDir)) {
		; If there is no footage folder at all - just skip the rest of this subroutine
		MsgBox, , Renamer,
		(
		No Footage folder found inside!
		Double check if you dragged correct folder!
		)

		return
	}
	
	FootageDirectories.Push(CurrentFootageDir)
	
	; Check if there are other directories in 'Footage' directory
	SubFolders := GetSubFolders(CurrentFootageDir)
	
	; Add subdirectiories to array
	if (SubFolders.MaxIndex() > 0) {
		for index, element in SubFolders
			FootageDirectories.Push(element)
	}
	
	; Move mouse over resource panel (make sure it is in the same place - lower right corner)
	MouseMove, % CFG.Coords.ResourcesPanel.X, % CFG.Coords.ResourcesPanel.Y, 1
	Sleep, % CFG.Slowness * 1
	MouseClick, Right
	Sleep, % CFG.Slowness * 1
	
	; Click on "Find Missing Resources"
	MouseMove,  % CFG.Coords.FindMissingRes.X, % CFG.Coords.FindMissingRes.Y, 1
	Sleep, % CFG.Slowness * 1
	MouseClick, Left
	
	; Wait for [Autosave Recovery] window to appear
	WinWaitActive, % CFG.WindowNames.FindMissingRes, , 1
	if ErrorLevel
	{
		; If could not summon this window it means that there are no missing resources so just skip the rest
	}
	else
	{
		for index, directory in FootageDirectories {
			clipboard := directory

			Sleep, % CFG.Slowness * 2
			; Click BROWSE button
			MouseMove, % CFG.Coords.BrowseMissingRes.X, % CFG.Coords.BrowseMissingRes.Y, 1
			Sleep, % CFG.Slowness * 1
			MouseClick, Left
			
			; Wait for [Selezione cartella] window to appear
			WinWaitActive, % CFG.WindowNames.SelectFolder
			Sleep, % CFG.Slowness * 1
			
			; Focus on path edit box and paste path
			WinGetActiveTitle, Title
			ControlFocus, Edit2, %Title%
			Sleep, % CFG.Slowness * 1
			Send, ^v
			Sleep, % CFG.Slowness * 1
			
			; Focus on OK button and click it
			ControlFocus, Button1, %Title%
			Send, {Enter}
			WinWaitClose		
		}
		
		; Close [Autosave Recovery] window
		Send, {Enter}
	}
Return


RemoveUnusedResources:
	GoSub, MakeSureNotchIsFocused ; Make sure Notch window is active

	; Move mouse over resource panel (make sure it is in the same place - lower right corner)
	MouseMove, % CFG.Coords.ResourcesPanel.X, % CFG.Coords.ResourcesPanel.Y, 1
	Sleep, % CFG.Slowness * 1
	MouseClick, Right
	Sleep, % CFG.Slowness * 1
	
	; Click on "Remove Unused Resources"
	MouseMove, % CFG.Coords.RemovedUnusedRes.X, % CFG.Coords.RemovedUnusedRes.Y, 1
	Sleep, % CFG.Slowness * 1
	MouseClick, Left
	Sleep, % CFG.Slowness * 1
Return


MakeSureNotchIsFocused:
	; Make sure Notch window is active
	if not WinActive("- Notch Builder") {
	MsgBox, , Renovator, ERROR: Lost focus on Notch window, exiting script!
		ExitApp
	}
Return

;=== end of FUNCTIONS
;====================