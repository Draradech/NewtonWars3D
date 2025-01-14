#include "simulation.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include "config.h"

#define LOG_SYS "SIM "
#include "log.h"

#define SHOT_LOG 1

#define LIMIT(x, min, max) (((x) < (min)) ? (min) : ((x) > (max)) ? (max) : (x))

static Planet* planets;
static Player* players;
static double pmin, pmax;
static int mid = 0;
static double potential[80][50][80];
static char area[80][50][80];
static char scratch[1024];

typedef struct
{
   unsigned char x;
   unsigned char y;
   unsigned char z;
} fillpos_t;

static int head = 0;
static int tail = 0;
#define blen 20000
static fillpos_t ringbuffer[blen] = {0};

static void push(fillpos_t pos)
{
   ringbuffer[head] = pos;
   head = (head + 1) % blen;
}

static fillpos_t pop(void)
{
   fillpos_t ret = ringbuffer[tail];
   tail = (tail + 1) % blen;
   return ret;
}

static int len(void)
{
   return (head - tail + blen) % blen;
}

static void floodfill(int x, int y, int z)
{
   fillpos_t pos = {x, y, z};
   int maxlen = 0;
   int l = 0;
   for(;;)
   {
      if(!area[pos.z][pos.y][pos.x] && potential[pos.z][pos.y][pos.x] > pmin)
      {
         area[pos.z][pos.y][pos.x] = 1;
         if(pos.x > 0)  push((fillpos_t){pos.x - 1, pos.y, pos.z});
         if(pos.x < 79) push((fillpos_t){pos.x + 1, pos.y, pos.z});
         if(pos.y > 0)  push((fillpos_t){pos.x, pos.y - 1, pos.z});
         if(pos.y < 49) push((fillpos_t){pos.x, pos.y + 1, pos.z});
         if(pos.z > 0)  push((fillpos_t){pos.x, pos.y, pos.z - 1});
         if(pos.z < 79) push((fillpos_t){pos.x, pos.y, pos.z + 1});
      }
      l = len();
      if(l > 0.9 * blen)
      {
         log("floodfill buffer overflow");
         exit(0);
      }
      if(l > maxlen) maxlen = l;
      if(l == 0) break;
      pos = pop();
   }
}

static double calcGPot(Vec3d pos)
{
   double l, potential = 0;
   int j;

   for(j = 0; j < conf.numPlanets; ++j)
   {
      l = distance(planets[j].position, pos);

      if (l <= planets[j].radius)
      {
         return -1;
      }

      potential += planets[j].mass / l;
   }
   return potential;
}

static int potentialEvaluation(void)
{
   int x, y, z, found;
   Vec3d p;
   double sum = 0;
   int num = 0;

   for(z = 0; z < 80; ++z)
   {
      p.z = z * (conf.battlefieldRadius + 300) * 2 / 80 - (conf.battlefieldRadius + 300);
      for(y = 0; y < 50; ++y)
      {
         p.y = y * (conf.battlefieldHeight + 300) * 2 / 50 - (conf.battlefieldHeight + 300);
         for(x = 0; x < 80; ++x)
         {
            p.x = x * (conf.battlefieldRadius + 300) * 2 / 80 - (conf.battlefieldRadius + 300);
            potential[z][y][x] = calcGPot(p);
            area[z][y][x] = 0;
            if (potential[z][y][x] > 0)
            {
               sum += potential[z][y][x];
               num++;
            }
         }
      }
   }

   pmax = 1.35 * sum / num;
   pmin = pmax - 10;

   found = 0;
   for(z = 0; z < 80 && !found; ++z)
   {
      for(y = 0; y < 50 && !found; ++y)
      {
         for(x = 0; x < 80 && !found; ++x)
         {
            if(potential[z][y][x] > pmin) found = 1;
         }
      }
   }

   floodfill(x, y, z);

   for(z = 0; z < 80; ++z)
   {
      for(y = 0; y < 50; ++y)
      {
         for(x = 0; x < 80; ++x)
         {
            if(!area[z][y][x] && potential[z][y][x] > pmin) return 0;
         }
      }
   }

   return 1;
}

