; Notch Workflow Automation AHK Pack
; RenderBuddy v1.2


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
;=========== START DEBUGGER

	; Start log file
	FileDelete, % A_MyDocuments . CFG.LogFilePath
	l("Started RenderBuddy")
	l("CFG:" . o(CFG))


;==== end of START DEBUGGER
;==========================



;================================
;==== INITIALIZE GLOBAL VARIABLES

	; Gather all ProjectFile's instances here
	ProjectFiles := []

	; Store scene info here
	SceneInfo := {}

	; Gather selected rows indices here
	SelectedRows := []

	; Gather checked rows indices here
	CheckedRows := []

	; Create temporary folder
	FileCreateDir, % A_MyDocuments . CFG.TemporaryFolder
	l("Created temporary folder. RESULT: " . InStr( FileExist(A_MyDocuments . CFG.TemporaryFolder), "D"))

	; Register a function to be called on exit
	OnExit, ExitSub

;==== end of INITIALIZE GLOBAL VARIABLES
;=======================================



;============================
;==== INITIALIZE CONTEXT MENU


	Menu RightClickMenu, Add, Remove, DeleteEntryMenu
	Menu RightClickMenu, Add, Change name, ChangeNameMenu
	Menu RightClickMenu, Add, Change duration, ChangeDurationMenu
	Menu RightClickMenu, Add, Switch loop mode, SwitchLoopModeMenu
	Menu RightClickMenu, Add, Debug Entry, DebugEntryMenu


;==== end of INITIALIZE CONTEXT MENU
;===================================



;===================================
;==== INITIALIZE GUI 1 - MAIN WINDOW

	Gui1Width := 1400
	Gui1Height := 420

	; Add Queue list view module
	Gui, 1: Add, Text, x0 y11 w295 h1 0x10
	Gui, 1: Add, Text, x300 y5 w90, RENDER QUEUE
	Gui, 1: Add, Text, x390 y11 w332 h1 0x10

	Gui, 1: Add, ListView, x10 y25 w700 h320 gQueueListView AltSubmit Checked Grid vQueueLV, |ID|Scene ID|Surface|Scene Name|Moment|Version|Duration|Loop|Render Name
	; Adjust ListView columns width
	LV_ModifyCol(1, 20)
	LV_ModifyCol(2, 20)
	LV_ModifyCol(3, 60)
	LV_ModifyCol(4, 40)
	LV_ModifyCol(5, 150)
	LV_ModifyCol(6, 40)
	LV_ModifyCol(7, 20)
	LV_ModifyCol(8, 60)
	LV_ModifyCol(9, 40)
	LV_ModifyCol(10, 247)
	
	Gui, 1: Add, Text, x12 y363 w300, Output folder:
	Gui, 1: Add, Edit, x82 y360 w528 vOutputFolderPath, % CFG.RenderPath
	Gui, 1: Add, Button, x610 y360 w60 gBrowseOutputFolder, BROWSE
	
	Gui, 1: Add, Text, x12 y393 w300, Loop transition frames:
	Gui, 1: Add, Edit, x127 y390 w25 vLoopTransitionFrames, % CFG.DefaultLoopTransitionFrames
	
	Gui, 1: Add, Button, x250 y390 w60 gRenderButton, RENDER
	Gui, 1: Add, Button, x400 y390 w100 gCleanButton, CLEAN QUEUE
	
	Gui, 1: Add, Text, x670 y393 w100, % CFG.ScriptVersion
	
	; Modify GUI properties
	Gui, 1: Margin, 0,0
	
	; Draw a line separating main part and MEDIAINFO part
	Gui, 1: Add, Text, x720 y5 w1 h410 0x11
	Gui, 1: Add, Text, x720 y11 w110 h1 0x10
	Gui, 1: Add, Text, x830 y5 w45, MEDIAINFO
	Gui, 1: Add, Text, x895 y11 w107 h1 0x10
	Gui, 1: Add, Text, x1000 y5 w1 h410 0x11
	
	Gui, 1: Add, Text, x730 y25 w260 r4 0x201 Border vMediaInfoDropZone, Drag video clip here to get info

	Gui, 1: Add, Picture, x730 y94 w260 h146 vMIImage
	
	Gui, 1: Add, Text, x730 y250 w260 vMIName, Name:
	Gui, 1: Add, Text, x730 y270 w260 vMIExtension, Extension:
	Gui, 1: Add, Text, x730 y290 w260 vMIFormat, Format:
	Gui, 1: Add, Text, x730 y310 w260 vMICodec, Codec:
	Gui, 1: Add, Text, x730 y330 w260 vMIResolution, Resolution:
	Gui, 1: Add, Text, x730 y350 w260 vMIAspectRatio, Aspect Ratio:
	Gui, 1: Add, Text, x730 y370 w260 vMIDuration, Duration:
	Gui, 1: Add, Text, x730 y390 w260 vMIFramesCount, Frames Count:

	; Imported Media list view
	Gui, 1: Add, Text, x1000 y11 w160 h1 0x10
	Gui, 1: Add, Text, x1160 y5 w90, USED VIDEOS
	Gui, 1: Add, Text, x1237 y11 w337 h1 0x10

	Gui, 1: Add, ListView, x1010 y25 w380 h320 gMediaUsedListView AltSubmit Grid vMediaUsedLV, Name|Frames|Duration
	; Adjust ListView columns width
	LV_ModifyCol(1, 220)
	LV_ModifyCol(2, 60)
	LV_ModifyCol(3, 95)

	Gui, 1: Add, Text, x1010 y363 w300 vLongestClipFramesText, Longest clip [frames]:
	Gui, 1: Add, Text, x1210 y363 w300 vLongestClipTimeText, Longest clip [MM:SS:FF]:
	Gui, 1: Add, Text, x1010 y383 w300 vOptimalLoopFramesText, Optimal loop [frames]:
	Gui, 1: Add, Text, x1210 y383 w300 vOptimalLoopDurationText, Optimal loop [MM:SS:FF]:


;==== end of INITIALIZE GUI 1 - MAIN WINDOW
;==========================================



;===================================
;==== INITIALIZE GUI 2 - CHANGE NAME


	Gui, 2: Add, Text, x5 y9, New name:
	Gui, 2: Add, Edit, x65 y5 w200 vNewNameInput
	Gui, 2: Add, Button, x270 y5 gChangeNameButton, OK

	; Modify GUI properties
	Gui, 2: Margin, 0,0


;==== end of INITIALIZE GUI 2 - CHANGE NAME
;==========================================



;=======================================
;==== INITIALIZE GUI 3 - RENDER PROGRESS

	; Variable that will keep number of currently rendered project files
	RenderProgress := 0
	MaxRenderProgress := 0
	
	Gui, 3: Color, 0xFF0000
	Gui, 3: +E0x20 -Caption +LastFound +ToolWindow +AlwaysOnTop
	
	Gui, 3: Font, s30
	Gui, 3: Add, Text, x220 y70 cWhite, RENDERING IN PROGRESS
	Gui, 3: Font, s14
	Gui, 3: Add, Text, x80 y150 cWhite vRenderProgressCharacters, % MakeProgressBar(80, 0, 100)
	Gui, 3: Add, Text, x460 y180 w100 cWhite vRenderProgressString, % (RenderProgress + 1) . " / " . MaxRenderProgress
	Gui, 3: Add, Text, x200 y220 cWhite, Press PRTSC to make screenshot instead of rendering this project file
	Gui, 3: Add, Text, x360 y240 cWhite, Press ESC to stop script execution

	; Make it unclickable, not focusable and transparent
	WinSet, Transparent, 150


;==== INITIALIZE GUI 3 - RENDER PROGRESS
;=======================================



