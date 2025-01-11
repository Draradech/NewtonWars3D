#ifndef _VECTOR_H_
#define _VECTOR_H_

typedef struct
{
   double x;
   double y;
   double z;
} Vec3d;

Vec3d vsub(Vec3d v1, Vec3d v2);
Vec3d vadd(Vec3d v1, Vec3d v2);
Vec3d vmul(Vec3d v, double d);
Vec3d vdiv(Vec3d v, double d);
double length(Vec3d v);
double distance(Vec3d v1, Vec3d v2);

#endif /* _VECTOR_H_ */
