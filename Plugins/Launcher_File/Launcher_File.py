import json
import os

class Launcher_File:
    def __init__(self, spr):
        self.spr = spr
        self.validExtensions = [
            'bmp', 'gif', 'ico', 'jpeg', 'jpg', 'pdf', 'png', 'svg', 'tif',
            'avi', 'flv', 'mp4', 'webm',
            'mp3', 'wav',
            'doc', 'docx', 'md', 'rtf', 'tex', 'txt',
            'xlsx',
            'c', 'css', 'cpp', 'h', 'htm', 'html', 'js', 'm', 'php', 'py', 'sh',
            'csv', 'diff', 'dmg', 'gz', 'iso', 'json', 'log', 'rss', 'sql', 'tgz', 'ttf', 'xml', 'zip',
            'app', 'exe'
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
            rtn.append(['Launcher_File:' + response, 100-i, x])
        callback(rtn)

    def action(self, key):
        if key[0:14] == 'Launcher_File:':
            os.system('open "' + key[14:] + '"')
            return True
        return False

    def suggest(self, query, callback):
        spaceIndex = query.index(' ')
        ext = query[0:spaceIndex]
        regexStr = query[spaceIndex+1:]
        if regexStr == '': callback([])
        if ext == 'o':
            self.spr.searchFiles(query[len(ext)+1:], 1000, True, False, True, True, True, False, [], self.path, self.pathsToExclude, callback)
        elif ext == 'fo':
            self.spr.searchFiles(query[len(ext)+1:], 1000, True, False, True, False, True, False, [], self.path, self.pathsToExclude, callback)
        else:
            self.spr.searchFiles(query[len(ext)+1:], 1000, True, False, False, True, True, False, [ext], self.path, self.pathsToExclude, callback)

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