;=======================================
;==== INITIALIZE GUI 4 - CHANGE DURATION


	Gui, 4: Add, Text, x5 y9, New duration:
	Gui, 4: Add, Edit, x75 y5 w190 vNewDurationInput
	Gui, 4: Add, Button, x270 y5 gChangeDurationButton, OK
	Gui, 4: Add, Text, x25 y40, To provide time in frames instead of typing 00:30:00 `n  just type frame count (f.e. 750) (default FPS: 25)

	; Modify GUI properties
	Gui, 4: Margin, 0,0


;==== end of INITIALIZE GUI 4 - CHANGE DURATION
;==============================================



;==========================
;==== end of INITIALIZATION

	GoSub, GuiOpen
	Return

;==== end of INITIALIZATION
;==========================


;==================
;========== HOTKEYS

+Escape::Reload ; Safe button - reload script with Shift+Escape buttons combination

;=== end of HOTKEYS
;==================



;======================
;==== GUI 1 - MECHANISM


	;Spawn main GUI
	GuiOpen:
		l("[SUB]: GuiOpen")

		; Safety exit flag
		STOPABLE = 0
		Gui, 1: Show, w%Gui1Width% h%Gui1Height%, RenderBuddy
	Return
	
	
	
	; What should happen when pressed RENDER button
	RenderButton:
		l("[SUB]: RenderButton")

		; Put GUI info to variables
		Gui, 1:Submit, NoHide
		
		; If output folder is not specified, do nothing
		if not OutputFolderPath
			return
			
		; Update output info
		for index, value in ProjectFiles {
			value.FillOutputInformation(OutputFolderPath)
		}
		
		; Get information about checked checkboxes
		CheckedRows := GetCheckedRows("QueueLV")
		
		; If any rows has not been checked, do nothing
		if CheckedRows.MaxIndex() < 1
			return
			
		; Get count of projects in queue
		MaxRenderProgress := CheckedRows.MaxIndex()
		
		; Hide Gui
		Gui, 1:Hide
		
		GoSub, ShowRenderProgressWindow
		
		STOPABLE = 1
		
		; Process all checked project files
		for index, value in CheckedRows
		{
			PROJECT := ProjectFiles[value]

			if ( PROJECT.Loop == "YES" ) {
				; Create folder for looped video files
				FileCreateDir, % PROJECT.RenderFolderPathLoop
			} else {
				; Create folder for cutted video files
				FileCreateDir, % PROJECT.RenderFolderPathCut
			}
			
			; Run currently processed project file
			Run % PROJECT.FilePath
			; Wait for project file to open
			WinWaitActive, % PROJECT.FileName
			Sleep, % CFG.Slowness * 4
			
			FillRenderSettings(PROJECT)
			
			; Send enter to start render
			Send, {Enter}

			WinWaitActive, % CFG.WindowNames.OverrideRender, , % CFG.Slowness / 100
			if ErrorLevel
			{
				; If window did not popped up it means that there is no file being overriden
			}
			else
			{
				; If window pop ups - send enter to override the file
				Sleep, % CFG.Slowness * 1
				Send, {Enter}
			}
			
			; Wait until exporting process ends then close Notch project
			Sleep, % CFG.Slowness * 50
			WinWaitActive, % PROJECT.FileName

			; If user interrupted render with PrntScreen key
			; Wait for it's subroutine to end
			while PRINTSCREEN_INTERRUPT
			{
				Sleep, % CFG.Slowness * 1
			}

			; Make sure Notch window is active
			if not WinActive("- Notch Builder") {
				MsgBox, , RenderBuddy,
				(
				Notch window is not focused. Do it and try again : )
				)
				Return
			}

			Sleep, % CFG.Slowness * 5

			Send, !{F4}

			Sleep, % CFG.Slowness * 5
			
			; If there is no sign to skip ffmpeg commands
			if !SKIP_FFMPEG {
				if ( PROJECT.Loop == "YES" ) {
					LoopDuration := ConvertNotchTimeToFPSCount( PROJECT.Duration, CFG.FPS ) / CFG.FPS
					LoopDurationPlusOne := LoopDuration + 1
					TransitionTime := LoopTransitionFrames / CFG.FPS
					LoopDurationNTransition := TransitionTime + LoopDuration + 1
					SourceFilepath := PROJECT.RenderFilePath
					TempFilepath := PROJECT.RenderTmpFilePathLoop
					OutputFilepath := PROJECT.RenderFilePathLoop

					; Command for blending two files together with transition at the beginning of video file
					LoopCMD = ffmpeg -y -i %SourceFilepath% -filter_complex "[0]pad=ceil(iw/4)*4:ceil(ih/4)*4[o];[o]split[tran][body];[body]trim=1:%LoopDurationPlusOne%,setpts=PTS-STARTPTS,format=yuva420p,fade=d=%TransitionTime%:alpha=1[jt];[tran]trim=%LoopDurationPlusOne%:%LoopDurationNTransition%,setpts=PTS-STARTPTS[main];[main][jt]overlay" %TempFilepath%

					; Reconvert output file to HAP codec
					ConvertToHAPCMD = ffmpeg -y -i %TempFilepath% -c:v hap %OutputFilepath%
					
					RunWait, %ComSpec% /c %LoopCMD%
					RunWait, %ComSpec% /c %ConvertToHAPCMD%
					
					; After convertion remove temporary files
					FileDelete, %TempFilepath%
				} else {
					; Prepare a command to trim videos
					TrimFrameCMD := "ffmpeg -y -ss 00:00:0.08 -i """ . PROJECT.RenderFilePath . """ -an -vcodec copy -t " . CFG.DefaultRenderTime . " """ . PROJECT.RenderFilePathCut . """"
					
					; Fire movie trimming
					RunWait, %ComSpec% /c %TrimFrameCMD%
				}
			}

			; Clean ffmpeg skipping flag
			SKIP_FFMPEG = 0
			
			; Increment rendering progress
			RenderProgress++
			
			Gui, 3: default
			GuiControl, Text, RenderProgressCharacters, % MakeProgressBar(80, RenderProgress, MaxRenderProgress)
			GuiControl, Text, RenderProgressString, % (RenderProgress + 1) . " / " . MaxRenderProgress
		}
		
		Gui, 3:Hide
		
		STOPABLE = 0
		
		Gui, 1: default
		Gui, 1: Show
		
		Run, %OutputFolderPath%
	Return
	
	
	
	; What should happen when pressed CLEAN button
	CleanButton:
		l("[SUB]: CleanButton")

		; Clear global arrays
		ProjectFiles := []
		SceneInfo := {}

		CleanListView("QueueLV")
		CleanListView("MediaUsedLV")
		FillMediaInfo({})
		FillUsedMediaInfo("","")
		
		RefreshEntries()
	Return



	CleanListView(list_view_name) {
		l("[FUNC]: CleanListView(list_view_name=" . list_view_name . ")")

		; Select ListView
		Gui, ListView, % list_view_name

		; Clean it
		LV_Delete()
	}
	
	
	
	ShowRenderProgressWindow:
		l("[SUB]: ShowRenderProgressWindow")

		; Reset the counter of currently rendered files
		RenderProgress := 0
		
		Gui, 3: default
		GuiControl, Text, RenderProgressString, % (RenderProgress + 1) . " / " . MaxRenderProgress
		Gui, 1: default
		
		; Show render window progress
		Gui, 3:Show, w1024 h276 NoActivate
	Return
	
	
	
	; Define user control of ListView
	QueueListView:
		l("[SUB]: QueueListView")

		if (A_GuiEvent = "RightClick") {
			GetSelectedRows(0)

			; Create context menu under mouse cursor
			MouseGetPos, MX, MY
			Menu, RightClickMenu, Show, %MX%, %MY%
		} else if (A_GuiEvent = "Normal") {
			; Show used media in this project in another list view
			GetSelectedRows(0)

			; Display used media for selected project entry
			SelectedProjectEntry := ProjectFiles[SelectedRows[1]]
			GoSub, DisplayUsedMedia
		}
	Return
	
	

	; What should happen when pressed BROWSE button
	BrowseOutputFolder:
		l("[SUB]: BrowseOutputFolder")

		StartDir := CFG.RenderPath
		FileSelectFolder, OutputFolder, *%StartDir%, 2, Select export folder
		
		Gui, 1: Default
		GuiControl,,OutputFolderPath, % OutputFolder
	Return
	
	
	
	; Extract information of ListView's selected rows
	GetSelectedRows(GUI_ID) {
		l("[FUNC]: GetSelectedRows(GUI_ID=" . GUI_ID . ")")

		global SelectedRows
		SelectedRows := []
		SelectedRow := 0

		if (GUI_ID = 0) {
			; Get rows for Queue list view
			Gui, ListView, QueueLV
		} else {
			; Get rows for Media Used list view
			Gui, ListView, MediaUsedLV
		} 

		Loop
		{
			SelectedRow := LV_GetNext(SelectedRow)
			
			if (SelectedRow = 0) {
				break
			}
			
			SelectedRows.Push(SelectedRow)
		}
	}
	
	
	
	; Delete selected rows
	DeleteEntryMenu:
		l("[SUB]: DeleteEntryMenu")

		LoopCount := SelectedRows.MaxIndex()
		
		while (LoopCount)
		{
			DeleteEntry(SelectedRows[LoopCount])
			LoopCount--
		}
		
		RefreshEntries()
	Return



	; Get information about checked rows
	GetCheckedRows(list_view_name) {
		l("[FUNC]: GetCheckedRows(list_view_name=" . list_view_name . ")")

		CheckedRows := []
		
		; Select list view
		Gui, ListView, % list_view_name
		
		Loop % LV_GetCount()
		{
			Gui +LastFound
			SendMessage,4140, A_Index - 1, 0xF000, SysListView321
			IsChecked := (ErrorLevel >> 12) - 1
			
			if IsChecked
				CheckedRows.Push(A_Index)
		}

		l("[RETURN]: " . CheckedRows)
		return CheckedRows
	}



	; Clean and repopulate ListView
	RefreshEntries() {
		l("[FUNC]: RefreshEntries()")

		global ProjectFiles
		global OutputFolderPath
		
		; Put GUI info to variables
		Gui, 1:Submit, NoHide
		
		Gui, 1: default
		
		; Select ListView #1
		Gui, ListView, QueueLV
		
		; Clean ListView
		LV_Delete()
		
		; Update object information and populate ListView with data
		for index, value in ProjectFiles {
			value.FillRestInformation()
			value.FillOutputInformation(OutputFolderPath)
			
			AddFileToListView(value)
		}
	}



	; Used media list view mechanics
	MediaUsedListView:
		l("[SUB]: MediaUsedListView")

		if (A_GuiEvent = "Normal") {
			; Display video clip info on single click
			GetSelectedRows(1)

			; Get selected row first column text
			LV_GetText(RowText, SelectedRows[1])
			for i, element in SceneInfo[SelectedProjectEntry.SceneName].MediaUsed {
				if element.Name == RowText {
					GuiControl,, MIImage, % element.ThumbnailPath

					GuiControl,, MIName, % "Name: " . element.Name
					GuiControl,, MIExtension, % "Extension: " . element.Extension
					GuiControl,, MIFormat, % "Format: " . element.Format
					GuiControl,, MICodec, % "Codec: " . element.Codec
					GuiControl,, MIResolution, % "Resolution: " element.Resolution
					GuiControl,, MIAspectRatio, % "Aspect Ratio: " . element.AspectRatio
					GuiControl,, MIDuration, % "Duration: " . element.Duration
					GuiControl,, MIFramesCount, % "Frames Count: " . element.FrameCount

					break
				}
			}
		} else if (A_GuiEvent = "DoubleClick") {
			; Open video clip on double click
			GetSelectedRows(1)

			; Get selected row first column text
			LV_GetText(RowText, SelectedRows[1])
			
			for i, element in SceneInfo[SelectedProjectEntry.SceneName].MediaUsed {
				if element.Name == RowText {
					Run, % element.Path
					break
				}
			}

		}
	Return



	DisplayUsedMedia:
		l("[SUB]: DisplayUsedMedia")

		; Select used media list view
		Gui, ListView, MediaUsedLV
		
		; Clean ListView
		LV_Delete()

		for i, element in SceneInfo[SelectedProjectEntry.SceneName].MediaUsed {
			LV_Add(,element.Name, element.FrameCount, element.Duration)
		}

		_longest_frames := SceneInfo[SelectedProjectEntry.SceneName].LongestClipFrames
		_optimal_loop := SceneInfo[SelectedProjectEntry.SceneName].OptimalLoopDuration
		
		FillUsedMediaInfo(_longest_frames, _optimal_loop)
	Return



	FillUsedMediaInfo(longest_frame, optimal_loop) {
		l("[FUNC]: FillUsedMediaInfo(longest_frame=" . longest_frame . ", optimal_loop=" . optimal_loop . ")")

		global CFG

		GuiControl,, LongestClipFramesText, % "Longest clip [frames]: " . longest_frame
		GuiControl,, LongestClipTimeText, % "Longest clip [MM:SS:FF]: " . ConvertFPSCountToNotchTime(longest_frame, CFG.FPS)
		GuiControl,, OptimalLoopFramesText, % "Optimal loop [frames]: " . optimal_loop
		GuiControl,, OptimalLoopDurationText, % "Optimal loop [MM:SS:FF]: " . ConvertFPSCountToNotchTime(optimal_loop, CFG.FPS)
	}


;==== end of GUI 1 - MECHANISM
;=============================



;======================
;==== GUI 2 - MECHANISM

	
	; Define what happens when clicked "Rename" context menu
	ChangeNameMenu:
		l("[SUB]: ChangeNameMenu")

		Gui, 2: Default
		GuiControl,,NewNameInput, % ProjectFiles[SelectedRows[1]].SceneName
		Gui, 2: Show, w300 h30
	Return



	; Define what happens when clicked RENAME button inside GUI 2
	ChangeNameButton:
		l("[SUB]: ChangeNameButton")

		; Get edit box content and hide gui
		Gui, 2: Submit, Hide
		
		; Apply name to selected rows
		if (NewNameInput) {
			LoopCount := SelectedRows.MaxIndex()
		
			while (LoopCount)
			{
				ProjectFiles[SelectedRows[LoopCount]].ChangeInformation( "SceneName", NewNameInput)
				LoopCount--
			}
		}

		RefreshEntries()
	Return


;==== end of GUI 2 - MECHANISM
;=============================



;======================
;==== GUI 4 - MECHANISM


	; Define what happens when clicked "Change Duration" context menu
	ChangeDurationMenu:
		l("[SUB]: ChangeDurationMenu")

		Gui, 4: Default
		GuiControl,,NewDurationInput, % ProjectFiles[SelectedRows[1]].Duration
		Gui, 4: Show, w300 h75
	Return



	; Define what happens when clicked CHANGE button inside GUI 4
	ChangeDurationButton:
		l("[SUB]: ChangeDurationButton")

		; Get edit box content and hide gui
		Gui, 4: Submit, Hide
		
		; Apply name to selected rows
		if (NewDurationInput) {
			LoopCount := SelectedRows.MaxIndex()
			
			; If time has been passed in frames number, convert it to HH:MM:SS format
			if not InStr(NewDurationInput, ":") {
				NewDurationInput := ConvertFPSCountToNotchTime(NewDurationInput, CFG.FPS)
			}
		
			while (LoopCount)
			{
				ProjectFiles[SelectedRows[LoopCount]].ChangeInformation( "Duration", NewDurationInput)
				LoopCount--
			}
		}

		RefreshEntries()
	Return


;==== end of GUI 4 - MECHANISM
;=============================



;=====================
;==== DEBUG ENTRY MENU

	; Define what happens when clicked "Debug Entry" context menu
	DebugEntryMenu:
		l("[SUB]: DebugEntryMenu")

		RefreshEntries()
		
		for index, value in SelectedRows {
			MsgBox % ProjectFiles[value].ToString()
		}
	Return

;==== end of DEBUG ENTRY MENU
;============================



;============================
;==== SWITCH RENDER TYPE MENU


	; Define what happens when clicked "Switch Loop Mode" context menu
	SwitchLoopModeMenu:
		l("[SUB]: SwitchLoopModeMenu")

		Counter := SelectedRows.MaxIndex()
		
		while (Counter)
		{
			; If life is marked as loop, flag it as normal render
			if ( ProjectFiles[SelectedRows[Counter]].Loop == "YES" ) {
				ProjectFiles[SelectedRows[Counter]].ChangeInformation( "Loop", "NO")
				
				; Set standard render duration
				ProjectFiles[SelectedRows[Counter]].ChangeInformation( "Duration", CFG.DefaultRenderTime )
			} else {
				; If life is marked normal render, mark it as loop
				ProjectFiles[SelectedRows[Counter]].ChangeInformation( "Loop", "YES")
				
				; Set optimal loop duration
				OptimalLoopDuration := ConvertFPSCountToNotchTime(ProjectFiles[SelectedRows[Counter]].OptimalLoopDuration, CFG.FPS)
				ProjectFiles[SelectedRows[Counter]].ChangeInformation( "Duration", OptimalLoopDuration)
			}
			
			Counter--
		}
		
		RefreshEntries()
	Return


;==== end of SWITCH RENDER TYPE MENU
;===================================



;===================================
;==== PROCESS DROPPED FILES ONTO GUI


	GuiDropFiles:
		l("[SUB]: GuiDropFiles")

		; Recognize onto what GUI element files has been dropped
		if ( A_GuiControl == "QueueLV" )
			; Files dropped onto list view - add them to render queue
			GoSub, PassToQueue
		else if ( A_GuiControl == "MediaInfoDropZone" )
			GoSub, PassToMediaInfo
		else
			return
			
		
	Return
	
	
	
	PassToQueue:
		l("[SUB]: PassToQueue")

		CalculateOptimalLoopTime := True
		
		Loop, parse, A_GuiEvent, `n
		{
			SplitPath, A_LoopField, name, dir, ext, name_no_ext
			
			if InStr(FileExist(A_LoopField), "D") {
				ProcessFolder(A_LoopField)
			} else if (ext == "dfx") {
				ProcessProjectFile(A_LoopField)
			}
		}
		
		RemoveOlderVersions()
	return
	
	
	
	PassToMediaInfo:
		l("[SUB]: PassToMediaInfo")

		VideoPath := ""

		Loop, parse, A_GuiEvent, `n
		{
			VideoPath := A_LoopField
		}

		video_info := new VideoInfo
		video_info.Get(VideoPath)

		; If passed no video, do nothing
		if (video_info = -1)
			return

		FillMediaInfo(video_info)		
	return



	FillMediaInfo(video_info){
		l("[FUNC]: FillMediaInfo(video_info=" . o(video_info) . ")")

		GuiControl,, MIImage, % video_info.ThumbnailPath

		GuiControl,, MIName, % "Name: " . video_info.Name
		GuiControl,, MIExtension, % "Extension: " . video_info.Extension
		GuiControl,, MIFormat, % "Format: " . video_info.Format
		GuiControl,, MICodec, % "Codec: " . video_info.Codec
		GuiControl,, MIResolution, % "Resolution: " video_info.Resolution
		GuiControl,, MIAspectRatio, % "Aspect Ratio: " . video_info.AspectRatio
		GuiControl,, MIDuration, % "Duration: " . video_info.Duration
		GuiControl,, MIFramesCount, % "Frames Count: " . video_info.FrameCount
	}



	ProcessFolder(FolderPath) {
		l("[FUNC]: ProcessFolder(FolderPath=" . FolderPath . ")")

		; Check if inside is a Notch folder
		Loop %FolderPath%\Notch\*.dfx, 0
		{
			ProcessProjectFile(A_LoopFileFullPath)
		}
		
		; Loop through files
		Loop %FolderPath%\*.dfx, 0
		{
			ProcessProjectFile(A_LoopFileFullPath)
		}
	}

	ProcessProjectFile(FilePath) {
		l("[FUNC]: ProcessProjectFile(FilePath=" . FilePath . ")")
		
		if not FilePath {
			l("[RETURN]: " . 0)
			return
		}
			
		global ProjectFiles
		global CFG
		global OptimalLoopDuration
		global CalculateOptimalLoopTime
		global SceneInfo
		
		; Create new ProjectFile object
		CurrentFile := new ProjectFile
		
		; Assign file ID for this queue
		if (ProjectFiles.MaxIndex() < 1) {
			CurrentFile.ID := 1
		} else {
			CurrentFile.ID := ProjectFiles.MaxIndex() + 1
		}
		
		CurrentFile.FilePath := FilePath
		
		; Get important info from filename
		; Example: 1069_GottaDance_Floor_A_v01
		; Example: 3025_Nevermind_Main_v01
		SplitPath, FilePath, name, dir, ext, name_no_ext
		SplittedString := StrSplit(name_no_ext, "_")
		
		; Save project file name for later
		CurrentFile.FileName := name_no_ext
		
		CurrentFile.Duration := CFG.DefaultRenderTime
		
		; Assign information from filename to ProjectFile object
		SceneID := SplittedString[1]
		SceneName := SplittedString[2]
		CurrentFile.SceneID := SceneID
		CurrentFile.SceneName := SceneName
		CurrentFile.Surface := SplittedString[3]
		
		; Check if filename contains moment information
		if (SplittedString.MaxIndex() = 4) {
			; If it does not contain moment info
			CurrentFile.VersionStr := SplittedString[4]
			TMP := CurrentFile.VersionStr
			StringTrimLeft, TMP2, TMP, 1
			CurrentFile.VersionInt := TMP2
		} else {
			; If it contains moment info
			CurrentFile.Moment := SplittedString[4]
			CurrentFile.VersionStr := SplittedString[5]
			TMP := CurrentFile.VersionStr
			StringTrimLeft, TMP2, TMP, 1
			CurrentFile.VersionInt := TMP2
		}
		
		; Remove leading "0" from version number
		CurrentFile.VersionInt := LTrim(CurrentFile.VersionInt, "0")

		; If this is the first project files imported from this scene
		if exist(SceneInfo[SceneName]) = 0 {
			; Create empty array for used media in there
			SceneInfo[SceneName] := { MediaUsed: [] }

			; Prepare footage folder path
			dir_splitted := StrSplit(dir, "\")
			dir_splitted.remove(dir_splitted.MaxIndex())
			FootageFolder := ArrayToString(dir_splitted, "\")

			; Get correct path for footage folder
			if FileExist(FootageFolder "\Footage")
				FootageFolder := FootageFolder "\Footage"
			else
				FootageFolder := FootageFolder "\footage"

			used_footage := GetVideoFiles(FootageFolder)

			for i, path in used_footage {
				video_info := new VideoInfo
				video_info.Get(path)

				SceneInfo[SceneName].MediaUsed.Push(video_info)
			}

			; Finally calculate optimal loop duration
			OptimalLoopDuration := GetOptimalLoopFramesDuration(SceneName)

			SceneInfo[SceneName]["OptimalLoopDuration"] := OptimalLoopDuration
		}

		CurrentFile.OptimalLoopDuration := OptimalLoopDuration
		
		; Fill the rest information based on config on the top of script file
		CurrentFile.FillRestInformation()
		
		; Put ProjectFile object to global array with other ProjectFile's
		ProjectFiles.Push(CurrentFile)

		AddFileToListView(CurrentFile)
	}


;==== PROCESS DROPPED FILES ONTO GUI
;===================================



;====================
;==== VIDEOINFO CLASS

	class VideoInfo {
		Path := ""
		Directory := ""
		Name := ""
		Extension := ""
		ThumbnailPath := ""
		Format := ""
		Codec := ""
		Width := 0
		Height := 0
		Resolution := ""
		AspectRatio := 0
		FrameCount := 0
		Duration := ""

		Get(Path) {
			l("[CLASS]: VideoInfo.Get()")

			global CFG

			SplitPath, Path, name, dir, ext, name_no_ext

			if ((ext != "mov") and (ext != "mp4"))
				return -1			

			; Save total path
			this.Path := Path

			; Save video name
			this.Name := name_no_ext

			; Save video extension
			this.Extension := ext

			; Save directory
			this.Directory := dir

			; Prepare command to run and get video info
			GetMIOutputCMD = mediainfo --output=JSON "%Path%"

			; Run the command
			MIOutput := RunWaitOne(GetMIOutputCMD)

			; Remove not imporant part
			MIOutput := SubStr(MIOutput, InStr(MIOutput, "@type",,, 2))

			; Get format info
			MIOutput := SubStr(MIOutput, InStr(MIOutput, "Format"))
			this.Format := StrSplit(MIOutput, ",")[1]
			this.Format := SubStr(this.Format, 11, -1)

			; Get codec info
			MIOutput := SubStr(MIOutput, InStr(MIOutput, "CodecID"))
			this.Codec := StrSplit(MIOutput, ",")[1]
			this.Codec := SubStr(this.Codec, 12, -1)

			; Get width info
			MIOutput := SubStr(MIOutput, InStr(MIOutput, "Width"))
			this.Width := StrSplit(MIOutput, ",")[1]
			this.Width := SubStr(this.Width, 10, -1)

			; Get height info
			MIOutput := SubStr(MIOutput, InStr(MIOutput, "Height"))
			this.Height := StrSplit(MIOutput, ",")[1]
			this.Height := SubStr(this.Height, 11, -1)

			this.Resolution := this.Width . "x" . this.Height

			; Get height info
			MIOutput := SubStr(MIOutput, InStr(MIOutput, "DisplayAspectRatio"))
			this.AspectRatio := StrSplit(MIOutput, ",")[1]
			this.AspectRatio := SubStr(this.AspectRatio, 23, -1)

			; Get frame count info
			MIOutput := SubStr(MIOutput, InStr(MIOutput, "FrameCount"))
			this.FrameCount := StrSplit(MIOutput, ",")[1]
			this.FrameCount := SubStr(this.FrameCount, 15, -1)

			; Get duration
			this.Duration := ConvertFPSCountToNotchTime(this.FrameCount, CFG.FPS)

			; Preapre thumbnail
			; Count number of files inside temporary folder
			TempDir := A_MyDocuments . CFG.TemporaryFolder

			_files_count := CountFilesInDir(A_MyDocuments . CFG.TemporaryFolder)

			; Prepare paths for thumbnail generation
			VideoPath_w_quotes := """" . Path . """"
			OutputPath_w_quotes := """" . TempDir . "thumb_" . _files_count . ".png"""

			; Save path to output object
			this.ThumbnailPath := TempDir . "thumb_" . _files_count . ".png"

			; Generate half-time to cut frame from there
			half_duration := ConvertFPSCountToFFMPEGTime(this.FrameCount / 2, CFG.FPS)

			; Generate thumbnail of file
			CreateThumbnailCMD = ffmpeg -y -ss %half_duration% -i %VideoPath_w_quotes% -vframes 1 -vf "scale=260:146:force_original_aspect_ratio=decrease,pad=260:146:(ow-iw)/2:(oh-ih)/2:color=black@0" %OutputPath_w_quotes%
			
			; Run the command
			RunWait, %ComSpec% /c %CreateThumbnailCMD%
		}

		ToString() {
			l("[CLASS]: VideoInfo.ToString()")

			OutString := "Path: " . this.Path
			OutString := OutString . "`nDirectory: " . this.Directory
			OutString := OutString . "`nName: " . this.Name
			OutString := OutString . "`nExtension: " . this.Extension
			OutString := OutString . "`nThumbnailPath: " . this.ThumbnailPath
			OutString := OutString . "`nFormat: " . this.Format
			OutString := OutString . "`nCodec: " . this.Codec
			OutString := OutString . "`nWidth: " . this.Width
			OutString := OutString . "`nHeight: " . this.Height
			OutString := OutString . "`nResolution: " . this.Resolution
			OutString := OutString . "`nAspectRatio: " . this.AspectRatio
			OutString := OutString . "`nFrameCount: " . this.FrameCount
			OutString := OutString . "`nDuration: " . this.Duration
			
			l("[RETURN]: " . OutString)
			return OutString
		}
	}

