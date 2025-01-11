#ifndef _NETWORK_H_
#define _NETWORK_H_

// server -> client
#define MSG_OWN_ID       1 // ts:f64 id:u32                         len: 16
#define MSG_PLAYER_POS   2 // ts:f64 id:u32 x:f32 y:f32 z:f32 r:f32 len: 32
#define MSG_PLANET_POS   3 // ts:f64 id:u32 x:f32 y:f32 z:f32 r:f32 len: 32
#define MSG_SHOT_POS     4 // ts:f64 id:u32 x:f32 y:f32 z:f32       len: 28
#define MSG_PLAYER_DEL   5 // ts:f64 id:u32                         len: 16
#define MSG_SHOT_FIN     6 // ts:f64 id:u32                         len: 16
#define MSG_SIM_TIME     7 // ts:f64                                len: 12
#define MSG_PLAYER_NAME  8 // ts:f64 id:u32 name:c8x16              len: 32
#define MSG_PLAYER_COLOR 9 // ts:f64 id:u32 rgbx:u8x4               len: 20


// client -> server

#define MSG_SET_NAME     50 // name:c8x16                            len: 20
#define MSG_SHOOT        51 // pitch:f64 yaw:f64 speed:f64           len: 28


void initNetwork(void);
void stepNetwork(double t, double delta);

#endif /* _NETWORK_H_ */
