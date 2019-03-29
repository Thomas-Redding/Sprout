import datetime
import os
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
        elif identifier == 'com.apple.systempreferences':
            info = self.spr.runAppleScript('tell application "System Preferences" to get id of current pane')
        elif False and identifier == 'com.apple.Terminal':
            # https://stackoverflow.com/a/16073987
            tty = self.spr.runAppleScript('tell application "Terminal" to tty of front tab of front window')[:-1]
            cmd = """
tell application "Terminal"
    do shell script "lsof -a -p `lsof -a -c bash -u $USER -d 0 -n | tail -n +2 | awk '{if($NF==\"<tty>\"){print $2}}'` -d cwd -n | tail -n +2 | awk '{print $NF}'"
end tell
"""
            cmd = cmd.replace('<tty>', tty)
            info = self.spr.runAppleScript(cmd)
            info = info[info.find('/'):]
            # bash    31900 thomasredding  cwd    DIR    1,4      288 3506773 /Users/thomasredding/Projects/Sprout
        elif identifier == 'com.apple.finder':
            try:
                info = self.spr.runAppleScript('tell application "Finder" to return target of Finder window 1')
                reversedPath = info.replace(' of folder ', '/')[7:-17].split('/')
                info = '/'.join(reversedPath[::-1])
            except:
                # Desktop
                info = os.path.join(os.path.join(os.path.expanduser('~')), 'Desktop') 
        path = self.outputPath + '/' + datetime.datetime.today().strftime('%Y-%m-%d') + '.txt'
        with open(path, "a+") as myfile:
            # 1549868894  com.google.Chrome   https://en.wikipedia.org
            if info:
                info = info.replace('\n', '')
                myfile.write(timeStamp + '\t' + identifier + '\t' + info + '\n')
            else:
                myfile.write(timeStamp + '\t' + identifier + '\n')
