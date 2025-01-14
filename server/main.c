#include <stdlib.h>
#include <stdio.h>

#include "seconds.h"
#include "config.h"
#include "network.h"
#include "simulation.h"

#define LOG_SYS "MAIN"
#include "log.h"

int main(int argc, char** argv)
{
   srand(seconds());
   config(&argc, argv);

   initSimulation();
   initNetwork();

   double t = seconds();
   double delta = 1.0 / 60;
   double alive = 0;
   for(;;)
   {
      double now = seconds();
      if(now - alive > 60)
      {
         log("alive");
         alive = now;
      }
      double remain = (t + delta) - now;
      if(remain > 0) wait(remain);
      t += delta;
      stepSimulation(t, delta);
      stepNetwork(t, delta);
   };

   return 0;
}
