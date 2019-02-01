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
            if vertical == 'top':      self.resizeWindow(0.0, 0.0, 0.5, 0.5) # Top-Left
            elif vertical == 'bottom': self.resizeWindow(0.0, 0.5, 0.5, 0.5) # Bottom-Left
            else:                      self.resizeWindow(0.0, 0.0, 0.5, 1.0) # Left
        elif horizontal == 'right':
            if vertical == 'top':      self.resizeWindow(0.5, 0.0, 0.5, 0.5) # Top-Right
            elif vertical == 'bottom': self.resizeWindow(0.5, 0.5, 0.5, 0.5) # Bototm-Right
            else:                      self.resizeWindow(0.5, 0.0, 0.5, 1.0) # Right
        else:
            if vertical == 'top':      self.resizeWindow(0.0, 0.0, 1.0, 1.0) # Top
            elif vertical == 'bottom': self.resizeWindow(0.0, 0.0, 1.0, 1.0) # Bottom

    def resizeWindow(self, newX, newY, newWidth, newHeight):
        newX *= self.screenSize[0]
        newWidth *= self.screenSize[0]
        newY *= self.screenSize[1]
        newHeight *= self.screenSize[1]
        self.spr.moveWindow(self.lastWindowMoved, newX, newY, newWidth, newHeight)
