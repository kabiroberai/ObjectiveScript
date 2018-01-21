//
//  Hooking.m
//  FFITesting
//
//  Created by Kabir Oberai on 13/12/17.
//  Copyright © 2017 Kabir Oberai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "JXRuntimeInterface.h"
#import "JXStruct.h"
#import "JXJSInterop.h"
#import "Block.h"

@interface NSInvocation (Hax)

- (void)invokeUsingIMP:(IMP)imp;

@end

// [class : [ivar : key]]
static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *allAssociatedObjects;

static JSClassRef JXGlobalClass;
static JSClassRef JXFunctionClass;
JSClassRef JXObjectClass;
JSClassRef JXAutoreleasingObjectClass;

// iterate through the methods of JS dict `obj`
static void iterateMethods(JSValue *dict, void (^iter)(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig)) {
	// .context returns the JSContext of the JSValue
	NSArray *methodNames = JXKeysOfDict(dict);
	// Loop through all names
	for (NSString *methodName in methodNames) {
		// Get the func associated with methodName
		JSValue *func = dict[methodName];
		
		// eg. v@:-viewDidload will result in isClassMethod=NO, components=["v@:", "viewDidLoad"]
		BOOL isClassMethod = [methodName containsString:@"+"];
		NSArray<NSString *> *components = [methodName componentsSeparatedByString:(isClassMethod ? @"+" : @"-")];
		NSString *sig = components[0];
		NSString *methodName = components[1];
		
		SEL sel = NSSelectorFromString(methodName);
		iter(func, isClassMethod, sel, sig);
	}
}

static void registerAssociatedObjects(NSDictionary<NSString *, NSString *> *associatedObjects, NSString *clsName) {
	// Add associated object keys
	// Get the existing keys for this class
	NSMutableDictionary *dict = allAssociatedObjects[clsName];
	if (!dict) {
		dict = [NSMutableDictionary new];
		allAssociatedObjects[clsName] = dict;
	}
	[dict addEntriesFromDictionary:associatedObjects];
}

static NSString *stringFromJSStringRef(JSStringRef ref) {
	CFStringRef cfName = JSStringCopyCFString(kCFAllocatorDefault, ref);
	return (__bridge_transfer NSString *)cfName;
}

static JSContext *contextFromJSContextRef(JSContextRef ref) {
	JSGlobalContextRef global = JSContextGetGlobalContext(ref);
	return [JSContext contextWithJSGlobalContextRef:global];
}

static const void *keyForAssociatedObject(NSString *name, id obj) {
	NSString *key = allAssociatedObjects[NSStringFromClass([obj class])][name];
	return (__bridge const void *)key;
}

// TODO: Fix ivar memory management (allow different OBJC_ASSOCIATIONs)

// Intercept global getProperty calls to return a class with the name propertyName if there isn't an object by the same name
static JSValueRef globalGetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef *exception) {
	NSString *propertyName = stringFromJSStringRef(propertyNameJS);
	
	// Skip any blacklisted properties to let JS handle them by returning NULL
	// self is blacklisted to avoid unwanted recursion due to the currSelfJS statement below
	NSArray<NSString *> *blacklist = @[@"Object", @"self"];
	if ([blacklist containsObject:propertyName]) return NULL;
	
	JX_DEBUG(@"Searching for class %@", propertyName);
	
	JSContext *ctx = contextFromJSContextRef(ctxRef);
	JSValue *currSelfJS = ctx[@"self"];
	id currSelf = JXObjectFromJSValue(currSelfJS);
	// can't check for currSelfJS.isUndefined because that's true when using JXObject
	if (currSelf) {
		const void *key = keyForAssociatedObject(propertyName, currSelf);
		if (key) {
			id obj = objc_getAssociatedObject(currSelf, key);
			return JXObjectToJSValue(obj, ctx).JSValueRef;
		}
	}
	
	// Otherwise return the ObjC class named propertyName (if any)
	Class cls = NSClassFromString(propertyName);
	if (!cls) return NULL;
	return JXObjectToJSValue(cls, ctx).JSValueRef;
}

