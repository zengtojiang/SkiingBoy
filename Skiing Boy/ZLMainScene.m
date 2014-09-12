//
//  ZLMainScene.m
//  SpriteKit
//
//  Created by Ray on 14-1-20.
//  Copyright (c) 2014年 CpSoft. All rights reserved.
//

#import "ZLMainScene.h"
#import "ZLHistoryManager.h"
#import "SKSharedAtles.h"
#import "ZLCoinNode.h"
#import "ZLAudioPlayer.h"


#define BIRD_ANCHOR_POINT       0.75f
#define DEFAULT_GRAVITY         (-4)
#define DEFAULT_VELOCITY        (300)//(-200)
#define VELOCITY_CHANGE_DELTA   (10)//(15)

#define WALL_WIDTH                  50//  60//地板高度
#define LEFT_MARGIN                 40

#define   COIN_ZPOSITION            1

//#define BACKGROUND_HEIGHT           51//  60//地板高度

@implementation ZLMainScene

- (instancetype)initWithSize:(CGSize)size{
    
    self = [super initWithSize:size];
    if (self) {
        
        self.mArrPositions=[NSMutableArray array];
        [self initGameParams];
        [self initPhysicsWorld];
        [self initBackground];
        [self initWorldBorder];
        [self initAction];
        [self initScroe];
        [self initPlayerBird];
        [self startPlayerBirdAction];
        [self initStartLabel:YES];
        [self initAudio];
       
        //重设游戏参数
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(resetGameMusic) name:ZL_RESET_GAME_NOTIFICATION object:nil];
         [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(restartNotification) name:ZL_RESTART_GAME_NOTIFICATION object:nil];
    }
    return self;
}

-(void)restartNotification
{
    [self initGameParams];
    for (SKNode *child in [self children]) {
        if (child.zPosition!=0) {
            [child removeFromParent];
        }
    }
    [self removeAllActions];
    //[self removeAllChildren];
    //[self initBackground];
    [self initScroe];
    [self initPlayerBird];
    [self startPlayerBirdAction];
    [self initStartLabel:YES];
}

//初设游戏参数
-(void)initGameParams
{
    _bGameOver=YES;
    //int _maxYWallCount=((CGRectGetMaxX(self.frame)-80)/WALL_WIDTH);
    //ZLTRACE(@"maxYWallCount:%d",_maxYWallCount);
    _wallGeneratorDuration=10;
    [self resetGameMusic];
    [self resetParams];
}

-(void)resetGameMusic
{
    _bPlayVoice=[ZLHistoryManager voiceOpened];
}

//重置参数
-(void)resetParams
{
    _birdVelocity=0;
    _heroBlood=1;
    _lastTimeInterval=-1;
    _wallGenerateTimer=-1;
    [self.mArrPositions removeAllObjects];
    NSString  *filePath=[[NSBundle mainBundle] pathForResource:@"position1" ofType:@"plist"];
    [self.mArrPositions addObjectsFromArray:[NSArray arrayWithContentsOfFile:filePath]];
    //ZLTRACE(@"positionArray:%@",self.mArrPositions);
    _curPositionIndex=0;
}

-(void)onTapStartGame
{
    [self resetParams];
    for (SKNode *child in [self children]) {
        if (child.zPosition!=0) {
            [child removeFromParent];
        }
    }
    //[self removeAllChildren];
    [self removeAllActions];
    //[self initBackground];
    [self initScroe];
    [self initPlayerBird];
    //_playerBird.physicsBody.velocity=CGVectorMake(0, _birdVelocity);
    self.physicsWorld.speed=1.0;
    _bGameOver=NO;
    [self initSwipeHintLabel];
    [_playerBird runAction:[SKSharedAtles playerAction]];
    //self.physicsWorld.gravity=CGVectorMake(0, DEFAULT_GRAVITY+_forceGravity);
}


