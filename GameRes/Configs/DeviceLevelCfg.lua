local DeviceLevel = 
{
    ios = 
    {
        -- 除此之外的都是低端机
        -- DeviceModel = Level
        -- A9 A9X
        ["iPhone8,1"] = 1 ,       --iPhone 6s
        ["iPhone8,2"] = 1 ,       --iPhone 6s Plus
        ["iPhone8,4"] = 1 ,       --iPhone SE
        ["iPad6,7"] = 1 ,         --iPad Pro (12.9-inch)
        ["iPad6,8"] = 1 ,
        ["iPad6,3"] = 1 ,         --iPad Pro (9.7-inch)
        ["iPad6,4"] = 1 ,
        ["iPad6,11"] = 1 ,        --iPad (5th generation)
        ["iPad6,12"] = 1 ,
        ["iPad5,3"] = 1,
        -- A10 A10X
        ["iPhone9,1"] = 2 ,       --国行、日版、港行iPhone 7 (A1660/A1779/A1780)
        ["iPhone9,2"] = 2 ,       --港行、国行iPhone 7 Plus (A1661/A1785/A1786)
        ["iPhone9,3"] = 2 ,       --美版、台版iPhone 7 (A1778)
        ["iPhone9,4"] = 2 ,       --美版、台版iPhone 7 Plus (A1784)
        ["iPad7,2"] = 2 ,         --iPad Pro (12.9-inch) (2nd generation)
        ["iPad7,1"] = 2 ,
        ["iPad7,3"] = 2 ,         --iPad Pro (10.5-inch)
        ["iPad7,4"] = 2 ,
        ["iPad7,5"] = 2 ,         --iPad (6th generation)
        ["iPad7,6"] = 2 ,         

        --处理器 A11之上
        ["iPhone10,1"] = 3 ,      --国行(A1863)、日行(A1906)iPhone 8
        ["iPhone10,4"] = 3 ,      --美版(Global/A1905)iPhone 8
        ["iPhone10,2"] = 3 ,      --国行(A1864)、日行(A1898)iPhone 8 Plus
        ["iPhone10,5"] = 3 ,      --美版(Global/A1897)iPhone 8 Plus
        ["iPhone10,3"] = 3 ,      --国行(A1865)、日行(A1902)iPhone X
        ["iPhone10,6"] = 3 ,      --美版(Global/A1901)iPhone X
        ["iPhone11,2"] = 3 ,      --iPhone Xs
        ["iPhone11,4"] = 3 ,      --iPhone Xs Max
        ["iPhone11,6"] = 3 ,      --iPhone Xs Max
        ["iPhone11,8"] = 3 ,      --iPhone Xʀ
        ["iPad8,1"] = 3 ,         --iPad Pro (11-inch)
        ["iPad8,2"] = 3 ,
        ["iPad8,3"] = 3 ,
        ["iPad8,4"] = 3 ,
        ["iPad8,5"] = 3 ,         -- iPad Pro (12.9-inch) (3rd generation)
        ["iPad8,6"] = 3 ,         
        ["iPad8,7"] = 3 ,
        ["iPad8,8"] = 3 ,

    },
    -- 机型名称是在官网上查询的ModelNumber （暂定 需要和真机测试时对比）
    android = 
    {
        --主频>2
        ["SM%pG960"] = 3,   --Galaxy S9、Galaxy S9+
        ["SM%pN960"] = 3,   --Galaxy Note 9
        ["SM%pG950"] = 3,   --Galaxy S8
        ["SM%pG955"] = 3,   --Galaxy S8 Plus
        ["SM%pN950"] = 3,   --Galaxy Note 8
        ["SM%pG930"] = 3,   --Galaxy S7
        ["SM%pG935"] = 3,   --Galaxy S7 Edge
        ["SM%pN930"] = 3,   --Galaxy Note 7

        ["SM%pJ700T1"] = 2, --GALAXY J7
        ["SM%pJ600G"] = 2,  -- Galaxy J6

        ["SM%pA720"] = 1,
    },
 
}
return DeviceLevel