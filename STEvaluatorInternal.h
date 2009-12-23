/*
 *  STEvaluatorInternal.h
 *  stein
 *
 *  Created by Peter MacWhinnie on 09/12/22.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#import <Cocoa/Cocoa.h>
#import "STEvaluator.h"

@class STList;

ST_EXTERN id __STSendMessageWithTargetAndArguments(STEvaluator *self, id target, STList *arguments, NSMutableDictionary *scope);
ST_EXTERN id __STEvaluateList(STEvaluator *self, STList *list, NSMutableDictionary *scope);
ST_EXTERN id __STEvaluateExpression(STEvaluator *self, id expression, NSMutableDictionary *scope);