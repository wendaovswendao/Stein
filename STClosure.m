//
//  STClosure.m
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STClosure.h"
#import "STList.h"
#import "STInterpreter.h"

@implementation STClosure

#pragma mark Initialization

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithPrototype:(STList *)prototype forImplementation:(STList *)implementation inScope:(STScope *)superscope
{
	NSParameterAssert(prototype);
	NSParameterAssert(implementation);
	
	if((self = [super init]))
	{
		mPrototype = prototype;
		mImplementation = implementation;
		mSuperscope = superscope;
		
		return self;
	}
	return nil;
}

#pragma mark - Stein Function

- (BOOL)evaluatesOwnArguments
{
	return NO;
}

- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)superscope
{
	STScope *scope = [STScope scopeWithParentScope:superscope];
	NSUInteger index = 0;
	NSUInteger countOfArguments = [arguments count];
	for (id name in mPrototype)
	{
		if(index >= countOfArguments)
			[scope setValue:STNull forConstantNamed:name];
		else
			[scope setValue:[arguments objectAtIndex:index] forConstantNamed:name];
		index++;
	}
	
	[scope setValue:arguments forConstantNamed:@"$_arguments"];
	
	//When a class is created in Stein, every method of that class
	//has the class's superclass associated with it. This is necessary
	//to prevent infinite loops in the `super` message-functor.
	if(mSuperclass)
		[scope setValue:mSuperclass forConstantNamed:kSTSuperclassVariableName];
	
	id result = nil;
	for (id expression in mImplementation)
		result = STEvaluate(expression, scope);
	
	return result;
}

#pragma mark - Properties

@synthesize superscope = mSuperscope;
@synthesize superclass = mSuperclass;
@synthesize name = mName;

#pragma mark -

@synthesize closureSignature = mClosureSignature;
@synthesize prototype = mPrototype;
@synthesize implementation = mImplementation;

#pragma mark - Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[STClosure class]])
	{
		return ([self.prototype isEqualTo:[object prototype]] && 
				[self.implementation isEqualTo:[object implementation]] && 
				[self.closureSignature isEqualTo:[object closureSignature]]);
	}
	
	return [super isEqualTo:object];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@ (%@)>", [self className], self, mName ?: @"[Anonymous]", [mPrototype.allObjects componentsJoinedByString:@" "]];
}

#pragma mark - Exception Handling

- (BOOL)onException:(STClosure *)closure
{
	@try
	{
		STFunctionApply(self, [STList new]);
	}
	@catch (id e)
	{
		STList *arguments = [STList new];
		[arguments addObject:e];
		STFunctionApply(closure, arguments);
		
		return YES;
	}
	
	return NO;
}

@end
