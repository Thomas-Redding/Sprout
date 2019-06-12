import json
import os
import threading
import time
import subprocess

class Launcher_Contacts:
    def __init__(self, spr):
        self.spr = spr
        self.spr.fetchContacts(lambda newContacts: self.updateContacts(newContacts))
        self._contacts = []

    def query(self, userInput, callback):
        suggestions = []
        for i in range(len(self._contacts)):
            contact = self._contacts[i]
            if userInput.lower() == contact["name"][:len(userInput)].lower():
                suggestions.append(('Launcher_Contacts:' + contact["name"], 100-i, contact["name"]))
        callback(suggestions)

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:18] != 'Launcher_Contacts:': return False
        contactName = key[18:]
        appleScript = """
tell application "Contacts"
    activate
    set theContact to the first person whose name is \"""" + contactName + """\"
    set selection to theContact
end tell
"""
        self.spr.runAppleScript(appleScript)
        return True

    def updateContacts(self, newContacts):
        self._contacts = newContacts
