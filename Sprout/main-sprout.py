from math import *
import time

wind = spr.makeWindow()
wind.setVisible(False)
wind.setFrame([100, 100, 500, 500])
wind.setTitle(None)

# Make the window hide and show with CMD + Space.
spr.listenForHotkey(49, False, True, False, False, lambda a, b, c, d, e : toggleWindowHide())
def toggleWindowHide():
  isVisible = wind.visible()
  if isVisible: wind.returnOwnership()
  else: wind.borrowOwnership()

supportedMethods = {'acos': acos, 'asin': asin, 'atan': atan, 'atan2': atan2, 'ceil': ceil,
    'cos': cos, 'cosh': cosh, 'degrees': degrees, 'e': e, 'exp': exp, 'fabs': fabs, 'floor': floor,
    'fmod': fmod, 'frexp': frexp, 'hypot': hypot, 'ldexp': ldexp, 'log': log, 'log10': log10,
    'modf': modf, 'pi': pi, 'pow': pow, 'radians': radians, 'sin': sin, 'sinh': sinh, 'sqrt': sqrt,
    'tan': tan, 'tanh': tanh }
def server(requestStr):
  if requestStr == 'quit':
    spr.quit()
    return
  try: wind.sendMessage(str(eval(requestStr, {"__builtins__":None}, supportedMethods)))
  except: wind.sendMessage("")
wind.onMessage = server
wind.onLoad = lambda: spr.print('I Loaded!')
wind.setIndexPath('~/Projects/Sprout/Sprout/index.html')

spr.print(str(spr.runningApps()))

spr.doLater(3, lambda: spr.stopRepeat(timerId, lambda: spr.print('DONE')))
timerId = spr.repeat(1, lambda: spr.print('REPEAT'))
