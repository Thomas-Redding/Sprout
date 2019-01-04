import sys

class SproutApp:
  def __init__(self):
    self.listenForHotkey(49, True, False, False, False)
  
  def listenForHotkey(self, keyCode, cmd, opt, ctrl, shift):
    x = str(keyCode)
    x += ' '
    x += '1' if cmd else '0'
    x += '1' if opt else '0'
    x += '1' if ctrl else '0'
    x += '1' if shift else '0'
    self._print('registerHotkey '+ x)
  
  def hotkeyPressed(self, keyCode, cmd, opt, ctrl, shift):
    # TODO
    self._print(str(keyCode))
    None
  
  def eventLoop(self):
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
      self._print('echo ' + line)
    return True
  
  def _print(self, s):
    sys.stdout.write(s)
    sys.stdout.flush()

sproutApp = SproutApp()
while True:
  if not sproutApp.eventLoop(): break
