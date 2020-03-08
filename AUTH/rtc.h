/*
 * DS1302 Real Time Clock
 */

#ifndef RTC_H_
#define RTC_H_

#include "time.h"

void rtc_get_time(int port, struct tm * timeptr);

#endif /* RTC_H_ */

