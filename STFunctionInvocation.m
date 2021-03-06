//
//  STFunctionInvocation.m
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/15.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STFunctionInvocation.h"
#import "STTypeBridge.h"

extern ffi_type *STTypeBridgeConvertObjCTypeToFFIType(const char *objcType); //From STTypeBridge.m

@implementation STFunctionInvocation

#pragma mark Initialization

- (id)initWithFunction:(void *)function signature:(NSMethodSignature *)signature
{
	NSParameterAssert(function);
	NSParameterAssert(signature);
	
	if((self = [super init]))
	{
		mFunctionPointer = function;
		
		//Create an ffi_type array for our invocation
		NSUInteger argumentCount = [signature numberOfArguments];
		mArgumentTypes = (argumentCount > 0)? NSAllocateCollectable(sizeof(ffi_type *) * argumentCount, 0) : NULL;
		
		for (NSInteger index = 0; index < argumentCount; index++)
			mArgumentTypes[index] = STTypeBridgeConvertObjCTypeToFFIType([signature getArgumentTypeAtIndex:index]);
		
		mResultType = STTypeBridgeConvertObjCTypeToFFIType([signature methodReturnType]);
		
		//Create CIF object
		mClosureInformation = NSAllocateCollectable(sizeof(ffi_cif), 0);
		int status = ffi_prep_cif(mClosureInformation, 
								  FFI_DEFAULT_ABI, 
								  argumentCount, 
								  mResultType, 
								  mArgumentTypes);
		if(status != FFI_OK)
		{
			[NSException raise:NSInternalInconsistencyException
						format:@"Could not prep closure information."];
			
			return nil;
		}
		
		size_t sizeOfReturnValue = STTypeBridgeGetSizeOfObjCType([signature methodReturnType]);
		mResultBuffer = NSAllocateCollectable(sizeOfReturnValue, 0);
		bzero(mResultBuffer, sizeOfReturnValue);
		
		mArgumentValues = NSAllocateCollectable(sizeof(void *) * argumentCount, 0);
		
		mFunctionSignature = signature;
		
		return self;
	}
	return nil;
}

#pragma mark - Properties

@synthesize functionSignature = mFunctionSignature;

#pragma mark - Arguments/Return Value

- (void)setArgument:(void *)argument atIndex:(NSUInteger)index
{
	NSAssert2((index < [mFunctionSignature numberOfArguments]), 
			  @"Index %ld out of bounds %ld", index, [mFunctionSignature numberOfArguments]);
	
	mArgumentValues[index] = argument;
}

- (void)getArgument:(void **)argument atIndex:(NSUInteger)index
{
	NSParameterAssert(argument);
	
	NSAssert2((index < [mFunctionSignature numberOfArguments]), 
			  @"Index %ld out of bounds %ld", index, [mFunctionSignature numberOfArguments]);
	
	*argument = mArgumentValues[index];
}

- (void)getReturnValue:(void **)returnValue
{
	NSParameterAssert(returnValue);
	
	*returnValue = mResultBuffer;
}

#pragma mark - Invocation

- (void)apply
{
	ffi_call(mClosureInformation, FFI_FN(mFunctionPointer), mResultBuffer, mArgumentValues);
}

@end
