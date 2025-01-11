#include <stdlib.h>
#include <stdio.h>

#include "seconds.h"
#include "config.h"
#include "network.h"
#include "simulation.h"

int main(int argc, char** argv)
{
   srand(seconds());
   config(&argc, argv);

   initSimulation();
   initNetwork();

   double t = seconds();
   double delta = 1.0 / 60;
   for(;;)
   {
      double now = seconds();
      double remain = (t + delta) - now;
      wait(remain);
      t += delta;
      stepSimulation(t, delta);
      stepNetwork(t, delta);
   };

   return 0;
}