-(void)initSwipeHintLabel
{
    SKLabelNode *swipeLabel = [SKLabelNode labelNodeWithFontNamed:@"ChalkboardSE-Bold"];
    swipeLabel.text = @"Slide to Move";
    swipeLabel.name=@"hintLabel";
    swipeLabel.zPosition = 4;
    swipeLabel.fontColor = HEXCOLOR(0x362e2b);///HEXCOLOR(0xe6b003);//HEXCOLOR(0x552d19);//[SKColor brownColor];
    swipeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    swipeLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
    [self addChild:swipeLabel];
    [swipeLabel runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction fadeOutWithDuration:1],[SKAction waitForDuration:0.1],[SKAction fadeInWithDuration:1.5],[SKAction waitForDuration:0.1]]] count:2],[SKAction removeFromParent]]]];
}

- (void)initPhysicsWorld{
    self.physicsWorld.contactDelegate = self;
    self.physicsWorld.gravity = CGVectorMake(0,0);
}

-(void)initAudio
{
    //waitForCompletion 音效动作是否和音效长度一样
    //捡到金币
    _playGoldAudio=[SKAction playSoundFileNamed:@"sound_good.mp3" waitForCompletion:NO];
    //拍翅膀
    //_playFlapAudio=[SKAction playSoundFileNamed:@"wingflap.mp3" waitForCompletion:NO];
    
    //碰到墙壁
    _playHitAudio=[SKAction playSoundFileNamed:@"die.mp3" waitForCompletion:YES];
    //碰到炸弹
    //_playBombAudio=[SKAction playSoundFileNamed:@"bomb.mp3" waitForCompletion:YES];
    //_playNewRecordAudio=[SKAction playSoundFileNamed:@"select.mp3" waitForCompletion:NO];
}

- (void)initBackground{
    
    SKTexture *groundTexture=[SKSharedAtles textureWithType:SKTextureTypeBackground];
    _adjustmentBackgroundPosition=0;
    
   
    _groundNode1=[SKSpriteNode spriteNodeWithTexture:groundTexture];
    _groundNode1.position=CGPointMake(0, _adjustmentBackgroundPosition);
    _groundNode1.anchorPoint=CGPointMake(0, 0);
    _groundNode1.zPosition=0;
    [self addChild:_groundNode1];
    
    _groundNode2=[SKSpriteNode spriteNodeWithTexture:groundTexture];
    _groundNode2.position=CGPointMake(0, _adjustmentBackgroundPosition-groundTexture.size.height+1);
    _groundNode2.anchorPoint=CGPointMake(0, 0);
    _groundNode2.zPosition=0;
    [self addChild:_groundNode2];
}

- (void)initAction{
    _HeroAction = [SKSharedAtles playerAction];
    _coinRotateAction = [SKSharedAtles coinRotateAction];
}

- (void)scrollBackgroundWithTime:(NSTimeInterval)currentTime{
    if (_lastTimeInterval<0) {
        _lastTimeInterval=currentTime;
        return;
    }
    float timeDelta=currentTime-_lastTimeInterval;
    _lastTimeInterval=currentTime;
    _adjustmentBackgroundPosition +=_birdVelocity*timeDelta;
    if (_adjustmentBackgroundPosition >=_groundNode1.size.height)
    {
        _adjustmentBackgroundPosition = 0;
    }
    _groundNode1.position=CGPointMake(0, _adjustmentBackgroundPosition);
    _groundNode2.position=CGPointMake(0,  _adjustmentBackgroundPosition-_groundNode1.size.height+1);
//    _groundNode1.position=CGPointMake(0, self.size.height+ _adjustmentBackgroundPosition);
//    _groundNode2.position=CGPointMake(0,  self.size.height-_groundNode1.size.height+_adjustmentBackgroundPosition);
}

