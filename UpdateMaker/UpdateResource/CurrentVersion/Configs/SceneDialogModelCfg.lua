--对话ImageModel的参数 
local IMDialogParam = 
    {
        --默认数据 
        ["default"] = 
        { 
            --左侧数据 
            [1]={Size = 1,RotY=160,PosX=-0.2,PosY=-1.45},
            --右侧数据 
            [2]={Size=1,RotY=-160,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/tanikenanminnv/tanikenanminnv.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.25,PosY=-1.475},
            [2] = {Size=0.6,RotY=-160,PosX=0.225,PosY=-1.475},
        },
        ["Assets/Outputs/Characters/NPCs/Guanyuan/guanyuan.prefab"] = 
        { 
            [1] = {Size=0.625,RotY=155,PosX=-0.2,PosY=-1.45},
            [2] = {Size=0.625,RotY=-160,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanmin/tanikenanmin.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=-160,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijun/shoubeijun.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.15,PosY=-1.5},
            [2] = {Size=0.6,RotY=-155,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Banyungonglaoren/banyungonglaoren.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.125,PosY=-1.425},
            [2] = {Size=0.6,RotY=205,PosX=0.2,PosY=-1.425},
        },
        ["Assets/Outputs/Characters/NPCs/Renleinvhai/renleinvhai.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=160,PosX=-0.25,PosY=-1},
            [2] = {Size=0.5,RotY=-155,PosX=0.2,PosY=-1},
        },
        ["Assets/Outputs/Characters/NPCs/xinbulaien/xinbulaien.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=-205,PosX=-0.15,PosY=-1.625},
            [2] = {Size=0.6,RotY=200,PosX=0.15,PosY=-1.625},
        },
        ["Assets/Outputs/Characters/NPCs/DIbo02/dibo02.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=140,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=190,PosX=0.1,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Qianchengzhe/qianchengzhe.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=210,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Tiejiang/tiejiang.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=205,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Qiaonasen/qiaonasen.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=145,PosX=-0.025,PosY=-1.525},
            [2] = {Size=0.6,RotY=-160,PosX=0.15,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/Ailisha/ailisha.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=160,PosX=-0.125,PosY=-1.53},
            [2] = {Size=0.575,RotY=-150,PosX=0.065,PosY=-1.53},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo/dibo.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=140,PosX=-0.2,PosY=-1.45},
            [2] = {Size=0.575,RotY=-175,PosX=0.225,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/jinglingyouxia_jinzhan/jinglingyouxia_jinzhan.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo01/dibo01.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=170,PosX=-0.25,PosY=-1.45},
            [2] = {Size=0.575,RotY=-145,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/renleinvguizu/renleinvguizu.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=160,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.55,RotY=-155,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/nuli/nuli.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.3,PosY=-1.4},
            [2] = {Size=0.6,RotY=210,PosX=0.2,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/Boss/Kulashouling/kulashouling.prefab"] = 
        { 
            [1] = {Size=3,RotY=-195,PosX=-1.5,PosY=-1.6},
            [2] = {Size=3,RotY=195,PosX=1.5,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/Shangren/shangren.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=155,PosX=-0.2,PosY=-1.45},
            [2] = {Size=0.55,RotY=200,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/xinbulaien_run/xinbulaien_run.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=-205,PosX=-0.15,PosY=-1.625},
            [2] = {Size=0.6,RotY=200,PosX=0.15,PosY=-1.625},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingguizu/jinglingguizu.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=155,PosX=-0.2,PosY=-1.53},
            [2] = {Size=0.55,RotY=-155,PosX=0.2,PosY=-1.53},
        },
        ["Assets/Outputs/Characters/NPCs/guanyuan01/guanyuan01.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.15,PosY=-1.45},
            [2] = {Size=0.6,RotY=-155,PosX=0.15,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijunduizhang/shoubeijunduizhang.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.175,PosY=-1.6},
            [2] = {Size=0.6,RotY=-155,PosX=0.175,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/haowanggangshibing/haowanggangshibing.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.1,PosY=-1.5},
            [2] = {Size=0.6,RotY=-155,PosX=0.175,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/Monsters/Shanghuibaobiao/shanghuibaobiao.prefab"] = 
        { 
            [1] = {Size=1.1,RotY=145,PosX=-0.2,PosY=-1.75},
            [2] = {Size=1.1,RotY=210,PosX=0.3,PosY=-1.75},
        },
        ["Assets/Outputs/Characters/NPCs/Fumoshi/fumoshi.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=160,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.575,RotY=-162.5,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Mitela/mitela.prefab"] = 
        { 
            [1] = {Size=0.7,RotY=165,PosX=-0.25,PosY=-1.1},
            [2] = {Size=0.7,RotY=-160,PosX=0.25,PosY=-1.1},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanminzhandou/tanikenanminzhandou.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.525},
            [2] = {Size=0.6,RotY=-160,PosX=0.2,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/nulizhandou/nulizhandou.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.3,PosY=-1.4},
            [2] = {Size=0.6,RotY=-160,PosX=0.15,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/Boss/Shamoer/shamoer.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=145,PosX=-0.15,PosY=-1.45},
            [2] = {Size=0.6,RotY=-160,PosX=0.225,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Shamoer2/shamoer2.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.1,PosY=-1.45},
            [2] = {Size=0.6,RotY=-160,PosX=0.25,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/Monsters/Diguojiandoushi/diguojiandoushi.prefab"] = 
        { 
            [1] = {Size=0.7,RotY=155,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.7,RotY=205,PosX=0.175,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/Boss/Xuejishi/xuejishi.prefab"] = 
        { 
            [1] = {Size=0.9,RotY=160,PosX=-0.2,PosY=-2.35},
            [2] = {Size=0.9,RotY=210,PosX=0.2,PosY=-2.35},
        },
        ["Assets/Outputs/Characters/NPCs/telien_normal/telien_normal.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.15,PosY=-1.65},
            [2] = {Size=0.6,RotY=-150,PosX=0.15,PosY=-1.65},
        },
        ["Assets/Outputs/Characters/NPCs/Guanyuan_yasong/guanyuan_yasong.prefab"] = 
        { 
            [1] = {Size=0.625,RotY=155,PosX=-0.2,PosY=-1.45},
            [2] = {Size=0.625,RotY=-160,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/Monsters/Defazhanshi/defazhanshi.prefab"] = 
        { 
            [1] = {Size=0.7,RotY=150,PosX=-0.2,PosY=-1.3},
            [2] = {Size=0.7,RotY=195,PosX=0.2,PosY=-1.3},
        },
        ["Assets/Outputs/Characters/Monsters/Diguoqiangqishi/diguoqiangqishi.prefab"] = 
        { 
            [1] = {Size=1,RotY=150,PosX=-0.2,PosY=-2.05},
            [2] = {Size=1,RotY=185,PosX=0.2,PosY=-2.05},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijun01/shoubeijun01.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=165,PosX=-0.2,PosY=-0.6},
            [2] = {Size=0.5,RotY=-155,PosX=0.15,PosY=-0.6},
        },
        ["Assets/Outputs/Characters/Monsters/kannongmasha/kannongmasha.prefab"] = 
        { 
            [1] = {Size=0.65,RotY=130,PosX=-0.15,PosY=-1.55},
            [2] = {Size=0.65,RotY=180,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Hunjisi/hunjisi.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.25,PosY=-1.375},
            [2] = {Size=0.6,RotY=-150,PosX=0.2,PosY=-1.375},
        },
        ["Assets/Outputs/Characters/Monsters/Diguoheifashi/diguoheifashi.prefab"] = 
        { 
            [1] = {Size=0.7,RotY=160,PosX=-0.15,PosY=-1.5},
            [2] = {Size=0.7,RotY=205,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Mushi/mushi.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.175,PosY=-1.55},
            [2] = {Size=0.6,RotY=-160,PosX=0.175,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Teleituo/teleituo.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.625},
            [2] = {Size=0.6,RotY=-160,PosX=0.2,PosY=-1.625},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanmin4/tanikenanmin4.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.18,PosY=-1.575},
            [2] = {Size=0.6,RotY=-165,PosX=0.18,PosY=-1.575},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanmin3/tanikenanmin3.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.575},
            [2] = {Size=0.6,RotY=-165,PosX=0.2,PosY=-1.575},
        },
        ["Assets/Outputs/Characters/NPCs/Beikelihuashen/beikelihuashen_eye.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=167.5,PosX=-0.2,PosY=-1.525},
            [2] = {Size=0.575,RotY=215,PosX=0.2,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/Balakaxuezhedelinghun/balakaxuezhedelinghun.prefab"] = 
        { 
            [1] = {Size=1,RotY=150,PosX=-0.25,PosY=-1.65},
            [2] = {Size=1,RotY=-130,PosX=0.25,PosY=-1.65},
        },
        ["Assets/Outputs/Characters/NPCs/Ailin3/ailin3.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=-200,PosX=-0.15,PosY=-1.125},
            [2] = {Size=0.6,RotY=195,PosX=0.15,PosY=-1.125},
        },
        ["Assets/Outputs/Characters/NPCs/Ailin1/ailin1.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=160,PosX=-0.2,PosY=-1.15},
            [2] = {Size=0.55,RotY=-150,PosX=0.125,PosY=-1.15},
        },
        ["Assets/Outputs/Characters/NPCs/Ailin2/ailin2.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.15},
            [2] = {Size=0.6,RotY=-155,PosX=0.15,PosY=-1.15},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijunduizhang01/shoubeijunduizhang01.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.1,PosY=-1.6},
            [2] = {Size=0.6,RotY=-155,PosX=0.1,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/guanyuan02/guanyuan02.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.15,PosY=-1.45},
            [2] = {Size=0.6,RotY=-155,PosX=0.15,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/Monsters/Babahuokaren/babahuokaren.prefab"] = 
        { 
            [1] = {Size=0.8,RotY=145,PosX=-0.3,PosY=-0.8},
            [2] = {Size=0.8,RotY=200,PosX=0.2,PosY=-0.8},
        },
        ["Assets/Outputs/Characters/Monsters/Chuizihuokacuncunzhanglulukajin/chuizihuokacuncunzhanglulukajin.prefab"] = 
        { 
            [1] = {Size=1,RotY=165,PosX=-0.3,PosY=-1.8},
            [2] = {Size=1,RotY=200,PosX=0.3,PosY=-1.8},
        },
        ["Assets/Outputs/Characters/Monsters/Chuizihuokaren/chuizihuokaren.prefab"] = 
        { 
            [1] = {Size=0.8,RotY=160,PosX=-0.25,PosY=-0.675},
            [2] = {Size=0.8,RotY=200,PosX=0.3,PosY=-0.675},
        },
        ["Assets/Outputs/Characters/Monsters/Xiaojingling/xiaojingling.prefab"] = 
        { 
            [1] = {Size=0.7,RotY=130,PosX=-0.2,PosY=-1.6},
            [2] = {Size=0.7,RotY=195,PosX=0.2,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/Lunaailin/lunaailin.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=160,PosX=-0.1,PosY=-1.125},
            [2] = {Size=0.5,RotY=-155,PosX=0.1,PosY=-1.125},
        },
        ["Assets/Outputs/Characters/Boss/Wennisha/wennisha.prefab"] = 
        { 
            [1] = {Size=0.525,RotY=150,PosX=-0.2,PosY=-1.4},
            [2] = {Size=0.525,RotY=-165,PosX=0.2,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/Monsters/Kuzhateshouweibing/kuzhateshouweibing.prefab"] = 
        { 
            [1] = {Size=1,RotY=140,PosX=-0.2,PosY=-1.5},
            [2] = {Size=1,RotY=210,PosX=0.3,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo/dibo_eye.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=140,PosX=-0.2,PosY=-1.45},
            [2] = {Size=0.575,RotY=-175,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/Boss/Wennisha/wennisha_eye.prefab"] = 
        { 
            [1] = {Size=0.85,RotY=-200,PosX=-0.5,PosY=-1.2},
            [2] = {Size=0.85,RotY=200,PosX=0.5,PosY=-1.2},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingguizu/jinglingguizu_eye.prefab"] = 
        { 
            [1] = {Size=0.85,RotY=155,PosX=0.1,PosY=-1.4},
            [2] = {Size=0.85,RotY=-155,PosX=-0.1,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/Monsters/Defaguizu/defaguizu.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=145,PosX=-0.05,PosY=-1.45},
            [2] = {Size=0.55,RotY=190,PosX=0.15,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Nanjuefuren/nanjuefuren.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=160,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.55,RotY=-160,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/Monsters/Xikandazhujiao/xikandazhujiao.prefab"] = 
        { 
            [1] = {Size=1.35,RotY=150,PosX=-0.4,PosY=-2.4},
            [2] = {Size=1.35,RotY=200,PosX=0.2,PosY=-2.4},
        },
        ["Assets/Outputs/Characters/Monsters/Xikanweibing/xikanweibing2.prefab"] = 
        { 
            [1] = {Size=1.8,RotY=170,PosX=-0.75,PosY=-1.5},
            [2] = {Size=1.8,RotY=-170,PosX=0.75,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/xikanpingmin/xikanpingmin.prefab"] = 
        { 
            [1] = {Size=0.65,RotY=-200,PosX=-0.175,PosY=-1.7},
            [2] = {Size=0.65,RotY=200,PosX=0.175,PosY=-1.7},
        },
        ["Assets/Outputs/Characters/NPCs/Nigulasi/nigulasi.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=150,PosX=-0.225,PosY=-1.425},
            [2] = {Size=0.575,RotY=195,PosX=0.1,PosY=-1.425},
        },
        ["Assets/Outputs/Characters/NPCs/yeying/yeying.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=-205,PosX=-0.15,PosY=-1.4},
            [2] = {Size=0.55,RotY=205,PosX=0.15,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/talannanjue/talannanjue.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.075,PosY=-1.6},
            [2] = {Size=0.6,RotY=-160,PosX=0.1,PosY=-1.65},
        },
        ["Assets/Outputs/Characters/Monsters/Annongqiuzhang2/annongqiuzhang2.prefab"] = 
        { 
            [1] = {Size=1,RotY=155,PosX=-0.2,PosY=-2.4},
            [2] = {Size=1,RotY=190,PosX=0.1,PosY=-2.4},
        },
        ["Assets/Outputs/Characters/Monsters/Annongqiuzhang1/annongqiuzhang1.prefab"] = 
        { 
            [1] = {Size=1,RotY=150,PosX=-0.2,PosY=-2.3},
            [2] = {Size=1,RotY=190,PosX=0.1,PosY=-2.3},
        },
        ["Assets/Outputs/Characters/NPCs/Annongyongshi/annongyongshi.prefab"] = 
        { 
            [1] = {Size=1.5,RotY=150,PosX=-0.15,PosY=-2.5},
            [2] = {Size=1.5,RotY=-150,PosX=0.3,PosY=-2.5},
        },
        ["Assets/Outputs/Characters/Monsters/Annongjisi/annongjisi.prefab"] = 
        { 
            [1] = {Size=1.05,RotY=160,PosX=-0.6,PosY=-1.5},
            [2] = {Size=1.05,RotY=-160,PosX=0.6,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/guanyuan/guanyuan.prefab"] = 
        { 
            [1] = {Size=1,RotY=150,PosX=0.125,PosY=-1.4},
            [2] = {Size=1,RotY=-150,PosX=-0.125,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/ailien/ailien.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.525},
            [2] = {Size=0.6,RotY=-160,PosX=0.15,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/Ailin4/ailin4.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.175,PosY=-1.15},
            [2] = {Size=0.6,RotY=-160,PosX=0.175,PosY=-1.15},
        },
        ["Assets/Outputs/Characters/NPCs/Beikelihuashen/beikelihuashen.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=167.5,PosX=-0.2,PosY=-1.525},
            [2] = {Size=0.575,RotY=-150,PosX=0.2,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/boboli1/boboli1.prefab"] = 
        { 
            [1] = {Size=0.8,RotY=155,PosX=-0.2,PosY=-1},
            [2] = {Size=0.8,RotY=-155,PosX=0.2,PosY=-1},
        },
        ["Assets/Outputs/Characters/NPCs/boboli2/boboli2.prefab"] = 
        { 
            [1] = {Size=0.8,RotY=160,PosX=-0.2,PosY=-1},
            [2] = {Size=0.8,RotY=-155,PosX=0.2,PosY=-1},
        },
        ["Assets/Outputs/Characters/NPCs/boboli3/boboli3.prefab"] = 
        { 
            [1] = {Size=0.8,RotY=155,PosX=-0.2,PosY=-1},
            [2] = {Size=0.8,RotY=-155,PosX=0.2,PosY=-1},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo/Dibo.prefab"] = 
        { 
            [1] = {Size=1,RotY=145,PosX=0.03,PosY=-1.38},
            [2] = {Size=1,RotY=-145,PosX=-0.03,PosY=-1.38},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo01/Dibo01.prefab"] = 
        { 
            [1] = {Size=1,RotY=180,PosX=0.03,PosY=-1.35},
            [2] = {Size=1,RotY=-180,PosX=-0.03,PosY=-1.35},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo02/Dibo02.prefab"] = 
        { 
            [1] = {Size=1,RotY=135,PosX=0.02,PosY=-1.425},
            [2] = {Size=1,RotY=-135,PosX=-0.02,PosY=-1.425},
        },
        ["Assets/Outputs/Characters/NPCs/famugong/famugong.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=145,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=-160,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Fumoshi/Fumoshi.prefab"] = 
        { 
            [1] = {Size=0.85,RotY=165,PosX=0.1,PosY=-1.45},
            [2] = {Size=0.85,RotY=-165,PosX=-0.1,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/gongguoshibing/gongguoshibing.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.1,PosY=-1.48},
            [2] = {Size=0.6,RotY=-160,PosX=0.25,PosY=-1.48},
        },
        ["Assets/Outputs/Characters/NPCs/gonghuiguanliyuan/gonghuiguanliyuan.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.22,PosY=-1.4},
            [2] = {Size=0.6,RotY=-160,PosX=0.22,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/Guanyuan_yasong/Guanyuan_yasong.prefab"] = 
        { 
            [1] = {Size=1,RotY=160,PosX=0.1,PosY=-1.4},
            [2] = {Size=1,RotY=-160,PosX=-0.1,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo02/dibo02.prefab"] = 
        { 
            [1] = {Size=1,RotY=150,PosX=-0.25,PosY=-1.45},
            [2] = {Size=1,RotY=-150,PosX=0.25,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/jinglingmodaoshi/jinglingmodaoshi.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=-160,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/jinglingyouxia_yuancheng/jinglingyouxia_yuancheng.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=195,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Kataya/kataya.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=150,PosX=-0.18,PosY=-1.3},
            [2] = {Size=0.5,RotY=-165,PosX=0.2,PosY=-1.3},
        },
        ["Assets/Outputs/Characters/NPCs/Kataya/kataya02.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=155,PosX=-0.2,PosY=-1.3},
            [2] = {Size=0.55,RotY=200,PosX=0.2,PosY=-1.3},
        },
        ["Assets/Outputs/Characters/NPCs/kuanggong/kuanggong.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=-155,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Kusa/kusa.prefab"] = 
        { 
            [1] = {Size=0.85,RotY=155,PosX=-0.05,PosY=-1.8},
            [2] = {Size=0.85,RotY=-150,PosX=0.025,PosY=-1.8},
        },
        ["Assets/Outputs/Characters/NPCs/lianmengjunduizhang/lianmengjunduizhang.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.15,PosY=-1.6},
            [2] = {Size=0.6,RotY=-150,PosX=0.15,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/lieren/lieren.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.175,PosY=-1.55},
            [2] = {Size=0.6,RotY=-155,PosX=0.175,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/nuli2/nuli2.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.3,PosY=-1.4},
            [2] = {Size=0.6,RotY=205,PosX=0.15,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/nuli3/nuli3.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.3,PosY=-1.4},
            [2] = {Size=0.6,RotY=205,PosX=0.15,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/nulizhandou2/nulizhandou02.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.3,PosY=-1.4},
            [2] = {Size=0.6,RotY=205,PosX=0.15,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/nulizhandou3/nulizhandou3.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.3,PosY=-1.4},
            [2] = {Size=0.6,RotY=205,PosX=0.15,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/renleinanpingmin/renleinanpingmin.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=145,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=-160,PosX=0.15,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/renleishiminnan/renleishiminnan.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=-160,PosX=0.125,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/shibiannanjue/shibiannanjue.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.1,PosY=-1.6},
            [2] = {Size=0.6,RotY=-160,PosX=0.1,PosY=-1.65},
        },
        ["Assets/Outputs/Characters/NPCs/shinv/shinv.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=155,PosX=-0.2,PosY=-1.45},
            [2] = {Size=0.55,RotY=-155,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijunduizhang01_zhandou/shoubeijunduizhang01_zhandou.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=0,PosY=-1.45},
            [2] = {Size=0.6,RotY=-165,PosX=0.15,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijunduizhang02/shoubeijunduizhang02.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.1,PosY=-1.65},
            [2] = {Size=0.6,RotY=-160,PosX=0.1,PosY=-1.65},
        },
        ["Assets/Outputs/Characters/NPCs/tanikenanmin2/tanikenanmin2.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.175,PosY=-1.55},
            [2] = {Size=0.6,RotY=-160,PosX=0.175,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanminzhandou2/tanikenanminzhandou2.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.525},
            [2] = {Size=0.6,RotY=-160,PosX=0.2,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/tanikenvhai/tanikenvhai.prefab"] = 
        { 
            [1] = {Size=0.45,RotY=160,PosX=-0.15,PosY=-1},
            [2] = {Size=0.45,RotY=-160,PosX=0.175,PosY=-1},
        },
        ["Assets/Outputs/Characters/NPCs/yuanzhengshibing/yuanzhengshibing.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=0,PosY=-1.55},
            [2] = {Size=0.6,RotY=-155,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/telien_fast/telien_fast.prefab"] = 
        { 
            [1] = {Size=1,RotY=160,PosX=0,PosY=-1.45},
            [2] = {Size=1,RotY=-160,PosX=0,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Fuleitiya/fuleitiya.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=160,PosX=-0.2,PosY=-1.525},
            [2] = {Size=0.575,RotY=-155,PosX=0.2,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/chuizijisi/chuizijisi.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=145,PosX=-0.2,PosY=-0.7},
            [2] = {Size=0.6,RotY=-160,PosX=0.2,PosY=-0.7},
        },
        ["Assets/Outputs/Characters/NPCs/balakaxuezhe/balakaxuezhe.prefab"] = 
        { 
            [1] = {Size=1,RotY=160,PosX=-0.2,PosY=-1.625},
            [2] = {Size=1,RotY=225,PosX=0.01,PosY=-1.625},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingfashi/jinglingfashi.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=150,PosX=-0.2,PosY=-1.54},
            [2] = {Size=0.575,RotY=-160,PosX=0.2,PosY=-1.54},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingfurennv/jinglingfurennv.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=150,PosX=-0.2,PosY=-1.53},
            [2] = {Size=0.55,RotY=205,PosX=0.175,PosY=-1.53},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingjun_jinzhan/jinglingjun_jinzhan.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/jinglingjun_jinzhan/jinglingjun_jinzhan.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/jinglingjun_yuancheng/jinglingjun_yuancheng.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingnanzi/Jinglingnanzi.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingnanzi/jinglingnanzi.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingnvhai/jinglingnvhai.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=155,PosX=-0.3,PosY=-1},
            [2] = {Size=0.5,RotY=200,PosX=0.2,PosY=-1},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingnvpingmin/jinglingnvpingmin.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=155,PosX=-0.2,PosY=-1.54},
            [2] = {Size=0.55,RotY=205,PosX=0.2,PosY=-1.54},
        },
        ["Assets/Outputs/Characters/NPCs/Jinglingzahuoshang/jinglingzahuoshang.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=145,PosX=-0.2,PosY=-1.55},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/jinglingzhanglao_a/jinglingzhanglao_a.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.6},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/jinglingzhanglao_b/jinglingzhanglao_b.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.6},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/kaiyazhijian01/kaiyazhijian01.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/kaiyazhijian02/kaiyazhijian02.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=156,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Qiaonasen/qiaonasen_eye.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=0,PosY=-1.525},
            [2] = {Size=0.6,RotY=205,PosX=0.1,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/tanikefujianv/tanikefujianv.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=160,PosX=-0.225,PosY=-1.5},
            [2] = {Size=0.55,RotY=205,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanminzhandou3/tanikenanminzhandou3.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.575},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.575},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanminzhandou4/tanikenanminzhandou4.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.575},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.575},
        },
        ["Assets/Outputs/Characters/NPCs/tanikepingminnv/tanikepingminnv.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=160,PosX=-0.225,PosY=-1.49},
            [2] = {Size=0.55,RotY=200,PosX=0.2,PosY=-1.49},
        },
        ["Assets/Outputs/Characters/NPCs/yuanzhengjunshibing/yuanzhengjunshibing.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=0,PosY=-1.5},
            [2] = {Size=0.6,RotY=200,PosX=0.15,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/Players/humwarrior_m.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.15,PosY=-1.5},
            [2] = {Size=0.6,RotY=200,PosX=0.15,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/Players/alipriest_f.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.1,PosY=-1.175},
            [2] = {Size=0.6,RotY=205,PosX=0.175,PosY=-1.175},
        },
        ["Assets/Outputs/Characters/Players/casassassin_m.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.175,PosY=-1.475},
            [2] = {Size=0.6,RotY=205,PosX=0.2,PosY=-1.475},
        },
        ["Assets/Outputs/Characters/Players/sprarcher_f.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=200,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/Players/alilancer_f.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.1,PosY=-1.175},
            [2] = {Size=0.6,RotY=205,PosX=0.175,PosY=-1.175},
        },
        ["Assets/Outputs/Characters/Monsters/Kemolaxia/kemolaxia.prefab"] = 
        { 
            [1] = {Size=1.1,RotY=145,PosX=-0.1,PosY=-1.8},
            [2] = {Size=1.1,RotY=210,PosX=0.5,PosY=-1.8},
        },
        ["Assets/Outputs/Characters/Monsters/Defaguizu/Defaguizu.prefab"] = 
        { 
            [1] = {Size=0.575,RotY=150,PosX=-0.2,PosY=-1.45},
            [2] = {Size=0.575,RotY=195,PosX=0.2,PosY=-1.45},
        },
        ["Assets/Outputs/Characters/NPCs/Kataya/kataya_eye.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=145,PosX=-0.2,PosY=-1.3},
            [2] = {Size=0.5,RotY=-160,PosX=0.2,PosY=-1.3},
        },
        ["Assets/Outputs/Characters/NPCs/weierailin/weierailin.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=150,PosX=-0.125,PosY=-1.15},
            [2] = {Size=0.5,RotY=-155,PosX=0.2,PosY=-1.15},
        },
        ["Assets/Outputs/Characters/Pets/pet_nainiuxiaozhu/pet_nainiuxiaozhu.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=150,PosX=-0.225,PosY=-0.35},
            [2] = {Size=0.5,RotY=-150,PosX=0.2,PosY=-0.35},
        },
        ["Assets/Outputs/Characters/Monsters/Fengzhiwuzhe/fengzhiwuzhe.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=150,PosX=-0.15,PosY=-1.6},
            [2] = {Size=0.5,RotY=-165,PosX=0.125,PosY=-1.6},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo/dibo.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=140,PosX=-0.15,PosY=-1.55},
            [2] = {Size=0.55,RotY=180,PosX=0.15,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/DIbo02/dibo02.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=140,PosX=-0.15,PosY=-1.55},
            [2] = {Size=0.55,RotY=180,PosX=0.15,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanmin/tanikenanmin.prefab bound_c"] = 
        { 
            [1] = {Size=0.55,RotY=140,PosX=-0.2,PosY=-0.625},
            [2] = {Size=0.55,RotY=220,PosX=0.2,PosY=-0.65},
        },
        ["Assets/Outputs/Characters/NPCs/DIbo02/dibo02.prefab stand01_c"] = 
        { 
            [1] = {Size=0.55,RotY=150,PosX=-0.2,PosY=-1.4},
            [2] = {Size=0.55,RotY=205,PosX=0.2,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijun/shoubeijun.prefab stand_battle_c"] = 
        { 
            [1] = {Size=0.65,RotY=145,PosX=0,PosY=-1.4},
            [2] = {Size=0.65,RotY=220,PosX=0.3,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo/dibo.prefab stand_battle_c"] = 
        { 
            [1] = {Size=0.575,RotY=175,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.575,RotY=220,PosX=0.15,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/haowanggangshibing/haowanggangshibing.prefab stand_battle_c"] = 
        { 
            [1] = {Size=0.65,RotY=145,PosX=0,PosY=-1.4},
            [2] = {Size=0.65,RotY=220,PosX=0.3,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijun/shoubeijun.prefab st_die_c"] = 
        { 
            [1] = {Size=0.75,RotY=150,PosX=0,PosY=-0.55},
            [2] = {Size=0.75,RotY=210,PosX=0.1,PosY=-0.55},
        },
        ["Assets/Outputs/Characters/NPCs/nuli/nuli.prefab sit_c"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.1,PosY=-0.6},
            [2] = {Size=0.6,RotY=210,PosX=-0.05,PosY=-0.6},
        },
        ["Assets/Outputs/Characters/NPCs/nuli/nuli.prefab st_cheers_c"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.1,PosY=-1.5},
            [2] = {Size=0.6,RotY=215,PosX=0.1,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/nuli2/nuli2.prefab st_cheers_c"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.1,PosY=-1.5},
            [2] = {Size=0.6,RotY=215,PosX=0.1,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanmin/tanikenanmin.prefab stand01_c"] = 
        { 
            [1] = {Size=0.6,RotY=140,PosX=-0.3,PosY=-1.15},
            [2] = {Size=0.6,RotY=200,PosX=0.4,PosY=-1.15},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijunduizhang01/shoubeijunduizhang01.prefab stand01_c"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.1,PosY=-1.3},
            [2] = {Size=0.6,RotY=210,PosX=0.3,PosY=-1.3},
        },
        ["Assets/Outputs/Characters/NPCs/Shamoer2/shamoer2.prefab stand01_c"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.15,PosY=-0.8},
            [2] = {Size=0.65,RotY=220,PosX=0.25,PosY=-0.8},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo/dibo.prefab tilibuzhia_b_c"] = 
        { 
            [1] = {Size=0.575,RotY=150,PosX=0,PosY=-0.65},
            [2] = {Size=0.575,RotY=220,PosX=0.4,PosY=-0.65},
        },
        ["Assets/Outputs/Characters/NPCs/nuli/nuli.prefab st_handclap_c"] = 
        { 
            [1] = {Size=0.65,RotY=150,PosX=-0.2,PosY=-1.525},
            [2] = {Size=0.65,RotY=210,PosX=0.2,PosY=-1.525},
        },
        ["Assets/Outputs/Characters/NPCs/Shamoer2/shamoer2.prefab stand02_c"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.2,PosY=-1.2},
            [2] = {Size=0.6,RotY=220,PosX=0.4,PosY=-1.2},
        },
        ["Assets/Outputs/Characters/NPCs/Dibo/dibo.prefab lean_c"] = 
        { 
            [1] = {Size=0.575,RotY=150,PosX=-0.15,PosY=-1.55},
            [2] = {Size=0.575,RotY=205,PosX=0.15,PosY=-1.55},
        },
        ["Assets/Outputs/Characters/Monsters/Kuzhatefashi/kuzhatefashi.prefab"] = 
        { 
            [1] = {Size=1.2,RotY=155,PosX=-0.1,PosY=-1.7},
            [2] = {Size=1.2,RotY=200,PosX=0.5,PosY=-1.7},
        },
        ["Assets/Outputs/Characters/Monsters/Haidao/haidao.prefab"] = 
        { 
            [1] = {Size=0.9,RotY=150,PosX=-0.075,PosY=-1.65},
            [2] = {Size=0.9,RotY=195,PosX=0.15,PosY=-1.65},
        },
        ["Assets/Outputs/Characters/Monsters/Kamayiqiuzhang/kamayiqiuzhang.prefab"] = 
        { 
            [1] = {Size=2,RotY=150,PosX=-0.1,PosY=-1.7},
            [2] = {Size=2,RotY=200,PosX=0.35,PosY=-1.7},
        },
        ["Assets/Outputs/Characters/Monsters/Kamayiyongzhe/kamayiyongzhe.prefab"] = 
        { 
            [1] = {Size=1.6,RotY=140,PosX=-0.25,PosY=-1.7},
            [2] = {Size=1.6,RotY=200,PosX=0.3,PosY=-1.7},
        },
        ["Assets/Outputs/Characters/NPCs/xianjizhe/xianjizhe.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.2,PosY=-1.5},
            [2] = {Size=0.6,RotY=210,PosX=0.2,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/fengzhijisishouling/fengzhijisishouling.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=155,PosX=-0.2,PosY=-1.53},
            [2] = {Size=0.55,RotY=195,PosX=0.1,PosY=-1.53},
        },
        ["Assets/Outputs/Characters/NPCs/talannanjue2/talannanjue2.prefab"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.075,PosY=-1.6},
            [2] = {Size=0.6,RotY=200,PosX=0.1,PosY=-1.65},
        },
        ["Assets/Outputs/Characters/Monsters/xikanlanni/xikanlanni.prefab"] = 
        { 
            [1] = {Size=1.35,RotY=150,PosX=-0.4,PosY=-2.4},
            [2] = {Size=1.35,RotY=200,PosX=0.2,PosY=-2.4},
        },
        ["Assets/Outputs/Characters/Monsters/xikanlannilaoshi/xikanlannilaoshi.prefab"] = 
        { 
            [1] = {Size=1.35,RotY=150,PosX=-0.4,PosY=-2.4},
            [2] = {Size=1.35,RotY=200,PosX=0.2,PosY=-2.4},
        },
        ["Assets/Outputs/Characters/NPCs/nulizhandou/nulizhandou.prefab stand_battle_c"] = 
        { 
            [1] = {Size=0.6,RotY=140,PosX=-0.15,PosY=-1},
            [2] = {Size=0.6,RotY=200,PosX=0.1,PosY=-1.1},
        },
        ["Assets/Outputs/Characters/NPCs/Tanikenanminzhandou4/tanikenanminzhandou4.prefab stand_battle_c"] = 
        { 
            [1] = {Size=0.6,RotY=155,PosX=-0.1,PosY=-1.4},
            [2] = {Size=0.6,RotY=185,PosX=0.2,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/Shoubeijun/shoubeijun.prefab stand01_c"] = 
        { 
            [1] = {Size=0.6,RotY=160,PosX=-0.25,PosY=-1.35},
            [2] = {Size=0.6,RotY=205,PosX=0.25,PosY=-1.35},
        },
        ["Assets/Outputs/Characters/NPCs/gongguoshibing/gongguoshibing.prefab stand_battle_c"] = 
        { 
            [1] = {Size=0.6,RotY=150,PosX=-0.025,PosY=-1.4},
            [2] = {Size=0.6,RotY=205,PosX=0.25,PosY=-1.4},
        },
        ["Assets/Outputs/Characters/NPCs/kanpasuo/kanpasuo.prefab"] = 
        { 
            [1] = {Size=0.55,RotY=150,PosX=-0.15,PosY=-1.5},
            [2] = {Size=0.55,RotY=205,PosX=0.15,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/Monsters/Fengzhijinglingshouling/fengzhijinglingshouling.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=150,PosX=-0.1,PosY=-1.5},
            [2] = {Size=0.5,RotY=195,PosX=0.1,PosY=-1.5},
        },
        ["Assets/Outputs/Characters/NPCs/sailien2/sailien2.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=150,PosX=-0.125,PosY=-1.575},
            [2] = {Size=0.5,RotY=190,PosX=0.1,PosY=-1.575},
        },
        ["Assets/Outputs/Characters/Monsters/Fengzhijisi/fengzhijisi.prefab"] = 
        { 
            [1] = {Size=0.5,RotY=150,PosX=-0.2,PosY=-1.425},
            [2] = {Size=0.5,RotY=190,PosX=0.05,PosY=-1.425},
        },
        ["Assets/Outputs/Characters/Monsters/Fangzhouxunchazhe/fangzhouxunchazhe.prefab"] = 
        { 
            [1] = {Size=1.25,RotY=155,PosX=-0.15,PosY=-2},
            [2] = {Size=1.25,RotY=195,PosX=0.15,PosY=-2},
        },
        ["Assets/Outputs/Characters/Monsters/Fangzhouxunchazhe2/fangzhouxunchazhe2.prefab"] = 
        { 
            [1] = {Size=1.25,RotY=155,PosX=-0.15,PosY=-2},
            [2] = {Size=1.25,RotY=195,PosX=0.15,PosY=-2},
        },
    }

function IMDialogParam.GetRawConfig(self, key1, key2)
    local item = IMDialogParam[key1]
    if item ~= nil then
        return item[key2]
    end
    return nil
end

function IMDialogParam.GetConfig(self, key1, key2)
    local item = self:GetRawConfig(key1, key2)
    if item == nil then
        item = IMDialogParam["default"]
        if item ~= nil then
            item = item[key2]
        end
    else
        --warn("<IMDialogParam>Cannot find "..key1..":"..key2)
    end
    return item
end

return IMDialogParam
