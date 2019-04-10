【技能数据参数】
event_type: 1 - GFX Event  2 - Animation Event  3 - Sound Event  4 - 判定事件  5 - 跳转事件  6 - 技能终止
trigger_type： 1 - 时间帧  2 - 循环帧  3 - 碰撞触发  4 - 按键触发  5 — 正常结束  6 - 异常结束
who_care:  1 - server  2 - client  3 - both

【技能处理流程】
1、cast skill，调用OnSkillStart
2、在OnSkillStart中启动第一个技能段，调用OnPerformStart()
3、在OnPerformStart中处理以下事情：
   (1)根据技能数据，添加各种event。时间帧相关的时间，添加Timer。碰撞触发事件、按键触发事件、正常结束触发事件和异常结束触发事件单独保存。
   (2)根据当前技能段的时间，添加Perform 结束Timer。
4、如果在Perform执行过程中有碰撞或者按键按下，执行第3步中记录的碰撞触发事件、按键触发事件。
5、当前Perform的Timer到期时，调用OnPerformEnd()
6、在OnPerformEnd中，处理3中记录的正常结束触发事件；此时需要关注正常结束触发事件有没有改变当前技能段序列执行顺序；如有改动，确定下一个Perform序号。如果未改动，检查当前技能段是否是最后一个技能段；如果是，结束技能，调用OnSkillEnd。如果不是，则将下一个Perform作为即将执行的Perform，调用该perform的OnPerformStart;
7、循环3-6。

【注意事项】
1、有些事件会影响技能段序列流程，比如跳转事件 技能终止事件。