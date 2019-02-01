from math import *

class Calculator:
  def __init__(self, spr):
    self.spr = spr
    self.supportedMethods = {'acos': acos, 'asin': asin, 'atan': atan, 'atan2': atan2, 'ceil': ceil,
    'cos': cos, 'cosh': cosh, 'degrees': degrees, 'e': e, 'exp': exp, 'fabs': fabs, 'floor': floor,
    'fmod': fmod, 'frexp': frexp, 'hypot': hypot, 'ldexp': ldexp, 'log': log, 'log10': log10,
    'modf': modf, 'pi': pi, 'pow': pow, 'radians': radians, 'sin': sin, 'sinh': sinh, 'sqrt': sqrt,
    'tan': tan, 'tanh': tanh }
    self._window = self.spr.makeWindow()
    self._window.setVisible(False)
    self._window.setFrame([100, 100, 500, 500])
    self._window.setTitle(None)
    self._window.onMessage = lambda requestStr : self.server(requestStr)
    self._window.setIndexPath('~/Projects/Sprout/Plugins/Calculator/index.html')
    self.spr.listenForHotkey(49, False, True, False, False, lambda a, b, c, d, e : self.toggleWindowHide())

  def toggleWindowHide(self):
    isVisible = self._window.visible()
    if isVisible: self._window.returnOwnership()
    else: self._window.borrowOwnership()

  def server(self, requestStr):
    if requestStr == 'quit':
      self.spr.quit()
      return
    requestStr = requestStr.replace('^', '**')
    try: self._window.sendMessage(str(eval(requestStr, {"__builtins__":None}, supportedMethods)))
    except: self._window.sendMessage("")
