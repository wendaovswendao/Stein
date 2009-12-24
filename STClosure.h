//
//  STClosure.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/13.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ffi/ffi.h>
#import <Stein/STFunction.h>

@class STEvaluator, STList;

/*!
 @class
 @abstract	The STClosure class is responsible for representing closures and functions in Stein.
 */
@interface STClosure : NSObject < STFunction >
{
	/* weak */		STEvaluator *mEvaluator;
	/* strong */	NSMutableDictionary *mSuperscope;
	/* weak */		Class mSuperclass;
	/* owner */		NSString *mName;
	
	//Closure Description
	/* strong */	NSMethodSignature *mClosureSignature;
	/* strong */	STList *mPrototype;
	/* strong */	STList *mImplementation;
	
	//Foreign Function Interface
	/* auto */		ffi_cif *mFFIClosureInformation;
	
	/* weak */		ffi_type *mFFIReturnType;
	/* auto */		ffi_type **mFFIArgumentTypes;
	
	/* owner */		ffi_closure *mFFIClosure;
}

/*!
 @method
 @abstract		Initialize a Stein closure with a prototype, implementation, a signature describing it's prototype, and an evaluator to apply it with.
 @param			prototype		The prototype of the closure in the form of an STList of symbols. May not be nil.
 @param			implementation	The implementation of the closure in the form of an STList of Stein expressions. May not be nil.
 @param			signature		A method signature object describing the types of the names in prototype as well as the return type of the closure.
 @param			evaluator		The evaluator to use when applying the closure.
 @param			superscope		The scope that encloses the closure being created.
 @result		A fully initialized Stein closure object ready for use.
 @discussion	This is the designated initializer of STClosure.
 */
- (id)initWithPrototype:(STList *)prototype forImplementation:(STList *)implementation withSignature:(NSMethodSignature *)signature fromEvaluator:(STEvaluator *)evaluator inScope:(NSMutableDictionary *)superscope;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract		The closure's native function pointer suitable for use anywhere a function pointer is expected.
 @discussion	Only closure's who have had type signature's specified can produce a valid function pointer.
 */
@property (readonly) void *functionPointer;

#pragma mark -

/*!
 @property
 @abstract	The evaluator to use when the closure is applied.
 */
@property (readonly) STEvaluator *evaluator;

/*!
 @property
 @abstract	The superscope of the closure.
 */
@property (readonly) NSMutableDictionary *superscope;

/*!
 @property
 @abstract		This property is provided for closures that serve as the implementation for methods.
 @discussion	When this property is set, the closure will set a value for the key kSTEvaluatorSuperclassKey
				in it's scope. This allows the super function to be used.
 */
@property (assign) Class superclass;

/*!
 @property
 @abstract		The name of the closure.
 @discussion	This is typically set by the function operator.
 */
@property (copy) NSString *name;

#pragma mark -

/*!
 @property
 @abstract	A method signature object describing the closure's arguments and return type.
 */
@property (readonly) NSMethodSignature *closureSignature;

/*!
 @property
 @abstract	An STList of symbols describing the closure's arguments.
 */
@property (readonly) STList *prototype;

/*!
 @property
 @abstract	An STList of expressions describing the closure's implementation.
 */
@property (readonly) STList *implementation;

#pragma mark -
#pragma mark Looping

/*!
 @method
 @abstract	Repeatedly apply the receiver until the result it returns is false, invoking a specified block each time it is true.
 @param		closure		The closure to apply for each loop.
 @result	The last value returned from the specified closure.
 */
- (id)whileTrue:(STClosure *)closure;

/*!
 @method
 @abstract	Repeatedly apply the receiver until the result it returns is true, invoking a specified block each time it is false.
 @param		closure		The closure to apply for each loop.
 @result	The last value returned from the specified closure.
 */
- (id)whileFalse:(STClosure *)closure;

#pragma mark -
#pragma mark Exception Handling

/*!
 @method
 @abstract	Invoke the receiver in the context of a try..catch block, invoking a specified block if an exception occurs.
 @param		closure		The closure to invoke if an exception is raised while evaluating the receiver.
 @result	YES if an exception was raised while evaluating the receiver; NO otherwise.
 */
- (BOOL)onException:(STClosure *)closure;

@end