;==== end of VIDEOINFO CLASS
;===========================



;======================
;==== PROJECTFILE CLASS


	Class ProjectFile {
		ID := 0
		SceneID := 0
		SceneName := "-"
		Surface := "-"
		SurfaceTag := "-"
		Moment := "-"
		VersionInt := 0
		VersionStr := "v00"
		ResolutionX := 0
		ResolutionY := 0
		NDIName := "-"
		PresetPosition := "-"
		RenderName := "-"
		RenderFolderPath := "-"
		RenderFilePath := "-"
		RenderFolderPathCut := "-"
		RenderFilePathCut := "-"
		RenderFolderPathLoop := "-"
		RenderFilePathLoop := "-"
		RenderTmpFilePathLoop := "-"
		FilePath := "-"
		FileName := "-"
		Duration := "00:00:00"
		OptimalLoopDuration := 0
		Loop := "NO"
		
		; Fill the rest information based on config on the top of script file
		FillRestInformation() {
			l("[CLASS]: ProjectFile.FillRestInformation()")

			; Import surfaces definitions from the top of this file
			global CFG

			for Index, Surf in CFG.Surfaces {
				if InStr(Surf.FilenameMark, This.Surface) {
					This.SurfaceTag := Surf.RenderLetter
					This.ResolutionX := Surf.Resolution.X
					This.ResolutionY := Surf.Resolution.Y
					This.NDIName := Surf.NDI
					This.PresetPosition := Surf.PresetPosition

					break
				}
			}
			
			if (This.Moment = "-") {
				if (CFG.OmitExportNameVersioning)
					This.RenderName := This.SceneID . "_" . This.SurfaceTag . "_" . This.SceneName . ".mov"
				else
					This.RenderName := This.SceneID . "_" . This.SurfaceTag . "_" . This.SceneName . "_" . This.VersionStr . ".mov"
			} else {
				if (CFG.OmitExportNameVersioning)
					This.RenderName := This.SceneID . "_" . This.SurfaceTag . "_" . This.SceneName . "_" . This.Moment . ".mov"
				else
					This.RenderName := This.SceneID . "_" . This.SurfaceTag . "_" . This.SceneName . "_" . This.Moment . "_" . This.VersionStr . ".mov"
			}
		}
		
		FillOutputInformation(OutputFolder) {
			l("[CLASS]: ProjectFile.FillOutputInformation(OutputFolder=" . OutputFolder . ")")

			this.RenderFolderPath := OutputFolder . "\" . This.SceneID . "_" . This.SceneName
			this.RenderFilePath := this.RenderFolderPath . "\" . this.RenderName
			
			this.RenderFolderPathCut := this.RenderFolderPath . "\cut"
			this.RenderFilePathCut := this.RenderFolderPath . "\cut\" . this.RenderName
			
			this.RenderFolderPathLoop := this.RenderFolderPath . "\loop"
			this.RenderFilePathLoop := this.RenderFolderPath . "\loop\" . this.RenderName
			this.RenderTmpFilePathLoop := this.RenderFolderPath . "\loop\tmp.mov"
		}
		
		ChangeInformation(Property, NewValue) {
			l("[CLASS]: ProjectFile.ChangeInformation(Property=" . Property . ", NewValue=" . NewValue . ")")

			if (Property = "SceneName") {
				this.SceneName := NewValue
			} else if (Property = "Duration") {
				this.Duration := NewValue
			} else if (Property = "Loop") {
				this.Loop := NewValue
			}

			this.FillRestInformation()
		}
		
		ToString() {
			l("[CLASS]: ProjectFile.ToString()")

			OutString := "ID: " . This.ID
			OutString := OutString . "`nSceneID: " . This.SceneID
			OutString := OutString . "`nSceneName: " . This.SceneName
			OutString := OutString . "`nSurface: " . This.Surface
			OutString := OutString . "`nSurfaceTag: " . This.SurfaceTag
			OutString := OutString . "`nMoment: " . This.Moment
			OutString := OutString . "`nVersionInt: " . This.VersionInt
			OutString := OutString . "`nVersionStr: " . This.VersionStr
			OutString := OutString . "`nResolutionX: " . This.ResolutionX
			OutString := OutString . "`nResolutionY: " . This.ResolutionY
			OutString := OutString . "`nNDIName: " . This.NDIName
			OutString := OutString . "`nPresetPosition: " . This.PresetPosition
			OutString := OutString . "`nDuration: " . This.Duration
			OutString := OutString . "`nOptimalLoopDuration: " . This.OptimalLoopDuration
			OutString := OutString . "`nLoop: " . This.Loop
			OutString := OutString . "`nFilePath: " . This.FilePath
			OutString := OutString . "`nFileName: " . This.FileName
			OutString := OutString . "`nRenderName: " . This.RenderName
			OutString := OutString . "`nRenderFolderPath: " . This.RenderFolderPath
			OutString := OutString . "`nRenderFilePath: " . This.RenderFilePath
			OutString := OutString . "`nRenderFolderPathCut: " . This.RenderFolderPathCut
			OutString := OutString . "`nRenderFilePathCut: " . This.RenderFilePathCut
			OutString := OutString . "`nRenderFolderPathLoop: " . This.RenderFolderPathLoop
			OutString := OutString . "`nRenderFilePathLoop: " . This.RenderFilePathLoop
			OutString := OutString . "`nRenderTmpFilePathLoop: " . This.RenderTmpFilePathLoop
			
			l("[RETURN]: " . OutString)
			return OutString
		}
	}


