import time
from tkinter import Tk, Label, Button, Menu

from SproutObjcInterface import ObjcInterface

class MainWindow:
  def __init__(self, master):
    self.master = master
    master.title("A simple GUI")
    self.label = Label(master, text="This is our first GUI!")
    self.label.pack()
    self.greet_button = Button(master, text="Greet", command=self.greet)
    self.greet_button.pack()
    self.close_button = Button(master, text="Close", command=master.quit)
    self.close_button.pack()

  def greet(self):
    print("Greetings!")

def do_about_dialog():
  tk_version = window.tk.call('info', 'patchlevel')
  showinfo(message= app_name + "\nThe answer to all your problems.\n\nTK version: " + tk_version)

def do_preferences():
  showinfo(message="Preferences window")

FOO = """
on run {x, y}
  return x + y
end run
"""

class SproutApp:
  def __init__(self):
    self.spr = ObjcInterface(self)
    # Listen to "CMD + Space" hotkey.
    self.spr.listenForHotkey(49, True, False, False, False)
    self.root = Tk()
    
    # Remove all menubar items except the "Sprout" one.
    emptyMenu = Menu(self.root)
    self.root.config(menu=emptyMenu)
    
    # Start app.
    self.mainWindow = MainWindow(self.root)
    self.root.after(100, self.repeat)
    self.root.mainloop()

  def repeat(self):
    self.spr.poll()
    self.root.after(200, self.repeat)
    self.spr.print(self.spr.activeApplication())
    self.spr.runAppleScript(FOO, ['2', '2'])
  
  def hotkeyPressed(self, keyCode, cmd, opt, ctrl, shift):
    if (keyCode == 49 and cmd and not opt and not ctrl and not shift):
      # Show/hide window when CMD + Space is pressed.
      if self.root.state() == "withdrawn":
        self.root.deiconify()
      else:
        self.root.withdraw()
    self.spr.print('key pressed:' + str(keyCode))

sproutApp = SproutApp()
