//
//  STParser.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STParser.h"
#import "STSymbol.h"
#import "STList.h"
#import "STStringWithCode.h"

#pragma mark Forward Declarations

static STList *GetExpressionAt(NSUInteger *ioIndex, NSString *string, BOOL usingDoNotation, BOOL isUnbordered, STEvaluator *targetEvaluator);

#pragma mark -
#pragma mark Tools

static inline unichar SafelyGetCharacterAtIndex(NSString *string, NSUInteger index)
{
	if(index >= [string length])
		return 0;
	
	return [string characterAtIndex:index];
}

#pragma mark -
#pragma mark Character Definitions

#define LIST_QUOTE_CHARACTER				'\''

#define LIST_OPEN_CHARACTER					'('
#define LIST_CLOSE_CHARACTER				')'

#define DO_LIST_OPEN_CHARACTER				'['
#define DO_LIST_CLOSE_CHARACTER				']'

#define STRING_OPEN_CHARACTER				'"'
#define STRING_CLOSE_CHARACTER				'"'

#define SINGLELINE_COMMENT_CHARACTER		';'
#define	MULTILINE_COMMENT_OPEN_CHARACTER	'`'
#define	MULTILINE_COMMENT_CLOSE_CHARACTER	'`'

#define UNBORDERED_LIST_CLOSE_CHARACTER		','

#pragma mark -
#pragma mark Checkers

static inline BOOL IsCharacterWhitespace(unichar character)
{
	return (character == ' ' || character == '\t' || character == '\n' || character == '\r');
}

static inline BOOL IsCharacterNewline(unichar character)
{
	return (character == '\n' || character == '\r');
}

static inline BOOL IsCharacterPartOfNumber(unichar character, BOOL isFirstCharacter)
{
	return isnumber(character) || (!isFirstCharacter && character == '.');
}

static inline BOOL IsCharacterPartOfIdentifier(unichar character, BOOL isFirstCharacter)
{
	return (character != LIST_QUOTE_CHARACTER && 
			character != LIST_OPEN_CHARACTER && 
			character != LIST_CLOSE_CHARACTER &&
			character != DO_LIST_OPEN_CHARACTER &&
			character != DO_LIST_CLOSE_CHARACTER &&
			character != UNBORDERED_LIST_CLOSE_CHARACTER &&
			!IsCharacterWhitespace(character) && 
			(isFirstCharacter || !IsCharacterPartOfNumber(character, NO)));
}

#pragma mark -
#pragma mark Parsers

static void IgnoreCommentAt(NSUInteger *ioIndex, NSString *string, BOOL isMultiline)
{
	//If we're skipping a multi-line comment, we need to ignore the
	//opening character or we'll end up causing an infinite loop.
	if(isMultiline)
		(*ioIndex)++;
	
	NSUInteger stringLength = [string length];
	for (NSUInteger index = *ioIndex; index < stringLength; index++)
	{
		unichar character = [string characterAtIndex:index];
		if(character == '\\')
		{
			continue;
		}
		else if((isMultiline && character == MULTILINE_COMMENT_CLOSE_CHARACTER) || 
				(!isMultiline && IsCharacterNewline(character)))
		{
			if(isMultiline)
				*ioIndex = index;
			else
				*ioIndex = index - 1;
			
			return;
		}
	}
	
	//We only reach here if we EOF without finding a newline.
	*ioIndex = stringLength - 1;
}

#pragma mark -

static NSNumber *GetNumberAt(NSUInteger *ioIndex, NSString *string)
{
	NSRange numberRange;
	numberRange.location = *ioIndex;
	numberRange.length = NSNotFound;
	
	NSUInteger stringLength = [string length];
	for (NSUInteger index = *ioIndex; index < stringLength; index++)
	{
		unichar character = [string characterAtIndex:index];
		if(!IsCharacterPartOfNumber(character, (index == *ioIndex)))
		{
			numberRange.length = (index - numberRange.location);
			*ioIndex = index - 1;
			
			break;
		}
	}
	if(numberRange.length == NSNotFound)
	{
		numberRange.length = ([string length] - *ioIndex);
		*ioIndex = [string length];
	}
	
	return [NSNumber numberWithDouble:[[string substringWithRange:numberRange] doubleValue]];
}

