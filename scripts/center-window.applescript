-- center-window.applescript
-- Centers the frontmost window on the main display
try
	tell application "System Events"
		set frontApp to first application process whose frontmost is true
		tell frontApp
			if (count of windows) = 0 then return
			set win to window 1
			set {wx, wy} to position of win
			set {ww, wh} to size of win
		end tell
	end tell

	tell application "Finder"
		set desktopBounds to bounds of window of desktop
	end tell
	set {sx, sy, sw, sh} to desktopBounds

	set newx to sx + (((sw - sx) - ww) / 2)
	set newy to sy + (((sh - sy) - wh) / 2)

	tell application "System Events"
		tell (first application process whose frontmost is true)
			set position of window 1 to {newx, newy}
		end tell
	end tell
on error errMsg
	-- Write error to a temporary log for troubleshooting
	do shell script "echo 'AppleScript error: '" & quoted form of errMsg & " >> /tmp/center-window.applescript.log"
end try
