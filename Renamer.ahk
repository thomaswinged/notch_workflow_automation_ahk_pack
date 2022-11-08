; Notch Workflow Automation AHK Pack
; Renamer v1.0


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

MsgBox, , Renamer,
(
USAGE:
Put the project's new name into the input field and then drag and drop the project folder onto GUI.
Wait until the final message.

In case of fire - press Shift + Escape, and it will reload all scripts safely : )
Also, please ensure your config.cfg file is fully configured!

Rock n' roll!
)

;=== end of WELCOME MESSAGE
;==========================


;===============================
;=========== INITIALIZE MAIN GUI

Gui Margin, 0,0
Gui, Add, Text, x10 y10 w300, New name:
Gui, Add, Edit, x70 yp-3 w200 vNewProjectName, GiveMeNewNamePlease
Gui, Add, Text, x10 y40 w260 r5 0x201 Border, Drag project folder here
Gui, Add, Text, x10 y120 w300, Instruction:`n    1. Fill name box with a proper name, f.e. LaVita`n    2. Drag and drop folder, f.e. 1157_Impossible`n    3. Wait until final message box appears`n`nRemember: NO SPACES! NO SYMBOLS!

Gui Show, w280 h205, Renamer

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
	
	Loop, parse, A_GuiEvent, `n
	{
		DroppedFolder := A_LoopField
	}
	
	GoSub, ProcessFolder
return


ProcessFolder:
	OldProjectFolderPath := DroppedFolder
	
	; Create Notch folder path string
	NotchFolder := OldProjectFolderPath . "\Notch"
	
	; Check if Notch folder is inside
	if not (FileExist(NotchFolder)) {
		MsgBox, , Renamer,
		(
		No Notch folder found inside!
		Double check if you dragged correct folder!
		)

		return
	}
	
	; Split path to separate directory names "E, RootDir, SCENOGRAPHIES, ProjectName"
	PathArray := StrSplit(OldProjectFolderPath, "\")
	
	; Extract current folder name
	OldFolderName := PathArray[PathArray.MaxIndex()]
	
	; Remove current folder name from array
	PathArray.remove(PathArray.MaxIndex())
	
	; Prepare new folder name
	SplittedOldFolderName := StrSplit(OldFolderName, "_")
	ProjectNumber := SplittedOldFolderName[1]
	OldProjectName := SplittedOldFolderName[2]
	NewFolderName := ProjectNumber . "_" . NewProjectName
	
	; Add new folder name to path
	PathArray[PathArray.MaxIndex() + 1] := NewFolderName
	
	; Create proper string for new folder path
	NewProjectFolderPath := Join(PathArray, "\")

	; Rename main folder
	FileMoveDir, %OldProjectFolderPath%, %NewProjectFolderPath%
	
	NotchFolder := NewProjectFolderPath . "\Notch"
	
	; Get all dfx files paths
	OldPathsDFX := []
	Loop %NotchFolder%\*.dfx, 0
	{
		OldPathsDFX.Push(A_LoopFileFullPath)
	}
	
	; Get all dfx files names
	OldNamesDFX := []
	for index, element in OldPathsDFX {
		splitted := StrSplit(element, "\")
		OldNamesDFX.Push(splitted[splitted.MaxIndex()])
	}
	
	NewNamesDFX := []
	; Rename old project names to new project names
	for index, element in OldNamesDFX {
		NewNamesDFX.Push(StrReplace(element, OldProjectName, NewProjectName))
	}
	
	; Create correct new paths for renamed DFX files
	NewPathsDFX := []
	for index, element in NewNamesDFX {
		NewPathsDFX.Push(NotchFolder . "\" . element)
	}

	; Rename DFX files
	for index, element in OldPathsDFX {
		FileMove, %element%, % NewPathsDFX[index]
	}
	
	GoSub, ProcessFilesDFX
Return


ProcessFilesDFX:
	for index, element in NewPathsDFX {
		SplitPath, element, name, dir, ext, name_no_ext
		
		; Run Notch project
		Run, % element
		
		; Wait for project file to open
		WinWaitActive, % name_no_ext
		Sleep, % CFG.Slowness * 10
		
		; Maximize window
		GoSub, MakeSureNotchIsFocused

		WindowName = %name% - Notch Builder
		WinMaximize, % WindowName
		Sleep, % CFG.Slowness * 2.5
		
		GoSub, FindMissingResources
	}
	
	MsgBox, Finished renaming project.`nCHECK, SAVE and CLOSE.
return


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


MakeSureNotchIsFocused:
	; Make sure Notch window is active
	if not WinActive("- Notch Builder") {
	MsgBox, ERROR: [CRITICAL] Renamer`nLost focus on Notch window, exiting script!
		ExitApp
	}
Return

;=== end of FUNCTIONS
;====================