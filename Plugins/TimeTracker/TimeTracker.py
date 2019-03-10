import datetime
import time

class TimeTracker:
    def __init__(self, spr, outputPath, pollInterval=3):
        if pollInterval < 1: pollInterval = 1
        self.outputPath = outputPath
        self.spr = spr
        self.spr.repeat(pollInterval, lambda:self.tick())

    def tick(self):
        identifier, app = self.spr.frontmostApp()
        timeStamp = str(int(time.time()))
        info = None
        if identifier == 'com.google.Chrome':
            info = self.spr.runAppleScript('tell application "Google Chrome" to return URL of active tab of front window')
        elif identifier == 'com.apple.Safari':
            info = self.spr.runAppleScript('tell application "Safari" to return URL of front document')
        elif identifier == 'com.apple.TextEdit':
            info = self.spr.runAppleScript('tell application "TextEdit" to return path of front document')
        elif identifier == 'com.apple.dt.Xcode':
            info = self.spr.runAppleScript('tell application "Xcode" to return path of front document')
        elif identifier == 'com.apple.finder':
            info = self.spr.runAppleScript('tell application "Finder" to return target of Finder window 1')
            reversedPath = info.replace(' of folder ', '/')[7:-17].split('/')
            info = '/'.join(reversedPath[::-1])
            # Users/.../data/imports
        path = self.outputPath + '/' + datetime.datetime.today().strftime('%Y-%m-%d') + '.txt'
        with open(path, "a+") as myfile:
            # 1549868894  com.google.Chrome   https://en.wikipedia.org
            if info:
                info = info.replace('\n', '')
                myfile.write(timeStamp + '\t' + identifier + '\t' + info + '\n')
            else:
                myfile.write(timeStamp + '\t' + identifier + '\n')
