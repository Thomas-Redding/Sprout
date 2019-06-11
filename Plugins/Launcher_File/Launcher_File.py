import json
import os
import threading
import time
import subprocess

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
        self.scopes = ['~/Desktop', '~/Downloads', '~/Documents', '~/Public']
        None

    def query(self, userInput, callback):
        for ext in self.validExtensions:
            if userInput[0:len(ext)+1] == ext + ' ':
                self.suggest(ext, userInput[len(ext)+1:], callback)
                return None
        if userInput[0:2] == 'o ':
            self.suggest('o', userInput[2:], callback)
        elif userInput[0:3] == 'fo ':
            self.suggest('fo', userInput[3:], callback)

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:14] != 'Launcher_File:': return False
        path = key[14:]
        if cmd:
            os.system('open ' + os.path.split(path)[0].replace(" ", "\\ "))
        else:
            os.system('open ' + path.replace(" ", "\\ "))
        return True

    def suggest(self, ext, query, callback):
        # https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html#//apple_ref/doc/uid/TP40001849
        # https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/Articles/pSpotlightComparison.html
        def searchCallback(results):
            rtn = []
            for i in range(len(results)):
                rtn.append(('Launcher_File:' + results[i], 10-i, results[i]))
            callback(rtn)
        queryName = "" if query == "" else " && kMDItemFSName == \'" + query + "*\'c"
        if ext == 'o':
            self.search("kMDItemContentType != public.folder" + queryName + "", searchCallback)
        elif ext == 'fo':
            self.search("kMDItemContentType == public.folder" + queryName, searchCallback)
        else:
            self.search("kMDItemContentType != public.folder" + queryName + " && kMDItemFSName = *." + ext, searchCallback)

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
                    sys.exit(1)
                state = 0
        return rtn

    def asyncPopen(self, popenArgs, callback):
        def runInThread(popenArgs, onExit):
            process = subprocess.Popen(popenArgs, shell=True, stdout=subprocess.PIPE,  stderr=subprocess.PIPE)
            # wait for the process to terminate
            output, error = process.communicate()
            errorCode = process.returncode
            callback(output.decode(), error.decode(), errorCode)
            return
        thread = threading.Thread(target=runInThread, args=(popenArgs, callback))
        thread.start()

    def search(self, query, callback):
        scopes = []
        for scope in self.scopes:
            if scope[0] == '~':
                scopes.append('/Users/thomasredding/' + scope[1:])
            else:
                scopes.append(scope)
        self.spr.searchFiles(query, scopes, [('kMDItemLastUsedDate', False)], callback, 5)