static void initPlanets(void)
{
   int tries = 0;
   do
   {
      int i, j;

      for(i = 0; i < conf.numPlanets; i++)
      {
         Planet* p = &(planets[i]);
         int nok;
         do
         {
            p->radius = 20.0 + (double)rand() / RAND_MAX * 20.0;
            p->mass = p->radius * p->radius * p->radius / 10.0;
            p->position.x = (double)rand() / RAND_MAX * conf.battlefieldRadius * 2 - conf.battlefieldRadius;
            p->position.y = (double)rand() / RAND_MAX * conf.battlefieldHeight * 2 - conf.battlefieldHeight;
            p->position.z = (double)rand() / RAND_MAX * conf.battlefieldRadius * 2 - conf.battlefieldRadius;
            nok = 0;
            Vec3d xz = p->position;
            xz.y = 0;
            if(length(xz) > conf.battlefieldRadius) nok = 1;
            for(j = 0; j < i && nok == 0; ++j)
            {
               if(distance(p->position, planets[j].position) <= (p->radius + planets[j].radius))
               {
                  nok = 1;
               }
            }
         } while (nok);
         p->dirty |= DIRTY_POS;
      }

      tries++;
   }
   while (!potentialEvaluation());

   sprintf(scratch, "pmin: %.2lf pmax: %.2lf (%d tries)", pmin, pmax, tries);
   log(scratch);
}

static void initPlayer(Player* p)
{
   int i, nok;

   do
   {
      p->position.x = (double)rand() / RAND_MAX * conf.battlefieldRadius * 2 - conf.battlefieldRadius;
      p->position.y = (double)rand() / RAND_MAX * conf.battlefieldHeight * 2 - conf.battlefieldHeight;
      p->position.z = (double)rand() / RAND_MAX * conf.battlefieldRadius * 2 - conf.battlefieldRadius;

      nok = 0;
      if(calcGPot(p->position) > pmax || calcGPot(p->position) < pmin)
      {
         nok = 1;
      }
      for(i = 0; i < conf.maxPlayers; ++i)
      {
         if(&players[i] == p || !players[i].live) continue;
         if(distance(p->position, players[i].position) <= conf.playerSpacing) /* players distance from other playerss */
         {
            nok = 1;
         }
      }
      for(i = 0; i < conf.numPlanets; ++i)
      {
         if(distance(p->position, planets[i].position) <= (planets[i].radius + conf.playerSize)) /* players distance from planetss */
         {
            nok = 1;
         }
      }
   } while (nok);
   p->dirty |= DIRTY_POS;
}

static void playerHit(int p, int p2)
{
   if(p == p2)
   {
      players[p].deaths++;
      players[p].dirty |= DIRTY_DATA;
   }
   else
   {
      players[p].kills++;
      players[p].dirty |= DIRTY_DATA;
      players[p2].deaths++;
      players[p2].dirty |= DIRTY_DATA;
   }
   initPlayer(&players[p2]);
}

Vec3d acc(Vec3d pos)
{
   int i;
   Vec3d an;
   double l;
   Vec3d a = {0, 0, 0};

   for(i = 0; i < conf.numPlanets; ++i)
   {
      an = vsub(planets[i].position, pos);
      l = length(an);
      an = vdiv(an, l);
      an = vmul(an, planets[i].mass / (l * l));

      a = vadd(a, an);
   }

   return a;
}

void stepIntegrate(Missile* m)
{
   // velocity verlet method
   // new_pos = pos + velocity * dt + acc * 0.5 * dt * dt
   // new_acc = acc(new_pos)
   // new_velocity = velocity + (acc + new_acc) * 0.5 * dt
   double dt = 1.0 / conf.segmentSteps;
   Vec3d new_pos = vadd(vadd(m->position, vmul(m->velocity, dt)), vmul(m->acceleration, 0.5 * dt * dt));
   Vec3d new_acc = acc(new_pos);
   Vec3d new_velocity = vadd(m->velocity, vmul(vadd(m->acceleration, new_acc), 0.5 * dt));
   m->position = new_pos;
   m->velocity = new_velocity;
   m->acceleration = new_acc;
   m->dirty |= DIRTY_POS;
}

