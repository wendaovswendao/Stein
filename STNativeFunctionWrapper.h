//
//  STNativeFunctionWrapper.h
//  stein
//
//  Created by Peter MacWhinnie on 10/1/14.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>
#import <ffi/ffi.h>

/*!
 @class
 @abstract	The STNativeFunctionWrapper class is used to create native function wrappers for objects implementing the STFunction protocol.
 */
@interface STNativeFunctionWrapper : NSObject
{
	NSObject < STFunction > *mFunction;
	NSMethodSignature *mSignature;
	
	ffi_cif *mClosureInformation;
	
	ffi_type *mReturnType;
	ffi_type **mArgumentTypes;
	
	ffi_closure *mClosure;
}
#pragma mark Initialization

/*!
 @method
 @abstract		Initialize the receiver with a specified function object, and a specified type signature.
 @param			function	The function object to create a native wrapper for. May not be nil.
 @param			signature	The signature that describes the function object's return type and parameters. May not be nil.
 @result		A fully initialized function wrapper.
 @discussion	This method raises an exception if any issues arise while creating the function wrapper.
				
				This is the designated initializer of STNativeFunctionWrapper.
 */
- (id)initWithFunction:(NSObject < STFunction > *)function signature:(NSMethodSignature *)signature;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The function that the native function wrapper is wrapping.
 */
@property (readonly) NSObject < STFunction > *function;

/*!
 @property
 @abstract	The signature of the function that the native function wrapper is wrapping.
 */
@property (readonly) NSMethodSignature *signature;

/*!
 @property
 @abstract	A pointer to the wrapper's native function. This value may be used like any C function pointer.
 */
@property (readonly) void *functionPointer;

@end