;==== end of PROJECTFILE CLASS
;=============================



;================================
;==== PROJECTFILE CLASS MECHANICS


	; Deletes row - from ListView and from ProjectFiles array
	DeleteEntry(RowIndex) {
		l("[FUNC]: DeleteEntry(RowIndex=" . RowIndex . ")")

		global ProjectFiles
		
		; Delete object from ProjectFiles array
		ProjectFiles.Remove(RowIndex)
		
		while (RowIndex < ProjectFiles.MaxIndex() + 1)
		{
			ProjectFiles[RowIndex].ID := ProjectFiles[RowIndex].ID - 1
			RowIndex++
		}
	}
	
	
	
	; Clean queue from old project files entries
	RemoveOlderVersions() {
		l("[FUNC]: RemoveOlderVersions()")

		global ProjectFiles
		global CFG
		
		if CFG.DisplayOldProjectVersions
			return
		
		index := 0
		while (index < ProjectFiles.MaxIndex())
		{
			CurrentProject := ProjectFiles[index]
			NextProject := ProjectFiles[index + 1]
			CurrentTag := CurrentProject.SurfaceTag
			NextTag := NextProject.SurfaceTag
			CurrentVersion := CurrentProject.VersionInt
			NextVersion := NextProject.VersionInt
			
			if (NextProject) {
				if (CurrentTag == NextTag) {
					if (CurrentVersion < NextVersion) {
						DeleteEntry(index)
						index := 0
					} else if (CurrentVersion > NextVersion) {
						DeleteEntry(index+1)
						index := 0
					}
				}
				
				index++
			}
		}
		
		RefreshEntries()
	}
	
	
	
	ChangeFileInfo(RowIndex, Property, NewValue) {
		l("[FUNC]: ChangeFileInfo(RowIndex=" . RowIndex . ", Property=" . Property . ", NewValue=" . NewValue . ")")

		global ProjectFiles
		
		if (Property = "SceneName") {
			ProjectFiles[RowIndex].SceneName := NewValue
		} else if (Property = "Duration") {
			ProjectFiles[RowIndex].Duration := NewValue
		}

		ProjectFiles[RowIndex].FillRestInformation()
	}



	AddFileToListView(F) {
		l("[FUNC]: AddFileToListView(F=" . o(F) . ")")

		; Select ListView #1
		Gui, ListView, QueueLV
		LV_Add(Checked, "", F.ID, F.SceneID, F.Surface, F.SceneName, F.Moment, F.VersionInt, F.Duration, F.Loop, F.RenderName)
	}
	
	
