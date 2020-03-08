/*
 * Two-Factor Authentication Password Generator
 * Copyright (c) 2020 Marco Maccaferri. All rights reserved.
 *
 * Based on code from Luca Dentella and others.
 * https://github.com/lucadentella/TOTP-Arduino
 *
 * Compile:
 *
 *   zcc +cpm -O3 auth.c base32.c sha1.c rtc.c time.c -o AUTH.COM
 */

#pragma output noprotectmsdos
#pragma output noredir

#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "base32.h"
#include "sha1.h"
#include "rtc.h"
#include "time.h"

static uint8_t _hmacKey[64];
static int     _hmacKeyLen;

#define STEPS  30

uint32_t generate_totp(uint32_t steps)
{
	uint8_t byteArray[8];
	uint8_t *hash;
	int offset;
	uint32_t truncatedHash;

	byteArray[0] = 0x00;
	byteArray[1] = 0x00;
	byteArray[2] = 0x00;
	byteArray[3] = 0x00;
	byteArray[4] = (uint8_t) ((steps >> 24) & 0xFF);
	byteArray[5] = (uint8_t) ((steps >> 16) & 0xFF);
	byteArray[6] = (uint8_t) ((steps >> 8) & 0xFF);
	byteArray[7] = (uint8_t) ((steps & 0xFF));

	sha1_init_hmac(_hmacKey, _hmacKeyLen);
	sha1_write_array(byteArray, 8);
	hash = sha1_result_hmac();

	offset = hash[20 - 1] & 0xF;
	truncatedHash = 0;
	for (int j = 0; j < 4; ++j) {
		truncatedHash <<= 8;
		truncatedHash |= hash[offset + j];
	}

	truncatedHash &= 0x7FFFFFFF;
	truncatedHash %= 1000000;

	return truncatedHash;
}

int main(int argc, char * argv[])
{
	FILE * fp;
	int tz, dst, rtc;
	uint32_t now, challenge, prev_challenge;
	char text[128], * key, * p;
	struct tm rtctime;

	if (argc <= 1) {
		printf("Two-Factor Authentication Password Generator\n\n");
		printf("Usage: auth keyname\n");
		return 0;
	}
	//printf("%s\n", argv[1]);

	rtc = 0xC0;
	_hmacKeyLen = 0;

	if ((fp = fopen("AUTH.CFG", "r")) != NULL) {
		while (fgets(text, sizeof(text) - 1, fp) != NULL) {
			if (!strncmp(text, "TZ=", 3)) {
				tz = atoi(&text[3]);
				continue;
			}
			if (!strncmp(text, "DST=", 4)) {
				dst = atoi(&text[4]);
				continue;
			}
			if (!strncmp(text, "RTC=", 4)) {
				rtc = text[4] >= 'A' ? text[4] - 'A' + 10 : text[4] - '0';
				rtc <<= 4;
				rtc |= text[5] >= 'A' ? text[5] - 'A' + 10 : text[5] - '0';
				continue;
			}
			if ((key = strchr(text, '=')) == NULL) {
				continue;
			}
			*key++ = '\0';
			if (!stricmp(text, argv[1])) {
				if ((p = strchr(key, '\r')) != NULL) {
					*p = '\0';
				}
				if ((p = strchr(key, '\n')) != NULL) {
					*p = '\0';
				}
				//printf("%s\n", key);
				_hmacKeyLen = base32_decode(key, _hmacKey);
				break;
			}
		}
		fclose(fp);
	}

	if (_hmacKeyLen == 0) {
		printf("Key not found\n");
		return 1;
	}

	//printf("TZ=%d%s\n", tz, dst ? " (DST)" : "");
	//printf("RTC=%02X\n", rtc);

	prev_challenge = 0;
	while (1) {
		if (kbhit()) {
			if (getch() == 3) {	// CTRL-C
				break;
			}
		}

		rtc_get_time(rtc, &rtctime);

		now = mk_gmtime(&rtctime);
		now -= tz * ONE_HOUR;
		if (dst) {
			now -= ONE_HOUR;
		}
		now += UNIX_OFFSET;

		challenge = now / STEPS;
		
		if (challenge != prev_challenge) {
			if (prev_challenge != 0) {
				printf("\033[2A");
			}
			printf("%02d-%02d-%04d %02d:%02d:%02d\n", rtctime.tm_mday, rtctime.tm_mon + 1, rtctime.tm_year + 1900, rtctime.tm_hour, rtctime.tm_min, rtctime.tm_sec);
			printf("%06ld\n", generate_totp(challenge));
			prev_challenge = challenge;
		}
	
		sleep(1);
	}

	return 0;
}
