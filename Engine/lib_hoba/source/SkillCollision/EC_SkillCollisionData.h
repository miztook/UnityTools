#ifndef _EC_SkillCollisionData_H_
#define _EC_SkillCollisionData_H_

struct PERFORM_DATA
{
	int target_affect_obj;				// 碰撞类型
	float target_affect_radius;			// 碰撞半径 （对于矩形就是宽度）
	float target_affect_lenght;			// 碰撞长度
	float target_affect_angle;			// 扇形半张角
	int	direction;						// 当前collision发生的方向 0: 无方向(默认)  1: 从左向右  2:从右向左  3: 向后  4: 向前  5: 随机
};

struct COLLISION_INST
{
	PERFORM_DATA perform_data;		// 其他collision参数
};

#endif	//	_EC_SkillCollisionData_H_


