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
        path = self.outputPath + '/' + datetime.datetime.today().strftime('%Y-%m-%d') + '.txt'
        with open(path, "a+") as myfile:
            myfile.write(str(identifier) + '\t' + str(1000*time.time()) + '\n')
