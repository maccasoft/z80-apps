/*
 * DS1302 Real Time Clock
 *
 * Based on code from Andrew Lync for RomWBW
 */

#include <stdint.h>
#include <stdlib.h>

#include "rtc.h"

#define MASK_DO     0b00000001			// RTC data out line
#define MASK_DI     0b10000000			// RTC data in line
#define MASK_CLK    0b01000000          // RTC Serial Clock line
#define MASK_RD     0b00100000          // Enable data read from RTC
#define MASK_RST    0b00010000          // De-activate RTC reset line

void rtc_bit_delay()
{
	for (int i = 0; i < 7; i++)
		;
}

void rtc_wr(int port, uint8_t c)
{
	for (int i = 0; i < 8; i++) {
		if ((c & 0x01) != 0) {
			outp(port, MASK_RST | MASK_DI);
			rtc_bit_delay();
			outp(port, MASK_RST | MASK_CLK | MASK_DI);
		}
		else {
			outp(port, MASK_RST);
			rtc_bit_delay();
			outp(port, MASK_RST | MASK_CLK);
		}
		rtc_bit_delay();
		c >>= 1;
	}
}

int rtc_rd(int port)
{
	int c = 0;
	
	for (int i = 0x01; i != 0x100; i <<= 1) {
		outp(port, MASK_RST | MASK_RD);
		rtc_bit_delay();
		if ((inp(port) & MASK_DO) != 0) {
			c |= i;
		}
		outp(port, MASK_RST | MASK_CLK | MASK_RD);
		rtc_bit_delay();
	}
	
	return c;
}

void rtc_get_time(int port, struct tm * timeptr)
{
    uint8_t c;

	outp(port, MASK_DI | MASK_RD);	// turn on RTC reset
	rtc_bit_delay();
	rtc_bit_delay();
	rtc_bit_delay();
	
	outp(port, MASK_DI | MASK_RD | MASK_RST);	// turn off RTC reset
	rtc_bit_delay();
	rtc_bit_delay();
	
	rtc_wr(port, 0b10111111); // send COMMAND BYTE (BURST READ) to DS1302
	
	c = rtc_rd(port);	// seconds
	timeptr->tm_sec = (c >> 4) * 10 + (c & 0x0F);
	c = rtc_rd(port);	// minutes
	timeptr->tm_min = (c >> 4) * 10 + (c & 0x0F);
	c = rtc_rd(port);	// hours
	timeptr->tm_hour = (c >> 4) * 10 + (c & 0x0F);

	c = rtc_rd(port);	// date
	timeptr->tm_mday = (c >> 4) * 10 + (c & 0x0F);
	c = rtc_rd(port);	// month
	timeptr->tm_mon = ((c >> 4) * 10 + (c & 0x0F)) - 1;
	c = rtc_rd(port);	// weekday
	timeptr->tm_wday = c;
	c = rtc_rd(port);	// year
	timeptr->tm_year = 100 + ((c >> 4) * 10 + (c & 0x0F));

	outp(port, MASK_DI | MASK_RD);
	rtc_bit_delay();
	rtc_bit_delay();
}

