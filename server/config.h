#ifndef _CONFIG_H_
#define _CONFIG_H_

typedef struct
{
   /* cmd */
   int maxPlayers;
   int numPlanets;
   int numShots;
   double playerSize;
   int blockMultiCon;
   int blockConTime;
   int timeout;
   /* fixed */
   int maxSegments;
   int segmentSteps;
   double battlefieldRadius;
   double battlefieldHeight;
   double playerSpacing;
} Config;

extern Config conf;

void config(int* argc, char** argv);

#endif /* _CONFIG_H_ */
