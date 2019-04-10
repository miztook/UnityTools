【功能定位说明】

1 CQuestAutoGather 自动采集
  - 仅用在寻路到矿物布置区域附近尾端调用，不于其他自动化有任何关联
  - 免去寻路到矿点后的手动操作
  - 只有开始Start关闭Stop，没有中断恢复

2 CAutoFightMan 自动化战斗
  -分两种类型
    CQuestAutoFight 
      -杀怪任务自动战斗
      -开始时通过任务信息获得 优先目标列表
    CWorldAutoFight 
      -非杀怪情况下的自动战斗，支持大世界非任务触发的自动战斗 + 副本目标自动战斗
      -副本目标切换时会刷新优先目标列表
  -提供开始Start 关闭Stop 中断Pause 恢复Restart
  -Start参数需要自动战斗类型

3 CQuestAutoMan 任务自动化
  -功能定位
      自动化任务串联，监听任务变化，然后根据任务DoShortcutExecute
        -CQuestNavigation.NavigatToMonster
          -CQuestAutoMan缓存自动战斗参数
          -到达目标点，找到对应怪物后 开启自动杀怪CQuestAutoFight
        -CQuestNavigation.NavigatToMine
          -CQuestAutoGather
  -提供开始Start 关闭Stop 中断Pause 恢复Restart
  -功能开启状态与主界面自动战斗UI表现保持一致

4 CDungeonAutoMan 副本自动化
  -功能定位
    自动副本串联，根据任务目标的变化，采取自动化的行为
      ObjType_Gather，自动采集 （采集逻辑生写）
      ObjType_ArriveRegion，自动移动到制定区域
      ObjType_KillMonster，走到对应区域后停下 （杀怪逻辑通过CAutoFightMan执行）
      ObjType_Conversation，自动TalkToServerNpc
  -提供开始Start 关闭Stop 中断Pause 恢复Restart
  -功能开启状态与主界面自动战斗UI表现保持一致



【☆☆☆☆☆☆☆☆☆☆☆☆重要警戒☆☆☆☆☆☆☆☆☆☆☆☆】

因为在逻辑中无法避免，自动化暂停中再次调用自动画的暂停与重启，
所以在实现中增加了引用计数；Pause 和 Restart 必须成对调用

BaseState变化非成对，单独处理


【=========================================================】



【行为触发时机】

[触发时机]          [自动任务]   [自动战斗]     [自动副本]     [备注信息]
√主角受控            Pause         Pause          Pause
√主动技能            Pause         ----           Pause
√打开书札            Pause         ----           Pause
√进入外观            Pause         Stop           Pause
√点地移动            Stop          Pause          Stop
√摇杆移动            Stop          Pause          Stop
×寻路移动            Stop          Pause          Stop       情形比较多，未确认
√进入变身            Stop          Stop           ----
√退出变身            Stop          Stop           ----
√触发教学            Stop          Stop           Stop
√触发 CG             Stop          Pause          Pause
√角色死亡            Stop          Stop           Stop
√进入跟随            Stop          Stop           Stop      
√Boss出场            ----          Pause          Pause
√确认匹配            Stop          Stop           ----       OnS2C3V3MatchResult
√任务更新            短暂延迟继续  ----           ----
√任务流程中断        Stop          Stop           ----       达到指定等级、进入副本、完成副本
√任务与副本目标切    Stop          Stop           Stop
√购买道具任务失败    Stop          Stop           ----
√退出跟随            ----          Stop           ----       通过跟随开启自动战斗时，退出跟随状态
√队长召唤跟随        ----          Stop           ----
√队长脱离战斗        ----          Stop           ----       队长脱离战斗时，服务器会将队员的自动战斗停掉 S2CTeamAutoFight

【其他处理】
1 同图传送，有黑屏过渡效果，效果开始前 暂停自动化，效果结束后，自动化重启
2 寻路移动指从UI触发的寻路，包括
  -CPanelMap.OnPointerClick
  -CPanelWorldBoss.OnClick Btn_FindBoss
  -CPanelUIWorldBossTips.OnClick Btn_FindBoss
  -从工会建筑页进入公会基地？？？？
  -使用NPC传送服务？？？？
  -使用传送道具 ？？？