-(void)initWorldBorder
{
    //上边界
    SKSpriteNode *topBorderLine = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(self.size.width, 2)];
    topBorderLine.zPosition = 0;
    topBorderLine.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMaxY(self.frame)+WALL_WIDTH);
    topBorderLine.physicsBody=[SKPhysicsBody bodyWithRectangleOfSize:topBorderLine.size];
    topBorderLine.physicsBody.mass=1;
    // wallLine.physicsBody.affectedByGravity=NO;
    topBorderLine.physicsBody.dynamic=NO;
    topBorderLine.physicsBody.restitution=0;
    topBorderLine.physicsBody.categoryBitMask = SKRoleCategoryBorder;
    topBorderLine.physicsBody.collisionBitMask=0;
    topBorderLine.physicsBody.contactTestBitMask = SKRoleCategoryCoin|SKRoleCategoryWall;
    [self addChild:topBorderLine];
    
    //左边界
    /*
    SKSpriteNode *leftBorderLine = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(2, self.size.height)];
    leftBorderLine.zPosition = 0;
    leftBorderLine.position = CGPointMake(CGRectGetMinX(self.frame)+LEFT_MARGIN-3,CGRectGetMidY(self.frame));
    leftBorderLine.physicsBody=[SKPhysicsBody bodyWithRectangleOfSize:leftBorderLine.size];
    leftBorderLine.physicsBody.mass=1;
    // wallLine.physicsBody.affectedByGravity=NO;
    leftBorderLine.physicsBody.dynamic=NO;
    leftBorderLine.physicsBody.restitution=0;
    leftBorderLine.physicsBody.categoryBitMask = SKRoleCategoryBorder;
    leftBorderLine.physicsBody.collisionBitMask=0;
    leftBorderLine.physicsBody.contactTestBitMask = SKRoleCategoryCoin|SKRoleCategoryWall|SKRoleCategoryHero;
    [self addChild:leftBorderLine];
    
    //右边界
    SKSpriteNode *rightBorderLine = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(2, self.size.height)];
    rightBorderLine.zPosition = 0;
    rightBorderLine.position = CGPointMake(CGRectGetMaxX(self.frame)-LEFT_MARGIN+3,CGRectGetMidY(self.frame));
    rightBorderLine.physicsBody=[SKPhysicsBody bodyWithRectangleOfSize:rightBorderLine.size];
    rightBorderLine.physicsBody.mass=1;
    // wallLine.physicsBody.affectedByGravity=NO;
    rightBorderLine.physicsBody.dynamic=NO;
    rightBorderLine.physicsBody.restitution=0;
    rightBorderLine.physicsBody.categoryBitMask = SKRoleCategoryBorder;
    rightBorderLine.physicsBody.collisionBitMask=0;
    rightBorderLine.physicsBody.contactTestBitMask = SKRoleCategoryCoin|SKRoleCategoryWall|SKRoleCategoryHero;
    [self addChild:rightBorderLine];
     */
}

- (void)initStartLabel:(BOOL)firsttime
{
    SKLabelNode *_startLabel = [SKLabelNode labelNodeWithFontNamed:@"ChalkboardSE-Bold"];
    _startLabel.text = firsttime?@"Tap to Start":@"Tap to Restart";
    _startLabel.name=@"startLabel";
    _startLabel.zPosition = 4;
    _startLabel.fontColor = HEXCOLOR(0x362e2b);///HEXCOLOR(0xe6b003);//HEXCOLOR(0x552d19);//[SKColor brownColor];
    _startLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    _startLabel.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
    [self addChild:_startLabel];
    [_startLabel runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction fadeOutWithDuration:1],[SKAction waitForDuration:0.1],[SKAction fadeInWithDuration:1.5],[SKAction waitForDuration:0.1]]]]];
}

- (void)initScroe{
    _curPoints=0;
    _historyPoints=[ZLHistoryManager getLastPoints];
    _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    _pointLabel.text = [NSString stringWithFormat:@"Score:%d",_curPoints];
    _pointLabel.zPosition = 4;
    _pointLabel.fontSize=16;
    _pointLabel.fontColor = HEXCOLOR(0x362e2b);//HEXCOLOR(0xe6b003);//[SKColor whiteColor];
    _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _pointLabel.position = CGPointMake(60 , self.size.height - 50);
    [self addChild:_pointLabel];
    
    _historyPointLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    _historyPointLabel.text = [NSString stringWithFormat:@"Record:%d",_historyPoints];
    _historyPointLabel.zPosition = 4;
    _historyPointLabel.fontColor = HEXCOLOR(0x362e2b);//HEXCOLOR(0xe6b003);//[SKColor whiteColor];
    _historyPointLabel.fontSize=16;
    _historyPointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    _historyPointLabel.position = CGPointMake(CGRectGetMidX(self.frame)+60 , self.size.height - 50);
    [self addChild:_historyPointLabel];
}

