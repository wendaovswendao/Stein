//
//  NSObject+Stein.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STEnumerable.h>

@protocol STFunction;
@class STClosure;

@interface NSObject (Stein)

#pragma mark Truthiness

+ (BOOL)isTrue;
- (BOOL)isTrue;

#pragma mark -
#pragma mark Control Flow

+ (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause;
- (id)ifTrue:(id < STFunction >)thenClause ifFalse:(id < STFunction >)elseClause;

#pragma mark -

+ (id)ifTrue:(id < STFunction >)thenClause;
- (id)ifTrue:(id < STFunction >)thenClause;

#pragma mark -

+ (id)ifFalse:(id < STFunction >)thenClause ifTrue:(id < STFunction >)elseClause;
- (id)ifFalse:(id < STFunction >)thenClause ifTrue:(id < STFunction >)elseClause;

#pragma mark -

+ (id)ifFalse:(id < STFunction >)thenClause;
- (id)ifFalse:(id < STFunction >)thenClause;

#pragma mark -

- (id)match:(STClosure *)matchers;

#pragma mark -
#pragma mark Printing

- (NSString *)prettyDescription;
- (NSString *)prettyPrint;

#pragma mark -

- (NSString *)print;

#pragma mark -
#pragma mark Ivars

- (void)setValue:(id)value forIvarNamed:(NSString *)name;
- (id)valueForIvarNamed:(NSString *)name;

#pragma mark -
#pragma mark Extension

+ (Class)extend:(STClosure *)extensions;

@end

#pragma mark -

@interface NSNumber (Stein)

- (BOOL)isTrue;

@end

#pragma mark -

@interface NSString (Stein)

@end

#pragma mark -

@interface NSNull (Stein)

+ (BOOL)isTrue;
- (BOOL)isTrue;

@end

#pragma mark -

@interface NSArray (Stein) < STEnumerable >

@end

@interface NSSet (Stein) < STEnumerable >

@end

@interface NSDictionary (Stein) < STEnumerable >

@end
