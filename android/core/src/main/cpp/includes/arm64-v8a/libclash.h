#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned char GoUint8;
typedef int GoInt32;

extern GoUint8 startTUN(void* callback, GoInt32 fd, char* stack, char* address, char* dns);

extern void stopTun(void);

extern void forceGC(void);

extern void updateDns(char* s);

extern void invokeAction(void* callback, char* paramsChar);

extern void setEventListener(void* listener);

extern char* getTraffic(GoUint8 onlyStatisticsProxy);

extern char* getTotalTraffic(GoUint8 onlyStatisticsProxy);

extern void suspend(GoUint8 suspended);

extern void quickSetup(void* callback, char* initParamsChar, char* setupParamsChar);

#ifdef __cplusplus
}
#endif
