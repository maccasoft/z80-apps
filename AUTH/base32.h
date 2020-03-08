/*
 * Base32 Decoder / Encoder
 */

#ifndef BASE32_H_
#define BASE32_H_

#include <stdint.h>

int base32_decode(const char *string, uint8_t *data);
int base32_encode(uint8_t *data, int length, char *string);

#endif /* BASE32_H_ */

