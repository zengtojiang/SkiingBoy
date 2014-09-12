//
//  ZLMainScene.h
//  SpriteKit
//
//  Created by Ray on 14-1-20.
//  Copyright (c) 2014年 CpSoft. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
/**
 
 具有物理特性的物品的锚地必须在中心
 方法1：把两个body连接在一起，bodyA的密度小于1，bodyB的密度大于1，并且bodyA不能受重力影响，让bodyB带着bodyA运动，连接的锚点在bodyB的中心
 方法2：把两个body连接在一起，给bodyB施加作用力，带动bodyA运动，连接的锚点在bodyB上
 */
@interface ZLMainScene : SKScene<SKPhysicsContactDelegate>{
    
    //位置
    int             _curPositionIndex;
    
    NSTimeInterval  _lastTimeInterval;
    BOOL       _bGameOver;
    BOOL       _bPlayVoice;
    
    //生命值
    int         _heroBlood;
    
    int         _birdVelocity;
    
    int         _wallGenerateTimer;
    int         _wallGeneratorDuration;//墙壁生成时间间隔
    
    //过关记录
    int         _curPoints;//当前关卡
    int         _historyPoints;//历史关卡

    SKSpriteNode    *_playerBird;
    SKLabelNode     *_historyPointLabel;
    SKLabelNode     *_pointLabel;
    
    SKSpriteNode    *_groundNode1;
    int             _adjustmentBackgroundPosition;
    SKSpriteNode    *_groundNode2;
    
    //音效加载
    SKAction        *_playFlapAudio;//拍翅膀
    SKAction        *_playGoldAudio;//捡到金币
    SKAction        *_playHitAudio;//碰到墙壁
    //SKAction        *_playNewRecordAudio;//刷新记录
    
    //动作
    SKAction        *_HeroAction;
    SKAction        *_coinRotateAction;
}

@property(nonatomic,retain)NSMutableArray  *mArrPositions;

@end
