//
//  SocketSignalingChannel.h
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/22.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

#ifndef p2p_SocketSignalingChannel_h
#define p2p_SocketSignalingChannel_h

#import <OMS/OMS.h>

/// P2P signaling channel Socket.IO implementation.
@interface SocketSignalingChannel : NSObject<OMSP2PSignalingChannelProtocol>

@property(nonatomic, weak) id<OMSP2PSignalingChannelDelegate> delegate;

@end

#endif

