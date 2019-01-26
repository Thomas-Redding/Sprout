import time

WAIT_TIME = 0.5

wind = spr.makeWindow()
wind.setVisible(False)
wind.setFrame([100, 100, 500, 500])
wind.setTitle(None)

# Make the window hide and show with CMD + Space.
spr.listenForHotkey(49, True, False, False, False, lambda a, b, c, d, e : toggleWindowHide())
def toggleWindowHide():
  isVisible = wind.visible()
  if isVisible: wind.returnOwnership()
  else: wind.borrowOwnership()

def server(requestStr):
  if 'quit' in requestStr: spr.quit()
  else: wind.sendMessage(requestStr + 'X')
wind.onMessage = server
wind.onLoad = lambda : spr.print('I Loaded!')
wind.setIndexPath('~/Projects/Sprout/Sprout/index.html')

spr.print(str(spr.runningApps()))
