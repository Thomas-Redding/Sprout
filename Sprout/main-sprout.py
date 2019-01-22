import time

from SproutObjcInterface import ObjcInterface
spr = ObjcInterface()

class SproutApp:
  def __init__(self):
    # Listen to "CMD + Space" hotkey.
    spr.listenForHotkey(49, True, False, False, False, lambda a, b, c, d, e : self.cmdSpacePressed())
    spr.makeWidgetWithId('sprout-trvQ1obpkMHqPfT3', '/Users/thomasredding/Desktop/sprout-temp', lambda widgetId : self.didLoad())
    spr.serveWidgetWithId('sprout-trvQ1obpkMHqPfT3', lambda widgetId, message : self.foo(widgetId, message))
    while True:
      time.sleep(0.02)
      spr.poll()
  def showHideWithCurrentVisibility(self, isVisible):
    if isVisible == '':
      spr.setWidgetProperty('sprout-trvQ1obpkMHqPfT3', 'visible', '1')
    else:
      spr.setWidgetProperty('sprout-trvQ1obpkMHqPfT3', 'visible', '')
  def cmdSpacePressed(self):
    spr.getWidgetProperty('sprout-trvQ1obpkMHqPfT3', 'visible', lambda widgetId, key, value : self.showHideWithCurrentVisibility(value))
  def didLoad(self):
    None
  def foo(self, widgetId, message):
    spr.sendMessageToWidget(widgetId, message)


sproutApp = SproutApp()
