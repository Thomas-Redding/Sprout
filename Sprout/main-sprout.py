import time
from tkinter import Tk, Label, Button

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

class SproutApp:
  def __init__(self):
    self.objcInterface = ObjcInterface(self)
    # Listen to "CMD + Space" hotkey.
    self.objcInterface.listenForHotkey(49, True, False, False, False)
    self.root = Tk()
    self.mainWindow = MainWindow(self.root)
    self.root.after(100, self.task)
    self.root.mainloop()

  def task(self):
    self.objcInterface.poll()
    self.root.after(100, self.task)
  
  def hotkeyPressed(self, keyCode, cmd, opt, ctrl, shift):
    self.objcInterface.print('key pressed:' + str(keyCode))

sproutApp = SproutApp()
