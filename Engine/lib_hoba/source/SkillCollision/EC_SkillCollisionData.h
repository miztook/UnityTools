#ifndef _EC_SkillCollisionData_H_
#define _EC_SkillCollisionData_H_

struct PERFORM_DATA
{
	int target_affect_obj;				// ��ײ����
	float target_affect_radius;			// ��ײ�뾶 �����ھ��ξ��ǿ�ȣ�
	float target_affect_lenght;			// ��ײ����
	float target_affect_angle;			// ���ΰ��Ž�
	int	direction;						// ��ǰcollision�����ķ��� 0: �޷���(Ĭ��)  1: ��������  2:��������  3: ���  4: ��ǰ  5: ���
};

struct COLLISION_INST
{
	PERFORM_DATA perform_data;		// ����collision����
};

#endif	//	_EC_SkillCollisionData_H_


