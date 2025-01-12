#include "network.h"

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <limits.h>
#include <string.h>
#include <sys/types.h>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#endif

#include "config.h"
#include "simulation.h"

#ifdef _WIN32
#define close closesocket
#ifndef IPV6_V6ONLY
#define IPV6_V6ONLY 27
#endif
typedef SOCKET fd_socket_t;
#else
#define INVALID_SOCKET -1
#endif

#define PORT "3490"
#define BACKLOG 4
#define MAX_SEND_BUFFER_SIZE (64 * 1024) // 64 KB buffer for all packets

typedef struct
{
   fd_socket_t socket;
   char msgbuf[64];
   int msgbufindex;
   int msgID;
   int inMsg;
   int local;
   int limit;
   char ip[INET6_ADDRSTRLEN];
   int timeout;
} connection_t;

typedef struct
{
   char ip[INET6_ADDRSTRLEN];
   int time;
} block_entry_t;

static const int yes = 1;
static const int no = 0;

static fd_set master, readfds;
static fd_socket_t sockmax, listener;
static char buf[64];
static char sendBuffer[MAX_SEND_BUFFER_SIZE];
static int sendBufferOffset = 0;
static block_entry_t block_list[16];
static connection_t* connection;

void sendFrameData(double t);
void sendStartPacket(int pl, double t);

static void print_error(const char* msg)
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
   fprintf(stderr, "%s: %s", msg, (LPCTSTR)lpMsgBuf);
   LocalFree( lpMsgBuf );
   #else
   perror(msg);
   #endif
}

static void snd(int socket, int len, char* msg)
{
   int flags;
   #if defined __APPLE__ || defined _WIN32
   flags = 0;
   #else
   flags = MSG_NOSIGNAL | MSG_DONTWAIT;
   #endif
   if(send(socket, msg, len, flags) == -1)
   {
      print_error("send");
   }
}

static int is_blocked(char* ip, double delta)
{
   int entry_min_time = -1;
   int min_time = INT_MAX;
   int i;

   for(i = 0; i < 16; ++i)
   {
      if(strcmp(ip, block_list[i].ip) == 0)
      {
         int time = block_list[i].time;
         block_list[i].time = conf.blockConTime / delta;
         return time;
      }
      if(block_list[i].time < min_time)
      {
         min_time = block_list[i].time;
         entry_min_time = i;
      }
   }
   strncpy_s(block_list[entry_min_time].ip, INET6_ADDRSTRLEN, ip, INET6_ADDRSTRLEN);
   block_list[entry_min_time].time =  conf.blockConTime / delta;
   return 0;
}

static int is_connected(char* ip)
{
   int k;
   for(k = 0; k < conf.maxPlayers; ++k)
   {
      if(connection[k].socket)
      {
         if(strcmp(ip, connection[k].ip) == 0)
         {
            return 1;
         }
      }
   }
   return 0;
}

static void update_block_list(void)
{
   int i;

   for(i = 0; i < 16; ++i)
   {
      if(block_list[i].time)
      {
         block_list[i].time--;
         if(block_list[i].time == 0)
         {
            block_list[i].ip[0] = '\0';
         }
      }
   }
}

static void update_limits(void)
{
   static int counter;
   int k;

   counter++;
   if(counter % 3 != 0) return;

   for(k = 0; k < conf.maxPlayers; ++k)
   {
      if(connection[k].socket)
      {
         connection[k].limit += 1;
         if(connection[k].limit > 512)
         {
            connection[k].limit = 512;
         }
      }
   }
}

static void update_timeouts(void)
{
   int k;

   for(k = 0; k < conf.maxPlayers; ++k)
   {
      if(connection[k].socket)
      {
         if(connection[k].timeout)
         {
            connection[k].timeout--;
         }
      }
   }
}