- (void)initPlayerBird{
    
    _playerBird = [SKSpriteNode spriteNodeWithTexture:[SKSharedAtles textureWithType:SKTextureTypeHero]];
    _playerBird.position =  CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame)+50);//CGPointMake(160, 300);
    _playerBird.zPosition = 2;
   // _playerBird.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_playerBird.size];
    _playerBird.physicsBody=[SKPhysicsBody bodyWithCircleOfRadius:_playerBird.size.width/3];
    _playerBird.physicsBody.categoryBitMask = SKRoleCategoryHero;
    _playerBird.physicsBody.mass=1;
    _playerBird.physicsBody.collisionBitMask = SKRoleCategoryBorder;
    _playerBird.physicsBody.contactTestBitMask = SKRoleCategoryBomb|SKRoleCategoryBorder|SKRoleCategoryCoin|SKRoleCategoryWall;
    [self addChild:_playerBird];
    //[_playerBird runAction:[SKSharedAtles playerAction]];
}

-(void)startPlayerBirdAction
{
    //[_playerBird runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction moveByX:0 y:15 duration:0.5],[SKAction waitForDuration:0.1],[SKAction moveByX:0 y:-30 duration:1],[SKAction waitForDuration:0.1],[SKAction moveByX:0 y:15 duration:0.5]]]]];
}

-(SKSpriteNode *)createWallAtPosition:(int)wallPos
{
    //int wallCount= (arc4random() % _maxYWallCount);
    
    //wallHeight=(CGRectGetHeight(self.frame)-wallCount*WALL_WIDTH-_wallGapHeight-BACKGROUND_HEIGHT);
    // int _bombYPosition=(arc4random() % (lround(CGRectGetHeight(self.frame)-100-BACKGROUND_HEIGHT))) + 100;
    int _wallXPosition=CGRectGetMinX(self.frame)+(wallPos+0.5f)*WALL_WIDTH+LEFT_MARGIN;
    //ZLTRACE(@"wallCount:%d wallYPosition:%d",wallPos,_wallYPosition);
    //int y2Position=CGRectGetMaxY(self.frame)-wallHeight+WALL_WIDTH/2;
    SKSpriteNode *wallSprite=[SKSpriteNode spriteNodeWithTexture:[SKSharedAtles textureWithType:SKTextureTypeStone]];
    wallSprite.anchorPoint=CGPointMake(0.5, 0.5);
    wallSprite.position=CGPointMake(_wallXPosition, CGRectGetMinY(self.frame)-wallSprite.size.height/2);
    wallSprite.zPosition=COIN_ZPOSITION;
    
    wallSprite.physicsBody=[SKPhysicsBody bodyWithRectangleOfSize:wallSprite.size];
    wallSprite.physicsBody.allowsRotation=NO;
    wallSprite.physicsBody.linearDamping=0.0;
    wallSprite.physicsBody.mass=10000;
    wallSprite.physicsBody.affectedByGravity=NO;
    wallSprite.physicsBody.categoryBitMask=SKRoleCategoryWall;
    //bombSprite.physicsBody.collisionBitMask = SKRoleCategoryHero;
    wallSprite.physicsBody.contactTestBitMask=SKRoleCategoryHero;
    //wallSprite.physicsBody.dynamic=NO;
    wallSprite.physicsBody.restitution=0;
    
    return wallSprite;
}

-(ZLCoinNode *)createCoinAtPosition:(int)position
{
    ZLCoinNode *coinSprite=[ZLCoinNode createCoinWithType:SKTextureTypeCoin];
     int _wallXPosition=CGRectGetMinX(self.frame)+(position+0.5f)*WALL_WIDTH+LEFT_MARGIN;
    //int _wallYPosition=CGRectGetMinY(self.frame)+(position+0.5f)*WALL_WIDTH+BACKGROUND_HEIGHT;
    
    coinSprite.position=CGPointMake(_wallXPosition, CGRectGetMinY(self.frame)-coinSprite.size.height/2);
    [coinSprite runAction:_coinRotateAction];
    return coinSprite;
}

