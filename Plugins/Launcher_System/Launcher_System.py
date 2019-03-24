
class Launcher_System:
    def __init__(self, spr):
        self.spr = spr

    def query(self, userInput, callback):
        if 'quit sprout'[0:len(userInput)] == userInput.lower():
            callback([('foo', 1000, 'Quit Sprout')])

    def action(self, key):
        self.spr.print('c2:' + key)