;==== end of PROJECTFILE CLASS MECHANICS
;=======================================



;==========================
;==== GENERAL GUI FUNCTIONS


	; On GUI close
	GuiClose:
		l("[SUB]: GuiClose")

		ExitApp



	; Safety key
	$Esc::
		l("[HOTKEY]: $Esc")

		if ( STOPABLE = 1 ) {
			MsgBox, Stopped script execution
			ExitApp
		} else {
			Send, {Esc}
		}
	Return


;==== end of GENERAL GUI FUNCTIONS
;=================================



;==================================
;==== RENDER PROGRESS GUI FUNCTIONS


	MakeProgressBar(CharactersCount, Progress, MaxProgress) {
		l("[FUNC]: MakeProgressBar(CharactersCount=" . CharactersCount . ", Progress=" . Progress . ", MaxProgress=" . MaxProgress . ")")

		CharacterProgress := Progress / MaxProgress * CharactersCount
		CharacterLeft := CharactersCount - CharacterProgress
		
		OutputString := "["
		
		Loop, %CharacterProgress% {
			OutputString := OutputString . "#"
		}
		
		Loop, %CharacterLeft% {
			OutputString := OutputString . "="
		}
		
		OutputString := OutputString . "]"
		
		Return OutputString
	}


;==== end of RENDER PROGRESS GUI FUNCTIONS
;=========================================



