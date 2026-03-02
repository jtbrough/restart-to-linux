use scripting additions

set launcherPath to (POSIX path of ((path to current application) as text)) & "Contents/MacOS/restart-to-linux-launcher"
set shellCommand to quoted form of launcherPath
«event sysoexec» shellCommand with «class badm»
