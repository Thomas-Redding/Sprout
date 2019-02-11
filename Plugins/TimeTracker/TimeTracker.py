import time
import datetime

class TimeTracker:

    def __init__(self, spr, outputPath, pollInterval=3):
        if pollInterval < 1: pollInterval = 1
        self.outputPath = outputPath
        self.spr = spr
        self.spr.repeat(pollInterval, lambda:self.tick())

    def tick(self):
        identifier, app = self.spr.frontmostApp()
        timeStamp = str(int(time.time()))
        info = ''
        if identifier == 'com.google.Chrome':
            info = self.spr.runAppleScript('tell application "Google Chrome" to return URL of active tab of front window')[:-1]
        elif identifier == 'com.apple.Safari':
            info = self.spr.runAppleScript('tell application "Safari" to return URL of front document')[:-1]
        elif identifier == 'com.apple.TextEdit':
            info = self.spr.runAppleScript('tell application "TextEdit" to return path of front document')[:-1]
        elif identifier == 'com.apple.dt.Xcode':
            info = self.spr.runAppleScript('tell application "Xcode" to return path of front document')[:-1]
        elif identifier == 'com.apple.finder':
            info = self.spr.runAppleScript('tell application "Finder" to return target of Finder window 1')
            # folder "imports" of folder "data" of ... folder "Users" of startup disk of application "Finder"
            info = info.replace('" of folder "', '/')[8:-41]
            # imports/data/.../Users
            info = '/'.join(info.split('/')[::-1])
            # Users/.../data/imports
        path = self.outputPath + '/' + datetime.datetime.today().strftime('%Y-%m-%d') + '.txt'
        with open(path, "a+") as myfile:
            # 1549868894  com.google.Chrome   https://en.wikipedia.org
            myfile.write(timeStamp + '\t' + identifier + '\t' + info + '\n')
