#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "config.h"

Config conf;

void help(void)
{
   printf("\n");
   printf("Usage: nw3d_server [OPTION VALUE] [OPTION VALUE] ...\n");
   printf("\n");
   printf("Valid options:\n");
   printf(" players       maximum number of players (default: 8)\n");
   printf(" planets       number of planets (default: 25)\n");
   printf(" shots         max number of live shots per player (default: 6)\n");
   printf(" playersize    radius of players (default: 4.0)\n");
/*
   printf(" rate          energy increase rate (default 2.0/s)\n");
   printf(" limit         energy limit (default 200.0)\n");
   printf(" roundtime     time limit per round in s (default 300)\n");
   printf(" extrapoints   selects the extrapoint mode (one out of: off, random, oldest, best\n) (default: best)");
   printf(" numdebris     number of debris particles on kill (default 10)\n");
   printf(" speeddebris   speed of debris particles (default 3.0)\n");
*/
}

void config(int* argc, char** argv)
{
   int i;
   char *b, *c;

   // changeable via cmd line
   conf.maxPlayers = 8;
   conf.numPlanets = 25;
   conf.numShots = 6 + 1;
   conf.playerSize = 5;
   conf.blockMultiCon = 0;
   conf.blockConTime = 0;
   conf.timeout = 0;
   conf.roundTime = 600;
   conf.roundPause = 30;

   //fixed
   conf.maxSegments = 2000;
   conf.segmentSteps = 25;
   conf.battlefieldRadius = 900;
   conf.battlefieldHeight = 500;
   conf.playerSpacing = 400;

   for(i = 1; i < *argc; ++i)
   {
      b = argv[i++];
      c = argv[i];

      if(!c)
      {
         help();
         exit(0);
      }

      if (*b == '-' || *b == '/') b++; /* allow -para and /para */
      if (*b == '-') b++; /* allow --para */

      if (strcmp(b, "players") == 0)
      {
         conf.maxPlayers = atoi(c);
         if(conf.maxPlayers > 16 || conf.maxPlayers < 1)
         {
            printf("players need to be between 1 and 16\n");
            exit(0);
         }
      }
      else if (strcmp(b, "planets") == 0)
      {
         conf.numPlanets = atoi(c);
         if(conf.numPlanets > 64 || conf.numPlanets < 1)
         {
            printf("planets need to be between 1 and 64\n");
            exit(0);
         }
      }
      else if (strcmp(b, "shots") == 0)
      {
         conf.numShots = atoi(c);
         if(conf.numShots > 64 || conf.numShots < 1)
         {
            printf("shots need to be between 1 and 64\n");
            exit(0);
         }
         conf.numShots++;
      }
      else if (strcmp(b, "playersize") == 0)
      {
         conf.playerSize = atof(c);
         if(conf.playerSize > 10 || conf.playerSize <= 0)
         {
            printf("playersize needs to be > 0.0 and <= 10.0\n");
            exit(0);
         }
      }
      /*
      else if (strcmp(b, "rate") == 0)
      {
         conf.rate = atof(c);
         if(conf.rate > 10.0 || conf.rate < 0.1)
         {
            printf("rate needs to be >= 0.1 and <= 10.0\n");
            exit(0);
         }
      }
      else if (strcmp(b, "limit") == 0)
      {
         conf.limit = atof(c);
         if(conf.limit > 10000.0 || conf.limit < 10.0)
         {
            printf("limit needs to be >= 0.0 and <= 10.0\n");
            exit(0);
         }
      }
      else if (strcmp(b, "roundtime") == 0)
      {
         conf.roundTime = atof(c);
         if(conf.roundTime > 3600 || conf.limit < 0)
         {
            printf("roundtime needs to be >= 0 and <= 3600\n");
            exit(0);
         }
      }
      else if ( (strcmp(b, "extrapoints") == 0) )
      {
          if( strcmp(c,"random") == 0 )
          {
             conf.extrapoints = CONFIG_EXTRAPOINTS_RANDOM;
          }
          else if( strcmp(c,"oldest") == 0 )
          {
             conf.extrapoints = CONFIG_EXTRAPOINTS_OLDEST;
          }
          else if( strcmp(c,"best") == 0 )
          {
             conf.extrapoints = CONFIG_EXTRAPOINTS_BEST;
          }
          else
          {
             conf.extrapoints = CONFIG_EXTRAPOINTS_OFF;
          }
      }
      */
      else if (  (strcmp(b, "h") == 0)
              || (strcmp(b, "help") == 0)
              || (strcmp(b, "?") == 0)
              )
      {
         help();
         exit(0);
      }
      else
      {
         printf("warning: nw ignored parameter %s %s\n", b, c);
      }
   }
}