;====================================================
;==== CALCULATE OPTIMAL VIDEO LOOP DURATION FUNCTIONS


	; Returns paths to all video files from provided path (f.e. Footage folder)
	GetVideoFiles(FolderPath) {
		l("[FUNC]: GetVideoFiles(FolderPath=" . FolderPath . ")")

		videos := []
		
		Loop, Files, %FolderPath%\*.mov, FR
		{
			; Omit files with . at the beginning
			SplitPath, A_LoopFileFullPath, name, dir, ext, name_no_ext
			if (InStr(name_no_ext, ".") == 1) {
				continue
			}
			
			videos.Push(A_LoopFileFullPath)
			
		}
		
		return videos
	}

	; Use MediaInfo to get frame count duration of a video file
	GetSingleVideoFileFramesCount(VideoPath) {
		l("[FUNC]: GetSingleVideoFileFramesCount(VideoPath=" . VideoPath . ")")

		; Check if for sure the file exists
		if !FileExist(VideoPath) {
			MsgBox, [GetSingleVideoFileFramesDuration] Provided path does not exist, exising!
			ExitApp
		}
		
		; Prepare command to run and get video frames count using mediainfo
		GetDurationFramesCMD = mediainfo --output=JSON "%VideoPath%" | findstr FrameCount
		
		; Run the command and save output string to variable
		FrameCount := RunWaitOne(GetDurationFramesCMD)
		
		; Filter the string to get only number of frames
		FrameCount := SubStr(StrSplit(StrSplit(FrameCount, "`n")[1], ":")[2], 3, -3)

		Return FrameCount
	}

	; Returns array of all video durations of all video files
	GetAllVideoFilesFramesCount(SceneName) {
		l("[FUNC]: GetAllVideoFilesFramesCount(SceneName=" . SceneName . ")")

		global SceneInfo
		FrameCounts := []
		
		for index, video_info in SceneInfo[SceneName].MediaUsed {
			FrameCounts.Push(video_info.FrameCount)
		}
		
		return FrameCounts
	}

	; Returns optimal loop duration for project made out of videos from provided scene
	GetOptimalLoopFramesDuration(SceneName) {
		l("[FUNC]: GetOptimalLoopFramesDuration(SceneName=" . SceneName . ")")

		global SceneInfo
		global CFG

		VideoDurations := GetAllVideoFilesFramesCount(SceneName)
		
		if (VideoDurations.MaxIndex() < 1)
			return 0
		
		UniqueDurations := RemoveDuplicates(VideoDurations)

		SceneInfo[SceneName]["LongestClipFrames"] := ArrayMax(UniqueDurations)

		LeastCommonMultiply := LCM(UniqueDurations)
		
		; If video loop is longer than default render time, use it instead
		MaxDuration = ConvertNotchTimeToFPSCount(CFG.DefaultRenderTime)
		if (LeastCommonMultiply > MaxDuration) {			
			LeastCommonMultiply := MaxDuration
		}
		
		return LeastCommonMultiply
	}


