#include <math.h>
#include "vector.h"

Vec3d vsub(Vec3d v1, Vec3d v2)
{
   Vec3d res;
   res.x = v1.x - v2.x;
   res.y = v1.y - v2.y;
   res.z = v1.z - v2.z;
   return res;
}

Vec3d vadd(Vec3d v1, Vec3d v2)
{
   Vec3d res;
   res.x = v1.x + v2.x;
   res.y = v1.y + v2.y;
   res.z = v1.z + v2.z;
   return res;
}

Vec3d vmul(Vec3d v, double d)
{
   Vec3d res;
   res.x = v.x * d;
   res.y = v.y * d;
   res.z = v.z * d;
   return res;
}

Vec3d vdiv(Vec3d v, double d)
{
   Vec3d res;
   res.x = v.x / d;
   res.y = v.y / d;
   res.z = v.z / d;
   return res;
}

double length(Vec3d v)
{
   return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

double distance(Vec3d v1, Vec3d v2)
{
   return length(vsub(v1, v2));
}
