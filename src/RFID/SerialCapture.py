# 2023-03-17. Leonardo Molina.
# 2023-03-17. Last modified.

# Save to disk any data captured from the first serial port that sends data within 1 second.
# Data is expected to be separated by new lines.

import serial
import serial.tools.list_ports
import signal
import sys
import threading
import time

from pathlib import Path
from datetime import datetime

class Capture(object):
    def __init__(self, output, baudrate=115200):
        self.event = threading.Event()
        self.lock = threading.Lock()
        self.lines = []
        self.baudrate = baudrate
        self.output = output
        self.serial = self.__connect()
        self.savingThread = threading.Thread(target=self.__savingThread)
        self.readingThread = threading.Thread(target=self.__readingThread)
        
        self.savingThread.start()
        self.readingThread.start()
    
    def dispose(self):
        self.event.set()
        self.join()
        self.serial.close()
        
    def join(self):
        self.savingThread.join()
        self.readingThread.join()
        
    @property
    def running(self):
        return not self.event.is_set()
    
    def __readingThread(self):
        while self.running:
            if self.serial.in_waiting:
                line = self.serial.readline().decode().strip()
                with self.lock:
                    self.lines.append(line)
            else:
                time.sleep(1e-3)
    
    def __savingThread(self):
        while self.running:
            self.__dump()
            time.sleep(0.1)
        self.__dump()
            
    def __dump(self):
        with self.lock:
            lines, self.lines = self.lines, []
        with open(self.output, 'a') as file:
            for line in lines:
                print('  %s' % line)
                file.write(line + '\n')
    
    def __connect(self):
        ports = list(serial.tools.list_ports.comports())
        for port in ports:
            try:
                s = serial.Serial(port.device, self.baudrate, timeout=1.0)
                line = s.readline().decode().strip()
                if line:
                    self.lines.append(line)
                    print('Connected to "%s"' % port.device)
                    return s
            except serial.SerialException:
                pass
        raise Exception('No device found')

def dispose(capture):
    print('Closing')
    capture.dispose()
    print('Finished')

if __name__ == '__main__':
    print('Started.')
    dateString = datetime.now().strftime('%Y%m%d-%H%M%S')
    output = Path.home() / 'Documents' / dateString
    output = str(output) + '.csv'
    print('Output file: "%s"' % output)
    
    # Run until interrupted with ctrl+c.
    capture = Capture(output=output)
    signal.signal(signal.SIGINT, lambda sig, frame: dispose(capture))
    signal.signal(signal.SIGTERM, lambda sig, frame: dispose(capture))
    while capture.running:
        time.sleep(0.1)