static id GetStringAt(NSUInteger *ioIndex, NSString *string, STEvaluator *evaluator)
{
	NSMutableString *resultString = [NSMutableString string];
	STStringWithCode *resultStringWithCode = nil;
	
	NSUInteger stringLength = [string length];
	for (NSUInteger index = (*ioIndex) + 1; index < stringLength; index++)
	{
		unichar character = [string characterAtIndex:index];
		if(character == STRING_CLOSE_CHARACTER)
		{
			*ioIndex = index;
			
			break;
		}
		
		if(character == '\\')
		{
			unichar escapeCharacter = SafelyGetCharacterAtIndex(string, index + 1);
			NSCAssert((escapeCharacter != 0), @"Escape token found at end of file.");
			
			switch (escapeCharacter)
			{
				case 'a':
					[resultString appendString:@"\a"];
					break;
					
				case 'b':
					[resultString appendString:@"\b"];
					break;
					
				case 'f':
					[resultString appendString:@"\f"];
					break;
					
				case 'n':
					[resultString appendString:@"\n"];
					break;
					
				case 'r':
					[resultString appendString:@"\r"];
					break;
					
				case 't':
					[resultString appendString:@"\t"];
					break;
					
				case 'v':
					[resultString appendString:@"\v"];
					break;
					
				case '\'':
					[resultString appendString:@"\'"];
					break;
					
				case '"':
					[resultString appendString:@"\""];
					break;
					
				case '\\':
					[resultString appendString:@"\\"];
					break;
					
				case '?':
					[resultString appendString:@"\?"];
					break;
				
				case '%':
					[resultString appendString:@"%"];
					break;
					
				default:
					break;
			}
			
			//Move past the escape sequence
			index++;
		}
		else if(character == '%' && SafelyGetCharacterAtIndex(string, index + 1) == '{')
		{
			//Find the closing bracket.
			NSRange codeRange = NSMakeRange(index - 1, 0);
			NSUInteger numberOfNestedBrackets = 0;
			for (NSUInteger bracketSearchIndex = index; bracketSearchIndex < stringLength; bracketSearchIndex++)
			{
				unichar innerCharacter = [string characterAtIndex:bracketSearchIndex];
				[resultString appendFormat:@"%C", innerCharacter];
				
				if(innerCharacter == '{')
				{
					numberOfNestedBrackets++;
				}
				else if(innerCharacter == '}')
				{
					numberOfNestedBrackets--;
					if(numberOfNestedBrackets == 0)
					{
						codeRange.length = bracketSearchIndex - codeRange.location;
						index = bracketSearchIndex;
						
						break;
					}
				}
			}
			
			NSString *expressionString = [string substringWithRange:NSMakeRange(codeRange.location + 3, 
																				codeRange.length - 3)];
			NSUInteger expressionStringIndex = 0;
			id expression = GetExpressionAt(&expressionStringIndex, expressionString, NO, YES, evaluator);
			if(!resultStringWithCode)
				resultStringWithCode = [STStringWithCode new];
			
			[resultStringWithCode addExpression:expression inRange:NSMakeRange(codeRange.location, codeRange.length)];
		}
		else
		{
			[resultString appendFormat:@"%C", character];
		}
	}
	
	if(resultStringWithCode)
	{
		resultStringWithCode.string = resultString;
		return resultStringWithCode;
	}
	
	return resultString;
}

static STSymbol *GetIdentifierAt(NSUInteger *ioIndex, NSString *string)
{
	NSRange identifierRange;
	identifierRange.location = *ioIndex;
	identifierRange.length = NSNotFound;
	
	NSUInteger stringLength = [string length];
	for (NSUInteger index = *ioIndex; index < stringLength; index++)
	{
		unichar character = [string characterAtIndex:index];
		if(!IsCharacterPartOfIdentifier(character, (index == *ioIndex)) || (character == ':'))
		{
			if(character == ':')
				index++;
			
			identifierRange.length = (index - identifierRange.location);
			*ioIndex = index - 1;
			
			break;
		}
	}
	if(identifierRange.length == NSNotFound)
	{
		identifierRange.length = ([string length] - *ioIndex);
		*ioIndex = [string length];
	}
	
	return [STSymbol symbolWithString:[string substringWithRange:identifierRange]];
}