-(void)createIncomingWallBombAndCoins
{
    _wallGenerateTimer++;
    if (_wallGenerateTimer >= _wallGeneratorDuration)
    {
        if (_curPositionIndex>=[self.mArrPositions count]) {
            _curPositionIndex=0;
        }
        if (_curPositionIndex<[self.mArrPositions count]) {
            NSString *positionStr=[self.mArrPositions objectAtIndex:_curPositionIndex];
            NSArray *posItemArray=[positionStr componentsSeparatedByString:@";"];
            if (posItemArray&&[posItemArray count]) {
                NSString *wallStr=[posItemArray objectAtIndex:0];
                if (wallStr&&[wallStr length]) {
                    NSArray *wallPosArr=[wallStr componentsSeparatedByString:@","];
                    for (int i=0; i<[wallPosArr count]; i++) {
                        SKSpriteNode *wallNode = [self createWallAtPosition:[[wallPosArr objectAtIndex:i] intValue]];
                        [self addChild:wallNode];
                        //[wallNode runAction:[SKAction sequence:@[[SKAction moveToY:CGRectGetMaxY(self.frame)+WALL_WIDTH/2 duration:_wallMoveSpeed],[SKAction removeFromParent]]]];
                        //[wallNode runAction:[SKAction sequence:@[[SKAction moveToX:-WALL_WIDTH/2 duration:_wallMoveSpeed],[SKAction removeFromParent]]]];
                    }
                }
                NSString *coinStr=[posItemArray objectAtIndex:1];
                if (coinStr&&[coinStr length]) {
                    NSArray *coinPosArr=[coinStr componentsSeparatedByString:@","];
                    for (int i=0; i<[coinPosArr count]; i++) {
                        ZLCoinNode *coinSprite = [self createCoinAtPosition:[[coinPosArr objectAtIndex:i] intValue]];
                        [self addChild:coinSprite];
                        //[coinSprite runAction:[SKAction sequence:@[[SKAction moveToY:CGRectGetMaxY(self.frame)+WALL_WIDTH/2 duration:_wallMoveSpeed],[SKAction removeFromParent]]]];
                        /*
                         int coinRand=arc4random() % (12);
                         if (coinRand==0) {
                         SKSpriteNode *bomeNode=[self createBombAtPosition:[[coinPosArr objectAtIndex:i] intValue]];
                         [self addChild:bomeNode];
                         [bomeNode runAction:[SKAction sequence:@[[SKAction moveToX:-WALL_WIDTH/2 duration:_wallMoveSpeed],[SKAction removeFromParent]]]];
                         }else{
                         ZLCoinNode *coinSprite = [self createCoinAtPosition:[[coinPosArr objectAtIndex:i] intValue]];
                         [self addChild:coinSprite];
                         [coinSprite runAction:[SKAction sequence:@[[SKAction moveToX:-WALL_WIDTH/2 duration:_wallMoveSpeed],[SKAction removeFromParent]]]];
                         }
                         */
                    }
                }
            }
        }
        _curPositionIndex++;
        _wallGenerateTimer = 0;
    }
   // _wallGenerateTimer +=1.0f*_birdVelocity/DEFAULT_VELOCITY;
}

-(void)adjustPlayerBirdAngle
{
    CGVector velocity=_playerBird.physicsBody.velocity;
    if (velocity.dy>0) {
        [_playerBird removeActionForKey:@"turndownaction"];
        if (![_playerBird actionForKey:@"turnupaction"]) {
            [_playerBird runAction:[SKAction rotateToAngle:0 duration:0.1f]];
            //[_playerBird runAction:[SKAction setTexture:[SKSharedAtles textureWithType:SKTextureTypeHeroUp]]];
            SKAction *rotateAction=[SKAction rotateToAngle:M_PI_4 duration:0.3f];
            rotateAction.timingMode=SKActionTimingEaseOut;
            [_playerBird runAction:rotateAction withKey:@"turnupaction"];
        }
    }else{
        [_playerBird removeActionForKey:@"turnupaction"];
        if (![_playerBird actionForKey:@"turndownaction"]) {
            //[_playerBird runAction:[SKAction setTexture:[SKSharedAtles textureWithType:SKTextureTypeHeroDown]]];
            SKAction *rotateAction=[SKAction rotateToAngle:M_PI_4*(-1) duration:0.5f];
            rotateAction.timingMode=SKActionTimingEaseIn;
            [_playerBird runAction:rotateAction withKey:@"turndownaction"];
        }
    }
}

