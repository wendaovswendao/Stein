//
//  STList.m
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "STList.h"

@implementation STList

#pragma mark Destruction

- (void)dealloc
{
	[mContents release];
	mContents = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Creation

- (id)init
{
	if((self = [super init]))
	{
		mContents = [NSMutableArray new];
		
		return self;
	}
	return nil;
}

+ (STList *)list
{
	return [[self new] autorelease];
}

#pragma mark -

- (id)initWithArray:(NSArray *)array
{
	if((self = [self init]))
	{
		[mContents setArray:array];
		
		return self;
	}
	return nil;
}

+ (STList *)listWithArray:(NSArray *)array
{
	return [[[self alloc] initWithArray:array] autorelease];
}

#pragma mark -

- (id)initWithList:(STList *)list
{
	if((self = [self init]))
	{
		[mContents setArray:list->mContents];
		
		return self;
	}
	return nil;
}

+ (STList *)listWithList:(STList *)list
{
	return [[[self alloc] initWithList:list] autorelease];
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	STList *list = [[[self class] allocWithZone:zone] initWithArray:mContents];
	list->mEvaluator = mEvaluator;
	return list;
}

#pragma mark -
#pragma mark Accessing Objects

- (id)head
{
	return ([mContents count] > 0)? [mContents objectAtIndex:0] : nil;
}

- (STList *)tail
{
	return [self sublistWithRange:NSMakeRange(1, [mContents count] - 1)];
}

#pragma mark -

- (id)objectAtIndex:(NSUInteger)index
{
	return [mContents objectAtIndex:index];
}

- (STList *)sublistWithRange:(NSRange)range
{
	STList *sublist = [[[STList alloc] initWithArray:[mContents subarrayWithRange:range]] autorelease];
	sublist.evaluator = mEvaluator;
	return sublist;
}

#pragma mark -
#pragma mark Modification

- (void)addObject:(id)object
{
	[mContents addObject:object];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
	[mContents insertObject:object atIndex:index];
}

#pragma mark -

- (void)removeObject:(id)object
{
	[mContents removeObject:object];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
	[mContents removeObjectAtIndex:index];
}

#pragma mark -

- (void)replaceValuesByPerformingSelectorOnEachObject:(SEL)selector
{
	NSParameterAssert(selector);
	
	for (NSInteger index = (self.count - 1); index >= 0; index--)
		[mContents replaceObjectAtIndex:index withObject:[[mContents objectAtIndex:index] performSelector:selector]];
}

#pragma mark -
#pragma mark Finding Objects

- (NSUInteger)indexOfObject:(id)object
{
	return [mContents indexOfObject:object];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)object
{
	return [mContents indexOfObjectIdenticalTo:object];
}

#pragma mark -
#pragma mark Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[STList class]])
		return [mContents isEqualToArray:((STList *)object)->mContents];
	else if([object isKindOfClass:[NSArray class]])
		return [mContents isEqualToArray:object];
	
	return [super isEqualTo:object];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@(%@)", mIsQuoted? @"'" : @"", [mContents componentsJoinedByString:@" "]];
}

#pragma mark -
#pragma mark Properties

@synthesize isQuoted = mIsQuoted;
@synthesize isDoConstruct = mIsDoConstruct;
@synthesize evaluator = mEvaluator;

#pragma mark -

@dynamic count;
- (NSUInteger)count
{
	return [mContents count];
}

#pragma mark -
#pragma mark Enumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	return [mContents countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
