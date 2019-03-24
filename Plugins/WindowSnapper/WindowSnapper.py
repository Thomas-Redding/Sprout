import time

class WindowSnapper:

    def __init__(self, spr):
        self.spr = spr
        self.padding = 20
        self.timePadding = 1
        self._mainScreenHeight = 0
        screens = self.spr.screenFrames()
        for screen in screens:
            if screen[0] != 0: continue
            if screen[1] != 0: continue
            self._mainScreenHeight = screen[3]

        self.lastWindowMoved = None
        self.lastWindowMovedTime = 0
        self.spr.listenForWindowMove(lambda liteWindow : self.windowMoved(liteWindow))
        self.spr.listenForMouseButtons(lambda button, goingDown : self.mouseButtonChanged(button, goingDown))

    # Typically takes between 0.1 and 0.4 seconds.
    def connectHotKeyToFrame(self, keyCode, cmd, opt, ctrl, shift, x, y, w, h):
        self.spr.listenForHotkey(keyCode, cmd, opt, ctrl, shift, lambda a, b, c, d, e : self.resizeMainWindow(x, y, w, h))

    def windowMoved(self, liteWindow):
        self.lastWindowMoved = liteWindow
        self.lastWindowMovedTime = time.time()

    def mouseButtonChanged(self, button, goingDown):
        if button != 1: return None
        if goingDown: return None
        if time.time() - self.lastWindowMovedTime > self.timePadding: return None
        x, y = self.spr.mousePosition()
        frames = self.spr.screenFrames()
        for frame in frames:
            relX = x - frame[0]
            relY = y - frame[1]
            if 0 <= relX <= self.padding: horizontal = 'left'
            elif frame[2] - self.padding <= relX <= frame[2]: horizontal = 'right'
            else: horizontal = 'center'
            if 0 <= relY <= self.padding: vertical = 'bottom'
            elif frame[3] - self.padding <= relY <= frame[3]: vertical = 'top'
            else: vertical = 'center'
            if horizontal == 'left':
                if vertical == 'top':      self.resizeDraggedWindow(frame[0],             frame[1],            frame[2]/2, frame[3]/2) # Top-Left
                elif vertical == 'bottom': self.resizeDraggedWindow(frame[0],             frame[1]+frame[3]/2, frame[2]/2, frame[3]/2) # Bottom-Left
                else:                      self.resizeDraggedWindow(frame[0],             frame[1],            frame[2]/2, frame[3])   # Left
            elif horizontal == 'right':
                if vertical == 'top':      self.resizeDraggedWindow(frame[0]+frame[2]/2,  frame[1],            frame[2]/2, frame[3]/2) # Top-Right
                elif vertical == 'bottom': self.resizeDraggedWindow(frame[0]+frame[2]/2,  frame[1]+frame[3]/2, frame[2]/2, frame[3]/2) # Bototm-Right
                else:                      self.resizeDraggedWindow(frame[0]+frame[2]/2,  frame[1],            frame[2]/2, frame[3])   # Right
            else:
                if vertical == 'top':      self.resizeDraggedWindow(frame[0],             frame[1],            frame[2],   frame[3])   # Top
                elif vertical == 'bottom': self.resizeDraggedWindow(frame[0],             frame[1],            frame[2],   frame[3])   # Bottom

    def resizeDraggedWindow(self, newX, newY, newWidth, newHeight):
        self.spr.moveWindow(self.lastWindowMoved, newX, newY, newWidth, newHeight)

    def _frameOfFocusedWindow(self):
        # 150ms script
        appleScript1 = """
set AppleScript's text item delimiters to ":"
set appname to text item -2 of (path to frontmost application as text)
set AppleScript's text item delimiters to ""
set frontApp to text items 1 thru -5 of appname as Unicode text
tell application frontApp
    get bounds of first window
end tell"""
        # 300ms script
        appleScript2 = """
tell application "System Events"
    tell (first item of (processes whose frontmost is true))
        {get position of window 1, get size of window 1}
    end tell
end tell"""
        result = None
        if self.spr.frontmostApp()[0] != 'com.sublimetext.3':
            result = self.spr.runAppleScript(appleScript1)
        if not result:
            result = self.spr.runAppleScript(appleScript2)
        if not result: return None
        frameStrings = result.split(',')
        result = [float(frameStrings[0]), float(frameStrings[1]), float(frameStrings[2]), float(frameStrings[3])]
        # Transform into normal Apple coordinates
        result[1] = self._mainScreenHeight - result[1]
        return result

    def resizeMainWindow(self, newX, newY, newWidth, newHeight):
        screens = self.spr.screenFrames()
        if newX == -1 or newY == -1 or newWidth == -1 or newHeight == -1 or len(screens) > 1:
            frame = self._frameOfFocusedWindow()
            for screen in screens:
                if not (screen[0] <= frame[0] <= screen[0] + screen[2]): continue
                if not (screen[1] <= frame[1] <= screen[1] + screen[3]): continue
                screenOfFocusedWindow = screen
                break
            if not screenOfFocusedWindow: return None
            newFrame = frame
        elif len(screens) == 1:
            screenOfFocusedWindow = screens[0]
            newFrame = [0, 0, 0, 0]
        else:
            return None
        if newX != -1:      newFrame[0] = newX * screenOfFocusedWindow[2]     + screenOfFocusedWindow[0]
        if newY != -1:      newFrame[1] = newY * screenOfFocusedWindow[3]     + screenOfFocusedWindow[1]
        if newWidth != -1:  newFrame[2] = newWidth * screenOfFocusedWindow[2]
        if newHeight != -1: newFrame[3] = newHeight * screenOfFocusedWindow[3]
        appleScriptParams = """
set x to $x
set y to $y
set w to $w
set h to $h"""
        appleScriptParams = appleScriptParams.replace('$x', str(newFrame[0]))
        appleScriptParams = appleScriptParams.replace('$y', str(newFrame[1]))
        appleScriptParams = appleScriptParams.replace('$w', str(newFrame[2]))
        appleScriptParams = appleScriptParams.replace('$h', str(newFrame[3]))
        # 150ms
        unused_appleScript1 = """
set AppleScript's text item delimiters to ":"
set appname to text item -2 of (path to frontmost application as text)
set AppleScript's text item delimiters to ""
set frontApp to text items 1 thru -5 of appname as Unicode text
tell application frontApp
    set bounds of first window to {x, y, w, h}
end tell"""
        # 100ms
        appleScript2 = """
tell application "System Events"
    set myFrontMost to name of first item of (processes whose frontmost is true)
    tell process myFrontMost
        set size of window 1 to {w, h}
        set position of window 1 to {x, y}
    end tell
end tell"""
        # Sometimes the window moves but doesn't resize, so we run the script twice.
        self.spr.runAppleScript(appleScriptParams + appleScript2)
        self.spr.runAppleScript(appleScriptParams + appleScript2)
