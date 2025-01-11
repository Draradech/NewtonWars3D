#ifndef _SIMULATION_H_
#define _SIMULATION_H_

#include "vector.h"

typedef struct
{
   Vec3d position;
   Vec3d velocity;
   Vec3d acceleration;
   double diedAt;
   int live;
   int leftSource;
   int age;
   int id;
   int dirty;
} Missile;

typedef struct
{
   Vec3d position;
   Missile* missiles;
   char name[16];
   int live;
   int deaths;
   int kills;
   int currentMissile;
   int dirty;
} Player;

typedef struct
{
   Vec3d position;
   double radius;
   double mass;
   int dirty;
} Planet;

void playerJoin(int p);
void playerLeave(int p);
void playerShoot(int p, double yaw, double pitch, double speed);
void playerName(int p, char* n);

Missile* getMissile(int p, int s);
Planet* getPlanet(int p);
Player* getPlayer(int p);

void initSimulation(void);
void stepSimulation(double t, double delta);

#endif /* _SIMULATION_H_ */
