# DESCRIPTION
A pack of workflow automation I wrote in AHK to help my coworkers and me in getting the job done. It was written to be used with Notch software (www.notch.one). My main goal in sharing it here is to describe various helpful code snippets I used and describe them on my blog (www.thomaswinged.me/entry/notch-workflow-automation-ahk-pack) as I had many adventures with this piece of code.

# CONFIG
First, check the configuration file under "include/config.cfg".
Inside you can f.e. modify resolutions of surfaces, add new ones, modify RenderBuddy output location, and so on.

To make the script adaptable to any setup, I created a configuration structure called "Coords" and "WindowNames" inside config.cfg.

First, I want to explain "Coords": your screen setup is almost for sure different than mine, f.e. you can have different resolutions, and buttons and fields can be in different positions. I attached a folder, "Required Window Names", with many screenshots in which I am showing which points on the screen correspond to which "Coord" value. Before launching scripts, please open every screenshot from that folder and, using the "Window Spy" AHK tool, check if the locations of these points match. If there are differences, please update the config.cfg file accordingly.

There is also a struct called "WindowNames" in cfg - in various Windows languages, Notch calls windows differently. Please open every window that is shown in the "Required Window Names" folder and check if it matches your naming. If there are differences, please update the config.cfg file accordingly.

Another necessary entry in the config.cfg file is "Slowness" - if automations are working too fast and they loose focus on windows - make the value larger, f.e. 200. If your PCs are much faster and scripts are too slow, make the value smaller, f.e. 50.

If you want to preserve a version in a render output video file (e.g., v1, v2, v3) - set OmitExportNameVersioning to 1.

Locations such as "PrintScreenDirectory": "\\Notch\\Notch Screenshots\\" are stored inside your Documents folder.

If there are any problems with scripts, please set the "Debug" value to 1, and check the log file that is being saved under "LogFilePath".

# REQUIREMENTS
Ensure that you have MediaInfo and FFmpeg downloaded and added to Environment Path.
In case you don't have it, here are the download links:
- MediaInfo: https://mediaarea.net/pl/MediaInfo/Download/Windows) then search for 62-bit CLI
- FFmpeg: https://ffmpeg.org/download.html#build-windows)

# EXTRAS
I also attached a template project and Notch render preset to make a complete toolset package in one place.
