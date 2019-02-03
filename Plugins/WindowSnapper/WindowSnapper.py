import time

class WindowSnapper:

    def __init__(self, spr):
        self.spr = spr
        self.screenSize = self.spr.screenSize()
        self.padding = 0.1 * min(self.screenSize)
        self.timePadding = 1
        self.lastWindowMoved = None
        self.lastWindowMovedTime = 0
        self.spr.listenForWindowMove(lambda windowNumber, windowName, bundleIdentifier, appName : self.windowMoved(windowNumber))
        self.spr.listenForMouseButtons(lambda button, goingDown : self.mouseButtonChanged(button, goingDown))

    def connectHotKeyToFrame(self, keyCode, cmd, opt, ctrl, shift, x, y, w, h):
        self.spr.listenForHotkey(keyCode, cmd, opt, ctrl, shift, lambda a, b, c, d, e : self.resizeMainWindow(x, y, w, h))

    def windowMoved(self, windowNumber):
        self.lastWindowMoved = windowNumber
        self.lastWindowMovedTime = time.time()

    def mouseButtonChanged(self, button, goingDown):
        if button != 1: return None
        if goingDown: return None
        if time.time() - self.lastWindowMovedTime > self.timePadding: return None
        x, y = self.spr.mousePosition()
        if (x < self.padding): horizontal = 'left'
        elif (x > self.screenSize[0] - self.padding): horizontal = 'right'
        else: horizontal = 'center'
        if (y < self.padding): vertical = 'bottom'
        elif (y > self.screenSize[1] - self.padding): vertical = 'top'
        else: vertical = 'center'
        if horizontal == 'left':
            if vertical == 'top':      self.resizeDraggedWindow(0.0, 0.0, 0.5, 0.5) # Top-Left
            elif vertical == 'bottom': self.resizeDraggedWindow(0.0, 0.5, 0.5, 0.5) # Bottom-Left
            else:                      self.resizeDraggedWindow(0.0, 0.0, 0.5, 1.0) # Left
        elif horizontal == 'right':
            if vertical == 'top':      self.resizeDraggedWindow(0.5, 0.0, 0.5, 0.5) # Top-Right
            elif vertical == 'bottom': self.resizeDraggedWindow(0.5, 0.5, 0.5, 0.5) # Bototm-Right
            else:                      self.resizeDraggedWindow(0.5, 0.0, 0.5, 1.0) # Right
        else:
            if vertical == 'top':      self.resizeDraggedWindow(0.0, 0.0, 1.0, 1.0) # Top
            elif vertical == 'bottom': self.resizeDraggedWindow(0.0, 0.0, 1.0, 1.0) # Bottom

    def resizeDraggedWindow(self, newX, newY, newWidth, newHeight):
        newX *= self.screenSize[0]
        newWidth *= self.screenSize[0]
        newY *= self.screenSize[1]
        newHeight *= self.screenSize[1]
        self.spr.moveWindow(self.lastWindowMoved, newX, newY, newWidth, newHeight)

    def resizeMainWindow(self, newX, newY, newWidth, newHeight):
        appleScript = """
set x to $x
set y to $y
set w to $w
set h to $h
tell application "Finder"
    set {screen_left, screen_top, screen_width, screen_height} to bounds of window of desktop
end tell
tell application "System Events"
    set myFrontMost to name of first item of (processes whose frontmost is true)
    tell process myFrontMost
        set {old_w, old_h} to get size of window 1
        set {old_x, old_y} to get position of window 1
        if x is equal to -1 then
            set x to old_x / screen_width
        end if
        if y is equal to -1 then
            set y to old_y / screen_height
        end if
        if w is equal to -1 then
            set w to old_w / screen_width
        end if
        if h is equal to -1 then
            set h to old_h / screen_height
        end if
        set size of window 1 to {(screen_width * w), (screen_height * h)}
        set position of window 1 to {(screen_width * x), (screen_height * y)}
    end tell
end tell
"""
        appleScript = appleScript.replace('$x', str(newX))
        appleScript = appleScript.replace('$y', str(newY))
        appleScript = appleScript.replace('$w', str(newWidth))
        appleScript = appleScript.replace('$h', str(newHeight))
        self.spr.runAppleScript(appleScript)