;==== end of CALCULATE OPTIMAL VIDEO LOOP DURATION FUNCTIONS
;===========================================================



;===================
;==== NOTCH CLICKERS


	FillRenderSettings(PROJECT) {
		l("[FUNC]: FillRenderSettings(SceneName=" . o(PROJECT) . ")")

		global OutputFolderPath
		global CFG
		global LoopTransitionFrames
		
		; Make sure Notch window is active
		if not WinActive("- Notch Builder") {
			MsgBox, , RenderBuddy,
			(
			Notch window is not focused. Do it and try again : )
			)

			Return
		}

		; Create Path For the renders
		OutputFolder := PROJECT.RenderFolderPath
		FileCreateDir, %OutputFolder%
		
		BlockInput, MouseMove

		; Store mouse current position
		MouseGetPos, x, y

		; Need to go to sleep, script is exhausted now
		Sleep, % CFG.Slowness * 4
		
		; Click [File]
		Mousemove, % CFG.Coords.FileMenu.X, % CFG.Coords.FileMenu.Y, 0
		Sleep, % CFG.Slowness * 2
		
		MouseClick, right
		MouseClick, left
		
		; Need to go to sleep, script is exhausted now
		Sleep, % CFG.Slowness * 2

		; Click [Export Video]
		Mousemove, % CFG.Coords.ExportVideoMenu.X, % CFG.Coords.ExportVideoMenu.Y, 0
		Sleep, % CFG.Slowness * 1
		MouseClick, left
		
		; Wait for [Export Video] window to appear
		WinWaitActive, % CFG.WindowNames.ExportVideo
		Sleep, % CFG.Slowness * 1

		; Click [Preset]
		Mousemove, % CFG.Coords.ExportPresetDrop.X, % CFG.Coords.ExportPresetDrop.Y, 0
		Sleep, % CFG.Slowness * 1
		MouseClick, left
		Sleep, % CFG.Slowness * 1
		Mousemove, % CFG.Coords.ExportPresetNone.X, % CFG.Coords.ExportPresetNone.Y, 0
		Sleep, % CFG.Slowness * 1
		MouseClick, left
		Sleep, % CFG.Slowness * 1

		; Choose adequate preset
		PresetPosition := PROJECT.PresetPosition
		Loop, %PresetPosition% {
			Send, {Down}
		}
		Sleep, % CFG.Slowness * 1

		; Click [Path]
		Mousemove, % CFG.Coords.RenderOutPath.X, % CFG.Coords.RenderOutPath.Y, 0
		Sleep, % CFG.Slowness * 1
		MouseClick, left
		Sleep, % CFG.Slowness * 1
		Send, ^a

		RenderDir := PROJECT.RenderFilePath

		; Push path to clipboard and paste it later to textbox
		clipboard := ""
		clipboard := RenderDir
		ClipWait

		Sleep, % CFG.Slowness * 1
		Send, ^v
		Sleep, % CFG.Slowness * 1

		; Set [End Render Time]
		if ( PROJECT.Loop == "YES" ) {
			; Adapt render time to loop time needs + add one second to cut start
			RenderTimeInput := ConvertFPSCountToNotchTime( ConvertNotchTimeToFPSCount(PROJECT.Duration, CFG.FPS) + LoopTransitionFrames + CFG.FPS, CFG.FPS)
		} else {
			RenderTimeInput := PROJECT.Duration
		}
			; Push adequate info to clipboard
			clipboard := ""
			clipboard := RenderTimeInput
			ClipWait

		Mousemove, % CFG.Coords.RenderOutTime.X, % CFG.Coords.RenderOutTime.Y, 0
		Sleep, % CFG.Slowness * 1
		MouseClick, left
		Sleep, % CFG.Slowness * 1
		Send, ^a
		Sleep, % CFG.Slowness * 1
		Send, ^v
		Sleep, % CFG.Slowness * 1
		
		; Return mouse to previous position
		MouseMove, x, y, 0
		
		BlockInput, MouseMoveOff

		; Restore clipboard
		clipboard := ClipboardBackup
	}


;==== end of NOTCH CLICKERS
;==========================



;==========================
;==== PRINT SCREEN INTERRUPT

	; Pressing Print Screen will stop current rendered project and make a screenshot instead
	; It will continue to render next projects then
	$PrintScreen::
		l("[HOTKEY]: $PrintScreen")

		WinGet, activeprocess, ProcessName, A
		WinGetTitle, windowtitle ,A

		if (activeprocess == "NotchApp.exe") and (windowtitle == "") {
			; If Notch render window is currently active
			PRINTSCREEN_INTERRUPT = 1
			SKIP_FFMPEG = 1

			; Check how many files is right now in screenshot directory
			init_screenshots_count := CountFilesInDir(A_MyDocuments . CFG.PrintScreenDirectory)

			; Click on Cancel
			MouseMove, % CFG.Coords.CancelRenderButton.X, % CFG.Coords.CancelRenderButton.Y, 0
			Sleep, % CFG.Slowness * 1
			MouseClick, Left
			WinWaitActive, % PROJECT.FileName

			; Send hotkey to make screenshot
			Send, {F8}

			; Wait until new file appears in screenshot directory
			while, 1
			{
				if CountFilesInDir(A_MyDocuments . CFG.PrintScreenDirectory) > init_screenshots_count
					break

				Sleep, % CFG.Slowness * 1
			}

			; Get newest file
			newest_file := GetNewestFileInDir(A_MyDocuments . CFG.PrintScreenDirectory)

			; Copy screenshot file to output render folder
			cur_screenshot_filepath := A_MyDocuments . CFG.PrintScreenDirectory . newest_file
			dest_render_folder := PROJECT.RenderFolderPath
			dest_screenshot_filename := StrSplit(PROJECT.RenderName, ".")[1] . ".png"
			dest_screenshot_filepath := dest_render_folder . "\" . dest_screenshot_filename

			FileCopy, %cur_screenshot_filepath%, %dest_screenshot_filepath%

			; Remove interrupted render file
			FileDelete, % PROJECT.RenderFilePath
			; Remove screenshot from screenshot directory
			FileDelete, % cur_screenshot_filepath

			PRINTSCREEN_INTERRUPT = 0
		} else {
			; If render window is not active - just pass PrintScreen thorugh
			Send, {PrintScreen}
		}
	Return



	CountFilesInDir(directory) {
		l("[FUNC]: CountFilesInDir(directory=" . directory . ")")

		FilesCount = 0

		Loop, %directory%*.*
			FilesCount := A_Index

		return FilesCount
	}



	GetNewestFileInDir(directory) {
		l("[FUNC]: GetNewestFileInDir(directory=" . directory . ")")

		Loop, %directory%\*
		{
			FileGetTime, Time, %A_LoopFileFullPath%, C

			if (Time > time_orig) {
				time_orig := Time
				newest_file := A_LoopFileName
			}
		}

		return newest_file
	}

;==== end of PRINT SCREEN INTERRUPT
;==================================