void initNetwork(void)
{
   struct addrinfo hints, *ai, *p;
   int rv;

   #ifdef _WIN32
   WSADATA wsaData;
   if(WSAStartup(MAKEWORD(2, 0), &wsaData) != 0)
   {
      fprintf(stderr, "WSAStartup failed.\n");
      exit(1);
   }
   #endif

   connection = malloc(conf.maxPlayers * sizeof(connection_t));
   memset(connection, 0, conf.maxPlayers * sizeof(connection_t));

   FD_ZERO(&master);
   FD_ZERO(&readfds);

   memset(&hints, 0, sizeof hints);
   hints.ai_family = AF_UNSPEC;
   hints.ai_socktype = SOCK_STREAM;
   hints.ai_flags = AI_PASSIVE;
   if ((rv = getaddrinfo(NULL, PORT, &hints, &ai)) != 0)
   {
      fprintf(stderr, "getaddrinfo: %s", gai_strerror(rv));
      exit(2);
   }

   // loop through all the results and bind to the first IPv6 we can
   for(p = ai; p != NULL; p = p->ai_next)
   {
      if(p->ai_family != AF_INET6)
      {
         continue;
      }

      if ((listener = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) == INVALID_SOCKET)
      {
         print_error("socket");
         continue;
      }

      if (setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes)) == -1)
      {
         print_error("setsockopt reuse");
         close(listener);
         continue;
      }

      // only interested if dualstack
      if (setsockopt(listener, IPPROTO_IPV6, IPV6_V6ONLY, (void *)&no, sizeof(no)) == -1)
      {
         print_error("setsockopt dualstack");
         close(listener);
         continue;
      }

      if (bind(listener, p->ai_addr, p->ai_addrlen) == -1)
      {
         print_error("bind");
         close(listener);
         continue;
      }

      break; // success
   }

   if (p == NULL) // IPv6 dualstack failed
   {
      // loop through all the results and bind to the first IPv4 we can
      for(p = ai; p != NULL; p = p->ai_next)
      {
         if(p->ai_family != AF_INET)
         {
            continue;
         }

         if ((listener = socket(p->ai_family, p->ai_socktype, p->ai_protocol)) == INVALID_SOCKET)
         {
            print_error("socket");
            continue;
         }

         if (setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes)) == -1)
         {
            print_error("setsockopt reuse");
            close(listener);
            continue;
         }

         if (bind(listener, p->ai_addr, p->ai_addrlen) == -1)
         {
            print_error("bind");
            close(listener);
            continue;
         }

         break; // success
      }

      if (p == NULL) // IPv4 failed as well
      {
         fprintf(stderr, "failed to bind\n");
         exit(3);
      }
   }

   freeaddrinfo(ai);

   if (listen(listener, BACKLOG) == -1)
   {
      print_error("listen");
      exit(4);
   }

   FD_SET(listener, &master);
   sockmax = listener;
   printf("waiting for connections...\n");
}

void disconnectPlayer(int p)
{
   int socket = connection[p].socket;
   playerLeave(p);
   close(connection[p].socket);
   FD_CLR(connection[p].socket, &master);
   connection[p].socket = 0;
   printf("socket %d closed\n", socket);
}

