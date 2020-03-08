## Two-Factor Authentication Password Generator

This is an implementation of the Time-based One-Time Password algorithm specified in RFC 6238.

### Installation

Copy the AUTH.COM and AUTH.CFG files to your CP/M system and edit the configuration file AUTH.CFG accordingly to your setup.

This program requires the [DS1302 Real Time Clock](https://github.com/electrified/rc2014-ds1302-rtc) board.
Make sure the time is set correctly or the generated passwords may not work.

**Example AUTH.CFG file**

```
; TimeZone Offset
TZ=+01
; Daylight Saving Time
DST=0
; RTC Port (HEX)
RTC=C0
; Secret Keys List
NAME1=ABCDEFGHIJKL23456
NAME2=ABCDEFGHIJKL65432
```

TZ sets your time zone  
DST sets if the daylight saving time is in effect (=1) or not (=0)  
RTC sets the I/O port for the DS1302 Real Time Clock board  

The secret keys are listed as NAME=STRING lines where NAME is the label that must be used on the command line and STRING is the
Base32 string representing the private key associated to the web site or service you want to access to.

### Usage

```
AUTH keyname
```

Where keyname is the secret key name, stored in the configuration file, related to the service you want to access to.

**Example output**

```
A>AUTH KEY1
08-03-2020 08:15:00
781278

```

The screen is updated accordingly to the key expiration period.  
Press CTRL-C to exit the program.
