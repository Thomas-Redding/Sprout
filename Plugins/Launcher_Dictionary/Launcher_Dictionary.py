import os


class Launcher_Dictionary:

    def __init__(self, spr):
        self.spr = spr

    def query(self, userInput, callback):
        if userInput[0:2] != 'd ': return None
        word = userInput[2:]
        foo = self.spr.define(word)
        if foo: callback([('Launcher_Dictionary:' + word, 400, 'define ' + word)])

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:20] == 'Launcher_Dictionary:':
            os.system('open dict://' + key[20:])
            os.system('open /Applications/Dictionary.app')
            return True
        return False