void stepNetwork(double t, double delta)
{
   int k, pi, nbytes;
   fd_socket_t i, newfd;
   (void) t;
   char remoteIP[INET6_ADDRSTRLEN];
   struct sockaddr_storage remoteaddr;
   socklen_t addrlen;
   struct timeval tv;

   update_block_list();
   update_limits();
   update_timeouts();

   tv.tv_sec = 0;
   tv.tv_usec = 1;
   readfds = master;
   if(select(sockmax + 1, &readfds, NULL, NULL, &tv) == -1)
   {
      print_error("select");
      exit(5);
   }

   for(i = 0; i <= sockmax; ++i)
   {
      if(FD_ISSET(i, &readfds))
      {
         if(i == listener)
         {
            addrlen = sizeof remoteaddr;
            newfd = accept(listener, (struct sockaddr *)&remoteaddr, &addrlen);
            if(newfd == INVALID_SOCKET)
            {
               print_error("accept");
            }
            else
            {
               int blocked, connected, local;
               getnameinfo((struct sockaddr *)&remoteaddr, addrlen, remoteIP, sizeof remoteIP, NULL, 0, NI_NUMERICHOST | NI_NUMERICSERV);
               local =   (  (strcmp(remoteIP,"127.0.0.1") == 0)
                         || (strcmp(remoteIP,"::ffff:127.0.0.1") == 0)
                         || (strcmp(remoteIP,"::1") == 0)
                         );
               blocked = local ? 0 : is_blocked(remoteIP, delta);
               connected = local ? 0 : is_connected(remoteIP);
               if(blocked)
               {
                  close(newfd);
                  printf("new connection from %s on socket %d refused: blocked for %lfs\n", remoteIP, (unsigned int)newfd, blocked * delta);
               }
               else if(connected && conf.blockMultiCon)
               {
                  close(newfd);
                  printf("new connection from %s on socket %d refused: already connected\n", remoteIP, (unsigned int)newfd);
               }
               else
               {
                  for(k = 0; k < conf.maxPlayers; ++k)
                  {
                     if(connection[k].socket == 0)
                     {
                        if (setsockopt(newfd, IPPROTO_TCP, TCP_NODELAY, (void *)&yes, sizeof(yes)) == -1)
                        {
                           printf("new connection from %s on socket %d refused:\n", remoteIP, (unsigned int)newfd);
                           print_error("setsockopt nodelay");
                           close(newfd);
                           break;
                        }

                        connection[k].socket = newfd;
                        connection[k].local = local;
                        connection[k].limit = 512;
                        connection[k].timeout = conf.timeout / delta;
                        strncpy_s(connection[k].ip, INET6_ADDRSTRLEN, remoteIP, INET6_ADDRSTRLEN);
                        playerJoin(k);
                        FD_SET(newfd, &master);
                        if(newfd > sockmax)
                        {
                           sockmax = newfd;
                        }
                        printf("new connection from %s on socket %d accepted\n", remoteIP, (unsigned int)newfd);
                        sendStartPacket(k, t);
                        break;
                     }
                  }
                  if(k == conf.maxPlayers)
                  {
                     close(newfd);
                     printf("new connection from %s on socket %d refused: max connections\n", remoteIP, (unsigned int)newfd);
                  }
               }
            }
         }
         else
         {
            pi = -1;
            for(k = 0; k < conf.maxPlayers; ++k)
            {
               if(connection[k].socket == i)
               {
                  pi = k;
                  break;
               }
            }
            if(pi == -1)
            {
               fprintf(stderr, "socket without player\n");
               exit(6);
            }
            nbytes = recv(i, buf, sizeof buf, 0);
            connection[pi].limit -= connection[pi].local ? 0 : nbytes;
            if (  (nbytes <= 0)
               || (connection[pi].limit < 0)
               )
            {
               if(connection[pi].limit < 0)
               {
                  printf("socket %d exceeded rate limit\n", (unsigned int)i);
               }
               else if(nbytes == 0)
               {
                  printf("socket %d hung up\n", (unsigned int)i);
               }
               else
               {
                  print_error("recv");
               }
               disconnectPlayer(pi);
            }
            else
            {
               connection_t* con = &(connection[pi]);
               con->timeout = conf.timeout / delta;
               int cancel = 0;
               for(k = 0; k < nbytes && pi >= 0 && !cancel; ++k)
               {
                  con->msgbuf[con->msgbufindex++] = buf[k];
                  if(!con->inMsg)
                  {
                     if(con->msgbufindex == 4)
                     {
                        con->msgID = *((int*)(con->msgbuf));
                        con->inMsg = 1;
                        con->msgbufindex = 0;
                     }
                  }
                  else
                  {
                     switch(con->msgID)
                     {
                        case MSG_SHOOT:
                        {
                           if(con->msgbufindex == 24)
                           {
                              double pitch, yaw, speed;
                              pitch = *((double*)(con->msgbuf));
                              yaw = *((double*)(con->msgbuf + 8));
                              speed = *((double*)(con->msgbuf + 16));
                              playerShoot(pi, yaw, pitch, speed);
                              con->inMsg = 0;
                              con->msgbufindex = 0;
                           }
                           break;
                        }
                        default:
                        {
                           printf("player %d sent unknown message %d.\n", pi, con->msgID);
                           disconnectPlayer(pi);
                           cancel = 1;
                        }
                     }
                  }
               }
            }
         }
      }
   }
   for(k = 0; k < conf.maxPlayers; ++k)
   {
      if(conf.timeout && connection[k].socket && connection[k].timeout == 0)
      {
         disconnectPlayer(k);
      }
   }
   sendFrameData(t);
}

void addToSendBuffer(const char* data, int size)
{
   if (sendBufferOffset + size > MAX_SEND_BUFFER_SIZE)
   {
      fprintf(stderr, "Send buffer overflow!\n");
      return;
   }
   memcpy(sendBuffer + sendBufferOffset, data, size);
   sendBufferOffset += size;
}

void sendAll(void)
{
   for (int i = 0; i < conf.maxPlayers; ++i)
   {
      if (connection[i].socket)
      {
         snd(connection[i].socket, sendBufferOffset, sendBuffer);
      }
   }
   sendBufferOffset = 0;
}

void sendOne(int pl)
{
   snd(connection[pl].socket, sendBufferOffset, sendBuffer);
   sendBufferOffset = 0;
}

void addSimTime(double t)
{
   unsigned char buf[12];
   uint32_t packetId = MSG_SIM_TIME;

   memcpy(buf, &packetId, 4);
   memcpy(buf + 4, &t, 8);

   addToSendBuffer((char*)buf, sizeof(buf));
}

void addPlanets(int dirtyOnly)
{
   unsigned char buf[24];
   uint32_t packetId = MSG_PLANET;
   float f;

   for(int i = 0; i < conf.numPlanets; i++)
   {
      Planet* p = getPlanet(i);
      if(p->dirty || !dirtyOnly)
      {
         memcpy(buf, &packetId, 4);
         memcpy(buf + 4, &i, 4);
         f = p->position.x;
         memcpy(buf + 8, &f, 4);
         f = p->position.y;
         memcpy(buf + 12, &f, 4);
         f = p->position.z;
         memcpy(buf + 16, &f, 4);
         f = p->radius;
         memcpy(buf + 20, &f, 4);
         addToSendBuffer((char*)buf, sizeof(buf));
         if(dirtyOnly) p->dirty = 0;
      }
   }
}

