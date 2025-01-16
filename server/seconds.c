#include "seconds.h"

#include <stdint.h>

#ifdef _WIN32
#include <windows.h>
#include <stdio.h>
static int64_t freq = 0;
double seconds(void)
{
    int64_t time;
    if (freq == 0)
    {
        QueryPerformanceFrequency((LARGE_INTEGER*)&freq);
    }
    QueryPerformanceCounter((LARGE_INTEGER*)&time);

    return (double)time / freq;
}

void usleep(int usec)
{
	HANDLE timer;
	LARGE_INTEGER ft;

	ft.QuadPart = -(10 * usec);

	timer = CreateWaitableTimer(NULL, TRUE, NULL);
	SetWaitableTimer(timer, &ft, 0, NULL, NULL, 0);
	WaitForSingleObject(timer, INFINITE);
	CloseHandle(timer);
}
#else
#include <unistd.h> // usleep
#include <time.h>
double seconds(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    return (double)ts.tv_sec + ts.tv_nsec * 1e-9;
}
#endif

void wait(double seconds)
{
    if (seconds > 0)
    {
        usleep((int)(1e6 * seconds));
    }
}