void stepSimulation(double t, double delta)
{
   int mi, i, j, pl, pl2;
   double l;
   
   for(pl = 0; pl < conf.maxPlayers; ++pl)
   {
      Player* p = &(players[pl]);
      if(!p->live) continue;

      for(mi = 0; mi < conf.numShots; ++mi)
      {
         Missile* m = &(p->missiles[mi]);
         
         double fractTs = t - delta;
         for(i = 0; i < conf.segmentSteps; ++i)
         {
            if(!m->live) break;
            stepIntegrate(m);
            fractTs += delta / conf.segmentSteps;

            for(j = 0; j < conf.numPlanets; ++j)
            {
               l = distance(planets[j].position, m->position);

               if (l <= planets[j].radius)
               {
                  m->live = 0;
                  m->diedAt = fractTs;
                  m->dirty |= DIRTY_LIVE;
                  #if SHOT_LOG
                  sprintf(scratch, "shot (id %d) died (hit planet)", m->id);
                  log(scratch);
                  #endif
               }
            }

            for(pl2 = 0; pl2 < conf.maxPlayers; ++pl2)
            {
               if(!players[pl2].live) continue;
               l = distance(players[pl2].position, m->position);

               if (  (l <= conf.playerSize)
                  && (m->leftSource == 1)
                  )
               {
                  playerHit(pl, pl2);
                  m->live = 0;
                  m->diedAt = fractTs;
                  m->dirty |= DIRTY_LIVE;
                  #if SHOT_LOG
                  sprintf(scratch, "shot (id %d) died (hit player)", m->id);
                  log(scratch);
                  #endif
               }

               if (  (l > (conf.playerSize + 1.0))
                  && (pl2 == pl)
                  )
               {
                  m->leftSource = 1;
               }
            }
         }
         if(!m->live) continue;
         m->age++;
         if(m->age >= conf.maxSegments)
         {
            m->live = 0;
            m->diedAt = fractTs;
            m->dirty |= DIRTY_LIVE;
            #if SHOT_LOG
            sprintf(scratch, "shot (id %d) died (old age)", m->id);
            log(scratch);
            #endif
         }
         if(length(m->position) >= 1e4)
         {
            m->live = 0;
            m->diedAt = fractTs;
            m->dirty |= DIRTY_LIVE;
            #if SHOT_LOG
            sprintf(scratch, "shot (id %d) died (out of bounds)", m->id);
            log(scratch);
            #endif
         }
      }
   }
}

void initSimulation(void)
{
   int mi, pl;
   
   planets = malloc(conf.numPlanets * sizeof(Planet));
   initPlanets();
   players = malloc(conf.maxPlayers * sizeof(Player));
   for(pl = 0; pl < conf.maxPlayers; ++pl)
   {
      Player* p = &(players[pl]);
      p->missiles = malloc(conf.numShots * sizeof(Missile));
      for(mi = 0; mi < conf.numShots; ++mi)
      {
         Missile* m = &(p->missiles[mi]);
         m->live = 0;
         m->dirty = 0;
      }
      p->live = 0;
      p->name[15] = 0;
   }
}

void playerJoin(int pl)
{
   Player* p = &(players[pl]);
   initPlayer(p);

   p->deaths = 0;
   p->kills = 0;
   p->currentMissile = 0;
   p->live = 1;
   strncpy(p->name, "Anonymous", 15);
   p->dirty |= DIRTY_NAME | DIRTY_DATA | DIRTY_LIVE;
}

void playerLeave(int pl)
{
   Player* p = &(players[pl]);
   p->live = 0;
   p->dirty |= DIRTY_LIVE;
   for(int mi = 0; mi < conf.numShots; ++mi)
   {
      Missile* m = &(p->missiles[mi]);
      m->live = 0;
      m->dirty = 0;
   }
}

void playerShoot(int pl, double yaw, double pitch, double speed)
{
   Player* p = &(players[pl]);
   p->currentMissile = (p->currentMissile + 1) % conf.numShots;
   Missile* m = &(p->missiles[p->currentMissile]);

   #if SHOT_LOG
   sprintf(scratch, "shot (id %d) (player %d): %13.8lf, %13.8lf, %13.8lf", mid, pl, yaw, pitch, speed);
   log(scratch);
   #endif

   m->id = mid++;
   m->position = p->position;
   m->velocity.x = speed * cos(yaw / 180.0 * M_PI) * cos(pitch / 180.0 * M_PI);
   m->velocity.y = speed * sin(pitch / 180.0 * M_PI);
   m->velocity.z = speed * sin(yaw / 180.0 * M_PI) * cos(pitch / 180.0 * M_PI);
   m->acceleration = acc(m->position);
   m->live = 1;
   m->leftSource = 0;
   m->age = 0;
   m->dirty = DIRTY_LIVE | DIRTY_POS;

   int nextM = (p->currentMissile + 1) % conf.numShots;
   m = &(p->missiles[nextM]);
   if(m->live)
   {
      m->live = 0;
      m->dirty = DIRTY_LIVE;
      #if SHOT_LOG
      sprintf(scratch, "shot (id %d) died (superceded)", m->id);
      log(scratch);
      #endif
   }
}

void playerName(int pl, char* n)
{
   Player* p = &(players[pl]);
   strncpy(p->name, n, 15);
   p->dirty = DIRTY_NAME;
}

Missile* getMissile(int p, int s)
{
   return &(players[p].missiles[((players[p].currentMissile + conf.numShots - s) % conf.numShots)]);
}

Planet* getPlanet(int i)
{
   return &(planets[i]);
}

Player* getPlayer(int p)
{
   return &(players[p]);
}
