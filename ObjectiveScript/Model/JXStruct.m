//
//  JXStruct.m
//  ObjectiveScript
//
//  Created by Kabir Oberai on 18/01/18.
//  Copyright © 2018 Kabir Oberai. All rights reserved.
//

#import <ffi.h>
#import "NSString+IsNumeric.h"
#import "JXJSInterop.h"
#import "JXStruct.h"
#import "JXTypeStruct+FFI.h"
#import "JXContextManager.h"

@implementation JXStruct {
	size_t *_offsets;
	JXTypeStruct *_type;
    BOOL _isCopy;
}

- (instancetype)initWithVal:(void *)val type:(const char *)type copy:(BOOL)copy context:(JSContext *)ctx {
	self = [super init];
	if (self) {
        _rawType = @(type);

		_type = [JXTypeStruct typeForEncodingC:type];
        if (!_type) {
            ctx.exception = JXConvertToError(JXCreateException(@"Could not initialize struct: invalid type"), ctx);
            return nil;
        }

        _name = _type.name;

        if (!_type.types) {
            ctx.exception = JXConvertToError(JXCreateException(@"Could not initialize struct: type metadata not found"), ctx);
            return nil;
        }

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

+ (instancetype)structWithVal:(void *)val type:(const char *)type copy:(BOOL)copy context:(JSContext *)ctx {
	return [[JXStruct alloc] initWithVal:val type:type copy:copy context:ctx];
}

- (nullable void *)getValueWithName:(NSString *)name type:(const char **)type context:(JSContext *)ctx {
    size_t idx;

    // name is either a number or a field name
    if (name.isNumeric) {
        idx = name.intValue;
    } else if (_type.fieldNames) {
        // return the value at the index corresponding to the field name
        idx = [_type.fieldNames indexOfObject:name];
    } else {
        // not a number and there are no field names, oops
        ctx.exception = JXConvertToError(JXCreateExceptionFormat(@"Could not access field %@ in struct %@: field name metadata not found", name, _type.name), ctx);
        return NULL;
    }

    if (idx >= _type.types.count) {
        ctx.exception = JXConvertToError(JXCreateExceptionFormat(@"Could not access field %@ in struct %@: index %lu out of bounds", name, _type.name, (unsigned long)idx), ctx);
        return NULL;
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
            void *val = [self getValueWithName:fieldName type:&type context:ctx];
            JSValue *jsVal = JXConvertToJSValue(val, type, ctx, JXInteropOptionDefault);
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
    }

    const char *type;
    void *val = [self getValueWithName:key type:&type context:ctx];
    return JXConvertToJSValue(val, type, ctx, JXInteropOptionDefault);
}

- (void)setJSProperty:(JSValue *)property forKey:(NSString *)key ctx:(JSContext *)ctx {
    const char *type;
    void *addr = [self getValueWithName:key type:&type context:ctx];
    if (!addr) return;

    JXConvertFromJSValue(property, type, ^(void *newVal) {
        memcpy(addr, newVal, JXSizeForEncoding(type));
    });
}

- (NSString *)extendedTypeInContext:(JSContext *)ctx {
    return [JXContextManager.sharedManager JXContextForJSContext:ctx].structDefs[self.name];
}

- (nullable JXStruct *)withType:(const char *)newType context:(JSContext *)ctx {
    return [JXStruct structWithVal:self.val type:newType copy:YES context:ctx];
}

- (void)dealloc {
	free(_offsets);
    if (_isCopy) {
        // only free _val if we malloc'd it ourselves
        free(_val);
    }
}

@end