static bool globalSetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS,
							  JSValueRef valueRef, JSValueRef *exception) {
	NSString *propertyName = stringFromJSStringRef(propertyNameJS);
	
	// Skip any blacklisted properties to let JS handle them by returning NULL
	NSArray<NSString *> *blacklist = @[@"Object"];
	if ([blacklist containsObject:propertyName]) return false;
	
	JSContext *ctx = contextFromJSContextRef(ctxRef);
	JSValue *currSelfJS = ctx[@"self"];
	if (currSelfJS.isUndefined) return false;
	JSValue *valueJS = [JSValue valueWithJSValueRef:valueRef inContext:ctx];
	// otherwise treat propertyName as an ivar on currentSelf
	id currSelf = JXObjectFromJSValue(currSelfJS);
	const void *key = keyForAssociatedObject(propertyName, currSelf);
	if (!key) return false;
	id value = JXObjectFromJSValue(valueJS);
	if (!value) return false;
	objc_setAssociatedObject(currSelf, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	return true;
}

// Returns a JXFunctionClass that holds the selector that was specified as propertyName
// When JXFunctionClass is called as a function, it passes the selector, `this` (i.e. the JXObjectClass), and arguments to msgSend
static JSValueRef objectGetProperty(JSContextRef ctxRef, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef *exception) {
	NSString *propertyName = stringFromJSStringRef(propertyNameJS);
	
	id __unsafe_unretained private = (__bridge id __unsafe_unretained)JSObjectGetPrivate(object);
	
	if ([private isKindOfClass:JXStruct.class]) {
		JXStruct *jxStruct = (JXStruct *)private;
		const char *type;
		void *val = [jxStruct getValueAtIndex:propertyName.intValue type:&type];
		JSContext *ctx = contextFromJSContextRef(ctxRef);
		// memoryMode doesn't really matter here because structs can't contain objects (when using ARC)
		JSValue *jsVal = JXConvertToJSValue(val, type, ctx, JXMemoryModeStrong);
		return jsVal.JSValueRef;
	}
	
	return JSObjectMake(ctxRef, JXFunctionClass, (__bridge_retained void *)propertyName);
}

static void releasePrivate(JSObjectRef object) {
	// We can't retrieve objects directly during finalize, so get the
	// private val of the object and then call dealloc later, on the main queue
	// TODO: Figure out if this causes any threading issues
	void *private = JSObjectGetPrivate(object);
	JX_DEBUG(@"Releasing %@", (__bridge id)private);
	dispatch_async(dispatch_get_main_queue(), ^{
		CFRelease(private);
	});
}

static JSValueRef callAsFunction(JSContextRef jsCtx, JSObjectRef function, JSObjectRef objRef,
						  size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception) {
	JSContext *ctx = contextFromJSContextRef(jsCtx);

	JSValue *objJS = [JSValue valueWithJSValueRef:objRef inContext:ctx];
	id obj = JXObjectFromJSValue(objJS);
	
	NSString *selName = (__bridge id)JSObjectGetPrivate(function);

	JSValue *args = [JSValue valueWithNewArrayInContext:ctx];
	for (size_t i = 0; i < argumentCount; i++) {
		args[i] = [JSValue valueWithJSValueRef:arguments[i] inContext:ctx];
	}
	
	BOOL isSuper = NO;
	if ([selName hasPrefix:@"^"]) {
		selName = [selName substringFromIndex:1];
		isSuper = YES;
	}
	
	// TODO: Add varargs support if possible (although even Swift-ObjC interop doesn't have it)
	
	size_t implicitArgs = argumentCount; // the number of trailing colons to add
	// decrement the number of implicit colons every time we see one explicitly added
	for (int i = 0; i < [selName lengthOfBytesUsingEncoding:NSUTF8StringEncoding]; i++) {
		if ([selName characterAtIndex:i] == ':') implicitArgs--;
	}
	// add the final num of implicit colons to the end
	selName = [selName stringByPaddingToLength:selName.length+implicitArgs withString:@":" startingAtIndex:0];
	
	Class cls = isSuper ? [NSClassFromString([ctx[@"clsName"] toString]) superclass] : [obj class];
	
	JSValue *jsVal;
	@try {
		jsVal = JXMsgSend(cls, ctx, obj, selName, args);
	} @catch (NSException *e) {
		*exception = JXConvertToError(e, ctx).JSValueRef;
	}
	return jsVal.JSValueRef;
}

static void setup() {
	allAssociatedObjects = [NSMutableDictionary new];
	
	// https://code.google.com/archive/p/jscocoa/wikis/JavascriptCore.wiki
	JSClassDefinition globalDef = kJSClassDefinitionEmpty;
	globalDef.getProperty = globalGetProperty;
	globalDef.setProperty = globalSetProperty;
	JXGlobalClass = JSClassCreate(&globalDef);
	
	JSClassDefinition functionDef = kJSClassDefinitionEmpty;
	functionDef.callAsFunction = callAsFunction;
	functionDef.finalize = releasePrivate;
	JXFunctionClass = JSClassCreate(&functionDef);
	
	JSClassDefinition objectDef = kJSClassDefinitionEmpty;
	objectDef.getProperty = objectGetProperty;
	JXObjectClass = JSClassCreate(&objectDef);
	
	JSClassDefinition autoreleasingObjectDef = kJSClassDefinitionEmpty;
	autoreleasingObjectDef.parentClass = JXObjectClass;
	autoreleasingObjectDef.finalize = releasePrivate;
	JXAutoreleasingObjectClass = JSClassCreate(&autoreleasingObjectDef);
}

// Called when a custom block is copied
static void copyHelper(struct JXBlockLiteral *dst, const struct JXBlockLiteral *src) {
	_Block_object_assign(&dst->info, src->info, BLOCK_FIELD_IS_OBJECT);
}

// Called when a custom block is disposed
static void disposeHelper(const struct JXBlockLiteral *src) {
	free(src->descriptor);
	_Block_object_dispose(src->info, BLOCK_FIELD_IS_OBJECT);
}

// non-static so that it can be tested
JSContext *JXCreateContext() {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{ setup(); });
	
	JSGlobalContextRef ctxRef = JSGlobalContextCreate(JXGlobalClass);
	JSContext *ctx = [JSContext contextWithJSGlobalContextRef:ctxRef];
	// ctx retains ctxRef, so we can release our ownership
	JSGlobalContextRelease(ctxRef);
	
	ctx.exceptionHandler = ^(JSContext *ctx, JSValue *error) {
		@throw JXConvertFromError(error);
	};
	
	// For logging messages
	ctx[@"NSLog"] = ^(JSValue *msg) {
		NSLog(@"%@", [msg toString]);
	};
	
	// Create the JS method hookClass(name: String, hooks: { String : Function })
	ctx[@"hookClass"] = ^(NSString *clsName, NSDictionary<NSString *, NSString *> *associatedObjects, JSValue *hooks) {
		Class cls = NSClassFromString(clsName);
		registerAssociatedObjects(associatedObjects, clsName);
		@try {
			iterateMethods(hooks, ^(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig) {
				JXSwizzle(func, cls, isClassMethod, sel, sig);
			});
		} @catch (NSException *e) {
			JSContext *ctx = [JSContext currentContext];
			ctx.exception = JXConvertToError(e, ctx);
		}
	};
	
	ctx[@"defineClass"] = ^(NSString *clsName, NSString *superclsName,
							NSArray<NSString *> *protoList, NSDictionary<NSString *, NSString *> *associatedObjects,
							JSValue *methods) {
		// Allocate class
		Class superclass = NSClassFromString(superclsName);
		Class cls = objc_allocateClassPair(superclass, clsName.UTF8String, 0);
		
		// Add protocols
		for (NSString *proto in protoList) {
			Protocol *protocol = objc_getProtocol(proto.UTF8String);
			class_addProtocol(cls, protocol);
		}
		
		// Add methods
		iterateMethods(methods, ^(JSValue *func, BOOL isClassMethod, SEL sel, NSString *sig) {
			const char *types = sig.UTF8String;
			JXTrampInfo *info = JXCreateTramp(func, types, cls);
			[info retainForever];
			class_addMethod(cls, sel, info.tramp, types);
		});
		
		// Register class
		objc_registerClassPair(cls);
		
		// Register associated objects
		registerAssociatedObjects(associatedObjects, clsName);
	};
	
	ctx[@"defineBlock"] = ^JSValue *(NSString *sig, JSValue *func) {
		JXTrampInfo *info = JXCreateTramp(func, sig.UTF8String, nil);
		
		int flags = BLOCK_HAS_SIGNATURE | BLOCK_HAS_COPY_DISPOSE;
		// TODO: check if sig has struct return
		BOOL hasStret = NO;
		if (hasStret) {
			flags |= BLOCK_HAS_STRET;
		}
		
		struct JXBlockDescriptor *descriptor = malloc(sizeof(struct JXBlockDescriptor));
		*descriptor = (struct JXBlockDescriptor) {
			.size = sizeof(struct JXBlockLiteral),
			.copyHelper = copyHelper,
			.disposeHelper = disposeHelper,
			.signature = info.types
		};
		
		struct JXBlockLiteral block = {
			.isa = &_NSConcreteStackBlock,
			.flags = flags,
			.invoke = info.tramp,
			.descriptor = descriptor,
			.info = (__bridge CFTypeRef)info,
		};
		
		return JXObjectToJSValue((__bridge Block)&block, [JSContext currentContext]);
	};
	
	ctx[@"box"] = ^JSValue *(JSValue *val) {
		id unboxedVal = JXObjectFromJSValue(val);
		return JXObjectToJSValue(unboxedVal, [JSContext currentContext]);
	};
	
	ctx[@"unbox"] = ^id(JSValue *val) {
		id obj = JXObjectFromJSValue(val);
		// TODO: Can JXObjectClass values be preserved here?
		return [obj copy];
	};
	
	return ctx;
}

void JXRunScript(NSString *script, NSString *resourcesPath) {
	JSContext *ctx = JXCreateContext();
	ctx[@"resourcesPath"] = JXObjectToJSValue(resourcesPath, ctx);
	[ctx evaluateScript:script];
}

