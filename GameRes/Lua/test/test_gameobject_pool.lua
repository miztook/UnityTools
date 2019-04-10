-- 以Panel为例
-- 

-- 注册缓存池
local item_template = self._Panel:FindChild('Img_ChatBG/View_Chanel/Content/Frame_MainChat')
self._ItemPool = self._Panel:AddComponent(ClassType.GameObjectPool)   
self._ItemPool:Regist(item_template, 5)

-- 获得缓存池对象
local PlayerChatobj = self._ItemPool:Get()


-- 使用该对象


-- 回收该对象
self._ItemPool:Release(PlayerChatobj)