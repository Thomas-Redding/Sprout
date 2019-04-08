import time

class WindowSnapper:

    def __init__(self, spr):
        self.spr = spr
        self.padding = 20
        self.extraCornerPading = 20
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
        if self.extraCornerPading < 0: self.extraCornerPading = 0
        for frame in frames:
            relX = x - frame[0]
            relY = y - frame[1]
            if 0 <= relX <= self.padding: horizontal = 'left'
            elif frame[2] - self.padding <= relX <= frame[2]: horizontal = 'right'
            else: horizontal = 'center'
            if 0 <= relY <= self.padding: vertical = 'bottom'
            elif frame[3] - self.padding <= relY <= frame[3]: vertical = 'top'
            else: vertical = 'center'
            if horizontal != 'center' or vertical != 'center':
                if 0 <= relX <= self.padding + self.extraCornerPading: horizontal = 'left'
                elif frame[2] - self.padding - self.extraCornerPading <= relX <= frame[2]: horizontal = 'right'
                else: horizontal = 'center'
                if 0 <= relY <= self.padding + self.extraCornerPading: vertical = 'bottom'
                elif frame[3] - self.padding - self.extraCornerPading <= relY <= frame[3]: vertical = 'top'
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

    def resizeMainWindow(self, newX, newY, newWidth, newHeight):
        screenOfFocusedWindow = None
        screens = self.spr.screenFrames()
        if newX == -1 or newY == -1 or newWidth == -1 or newHeight == -1 or len(screens) > 1:
            frame = self.spr.getFrontmostWindowFrame()
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
        self.spr.setFrontmostWindowFrame(newFrame)