-(void)obstacleCollisionAnimated:(SKSpriteNode *)node
{
    [self runAction:_playHitAudio];
    //[node removeFromParent];
    _heroBlood--;
    if (_heroBlood<=0) {
        [self onGameOverWithType:1];
    }
}

-(void)borderCollisionAnimated
{
    
}

-(void)wallOrCoinCollisionWithBorder:(SKSpriteNode *)node
{
    [node removeAllActions];
    [node removeFromParent];
}

-(void)onGotCoin:(ZLCoinNode *)sprite
{
    
    _curPoints +=sprite.coinValue;
    [sprite removeAllActions];
    [sprite removeFromParent];
    [_pointLabel runAction:[SKAction runBlock:^{
        _pointLabel.text = [NSString stringWithFormat:@"Score:%d",_curPoints];
    }]];
    if (_bPlayVoice) {
        [self runAction:_playGoldAudio];
        //[ZLAudioPlayer playAudioWithType:ZLAUDIOTYPEGOLD];
    }
    if (_curPoints>_historyPoints) {
        [ZLHistoryManager setLastPoints:_curPoints];
        _historyPoints=[ZLHistoryManager getLastPoints];
        [_historyPointLabel runAction:[SKAction runBlock:^{
            _historyPointLabel.text = [NSString stringWithFormat:@"Record:%d",_historyPoints];
        }]];
        //        [_historyPointLabel runAction:[SKAction sequence:@[_playNewRecordAudio,[SKAction runBlock:^{
        //            _historyPointLabel.text = [NSString stringWithFormat:@"Record:%d",_historyPoints];
        //        }]]]];
    }
}

/**
 overType =1 碰到墙壁
 overType=2  碰到炸弹
 */
-(void)onGameOverWithType:(int)overType
{
    if (_bGameOver) {
        return;
    }
    _bGameOver=YES;
    [self removeAllActions];
//    _playerBird.physicsBody.velocity=CGVectorMake(0, 0);
//    _playerBird.physicsBody.angularVelocity=0;
    _playerBird.physicsBody.resting=YES;
    self.physicsWorld.speed=0;
    for (SKNode *child in [self children]) {
        if (![child.name isEqualToString:@"hintLabel"]) {
            child.physicsBody.resting=YES;
            [child removeAllActions];
        }else{
            [child removeFromParent];
        }
    }
    SKAction *dieAudio=nil;
    if (overType==1) {
        dieAudio=_playHitAudio;
    }
    if (_bPlayVoice) {
        [self runAction:[SKAction sequence:@[dieAudio,[SKAction runBlock:^{
            [self initStartLabel:NO];
            
        }]]]];
    }else{
        [self runAction:[SKAction runBlock:^{
            [self initStartLabel:NO];
        }]];
    }
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.paused) {
        ZLTRACE(@"game has paused");
        return;
    }
    if (_bGameOver) {
        if ([self childNodeWithName:@"startLabel"]) {
            //出现了点击开始图标才能开始
            [self onTapStartGame];
        }
    }
    /*
    else{
        if (_bPlayVoice) {
            // [ZLAudioPlayer playAudioWithType:ZLAUDIOTYPEFLAP];
            [self runAction:_playFlapAudio];
        }
        _birdVelocity=DEFAULT_VELOCITY*(-1);
        //[_playerBird.physicsBody applyImpulse:CGVectorMake(0,50)];
    }
     */
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (self.paused) {
        ZLTRACE(@"game has paused");
        return;
    }
    if (_bGameOver) {
        ZLTRACE(@"game is over");
        return;
    }
    for (UITouch *touch in touches) {
        
        CGPoint location = [touch locationInNode:self];
        
        if (location.x >= self.size.width - (_playerBird.size.width / 2)-LEFT_MARGIN) {
            
            location.x = self.size.width - (_playerBird.size.width / 2)-LEFT_MARGIN;
            
        }else if (location.x <= (_playerBird.size.width / 2)+LEFT_MARGIN) {
            
            location.x = _playerBird.size.width / 2+LEFT_MARGIN;
            
        }
        /*
        if (location.y >= self.size.height - (_playerPlane.size.height / 2)) {
            
            location.y = self.size.height - (_playerPlane.size.height / 2);
            
        }else if (location.y <= (_playerPlane.size.height / 2)) {
            
            location.y = (_playerPlane.size.height / 2);
            
        }
        */
        SKAction *action = [SKAction moveTo:CGPointMake(location.x, _playerBird.position.y) duration:0];
        
        [_playerBird runAction:action];
    }
}

