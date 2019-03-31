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
            'app', 'exe',
            'beta'
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
        # nameToPaths[name][index][0] = [path]
        # nameToPaths[name][index][1] = rank
        nameToPaths = {}
        for i in range(len(responses)):
            p = responses[i].split('/')
            if p[-1] not in nameToPaths:
                nameToPaths[p[-1]] = []
            nameToPaths[p[-1]].append((p, i))
        rtn = []
        for name in nameToPaths:
            if len(nameToPaths[name]) == 1:
                rtn.append(['Launcher_File:' + '/'.join(nameToPaths[name][0][0]), 100-nameToPaths[name][0][1], name])
            else:
                dirCounts = {}
                for i in range(len(nameToPaths[name])):
                    path = nameToPaths[name][i][0]
                    for j in range(len(path)):
                        if path[j] not in dirCounts:
                            dirCounts[path[j]] = 0
                        dirCounts[path[j]] += 1
                for i in range(len(nameToPaths[name])):
                    path = nameToPaths[name][i][0]
                    best = None
                    bestCount = 100000
                    for j in range(len(path)-1, -1, -1):
                        if dirCounts[path[j]] < bestCount:
                            best = path[j]
                            bestCount = dirCounts[path[j]]
                    rtn.append(['Launcher_File:' + '/'.join(path), 100-nameToPaths[name][i][1], name + ' - ' + best])
        callback(rtn)

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:14] == 'Launcher_File:':
            path = key[14:]
            if cmd:
                os.system('open "' + path[:path.rfind('/')] + '"')
            else:
                os.system('open "' + path + '"')
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
