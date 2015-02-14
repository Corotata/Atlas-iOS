//
//  ATLMessagePartMock.m
//  Atlas
//
//  Created by Kevin Coleman on 12/9/14.
//  Copyright (c) 2015 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
#import "LYRMessagePartMock.h"

@interface LYRMessagePartMock ()

@property (nonatomic, readwrite) NSString *MIMEType;
@property (nonatomic, readwrite) NSData *data;

@end

@implementation LYRMessagePartMock

+ (instancetype)messagePartWithMIMEType:(NSString *)MIMEType data:(NSData *)data
{
    return [[self alloc] initWithMIMEType:MIMEType data:data];
}

+ (instancetype)messagePartWithMIMEType:(NSString *)MIMEType stream:(NSInputStream *)stream
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Method not yet implemented" userInfo:nil];
}

+ (instancetype)messagePartWithText:(NSString *)text
{
   return [[self alloc] initWithMIMEType:ATLMIMETypeTextPlain data:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

- (id)initWithMIMEType:(NSString *)MIMEType data:(NSData *)data
{
    self = [super init];
    if (self) {
        _MIMEType = MIMEType;
        _data = data;
    }
    return self;
}

- (NSInputStream *)inputStream
{
    return nil;
}

@end