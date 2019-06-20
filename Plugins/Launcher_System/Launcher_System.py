
class Launcher_System:
    def __init__(self, spr):
        self.sleepPriority = 0
        self.shutdownPriority = 0
        self.restartPriority = 0
        self.spr = spr

    def query(self, userInput, callback):
        if 'quit sprout'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:quitSprout', 1000, 'quit Sprout')])
        if 'restart sprout'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:restartSprout', 1000, 'restart Sprout')])
        if 'sleep'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:sleepScreen', self.sleepPriority, 'sleep')])
        if 'shutdown'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:shutdown', self.shutdownPriority, 'shutdown')])
        if 'restart'[0:len(userInput)] == userInput.lower():
            callback([('Launcher_System:restart', self.restartPriority, 'restart')])

    def action(self, key, cmd, opt, ctrl, shift):
        if key == 'Launcher_System:quitSprout':
            self.spr.quitSprout()
            return True
        elif key == 'Launcher_System:restartSprout':
            self.spr.restartSprout()
        elif key == 'Launcher_System:sleepScreen':
            self.spr.sleepScreen()
            return True
        elif key == 'Launcher_System:shutdown':
            self.spr.shutDown()
            return True
        elif key == 'Launcher_System:restart':
            self.spr.restart()
            return True
        return False
