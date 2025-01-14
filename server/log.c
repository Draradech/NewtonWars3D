#include "log.h"

#include <time.h>
#include <stdio.h>
#if _WIN32
#include <windows.h>
#else
#include <errno.h>
#include <string.h>
#endif

static void emit(const char* sys, const char* msg, const char* msg2)
{
    time_t rawtime;
    struct tm* timeinfo;
    char timestr[80];
    time(&rawtime);
    timeinfo = gmtime(&rawtime);
    strftime(timestr, 80, "%Y-%m-%d %H:%M:%S", timeinfo);
    printf("[%s UTC][%s] %s %s", timestr, sys, msg, msg2);
}

void log_sys(const char* sys, const char* msg)
{
    emit(sys, msg, "\n");
}

void log_sys_errno(const char* sys, const char* msg)
{
   #if _WIN32
   LPVOID lpMsgBuf;
   FormatMessage(
      FORMAT_MESSAGE_ALLOCATE_BUFFER |
      FORMAT_MESSAGE_FROM_SYSTEM |
      FORMAT_MESSAGE_IGNORE_INSERTS,
      NULL,
      GetLastError(),
      MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US),
      (LPTSTR) &lpMsgBuf,
      0,
      NULL
   );
   emit(sys, msg, (LPCTSTR)lpMsgBuf);
   LocalFree( lpMsgBuf );
   #else
   emit(sys, msg, strerror(errno));
   #endif
}