void addPlayerPos(int dirtyOnly)
{
   unsigned char buf[24];
   uint32_t packetId = MSG_PLAYER_POS;
   float f;

   for(int i = 0; i < conf.maxPlayers; i++)
   {
      Player* p = getPlayer(i);
      if(p->live && ((p->dirty & DIRTY_POS) || !dirtyOnly))
      {
         memcpy(buf, &packetId, 4);
         memcpy(buf + 4, &i, 4);
         f = p->position.x;
         memcpy(buf + 8, &f, 4);
         f = p->position.y;
         memcpy(buf + 12, &f, 4);
         f = p->position.z;
         memcpy(buf + 16, &f, 4);
         f = conf.playerSize;
         memcpy(buf + 20, &f, 4);
         addToSendBuffer((char*)buf, sizeof(buf));
         if(dirtyOnly) p->dirty &= ~DIRTY_POS;
      }
   }
}

void addPlayerDel(void)
{
   unsigned char buf[8];
   uint32_t packetId = MSG_PLAYER_DEL;

   for(int i = 0; i < conf.maxPlayers; i++)
   {
      Player* p = getPlayer(i);
      if(!p->live && p->dirty & DIRTY_LIVE)
      {
         memcpy(buf, &packetId, 4);
         memcpy(buf + 4, &i, 4);
         addToSendBuffer((char*)buf, sizeof(buf));
         p->dirty &= ~DIRTY_LIVE;
      }
   }
}

void addOwnId(int pl)
{
   unsigned char buf[8];
   uint32_t packetId = MSG_OWN_ID;

   memcpy(buf, &packetId, 4);
   memcpy(buf + 4, &pl, 4);
   addToSendBuffer((char*)buf, sizeof(buf));
}

void addNewMissiles(void)
{
   unsigned char buf[12];
   uint32_t packetId = MSG_NEW_MISS;

   for(int pl = 0; pl < conf.maxPlayers; ++pl)
   {
      if(!getPlayer(pl)->live) continue;
      for(int mi = 0; mi < conf.numShots; ++mi)
      {
         Missile* m = getMissile(pl, mi);
         if(m->live && m->dirty & DIRTY_LIVE)
         {
            memcpy(buf, &packetId, 4);
            memcpy(buf + 4, &pl, 4);
            memcpy(buf + 8, &m->id, 4);
            addToSendBuffer((char*)buf, sizeof(buf));
            m->dirty &= ~DIRTY_LIVE;
         }
      }
   }
}

void addMissilePos(double t)
{
   unsigned char buf[28];
   uint32_t packetId = MSG_MISS_POS;
   double ts;
   float f;

   for(int pl = 0; pl < conf.maxPlayers; ++pl)
   {
      if(!getPlayer(pl)->live) continue;
      for(int mi = 0; mi < conf.numShots; ++mi)
      {
         Missile* m = getMissile(pl, mi);
         if(m->dirty & DIRTY_POS)
         {
            memcpy(buf, &packetId, 4);
            memcpy(buf + 4, &m->id, 4);
            ts = m->live ? t : m->diedAt;
            memcpy(buf + 8, &ts, 8);
            f = m->position.x;
            memcpy(buf + 16, &f, 4);
            f = m->position.y;
            memcpy(buf + 20, &f, 4);
            f = m->position.z;
            memcpy(buf + 24, &f, 4);
            addToSendBuffer((char*)buf, sizeof(buf));
            m->dirty &= ~DIRTY_POS;
         }
      }
   }
}

void addMissileEnd(void)
{
   unsigned char buf[8];
   uint32_t packetId = MSG_MISS_END;

   for(int pl = 0; pl < conf.maxPlayers; ++pl)
   {
      if(!getPlayer(pl)->live) continue;
      for(int mi = 0; mi < conf.numShots; ++mi)
      {
         Missile* m = getMissile(pl, mi);
         if(!m->live && m->dirty & DIRTY_LIVE)
         {
            memcpy(buf, &packetId, 4);
            memcpy(buf + 4, &m->id, 4);
            addToSendBuffer((char*)buf, sizeof(buf));
            m->dirty &= ~DIRTY_LIVE;
         }
      }
   }
}

void sendFrameData(double t)
{
   addPlanets(1);
   addPlayerPos(1);
   addPlayerDel();
   addNewMissiles();
   addMissilePos(t);
   addMissileEnd();
   addSimTime(t);
   sendAll();
}

void sendStartPacket(int pl, double t)
{
   addOwnId(pl);
   addPlanets(0);
   addPlayerPos(0);
   addSimTime(t);
   sendOne(pl);
}
