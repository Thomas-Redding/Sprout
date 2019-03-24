import json
from math import *
import requests # pip install requests;

class Launcher_File:
    def __init__(self, spr):
        self.spr = spr
        self.validExtensions = [
            'jpg', 'png', 'gif',
            'mp4',
            'txt', 'md', 'doc', 'docx',
            'py', 'h', 'c', 'cpp', 'm'
        ]
        self.path = '~'
        self.pathsToExclude = [ '~/Library', '~/Music' ]
        None

    def query(self, userInput, callback):
        for ext in self.validExtensions:
            if userInput[0:len(ext)+1] == ext + ' ':
                self.suggest(userInput, lambda response : self.handleCallback(response, callback))
                return None
        if userInput[0:2] == 'o ' or userInput[0:3] == 'fo ':
            self.suggest(userInput, lambda response : self.handleCallback(response, callback))

    def handleCallback(self, responses, callback):
        rtn = []
        for i in range(len(responses)):
            response = responses[i]
            if response == '': continue
            x = '&nbsp;/&nbsp;'.join(response.split('/')[::-1])
            rtn.append([response, 100-i, x])
        callback(rtn)

    def action(self, key):
        self.spr.print('qq:' + key)

    def suggest(self, query, callback):
        spaceIndex = query.index(' ')
        ext = query[0:spaceIndex]
        regexStr = query[spaceIndex+1:]
        if regexStr == '': callback([])
        if ext == 'o':
            self.spr.searchFiles(query[len(ext)+1:], 1000, True, False, True, True, True, [], self.path, self.pathsToExclude, callback)
        elif ext == 'fo':
            self.spr.searchFiles(query[len(ext)+1:], 1000, True, False, True, False, True, [], self.path, self.pathsToExclude, callback)
        else:
            self.spr.searchFiles(query[len(ext)+1:], 1000, True, False, False, True, True, [ext], self.path, self.pathsToExclude, callback)

    def unescape(self, s):
        state = 0
        rtn = ''
        for c in s:
            if state == 0:
                if c == '\\': state = 1
                else: rtn += c
            else:
                if c == '\\': rtn += '\\'
                elif c == '"': rtn += '"'
                elif c == "'": rtn += "'"
                elif c == 'n': rtn += 'n'
                elif c == 't': rtn += 't'
                else:
                    print('ERROR in unescapeNewlines', s)
                    sys.exit(1)
                state = 0
        return rtn