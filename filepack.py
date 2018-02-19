#!/usr/bin/python

# Binary to CP/M file packager
# Written for RC2014 computer by Marco Maccaferri
# Based on documentation by Grant Searle

import sys
import glob
import ntpath
import getopt
import serial

from time import sleep

cmd_delay = 0
byte_delay = 0

fill_ch = -1
user = 0

def encodeFile(filename, device):

    name = ntpath.basename(filename).upper()

    f = open(filename, "rb")
    try:
        # command to create file
        device.write ("A:DOWNLOAD %s%c%c" % (name, 13, 10))
        device.flush()
        sleep(cmd_delay);

        # user selection
        device.write ("U%d%c%c" % (user, 13, 10))
        device.flush()
        sleep(byte_delay);

        # start data stream
        device.write (":")
        device.flush()
        sleep(cmd_delay);

        length = 0
        checksum = 0

        # data stream
        byte = f.read(1)
        while byte != "":
            device.write(byte.encode('hex').upper())
            device.flush()
            length = length + 1
            checksum = checksum + ord(byte)
            byte = f.read(1)
            sleep(byte_delay);

        # fill last sector, if required
        if fill_ch <> -1:
            while (length % 128) <> 0:
                device.write("%02X" % (fill_ch))
                device.flush()
                length = length + 1
                checksum = checksum + fill_ch
                sleep(byte_delay);

        # end data stream and checksum
        device.write(">%02X%02X" % (length % 256, checksum % 256))

    finally:
        f.close()

    device.write ("%c%c" % (13, 10))
    device.flush()
    sleep(cmd_delay);

def usage():
    print("Usage: %s [-b n] [-c n] [-f n] [-p port] [-t n] [-u n] file1 [[file2] ... fileN]" % (sys.argv[0]))
    print("Where:")
    print("    -b - Set port baud rate to n (default 115200)")
    print("    -c - Set command delay to n ms. (default 0)")
    print("    -f - Fill last 128 bytes sector with byte value n (default 0, no fill)")
    print("    -p - Send output to port (default stdout)")
    print("    -t - Set byte transfer delay to n ms. (default 0)")
    print("    -u - Select user n (default 0)")
    print("    file1...fileN - List of files to transfer")

try:
    opts, args = getopt.getopt(sys.argv[1:], "b:c:f:p:t:u:")
    if len(args) == 0:
        usage()
        sys.exit()
except getopt.GetoptError as err:
    print(err)
    usage()
    sys.exit()

port = None
baudrate = 115200

for o, a in opts:
    if o == "-b":
        baudrate = int(a)
    if o == "-c":
        cmd_delay = int(a) / 1000.0
    if o == "-f":
        fill_ch = int(a)
    if o == "-p":
        port = a
    if o == "-t":
        byte_delay = int(a) / 1000.0
    if o == "-u":
        user = int(a)

if port <> None:
    device = serial.Serial()
    device.port = port
    device.baudrate = baudrate
    device.dtr = True
    device.open()
else:
    device = sys.stdout

for x in args:
    for fn in glob.glob(x):
        encodeFile(fn, device)

if port <> None:
    device.close()