-(void)updateCoinVelocity
{
    if (_birdVelocity<=0||_birdVelocity<DEFAULT_VELOCITY) {
        _birdVelocity +=VELOCITY_CHANGE_DELTA;
    }
    for (SKNode *child in [self children]) {
        if (child.zPosition==COIN_ZPOSITION) {
            //ZLTRACE(@"abc");
            child.physicsBody.velocity=CGVectorMake(0, _birdVelocity*2);
        }
    }
}


- (void)update:(NSTimeInterval)currentTime{
    
    if (!_bGameOver) {
        //[self applyForceToPlayer];
        
        //[self adjustPlayerBirdAngle];
        //[self createIncomingWalls];
        [self createIncomingWallBombAndCoins];
        
        [self scrollBackgroundWithTime:currentTime];
        
        [self updateCoinVelocity];
        //[self createIncomingWallBombAndCoins];
        /*
        if (_coinModeTimer>=1000) {
            [self createIncomingCoins];
        }else{
            [self createIncomingWallBombAndCoins];
        }
        _coinModeTimer++;
         */
    }
}

#pragma mark -
- (void)didBeginContact:(SKPhysicsContact *)contact{
    if (contact.bodyA.categoryBitMask & SKRoleCategoryHero || contact.bodyB.categoryBitMask & SKRoleCategoryHero) {
        
        if (contact.bodyA.categoryBitMask & SKRoleCategoryWall || contact.bodyB.categoryBitMask & SKRoleCategoryWall) {
            ZLTRACE(@"bird collision with wall");
            SKSpriteNode *obstacleNode = (contact.bodyA.categoryBitMask & SKRoleCategoryWall) ? (SKSpriteNode *)contact.bodyA.node : (SKSpriteNode *)contact.bodyB.node;
            [self obstacleCollisionAnimated:obstacleNode];
            //[self onGameOverWithType:1];
        }else if(contact.bodyA.categoryBitMask & SKRoleCategoryBorder || contact.bodyB.categoryBitMask & SKRoleCategoryBorder){
            //ZLTRACE(@"bird collision with background");
            //[self onGameOverWithType:1];
            [self borderCollisionAnimated];
        }else if(contact.bodyA.categoryBitMask & SKRoleCategoryCoin || contact.bodyB.categoryBitMask & SKRoleCategoryCoin){
            ZLTRACE(@"bird collision with coin");
            ZLCoinNode *coinNode = (contact.bodyA.categoryBitMask & SKRoleCategoryCoin) ? (ZLCoinNode *)contact.bodyA.node : (ZLCoinNode *)contact.bodyB.node;
            [self onGotCoin:coinNode];
        }
    }else if (contact.bodyA.categoryBitMask & SKRoleCategoryBorder || contact.bodyB.categoryBitMask & SKRoleCategoryBorder) {
        if ((contact.bodyA.categoryBitMask & SKRoleCategoryWall || contact.bodyB.categoryBitMask & SKRoleCategoryWall)||(contact.bodyA.categoryBitMask & SKRoleCategoryCoin || contact.bodyB.categoryBitMask & SKRoleCategoryCoin)) {
            ZLTRACE(@"border collision with wall or coin");
            SKSpriteNode *obstacleNode = (contact.bodyA.categoryBitMask & SKRoleCategoryBorder) ? (SKSpriteNode *)contact.bodyB.node : (SKSpriteNode *)contact.bodyA.node;
            //[obstacleNode removeFromParent];
            [self wallOrCoinCollisionWithBorder:obstacleNode];
        }
    }
}

- (void)didEndContact:(SKPhysicsContact *)contact{
}


@end
