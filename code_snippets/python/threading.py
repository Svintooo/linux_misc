#!/usr/bin/env python3

##
## Text Server (socket server)
##

import socketserver
import re

class IMAPDummyServer(socketserver.StreamRequestHandler):
  def read (self):
    return self.rfile.readline().decode().strip()

  def write(self, string):
    data = string+'\r\n'
    data = data.encode()
    self.wfile.write(data)
    return True

  def handle(self):
    self.write('* OK IMAP4rev1 IMAPDummy')
    while True:
      data = self.read()
      try:
        id, command, *args = re.split(r'\s+', data)
      except:
        id, command, *args = ('?','','')
      command = command.upper()
      if command == 'CAPABILITY':
        self.write('* CAPABILITY IMAP4 IMAP4rev1')
        self.write(id+' OK CAPABILITY completed')
      elif command == 'LOGIN':
        self.write('* CAPABILITY IMAP4rev1 AUTH=CRAM-MD5 UIDPLUS XLIST')
        self.write(id+' OK LOGIN complete')
      elif command == 'LOGOUT':
        self.write('* BYE IMAP4rev1 Server logging out')
        self.write(id+' OK LOGOUT completed')
        break
      else:
        self.wfile.write(id+' BAD Command does not exist or is not implemented')

##
## Threading
##

import threading
class IMAPDummyThread (threading.Thread):
  def __init__(self,  *args, **kwargs):
    super(IMAPDummyThread, self).__init__(*args, **kwargs)
    self._stop_event = threading.Event()
    self._stop_check_interval = 1  # Seconds
    host = "localhost"
    port = 0  # Random port
    self.server = socketserver.TCPServer((host,port),IMAPDummyServer)
    #print(self.server.server_address[1]) #FIXME
  def _stop_handler(self):
    if self._stop_event.is_set():
      self.server.shutdown()
    else:
      self._timer_event = threading.Timer(self._stop_check_interval,
                                          self._stop_handler)
      self._timer_event.start()
      print('.',end='',flush=True)#DEBUG
  def stop(self):
    self._stop_event.set()
  def port(self):
    return self.server.server_address[1]
  def run(self):
    self._stop_handler()
    self.server.serve_forever()

threads = []
threads.append( IMAPDummyThread() )
threads.append( IMAPDummyThread() )
for thread in threads:
  print('Listening port: '+str(thread.port()),flush=True)
for thread in threads:
  thread.start()
import time
time.sleep(10)
print('\nMain: stopping threads',flush=True)
for thread in threads:
  thread.stop()
for thread in threads:
  thread.join()  # Wait for threads to stop
