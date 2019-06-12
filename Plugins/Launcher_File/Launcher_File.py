import json
import os
import threading
import subprocess

"""
launcherFile = Launcher_File()
launcherFile.maxResults = 20

self.fileKeyword = "file"
self.folderKeyword = "folder"
# file foo = files starting with foo
# folder foo = folders starting with foo

launcherFile.validExtensions = ["jpg"]
launcherFile.validExtensions.append("png")
# jpg foo = .jpg files starting with foo
# etc

launcherFile.scopes = [ "~/Desktop" ] # Search files on the user's Desktop
launcherFile.scopes.append("~/Downloads") # ... and downloads

# Define how to handle a user selectin a file. This example opens the enclosing folder if
# the command key is pressed, otherwise it opens the file. The default implementation
# simply always opens the file.
launcherFile.handleSelection = lambda path, command, option, control, shift:
    if command:
        os.system('open ' + os.path.split(path)[0])
    else:
        os.system('open ' + path)
"""

class Launcher_File:
    def __init__(self, spr):
        self.spr = spr
        self.fileKeyword = "file"
        self.folderKeyword = "folder"
        self.maxResults = 10
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
        self.handleSelection = lambda path, cmd, opt, ctrl, shift: os.system('open ' + path)

    def query(self, userInput, callback):
        for ext in self.validExtensions:
            if userInput[0:len(ext)+1] == ext + ' ':
                self.suggest(ext, userInput[len(ext)+1:], callback)
                return None
        if userInput[0:2] == self.fileKeyword + ' ':
            self.suggest(self.fileKeyword, userInput[2:], callback)
        elif userInput[0:3] == self.folderKeyword + ' ':
            self.suggest(self.folderKeyword, userInput[3:], callback)

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:14] != 'Launcher_File:': return False
        self.handleSelection(key[14:].replace(" ", "\\ "), cmd, opt, ctrl, shift)
        return True

    def suggest(self, ext, query, callback):
        # https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html#//apple_ref/doc/uid/TP40001849
        # https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/Articles/pSpotlightComparison.html
        def searchCallback(results):
            rtn = []
            for i in range(len(results)):
                path = results[i]
                reversedPath = " / ".join(path.split('/')[::-1])
                html = "<img src='" + self._pathToFileIcon(path) + "'></img>" + reversedPath
                rtn.append(('Launcher_File:' + results[i], 10-i, html))
            callback(rtn)
        queryName = "" if query == "" else " && kMDItemFSName == '" + query + "*'c"
        if ext == self.fileKeyword:
            self.search("kMDItemContentType != public.folder" + queryName + "", searchCallback)
        elif ext == self.folderKeyword:
            def callbackWrapper(results):
                for scope in self.scopes:
                    if os.path.basename(scope).lower().startswith(query.lower()):
                        results.insert(0, scope)
                searchCallback(results[0:self.maxResults])
            self.search("kMDItemContentType == public.folder" + queryName, callbackWrapper)
        else:
            self.search("kMDItemContentType != public.folder" + queryName + " && kMDItemFSName = '*." + ext + "'c", searchCallback)

    def search(self, query, callback):
        scopes = []
        for scope in self.scopes:
            if scope[0] == '~':
                scopes.append('/Users/thomasredding/' + scope[1:])
            else:
                scopes.append(scope)
        self.spr.searchFiles(query, scopes, [('kMDItemLastUsedDate', False)], callback, self.maxResults)

    def _pathToFileIcon(self, path):
        fileName, extension = os.path.splitext(path)
        pathToIcon = ""
        if extension == "":
            pathToIcon = "/Users/thomasredding/proj/Sprout/Plugins/Launcher_File/icons/dir.png"
        else:
            extension = extension[1:] # remove "."
            pathToIcon = "/Users/thomasredding/proj/Sprout/Plugins/Launcher_File/icons/" + extension + ".png"
        if not os.path.isfile(pathToIcon):
            pathToIcon = "/Users/thomasredding/proj/Sprout/Plugins/Launcher_File/icons/default.png"
        return pathToIcon
