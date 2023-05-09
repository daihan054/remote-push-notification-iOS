//
//  ARTConnection.m
//  ably
//
//  Created by Ricardo Pereira on 30/10/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnection+Private.h"

#import "ARTRealtime+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTSentry.h"
#import "ARTQueuedDealloc.h"

@implementation ARTConnection {
    ARTQueuedDealloc *_dealloc;
}

- (ARTConnectionInternal *_Nonnull)internal_nosync {
    return _internal;
}

- (NSString *)id {
    return _internal.id;
}

- (NSString *)key {
    return _internal.key;
}

- (NSString *)recoveryKey {
    return _internal.recoveryKey;
}

- (int64_t)serial {
    return _internal.serial;
}

- (NSInteger)maxMessageSize {
    return _internal.maxMessageSize;
}

- (ARTRealtimeConnectionState)state {
    return _internal.state;
}

- (ARTErrorInfo *)errorReason {
    return _internal.errorReason;
}

- (instancetype)initWithInternal:(ARTConnectionInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (void)close {
    [_internal close];
}

- (void)connect {
    [_internal connect];
}

- (void)off {
    [_internal off];
}

- (void)off:(nonnull ARTEventListener *)listener {
    [_internal off:listener];
}

- (void)off:(ARTRealtimeConnectionEvent)event listener:(nonnull ARTEventListener *)listener {
    [_internal off:event listener:listener];
}

- (nonnull ARTEventListener *)on:(nonnull void (^)(ARTConnectionStateChange * _Nullable))cb {
    return [_internal on:cb];
}

- (nonnull ARTEventListener *)on:(ARTRealtimeConnectionEvent)event callback:(nonnull void (^)(ARTConnectionStateChange * _Nullable))cb {
    return [_internal on:event callback:cb];
}

- (nonnull ARTEventListener *)once:(nonnull void (^)(ARTConnectionStateChange * _Nullable))cb {
    return [_internal once:cb];
}

- (nonnull ARTEventListener *)once:(ARTRealtimeConnectionEvent)event callback:(nonnull void (^)(ARTConnectionStateChange * _Nullable))cb {
    return [_internal once:event callback:cb];
}

- (void)ping:(nonnull void (^)(ARTErrorInfo * _Nullable))cb {
    [_internal ping:cb];
}

@end

@implementation ARTConnectionInternal {
    _Nonnull dispatch_queue_t _queue;
    NSString *_id;
    NSString *_key;
    NSInteger _maxMessageSize;
    int64_t _serial;
    ARTRealtimeConnectionState _state;
    ARTErrorInfo *_errorReason;
}

- (instancetype)initWithRealtime:(ARTRealtimeInternal *)realtime {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    if (self = [super init]) {
        _eventEmitter = [[ARTPublicEventEmitter alloc] initWithRest:realtime.rest];
        _realtime = realtime;
        _queue = _realtime.rest.queue;
        _serial = -1;
    }
    return self;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)connect {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime connect];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)close {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime close];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)ping:(void (^)(ARTErrorInfo *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime ping:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)id {
    __block NSString *ret;   
dispatch_sync(_queue, ^{
    ret = [self id_nosync];
});
    return ret;
} 

- (NSString *)key {
    __block NSString *ret;   
dispatch_sync(_queue, ^{
    ret = [self key_nosync];
});
    return ret;
} 

- (int64_t)serial {
    __block int64_t ret;   
dispatch_sync(_queue, ^{
    ret = [self serial_nosync];
});
    return ret;
} 

- (ARTRealtimeConnectionState)state {
    __block ARTRealtimeConnectionState ret;   
dispatch_sync(_queue, ^{
    ret = [self state_nosync];
});
    return ret;
}

- (ARTErrorInfo *)errorReason {
    __block ARTErrorInfo *ret;   
dispatch_sync(_queue, ^{
    ret = [self errorReason_nosync];
});
    return ret;
}

- (ARTErrorInfo *)error_nosync {
    if (self.errorReason_nosync) {
        return self.errorReason_nosync;
    }
    switch (self.state_nosync) {
        case ARTRealtimeDisconnected:
            return [ARTErrorInfo createWithCode:80003 status:400 message:@"Connection to server temporarily unavailable"];
        case ARTRealtimeSuspended:
            return [ARTErrorInfo createWithCode:80002 status:400 message:@"Connection to server unavailable"];
        case ARTRealtimeFailed:
            return [ARTErrorInfo createWithCode:80000 status:400 message:@"Connection failed or disconnected by server"];
        case ARTRealtimeClosing:
            return [ARTErrorInfo createWithCode:80017 status:400 message:@"Connection closing"];
        case ARTRealtimeClosed:
            return [ARTErrorInfo createWithCode:80003 status:400 message:@"Connection closed"];
        default:
            return [ARTErrorInfo createWithCode:80010 status:400 message:[NSString stringWithFormat:@"Invalid operation (connection state is %lu - %@)", (unsigned long)self.state_nosync, ARTRealtimeConnectionStateToStr(self.state_nosync)]];
    }
}

- (BOOL)isActive_nosync {
    return self.realtime.isActive;
}

- (NSString *)id_nosync {
    return _id;
} 

- (NSString *)key_nosync {
    return _key;
} 

- (int64_t)serial_nosync {
    return _serial;
} 

- (ARTRealtimeConnectionState)state_nosync {
    return _state;
}

- (ARTErrorInfo *)errorReason_nosync {
    return _errorReason;
}

- (void)setId:(NSString *)newId {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _id = newId;
    [ARTSentry setExtras:@"connectionId" value:newId];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setKey:(NSString *)key {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _key = key;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setSerial:(int64_t)serial {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _serial = serial;
    [ARTSentry setExtras:@"connectionSerial" value: [NSNumber numberWithLongLong:serial]];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setMaxMessageSize:(NSInteger)maxMessageSize {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _maxMessageSize = maxMessageSize;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setState:(ARTRealtimeConnectionState)state {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _state = state;
    [ARTSentry setExtras:@"connectionState" value:ARTRealtimeConnectionStateToStr(state)];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setErrorReason:(ARTErrorInfo *_Nullable)errorReason {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _errorReason = errorReason;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)recoveryKey {
    __block NSString *ret;
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    ret = [self recoveryKey_nosync];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
    return ret;
}

- (NSString *)recoveryKey_nosync {
    switch(self.state_nosync) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended: {
            NSString *recStr = self.key_nosync;
            if (recStr == nil) {
                return nil;
            }
            NSString *str = [recStr stringByAppendingString:[NSString stringWithFormat:@":%ld:%ld", (long)self.serial_nosync, (long)_realtime.msgSerial]];
            return str;
        } default:
            return nil;
    }
}

- (ARTEventListener *)on:(ARTRealtimeConnectionEvent)event callback:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter on:[ARTEvent newWithConnectionEvent:event] callback:cb];
}

- (ARTEventListener *)on:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter on:cb];
}

- (ARTEventListener *)once:(ARTRealtimeConnectionEvent)event callback:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter once:[ARTEvent newWithConnectionEvent:event] callback:cb];
}

- (ARTEventListener *)once:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter once:cb];
}

- (void)off {
    if (_realtime && _realtime.rest) {
        [_eventEmitter off];
    } else {
        [_eventEmitter off];
    }
}
- (void)off:(ARTRealtimeConnectionEvent)event listener:(ARTEventListener *)listener {
    [_eventEmitter off:[ARTEvent newWithConnectionEvent:event] listener:listener];
}

- (void)off:(ARTEventListener *)listener {
    [_eventEmitter off:listener];
}

- (void)emit:(ARTRealtimeConnectionEvent)event with:(ARTConnectionStateChange *)data {
    [_eventEmitter emit:[ARTEvent newWithConnectionEvent:event] with:data];
}

@end

#pragma mark - ARTEvent

@implementation ARTEvent (ConnectionEvent)

- (instancetype)initWithConnectionEvent:(ARTRealtimeConnectionEvent)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTRealtimeConnectionEvent%@", ARTRealtimeConnectionEventToStr(value)]];
}

+ (instancetype)newWithConnectionEvent:(ARTRealtimeConnectionEvent)value {
    return [[self alloc] initWithConnectionEvent:value];
}

@end
