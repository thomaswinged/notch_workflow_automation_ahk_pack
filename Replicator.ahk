; Notch Workflow Automation AHK Pack
; Replicator v1.0


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

MsgBox, , Replicator,
(
USAGE:
Drag and drop the source .dfx file you want to replicate to other missing surfaces.
When the script finishes, a final pop-up message will appear!

In case of fire - press Shift + Escape, and it will reload all scripts safely : )
Also, please ensure your config.cfg file is fully configured!

Rock n' roll!
)

;=== end of WELCOME MESSAGE
;==========================


;================================
;==== INITIALIZE GLOBAL VARIABLES

SelectedSurfaces := []
NewSurfaces := []

;==== end of INITIALIZE GLOBAL VARIABLES
;=======================================


;===============================
;=========== INITIALIZE MAIN GUI

Gui, Margin, 0,0
Gui, Add, Text, w250 r5 0x201 Border, Drag source .dfx file here

; Create checkboxes for enabling selective surface replication
for Index, Surface in CFG.Surfaces {
	CheckboxID := "v"Surface.Name
	CheckboxID = %CheckboxID%Enabled

	Gui, Add, Checkbox, x10 h15 %CheckboxID%, % Surface.Name
}

Gui Show, w250 h160, Replicator

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
	
	DroppedFile = ''
	
	Loop, parse, A_GuiEvent, `n
	{
		DroppedFile := A_LoopField
	}
	
	GoSub, ReplicateOtherSurfaceFiles
return


; Replicate main surface file
ReplicateOtherSurfaceFiles:
	NewSurfaces := []
	
	SplitPath, DroppedFile, name, dir, ext, name_no_ext
	
	CurrentSurface = ""
	
	; Find which surface is this file
	for Index, Surface in CFG.Surfaces {
		if InStr(name_no_ext, Surface.FilenameMark) {
			CurrentSurface := Surface.FilenameMark
			break
		}
	}

	if (CurrentSurface == "") {
		MsgBox, File has unknown surface name mark (f.e. _Main_), skipping!
		return
	}
	
	; For each surface
	for Index, Surface in CFG.Surfaces {
		CurrentNew_NameNoExt := StrReplace(name_no_ext, CurrentSurface, Surface.FilenameMark)
		CurrentNew_Name = %CurrentNew_NameNoExt%.%ext%
		CurrentNew_Path = %dir%\%CurrentNew_Name%
		
		if not FileExist(CurrentNew_Path) {
			; Create only surfaces that were checked
			SurfaceEnabledCheckbox := Surface.Name
			SurfaceEnabledCheckbox = %SurfaceEnabledCheckbox%Enabled

			if (%SurfaceEnabledCheckbox% = 1) {
				; Create new file with changed name matching surface
				FileCopy, %DroppedFile%, %CurrentNew_Path%, 0

				NewSurfaces.Push({"Path": CurrentNew_Path, "Name": Surface.Name})
			}
		}
	}

	GoSub, OpenEachNewSurfaceAndAdapt
Return


OpenEachNewSurfaceAndAdapt:
	Loop, % NewSurfaces.MaxIndex() {
		CurrentPath := NewSurfaces[A_Index].Path
		CurrentSurfaceName := NewSurfaces[A_Index].Name

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
		GoSub, RemoveUnusedResources
	}
	
	MsgBox, , Replicator, FINISHED! `nCHECK, SAVE and CLOSE.
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
	MsgBox, , Replicator, ERROR: Lost focus on Notch window, exiting script!
		ExitApp
	}
Return

;=== end of FUNCTIONS
;====================