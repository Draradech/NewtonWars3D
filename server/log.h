#ifndef _LOG_H_
#define _LOG_H_

void log_sys(const char* sys, const char* msg);
void log_sys_errno(const char* sys, const char* msg);

#ifndef LOG_SYS
#define LOG_SYS "    "
#endif

#define log(x) log_sys((LOG_SYS), (x))
#define log_errno(x) log_sys_errno((LOG_SYS), (x))

#endif // _LOG_H_
