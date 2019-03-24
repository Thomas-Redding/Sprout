
class Launcher_System:
    def __init__(self, spr):
        self.spr = spr

    def query(self, userInput, callback):
        if 'quit sprout'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:quitSprout', 1000, 'Quit Sprout')])

    def action(self, key):
        if key == 'Launcher_System:quitSprout':
            self.spr.quitSprout()
            return True
        return False
