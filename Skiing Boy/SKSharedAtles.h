//
//  SKSharedAtles.h
//  SpriteKit
//
//  Created by Ray on 14-1-20.
//  Copyright (c) 2014年 CpSoft. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(int, SKTextureType) {
    SKTextureTypeBackground = 1,
    SKTextureTypeHero = 6,
    SKTextureTypeStone = 7,//石头
    SKTextureTypeCoin=10,//金币
    SKTextureTypeBean=11,//金豆
};

#define ZL_MAX_WALL_COUNT      6//墙块数目

@interface SKSharedAtles : SKTextureAtlas

+ (SKTexture *)textureWithType:(SKTextureType)type;

+ (SKAction *)playerAction;

+ (SKAction *)coinRotateAction;

@end
