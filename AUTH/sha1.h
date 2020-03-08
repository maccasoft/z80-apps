/*
 * SHA1
 */

#ifndef SHA1_H_
#define SHA1_H_

#include <stdint.h>

#define HASH_LENGTH     20
#define BLOCK_LENGTH    64

void      sha1_init_hmac(const uint8_t * key, int keyLength);
void      sha1_write_byte(uint8_t data);
void      sha1_write_array(const uint8_t *data, int length);
uint8_t * sha1_result_hmac();

#endif /* SHA1_H_ */

