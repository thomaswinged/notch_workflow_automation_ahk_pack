; Notch Workflow Automation AHK Pack
; Base Toolset Functions

;=====================
;========== APP HEADER

#Include include\JSON.ahk
#NoEnv
SetTitleMatchMode, 2 ; A window's title can contain WinTitle anywhere inside it to be a match
#SingleInstance Force ; Only allows one instance of the script to run.
SetBatchLines, -1
SetWinDelay, 0

;=== end of APP HEADER
;=====================


;=============================
;========== USER CONFIGURATION
; Coords - coordinates of necessary mouse clicks must be specified correctly before using a script; each resolution and each monitors setup may have different coordinates
; WindowNames - names of windows may change at some point when Notch releases a new version
;	MainEditorWindow - is the suffix of the Notch editor window name, including "- "
; Surfaces - contain all information about surfaces
; 	PixelmapBinName - the name of a bin with pixelmap that is available in the Notch editor
;	Resolution - resolution of surface
;	NDI - output NDI name
; Slowness - how slow and precise the script is; if it's too slow, you can crank it down : )

FileRead, ConfigFile, include\config.cfg
CFG := JSON.Load(ConfigFile)

;=== end of USER CONFIGURATION
;=============================


;====================
;========== FUNCTIONS

PlacePixelmap(SurfaceName) {
	global CFG

	; Make sure Notch window is activse
	if not WinActive("- Notch Builder") {
		MsgBox, , Warning!,
		(
		Notch window is not focused. Do it and try again : )
		)
		Return
	}


	; Store clipboard to a backup value
	ClipBackup := clipboard

	; Click Bin input field
	Mousemove, % CFG.Coords.BinInputField.X, % CFG.Coords.BinInputField.Y, 1
	Sleep, % CFG.Slowness * 1

	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Paste Bin name
	Send, ^a
	clipboard := CFG.Surfaces[SurfaceName].PixelmapBinName
	Send, ^v
	Sleep, % CFG.Slowness * 3

	; Drag bin to center of nodegraph
	MouseClickDrag, L, % CFG.Coords.BinEntry.X, % CFG.Coords.BinEntry.Y, % CFG.Coords.GraphCenter.X, % CFG.Coords.GraphCenter.Y

	; Restore clipboard
	clipboard := ClipBackup

	Return
}


SetProperties(SurfaceName) {
	global CFG
	
	; Make sure Notch window is active
	if not WinActive("- Notch Builder") {
		MsgBox, , Warning,
		(
		Notch window is not focused. Do it and try again : )
		)
		Return
	}
	
	; Block user mouse input while this script is performing
	BlockInput, MouseMove
	
	; Store clipboard to a backup value
	ClipBackup := clipboard

	; Store mouse current position
	MouseGetPos, x, y

	; Click [Project]
	Mousemove, % CFG.Coords.ProjectMenu.X, % CFG.Coords.ProjectMenu.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Click [Settings]
	Mousemove, % CFG.Coords.ProjectSettingsMenu.X, % CFG.Coords.ProjectSettingsMenu.Y, 1
	MouseClick, left

	; Wait for window to appear
	WinWaitActive, % CFG.WindowNames.ProjectSettings
	Sleep, % CFG.Slowness
	WinActivate, % CFG.WindowNames.ProjectSettings ; TODO: is this needed?

	; Click [Rendering]
	Mousemove, % CFG.Coords.ProjSetRendering.X, % CFG.Coords.ProjSetRendering.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Click [Output Width] textbox
	Mousemove, % CFG.Coords.ProjSetOutWidth.X, % CFG.Coords.ProjSetOutWidth.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Set resolution X
	Send, ^a
	clipboard := CFG.Surfaces[SurfaceName].Resolution.X
	ClipWait
	Send ^v
	Sleep, % CFG.Slowness * 1

	; Click [Output Height] textbox
	Mousemove, % CFG.Coords.ProjSetOutHeight.X, % CFG.Coords.ProjSetOutHeight.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Set resolution Y
	Send, ^a
	clipboard := CFG.Surfaces[SurfaceName].Resolution.Y
	ClipWait
	Send ^v
	Sleep, % CFG.Slowness * 1

	; Click [Output Resizing] menu
	Mousemove, % CFG.Coords.ProjSetOutResizing.X, % CFG.Coords.ProjSetOutResizing.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Click [Scale] setting
	Mousemove, % CFG.Coords.ProjSetOutResScale.X, % CFG.Coords.ProjSetOutResScale.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Click [OK]
	Mousemove, % CFG.Coords.ProjSetRenderOK.X, % CFG.Coords.ProjSetRenderOK.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Wait for window to appear
	WinWaitActive, % CFG.WindowNames.MainEditorWindow
	Sleep, % CFG.Slowness * 1

	; Click [Devices]
	Mousemove, % CFG.Coords.DevicesMenu.X, % CFG.Coords.DevicesMenu.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	; Click [VideoIn/Camera/Kinekt Settings]
	Mousemove, % CFG.Coords.DevVideoSettings.X, % CFG.Coords.DevVideoSettings.Y, 1
	MouseClick, left

	; Wait for window to appear
	WinWaitActive, % CFG.WindowNames.DevVideoSettings
	Sleep, % CFG.Slowness * 2
	WinActivate, % CFG.WindowNames.DevVideoSettings ; TODO: is this needed?

	; Click [Sender Name] textbox and set NDI name
	Mousemove, % CFG.Coords.DevSetNDIName.X, % CFG.Coords.DevSetNDIName.Y, 1
	MouseClick, left
	Sleep, % CFG.Slowness * 1

	Send, ^a
	clipboard := CFG.Surfaces[SurfaceName].NDI
	ClipWait
	Send ^v
	Sleep, % CFG.Slowness * 1

	; Click [OK]
	Send, {Enter}

	; Wait for window to appear
	WinWaitActive, % CFG.WindowNames.MainEditorWindow
	Sleep, % CFG.Slowness * 1

	; Return mouse to previos position
	MouseMove %x%, %y%

	; Restore clipboard
	clipboard := ClipBackup

	; Unblock mouse
	BlockInput, MouseMoveOff

	Return
}

IsFolder( path ) {
	return InStr( FileExist(path), "D")
}

Join(array, sep) {
	for index, element in array {
		str .= sep . element
	}
		
	return SubStr(str, StrLen(sep)+1)
}


GetSubFolders(FolderPath) {
	subfolders := []
	
	Loop, Files, %FolderPath%\*, DR
		subfolders.Push(A_LoopFileFullPath)
	
	return subfolders
}


FlattenArray(array) {
	flatten := []
	
	for index, element in array {
		if element[1] {
			msgbox found array inside
			for index2, element2 in FlattenArray(element)
				flatten.Push(element2)
		} else {
			msgbox adding element %element%
			flatten.Push(element)
		}
	}
	
	return flatten
}

;=== end of FUNCTIONS
;====================
