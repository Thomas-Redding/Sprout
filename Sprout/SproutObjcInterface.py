import select
import sys

class ObjcInterface:
  def __init__(self, delegate):
    self.delegate = delegate
  
  # Call `self.delegate.hotkeyPressed` when this hotkey is pressed.
  def listenForHotkey(self, keyCode, cmd, opt, ctrl, shift):
    x = str(keyCode)
    x += ' '
    x += '1' if cmd else '0'
    x += '1' if opt else '0'
    x += '1' if ctrl else '0'
    x += '1' if shift else '0'
    sys.stdout.write('registerHotkey '+ x)
    sys.stdout.flush()
  
  # Call this method frequently (on the order of 30 times per second).
  # It checks whether events (e.g. hotkeys) have occured.
  def poll(self):
    # Loop while the standard input pipe has data.
    # This while-loop condition may not work on Windows.
    # See https://stackoverflow.com/a/3732001.
    while select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], []):
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
        self.delegate.hotkeyPressed(keyCode, cmd, opt, ctrl, shift)
      else:
        self.print(line)

  # Print to Xcode console.
  def print(self, s):
    sys.stdout.write('print ' + str(s))
    sys.stdout.flush()
