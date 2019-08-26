local DeviceLevel = 
{
    ios = 
    {
        -- 除此之外的都是低端机
        -- DeviceModel = Level
        -- A9 A9X
        ["iPhone8,1"]           = 2 ,       --iPhone 6s
        ["iPhone8,2"]           = 2 ,       --iPhone 6s Plus
        ["iPhone8,4"]           = 2 ,       --iPhone SE
        ["iPad6,7"]             = 2 ,         --iPad Pro (12.9-inch)
        ["iPad6,8"]             = 2 ,
        ["iPad6,3"]             = 2 ,         --iPad Pro (9.7-inch)
        ["iPad6,4"]             = 2 ,
        ["iPad6,11"]            = 2 ,        --iPad (5th generation)
        ["iPad6,12"]            = 2 ,
        ["iPad5,3"]             = 2,
        -- A10 A10X
        ["iPhone9,1"]           = 3 ,       --国行、日版、港行iPhone 7 (A1660/A1779/A1780)
        ["iPhone9,2"]           = 3 ,       --港行、国行iPhone 7 Plus (A1661/A1785/A1786)
        ["iPhone9,3"]           = 3 ,       --美版、台版iPhone 7 (A1778)
        ["iPhone9,4"]           = 3 ,       --美版、台版iPhone 7 Plus (A1784)
        ["iPad7,2"]             = 3 ,         --iPad Pro (12.9-inch) (2nd generation)
        ["iPad7,1"]             = 3 ,
        ["iPad7,3"]             = 3 ,         --iPad Pro (10.5-inch)
        ["iPad7,4"]             = 3 ,
        ["iPad7,5"]             = 3 ,         --iPad (6th generation)
        ["iPad7,6"]             = 3 ,         

        --处理器 A11之上
        ["iPhone10,1"]          = 4 ,      --国行(A1863)、日行(A1906)iPhone 8
        ["iPhone10,4"]          = 4 ,      --美版(Global/A1905)iPhone 8
        ["iPhone10,2"]          = 4 ,      --国行(A1864)、日行(A1898)iPhone 8 Plus
        ["iPhone10,5"]          = 4 ,      --美版(Global/A1897)iPhone 8 Plus
        ["iPhone10,3"]          = 4 ,      --国行(A1865)、日行(A1902)iPhone X
        ["iPhone10,6"]          = 4 ,      --美版(Global/A1901)iPhone X
        ["iPhone11,2"]          = 4 ,      --iPhone Xs
        ["iPhone11,4"]          = 4 ,      --iPhone Xs Max
        ["iPhone11,6"]          = 4 ,      --iPhone Xs Max
        ["iPhone11,8"]          = 4 ,      --iPhone Xʀ
        ["iPad8,1"]             = 4 ,         --iPad Pro (11-inch)
        ["iPad8,2"]             = 4 ,
        ["iPad8,3"]             = 4 ,
        ["iPad8,4"]             = 4 ,
        ["iPad8,5"]             = 4 ,         -- iPad Pro (12.9-inch) (3rd generation)
        ["iPad8,6"]             = 4 ,         
        ["iPad8,7"]             = 4 ,
        ["iPad8,8"]             = 4 ,

    },
    -- 机型名称是在官网上查询的ModelNumber （暂定 需要和真机测试时对比）
    android = 
    {
        --主频>2
        ["Xiaomi%pMI%p8"]       = 4, -- 小米8
        ["Xiaomi%pMI%p9"]       = 4, -- 小米9
        ["SM%pG960"]            = 4,      --Galaxy S9、Galaxy S9+
        ["SM%pN960"]            = 3,      --Galaxy Note 9
        ["SM%pG950"]            = 3,      --Galaxy S8
        ["SM%pG955"]            = 4,      --Galaxy S8 Plus
        ["SM%pN950"]            = 3,      --Galaxy Note 8
      
        -- ["F7 LG870"] = 4,   --LG Optimus G7

        ["SM%pN935"]            = 3,      --Galaxy Note FE
        ["SM%pJ700T1"]          = 3,    --GALAXY J7
        ["SM%pJ600G"]           = 3,     --Galaxy J6
        ["SM%pG935"]            = 3,     --Galaxy S7 Edge
        ["SM%pG930"]            = 3,     --Galaxy S7
        ["SM%pN930"]            = 3,      --Galaxy Note 7

        ["SM%pG920"]            = 2,      --Galaxy S6
        ["SM%pG925"]            = 2,      --Galaxy S6 Edge
        ["SM%pN920"]            = 2,      --Galaxy Note 5

        ["SHV%pE330"]           = 2,     --Galaxy S4
        ["SHV%pE210"]           = 2,     --Galaxy S3
        ["SHW%pM250"]           = 2,     --Galaxy S2
        ["SM%pG900"]            = 2,     --Galaxy S5
        ["SM%pJ700"]             = 2,     --Galaxy J7
        ["SM%pN900"]             = 2,     --Galaxy Note 3
        ["SM%pN910"]             = 2,     --Galaxy Note 4
        ["SM%pT230"]             = 2,     --Galaxy Note Tab 4
        -- 后续添加
        ["SM%pG920"]             = 2,      --Galaxy S6
        ["SM%pG973"]             = 4,      --Galaxy S10
        ["SM%pA9100"]            = 4,      --Galaxy A9 Pro
        ["SM%pG611L"]            = 2,      --Galaxy On7 Prime
        ["SM%pA530"]             = 3,      --Galaxy A8(2018)
        ["SM%pA810F"]            = 2,      --Galaxy A8(2016)
        ["SM%pN935S"]            = 2,      --Galaxy Note Fan Edition

        -- LG
        ["V405"]                = 4,     --LG Optimus V40
        ["LM%pV405"]            = 4,
        ["LM%pV409"]            = 4,
        ["V30%pH930"]           = 3,     --LG Optimus V30
        ["V30%pV300"]           = 3,   
        ["LM%pG710"]            = 4,     --G7

        ["V20%pF800"]           = 3,     --LG V20 
        ["V20%pH990"]           = 3,
        ["G600"]                = 3,     --LG G6
        ["G5%H840"]             = 2,     --LG G5

        ["V10%pF600"]           = 2,     --LG V10
        ["V10%pH968"]           = 2,
        -- 后续添加
        ["LG%pG7%pThinQ"]       = 3,
        ["LG%pH810"]             = 2,      --LG G4 
        ["LG%pH811"]             = 2 ,          --LG V10
        ["LM%pV500"]             = 3,     --LG V50 ThinQ


    },
 
}
return DeviceLevel