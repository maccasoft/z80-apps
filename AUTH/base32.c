/*
 * Base32 Decoder / Encoder
 */

#include <ctype.h>

#include "base32.h"

static const char *ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"; // RFC 4668/3548
static const int MASK = 31;
static const int SHIFT = 5;

static int index_of(char c)
{
	for (int i = 0; i < 32; i++) {
		if (toupper(c) == ALPHABET[i])
			return i;
	}
	return -1;
}

int base32_decode(const char *string, uint8_t *data)
{
	int length = 0;
	int buffer = 0;
	int bitsleft = 0;

	while (*string != 0) {
		int index = index_of(*string);
		buffer <<= SHIFT;
		buffer |= index & MASK;
		bitsleft += SHIFT;
		if (bitsleft >= 8) {
			data[length++] = (uint8_t) (buffer >> (bitsleft - 8));
			bitsleft -= 8;
		}
		string++;
	}

	return length;
}

#if 0
int base32_encode(uint8_t *data, int length, char *string)
{
	int result = 0;

    int buffer = data[0];
    int next = 1;
    int bitsLeft = 8;

    while (bitsLeft > 0 || next < length) {
      if (bitsLeft < SHIFT) {
        if (next < length) {
          buffer <<= 8;
          buffer |= data[next++] & 0xff;
          bitsLeft += 8;
        } else {
          int pad = SHIFT - bitsLeft;
          buffer <<= pad;
          bitsLeft += pad;
        }
      }
      int index = MASK & (buffer >> (bitsLeft - SHIFT));
      bitsLeft -= SHIFT;
      *string++ = ALPHABET[index];
      result++;
    }

    *string = '\0';

    return result;
}
#endif
