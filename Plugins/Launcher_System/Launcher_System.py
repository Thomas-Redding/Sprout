
class Launcher_System:
    def __init__(self, spr):
        self.spr = spr

    def query(self, userInput, callback):
        if 'quit sprout'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:quitSprout', 1000, 'quit Sprout')])
        if 'restart sprout'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:restartSprout', 1000, 'restart Sprout')])

    def action(self, key, cmd, opt, ctrl, shift):
        if key == 'Launcher_System:quitSprout':
            self.spr.quitSprout()
            return True
        elif key == 'Launcher_System:restartSprout':
            self.spr.restartSprout()
            return True
        return False