static STList *GetExpressionAt(NSUInteger *ioIndex, NSString *string, BOOL usingDoNotation, BOOL isUnbordered, STEvaluator *targetEvaluator)
{
	STList *expression = [STList list];
	expression.evaluator = targetEvaluator;
	
	NSUInteger index = *ioIndex;
	if(usingDoNotation)
	{
		index++;
		
		expression.isQuoted = YES;
		expression.isDoConstruct = YES;
	}
	else if(!isUnbordered)
	{
		index++;
		
		if([string characterAtIndex:*ioIndex] == LIST_QUOTE_CHARACTER)
		{
			index++;
			expression.isQuoted = YES;
		}
	}
	
	NSUInteger stringLength = [string length];
	for (; index < stringLength; index++)
	{
		unichar character = [string characterAtIndex:index];
		
		if(character == DO_LIST_CLOSE_CHARACTER)
		{
			//If we're unbordered then we need to move back one character
			//so that any containing do-dot statement will see it's closing
			//character. This will also result in error reporting when a
			//dot is used outside of a do-dot statement.
			if(isUnbordered)
				index--;
			
			break;
		}
		
		//If we're unbordered and we've encountered a newline, our expression is done.
		if(isUnbordered && (character == UNBORDERED_LIST_CLOSE_CHARACTER || IsCharacterNewline(character)))
		{
			break;
		}
		//If we encounter whitespace we just ignore it.
		else if(IsCharacterWhitespace(character))
		{
			continue;
		}
		//If we encounter a backslash, we skip the next character
		else if(character == '\\')
		{
			index++;
			continue;
		}
		//If we encounter a comment, we just move to the end of it, ignoring it's contents.
		else if(character == SINGLELINE_COMMENT_CHARACTER || character == MULTILINE_COMMENT_OPEN_CHARACTER)
		{
			IgnoreCommentAt(&index, string, (character == MULTILINE_COMMENT_OPEN_CHARACTER));
		}
		//If we encounter the word 'do' at the end of a line, we start do-notation expression parsing.
		else if(character == DO_LIST_OPEN_CHARACTER)
		{
			[expression addObject:GetExpressionAt(&index, string, YES, NO, targetEvaluator)];
		}
		//If we're in do-notation, and we've gotten this far, we're looking for subexpressions.
		else if(usingDoNotation)
		{
			[expression addObject:GetExpressionAt(&index, string, NO, YES, targetEvaluator)];
		}
		//If we find part of a number, we read it and add it to our expression.
		else if(IsCharacterPartOfNumber(character, YES))
		{
			[expression addObject:GetNumberAt(&index, string)];
		}
		//If we find a string, we read it and add it to our expression.
		else if(character == STRING_OPEN_CHARACTER)
		{
			[expression addObject:GetStringAt(&index, string, targetEvaluator)];
		}
		//If we find part of an identifier, we read it and add it to our expression.
		else if(IsCharacterPartOfIdentifier(character, YES))
		{
			[expression addObject:GetIdentifierAt(&index, string)];
		}
		//If we find a quote character we scan the next subexpression as a quoted list.
		else if(character == LIST_QUOTE_CHARACTER)
		{
			unichar secondCharacter = SafelyGetCharacterAtIndex(string, index + 1);
			NSCAssert((secondCharacter != 0), 
					  @"Unexpected quote token at the end of a file.");
			
			if(secondCharacter == LIST_OPEN_CHARACTER)
			{
				[expression addObject:GetExpressionAt(&index, string, NO, NO, targetEvaluator)];
			}
			else
			{
				//Move past the opening quote.
				index++;
				
				STSymbol *identifier = GetIdentifierAt(&index, string);
				identifier.isQuoted = YES;
				[expression addObject:identifier];
			}
		}
		//If we encounter the list open character we scan the next subexpression.
		else if(character == LIST_OPEN_CHARACTER)
		{
			[expression addObject:GetExpressionAt(&index, string, NO, NO, targetEvaluator)];
		}
		//If we encounter the list close character, we're done this expression and return.
		else if(character == LIST_CLOSE_CHARACTER)
		{
			break;
		}
		//If we reach here, we've encountered an unexpected token.
		else
		{
			NSCAssert(0, @"Unexpected token '%C'.", character);
		}
	}
	*ioIndex = index;
	
	return expression;
}

#pragma mark -
#pragma mark Exported Interface

NSArray *STParseString(NSString *string, STEvaluator *targetEvaluator)
{
	NSCParameterAssert(string);
	
	NSMutableArray *expressions = [NSMutableArray array];
	
	NSUInteger stringLength = [string length];
	for (NSUInteger index = 0; index < stringLength; index++)
	{
		unichar character = [string characterAtIndex:index];
		
		//We ignore whitespace, it doesn't really do anything.
		if(IsCharacterWhitespace(character))
		{
			continue;
		}
		//If we encounter a backslash, we skip the next character
		else if(character == '\\')
		{
			index++;
			continue;
		}
		//When we encounter comments, we move to the end of them and ignore their contents.
		else if(character == SINGLELINE_COMMENT_CHARACTER || character == MULTILINE_COMMENT_OPEN_CHARACTER)
		{
			IgnoreCommentAt(&index, string, (character == MULTILINE_COMMENT_OPEN_CHARACTER));
		}
		//When we reach this clause it's time to start parsing the line as though it's an expression.
		else
		{
			[expressions addObject:GetExpressionAt(&index, string, NO, YES, targetEvaluator)];
		}
	}
	
	return expressions;
}
