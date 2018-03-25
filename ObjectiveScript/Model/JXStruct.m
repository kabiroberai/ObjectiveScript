//
//  JXStruct.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 18/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <ffi.h>
#import "JXJSInterop.h"
#import "JXStruct.h"
#import "JXStructType.h"

@implementation JXStruct {
	size_t *_offsets;
	JXStructType *_type;
    BOOL _isCopy;
}

- (instancetype)initWithVal:(void *)val type:(const char *)type copy:(BOOL)copy {
	self = [super init];
	if (self) {
		_type = (JXStructType *)JXTypeForEncoding(type);

        _name = _type.name;

        ffi_type *ffiType = [_type ffiType];
        size_t nelements = _type.types.count;
		_offsets = malloc(sizeof(size_t) * nelements);
		// fully populate type and get offsets
		ffi_get_struct_offsets(FFI_DEFAULT_ABI, ffiType, _offsets);

        _isCopy = copy;
        if (copy) {
            _val = malloc(ffiType->size);
            memcpy(_val, val, ffiType->size);
        } else {
            _val = val;
        }
        
        JXFreeFFIType(ffiType);
	}
	return self;
}

+ (instancetype)structWithVal:(void *)val type:(const char *)type copy:(BOOL)copy {
	return [[JXStruct alloc] initWithVal:val type:type copy:copy];
}

- (void *)getValueWithName:(NSString *)name type:(const char **)type {
    size_t idx;

    // name is either a number or a field name
    if (_type.fieldNames) {
        // return the value at the index corresponding to the field name
        idx = [_type.fieldNames indexOfObject:name];
    } else {
        idx = name.intValue;
    }

    *type = _type.types[idx].encoding.UTF8String;
    return self.val + _offsets[idx];
}

- (NSString *)descriptionWithContext:(JSContext *)ctx {
    if (_type.fieldNames) {
        // get the js description of each field and add them to an array
        // output is similar to `po struct` in lldb
        NSMutableArray *fields = [NSMutableArray array];
        for (NSUInteger i = 0; i < _type.types.count; i++) {
            NSString *fieldName = _type.fieldNames[i];
            const char *type;
            void *val = [self getValueWithName:fieldName type:&type];
            JSValue *jsVal = JXConvertToJSValue(val, type, ctx, JXInteropOptionRetain | JXInteropOptionAutorelease);
            [fields addObject:[NSString stringWithFormat:@"%@ = %@", fieldName, jsVal]];
        }
        return [NSString stringWithFormat:@"(%@)", [fields componentsJoinedByString:@", "]];
    } else {
        return [NSString stringWithFormat:@"%p", self];
    }
}

- (JSValue *)jsPropertyForKey:(NSString *)key ctx:(JSContext *)ctx {
    if ([key isEqualToString:@"Symbol.toPrimitive"]) {
        // Symbol.toPrimitive should be a function that returns the struct address/name as a JSValue.
        NSString *ret = [self descriptionWithContext:ctx];
        return [JSValue valueWithObject:^NSString *{
            return ret;
        } inContext:ctx];
    } else if ([key isEqualToString:@"withType"]) {
        JXInteropOptions options = JXInteropOptionRetain | JXInteropOptionAutorelease;
        if (_isCopy) options |= JXInteropOptionCopyStructs;
        return [JSValue valueWithObject:^JSValue *(NSString *type) {
            return JXConvertToJSValue(self.val, type.UTF8String, [JSContext currentContext], options);
        } inContext:ctx];
    }

    const char *type;
    void *val = [self getValueWithName:key type:&type];
    return JXConvertToJSValue(val, type, ctx, JXInteropOptionRetain | JXInteropOptionAutorelease);
}

- (void)setJSProperty:(JSValue *)property forKey:(NSString *)key ctx:(JSContext *)ctx {
    const char *type;
    void *addr = [self getValueWithName:key type:&type];

    JXConvertFromJSValue(property, type, ^(void *newVal) {
        memcpy(addr, newVal, JXSizeForEncoding(type));
    });
}

- (void)dealloc {
	free(_offsets);
    if (_isCopy) {
        // only free _val if we malloc'd it ourselves
        free(_val);
    }
}

@end
