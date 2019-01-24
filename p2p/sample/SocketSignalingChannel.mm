//
//  SocketSignalingChannel.m
//  OMSChat
//
//  Created by Tomohiro Matsuzawa on 2019/01/22.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMS/OMS.h"
#import "SocketSignalingChannel.h"

#include "sio_client.h"
#include "sio_message.h"

@interface SocketSignalingChannel()

-(void)onICSMessage:(NSString*)message from:(NSString*)senderId;
-(void)onServerAuthenticated:(NSString*)uid;

@end

@implementation SocketSignalingChannel{
    sio::client *_io;
    NSMutableArray *_observers;
    void (^_connectSuccessCallback)(NSString *);
    void (^_connectFailureCallback)(NSError *);
    void (^_disconnectComplete)();
}

-(id)init{
    self=[super init];
    _io=new sio::client();
    _observers=[[NSMutableArray alloc]init];
    return self;
}

-(void)connect:(NSString *)token onSuccess:(void (^)(NSString *))onSuccess onFailure:(void (^)(NSError*))onFailure{
    NSError *error = nil;
    NSData* stringData=[token dataUsingEncoding:NSUTF8StringEncoding ];
    NSDictionary* loginInfo=[NSJSONSerialization JSONObjectWithData:stringData options:NSJSONReadingMutableContainers error:&error];
    if(error){
        if(onFailure)
            onFailure(error);
        return;
    }
    _connectSuccessCallback=onSuccess;
    _connectFailureCallback=onFailure;
    
    // NSDictionary *infoDict = [[NSBundle bundleForClass:self] infoDictionary];
    // NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    std::map<std::string, std::string> query;
    query.insert(std::pair<std::string, std::string>("clientVersion","4.1"));
    query.insert(std::pair<std::string, std::string>("clientType","iOS"));
    query.insert(std::pair<std::string, std::string>("token", [[loginInfo objectForKey:@"token"] UTF8String]));
    
    sio::socket::ptr socket = _io->socket();
    socket->on("ics-message",std::bind(&OnWoogeenMessage, (__bridge CFTypeRef)self, std::placeholders::_1,std::placeholders::_2,std::placeholders::_3,std::placeholders::_4));
    socket->on("server-authenticated",std::bind(&OnServerAuthenticated, (__bridge CFTypeRef)self, std::placeholders::_1,std::placeholders::_2,std::placeholders::_3,std::placeholders::_4));
    
    NSLog(@"Connect to %@",[loginInfo objectForKey:@"host"]);
    _io->set_reconnect_attempts(0);
    _io->set_fail_listener(std::bind(&OnSocketClientError, (__bridge CFTypeRef)self));
    _io->set_socket_close_listener(std::bind(&OnSocketClosed, (__bridge CFTypeRef)self));
    _io->connect([[loginInfo objectForKey:@"host"] UTF8String],query);
}

-(void)sendMessage:(NSString *)message to:(NSString *)targetId onSuccess:(void (^)())onSuccess onFailure:(void (^)(NSError *))onFailure{
    sio::message::ptr jsonObject = sio::object_message::create();
    jsonObject->get_map()["to"]=sio::string_message::create([targetId UTF8String]);
    jsonObject->get_map()["data"]=sio::string_message::create([message UTF8String]);
    _io->socket()->emit("ics-message",jsonObject, [=](sio::message::list const& msg){
        if(msg.size()==0){
            if(onSuccess==nil)
                return;
            onSuccess();
        } else{
            if(onFailure==nil)
                return;
            NSError *err=[[NSError alloc]initWithDomain:OMSErrorDomain code:OMSP2PErrorClientInvalidState userInfo:[[NSDictionary alloc]initWithObjectsAndKeys:@"Emit message to server failed.", NSLocalizedDescriptionKey, nil]];
            onFailure(err);
        }
    });
}

-(void)onICSMessage:(NSString *)message from:(NSString *)senderId{
    if([_delegate respondsToSelector:@selector(channel:didReceiveMessage:from:)]){
        [_delegate channel:self didReceiveMessage:message from:senderId];
    }
}

- (void) onSocketClientError:(NSError *)err {
    // restore the state
    if (_io->opened()) {
        _io->close();
    }
    if(_connectFailureCallback){
        _connectFailureCallback(err);
        _connectFailureCallback=nil;
    }
}

-(void)onSocketClosed{
    if(_disconnectComplete){
        _disconnectComplete();
        _disconnectComplete=nil;
    }
    if([_delegate respondsToSelector:@selector(channelDidDisconnect:)]){
        [_delegate channelDidDisconnect:self];
    }
}

-(void)onServerAuthenticated:(NSString *)uid{
    if(_connectSuccessCallback){
        _connectSuccessCallback(uid);
        _connectSuccessCallback=nil;
    }
}

-(void)disconnectWithOnSuccess:(void (^)())onSuccess onFailure:(void (^)(NSError *))onFailure{
    if(!_io->opened()){
        if(onFailure){
            NSError *err = [[NSError alloc] initWithDomain:OMSErrorDomain code:OMSP2PErrorClientInvalidState userInfo:nil];
            onFailure(err);
        }
        return;
    }
    _io->close();
    _disconnectComplete=onSuccess;
}

void OnSocketClientError(CFTypeRef ctrl) {
    NSError *err = [[NSError alloc] initWithDomain:OMSErrorDomain code:OMSP2PErrorClientIllegalArgument userInfo:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [((__bridge SocketSignalingChannel*)ctrl) onSocketClientError:err];
    });
}

void OnSocketClosed(CFTypeRef ctrl){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [((__bridge SocketSignalingChannel*)ctrl) onSocketClosed];
    });
}

void OnWoogeenMessage(CFTypeRef ctrl,std::string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp){
    if(data->get_flag() == sio::message::flag_object)
    {
        NSString* msg = [NSString stringWithUTF8String:data->get_map()["data"]->get_string().data()];
        NSString* from = [NSString stringWithUTF8String:data->get_map()["from"]->get_string().data()];
        [((__bridge SocketSignalingChannel*)ctrl) onICSMessage:msg from:from];
    }
}

void OnServerAuthenticated(CFTypeRef ctrl,std::string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp){
    if(data->get_flag() == sio::message::flag_object)
    {
        NSString* uid = [NSString stringWithUTF8String:data->get_map()["uid"]->get_string().data()];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [((__bridge SocketSignalingChannel*)ctrl) onServerAuthenticated:uid];
        });
    }
}


@end
