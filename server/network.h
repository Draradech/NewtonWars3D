#ifndef _NETWORK_H_
#define _NETWORK_H_

// server -> client
#define MSG_SIM_TIME     1 // ts:f64                                       len: 12
#define MSG_OWN_ID       2 // pyid:u32                                     len: 8
#define MSG_PLAYER_POS   3 // pyid:u32 x:f32 y:f32 z:f32 r:f32             len: 24
#define MSG_PLAYER_DATA  4 // pyid:u32 score:f32                           len: 12
#define MSG_PLAYER_NAME  5 // pyid:u32 name:c8x16                          len: 24
#define MSG_PLAYER_DEL   6 // pyid:u32                                     len: 8
#define MSG_PLANET       7 // pnid:u32 x:f32 y:f32 z:f32 r:f32             len: 24
#define MSG_NEW_MISS     8 // pyid:u32 mid:u32                             len: 12
#define MSG_MISS_POS     9 // mid:u32 ts:f64 x:f32 y:f32 z:f32             len: 28
#define MSG_ROUND_TIME  10 // rt:i32                                       len: 8

// client -> server

#define MSG_SET_NAME    50 // name:c8x16                                   len: 20
#define MSG_SHOOT       51 // pitch:f64 yaw:f64 speed:f64                  len: 28

void initNetwork(void);
void stepNetwork(double t, double delta);

#endif /* _NETWORK_H_ */