;=====================
;==== HELPER FUNCTIONS



	HasVal(haystack, needle) {
		l("[FUNC]: HasVal(haystack=" . o(haystack) . ", needle=" . needle . ")")

		if !(IsObject(haystack)) || (haystack.Length() = 0)
			return 0
		for index, value in haystack
			if (value = needle)
				return index
		return 0
	}
	
	
	
	; Converts frames to time format MM:SS:FF
	ConvertFPSCountToNotchTime(FPSCount, FPS) {
		l("[FUNC]: ConvertFPSCountToNotchTime(FPSCount=" . FPSCount . ", FPS=" . FPS . ")")

		Seconds := FPSCount / FPS

		sec := 1, min := 60 * sec, hr := 60 * min
		m := Seconds//min, Seconds := Mod(Seconds, min)
		s := floor(Seconds)
		f := (Seconds - s) * FPS

		m := TrimZeroes(m)
		s := TrimZeroes(s)
		f := TrimZeroes(f)

		while (StrLen(m) < 2) {
			m := "0" . m
		}
		
		while (StrLen(s) < 2) {
			s := "0" . s
		}
		
		while (StrLen(f) < 2) {
			f := "0" . f
		}
		
		return m . ":" . s . ":" . f
	}
	
	
	
	; Converts frames to time format HH:MM:SS
	ConvertFPSCountToFFMPEGTime(FPSCount, FPS) {
		l("[FUNC]: ConvertFPSCountToFFMPEGTime(FPSCount=" . FPSCount . ", FPS=" . FPS . ")")

		Seconds := FPSCount / FPS
		
		sec := 1, min := 60 * sec, hr := 60 * min
		h := Seconds//hr, Seconds := Mod(Seconds, hr)
		m := Seconds//min, Seconds := Mod(Seconds, min)
		s := Seconds
		
		h := TrimZeroes(h)
		m := TrimZeroes(m)
		s := TrimZeroes(s)
		
		while (StrLen(h) < 2) {
			h := "0" . h
		}
		
		while (StrLen(m) < 2) {
			m := "0" . m
		}
		
		while (StrLen(s) < 2) {
			s := "0" . s
		}
		
		return h . ":" . m . ":" . s
	}
	
	
	
	; Converts time format MM:SS:FF to frames
	ConvertNotchTimeToFPSCount(TimeInput, FPS) {
		l("[FUNC]: ConvertNotchTimeToFPSCount(TimeInput=" . TimeInput . ", FPS=" . FPS . ")")

		Splitted := StrSplit(TimeInput, ":")
		
		Frames := (Splitted[1] * 60 * 25) + (Splitted[2] * 25) + Splitted[3]
		
		return Frames
	}



	; Removes trailing zeroes from string
	TrimZeroes(Input) {
		l("[FUNC]: TrimZeroes(Input=" . Input . ")")

		Loop, % StrLen(Input) {
			StringRight, TMP, Input, 1
			
			if (InStr(Input, ".") && TMP = "0") {
				StringTrimRight, Input, Input, 1
			} else if (TMP = ".") {
				StringTrimRight, Input, Input, 1
			}
		}
		
		return Input
	}
	
	
	
	; https://stackoverflow.com/questions/44791916/assigning-command-output-into-a-variable
	RunWaitOne(command) {
		l("[FUNC]: RunWaitOne(command=" . command . ")")

		; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
		shell := ComObjCreate("WScript.Shell")
		; Execute a single command via cmd.exe
		cmd = %ComSpec% /C %command%
		Clipboard := cmd
		exec := shell.Exec(cmd)
		; Read and return the command's output
		return exec.StdOut.ReadAll()
	}
	
	

	; https://www.autohotkey.com/boards/viewtopic.php?t=39956
	RemoveDuplicates(object) {
		l("[FUNC]: RemoveDuplicates(object=" . o(object) . ")")

		secondobject:=[]
		Loop % object.Length()
		{
			value:=Object.RemoveAt(1) ; otherwise Object.Pop() a little faster, but would not keep the original order
			Loop % secondobject.Length()
				If (value=secondobject[A_Index])
					Continue 2 ; jump to the top of the outer loop, we found a duplicate, discard it and move on
			secondobject.Push(value)
		}
		Return secondobject
	}



	; Converts array to string form
	ArrayToString(Array, Denom) {
		l("[FUNC]: ArrayToString(object=" . o(Array) . ", Denom=" . Denom . ")")

		Str := ""
		For Index, Value In Array
		   Str .= Denom . Value
		Str := LTrim(Str, Denom) ; Remove leading denoms
		return Str
	}


	; Least Common Multiply
	LCM(InputArray) {
		l("[FUNC]: LCM(InputArray=" . o(InputArray) . ")")

		; Copy input array
		element_array := []
		for i, e in InputArray
			element_array.Push(e)

		lcm = 1
		divisor = 2 
		  
		while True
		{
			counter = 0
			divisible := False

			for i, e in element_array {
				if (element_array[i] == 0) {
					return 0
				} else if (element_array[i] < 0) {
					element_array[i] := element_array[i] * (-1)
				}

				if (element_array[i] == 1) {
					counter := counter + 1
				}

				if (mod(element_array[i], divisor) == 0) {
					divisible := True
					element_array[i] := element_array[i] / divisor
				}
			}
			
			if (divisible) {
				lcm := lcm * divisor
			} else { 
				divisor := divisor + 1
			}
			
			if (counter == element_array.Length()) { 
				return lcm
			} 
		} 
	}
	
	
	
	; Returns min value from array
	ArrayMin(ArrayIn) {
		l("[FUNC]: ArrayMin(ArrayIn=" . o(ArrayIn) . ")")

		min := ArrayIn[1]
		
		for k, v in ArrayIn
			if (v < min)
				min := v
		
		return min
	}
	
	
	
	; Returns max value from array
	ArrayMax(ArrayIn) {
		l("[FUNC]: ArrayMax(ArrayIn=" . o(ArrayIn) . ")")

		max := ArrayIn[1]
		
		for k, v in ArrayIn
			if (v > max)
				max := v
		
		return max
	}



	; Returns index of element's first occurence inside array. If no item found, returns -1
	IndexOf(obj, item, case_sensitive := false) {
		l("[FUNC]: IndexOf(obj=" . o(obj) . ", item=" . item . ", case_sensitive=" . case_sensitive . ")")

		for i, val in obj {
			if (case_sensitive ? (val == item) : (val = item))
				return i
		}
		
		return -1
	}



	; Checks if variable exists
	exist(ByRef v) {
		l("[FUNC]: exist(ByRef v=" . ByRef v . ")")

		return &v = &n ? 0 : v = "" ? 2 : 1 
	}



	; https://gist.github.com/errorseven/3b1e89e4d2f4d50b782f54954b2a97ca
	o(obj) { 
		Linear := isLinear(obj)
			
		For e, v in obj {
			if (Linear == False) {
				if (IsObject(v)) 
				   r .= e ":" o(v) ", "        
				else {                  
					r .= e ":"  
					if v is number 
						r .= v ", "
					else 
						r .= """" v """, " 
				}            
			} else {
				if (IsObject(v)) 
					r .= o(v) ", "
				else {          
					if v is number 
						r .= v ", "
					else 
						r .= """" v """, " 
				}
			}
		}
		return Linear ? "[" trim(r, ", ") "]" 
					 : "{" trim(r, ", ") "}"
	}
	isLinear(obj) {

		n := obj.count(), i := 1   
		loop % (n / 2) + 1
			if (!obj[i++] || !obj[n--])
				return 0
		return 1
	}


;==== end of HELPER FUNCTIONS
;============================



;=======================
;==== LOG FILE FUNCTIONS

	l(message) {
		global CFG

		if !CFG.Debug
			return

		FormatTime, timenow, %current%, yyyyMMddHHmmss
		FileAppend, <LOG_%timenow%> %message%`n`n, % A_MyDocuments . CFG.LogFilePath
	}

;==== end of LOG FILE FUNCTIONS
;==============================



;============
;==== ON EXIT

	ExitSub:
		l("[SUB]: ExitSub")
		global CFG

		; Remove temporary folder
		_temp_folder_ := A_MyDocuments . CFG.TemporaryFolder
		FileRemoveDir, %_temp_folder_%, 1
	ExitApp

;==== end of ON EXIT
;===================