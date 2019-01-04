import sys

class ObjcInterface:
  def __init__(self, delegate):
    self.delegate = delegate
  
  def listenForHotkey(self, keyCode, cmd, opt, ctrl, shift):
    x = str(keyCode)
    x += ' '
    x += '1' if cmd else '0'
    x += '1' if opt else '0'
    x += '1' if ctrl else '0'
    x += '1' if shift else '0'
    sys.stdout.write('registerHotkey '+ x)
    sys.stdout.flush()
  
  def hotkeyPressed(self, keyCode, cmd, opt, ctrl, shift):
    self.delegate.hotkeyPressed(keyCode, cmd, opt, ctrl, shift)
  
  def eventLoop(self):
    # TODO: Figure out how to stop blocking here.
    line = sys.stdin.readline()
    line = line[:-1]
    if line[0:13] == 'hotKeyPressed':
      args = line[14:]
      spaceIndex = args.index(' ')
      keyCode = int(args[0:spaceIndex])
      modifierFlags = args[spaceIndex+1]
      cmd = (modifierFlags[0] == '1')
      opt = (modifierFlags[0] == '1')
      ctrl = (modifierFlags[0] == '1')
      shift = (modifierFlags[0] == '1')
      self.hotkeyPressed(keyCode, cmd, opt, ctrl, shift)
    else:
      self.print(line)
    return True
  
  def print(self, s):
    sys.stdout.write('print ' + s)
    sys.stdout.flush()


class SproutApp:
  def __init__(self):
    self.objcInterface = ObjcInterface(self)
    self.objcInterface.listenForHotkey(49, True, False, False, False)
    while True:
      if not self.objcInterface.eventLoop():
        break
  def hotkeyPressed(self, keyCode, cmd, opt, ctrl, shift):
    self.objcInterface.print('key pressed:' + str(keyCode))


sproutApp = SproutApp()
