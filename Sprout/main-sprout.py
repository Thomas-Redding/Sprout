import time

WAIT_TIME = 0.5

spr.listenForHotkey(49, True, False, False, False, lambda a, b, c, d, e : spr.print('CMD + SPACE PRESSED'))
time.sleep(WAIT_TIME)
wind = spr.makeWindow()
time.sleep(WAIT_TIME)
spr.print('WINDOW FRAME:' + str(wind.frame()))
wind.setFrame([100, 100, 300, 300])
spr.print('WINDOW FRAME:' + str(wind.frame()))
time.sleep(WAIT_TIME)
wind.onLoad = lambda : spr.print('I Loaded!!!')
wind.onMessage = lambda message : spr.print('Message from Window: ' + message)
wind.setIndexPath('~/Projects/Sprout/Sprout/index.html')
time.sleep(WAIT_TIME)
spr.print('WINDOW FRAME:' + str(wind.frame()))
wind.setFrame([100, 100, 400, 400])
spr.print('WINDOW FRAME:' + str(wind.frame()))
time.sleep(WAIT_TIME)
wind.sendMessage('Lorem Ipsum 1')
time.sleep(WAIT_TIME)
wind.sendMessage('Lorem Ipsum 2')
time.sleep(WAIT_TIME)
wind.sendMessage('Lorem Ipsum 3')
time.sleep(10) # Time to test receiving messages from the website.
wind.close()
time.sleep(WAIT_TIME)
spr.quit()
