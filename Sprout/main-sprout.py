import time

from SproutObjcInterface import ObjcInterface
spr = ObjcInterface()

class SproutApp:
  def __init__(self):
    spr = ObjcInterface()
    # Listen to "CMD + Space" hotkey.
    spr.listenForHotkey(49, True, False, False, False, lambda a, b, c, d, e : self.cmdSpacePressed())
    spr.makeWidgetWithId('sprout-trvQ1obpkMHqPfT3', '/Users/thomasredding/Desktop/sprout-temp', lambda widgetId : self.didLoad())
    spr.serveWidgetWithId('sprout-trvQ1obpkMHqPfT3', lambda widgetId, message : self.foo(widgetId, message))
    while True:
      time.sleep(1)
      spr.poll()
  def hotkeyPressed(self, keyCode, cmd, opt, ctrl, shift):
    spr.print('hotkeyPressed:' + str(keyCode))
    if (keyCode == 49 and cmd and not opt and not ctrl and not shift):
      # Show/hide window when CMD + Space is pressed.
      None
  def cmdSpacePressed(self):
    spr.print('cmdSpacePressed')
  def didLoad(self):
    spr.setWidgetProperty('sprout-trvQ1obpkMHqPfT3', 'x', '100')
  def foo(self, widgetId, message):
    spr.sendMessageToWidget(widgetId, message)

sproutApp = SproutApp()
