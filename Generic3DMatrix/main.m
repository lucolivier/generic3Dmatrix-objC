//
//  main.m
//  Generic3DMatrix
//
//  Created by Luc-Olivier on 5/5/16.
//  Copyright © 2016 Luc-Olivier. All rights reserved.
//

#import <Foundation/Foundation.h>
#define _c(s) [s cStringUsingEncoding:NSUTF8StringEncoding]
#define _n(n) _c([n stringValue])
#define _ps(s) printf("%s\n", s)

typedef unsigned int UInt;

static NSArray *Matrix3DExceptionNames = nil;

typedef enum {
    M3DE_OutOfRange,
    M3DE_BadObjectType
} Matrix3DException_t;
@interface Matrix3DExceptions : NSObject {
}
+ (void) setNames;
+ (NSString*) name: (Matrix3DException_t) name;
+ (NSException*) exception: (Matrix3DException_t) name;
@end
@implementation Matrix3DExceptions
+ (void) setNames {
    Matrix3DExceptionNames = @[
                               @"M3DE_OutOfRange",
                               @"M3DE_BadObjectType"
                               ];
}
+ (NSString*) name: (Matrix3DException_t) name {
    return Matrix3DExceptionNames[name];
}
+ (NSException*) exception: (Matrix3DException_t) name {
    return [NSException exceptionWithName:Matrix3DExceptionNames[name] reason:nil userInfo:nil];
}
@end

@interface ErrorBunch : NSObject
@property (readonly) Matrix3DException_t err_name;
@property (readonly) NSString *err_message;
@property (readonly) NSException *err_exception;
- initWithName: (Matrix3DException_t) name message: (NSString*) message exception: (NSException*) exception;
+ errorWithName: (Matrix3DException_t) name message: (NSString*) message exception: (NSException*) exception;
- (NSString *)description;
@end
@implementation ErrorBunch
- initWithName: (Matrix3DException_t) name message: (NSString*) message exception: (NSException*) exception {
    if (self=[super init]) {
        _err_name = name; _err_message = message; _err_exception = exception;
    }
    return self;
}
+ errorWithName: (Matrix3DException_t) name message: (NSString*) message exception: (NSException*) exception {
    return [[ErrorBunch alloc] initWithName:name message:message exception:exception];
}
- (NSString *)description {
    return [NSString stringWithFormat:
            @"ERR: %@\n%@\n%@\n",
            [Matrix3DExceptions name:self.err_name],
            self.err_message,
            (self.err_exception!=nil)?self.err_exception.name:@"nil"
            ];
}
@end

@interface Matrix3D : NSObject {
    UInt _xs, _ys, _zs;
    NSMutableArray *matrix;
    id _kind;
}
@property ErrorBunch *err;
- initWithXs: (UInt) xs Ys: (UInt) ys Zs: (UInt) zs ofKind: (id) kind;
- (NSString*) description;
- (BOOL) isValidCell: (UInt) x _: (UInt) y _: (UInt) z; // @throw
- set: (UInt) x _: (UInt) y _: (UInt) z value: (id) value;
- (id) get: (UInt) x _: (UInt) y _: (UInt) z;
@end

@implementation Matrix3D
- initWithXs: (UInt) xs Ys: (UInt) ys Zs: (UInt) zs ofKind: (id) kind {
    if (self=[super init]) {
        _xs = (xs == 0 ? 1 : xs);
        _ys = (ys == 0 ? 1 : ys);
        _zs = (zs == 0 ? 1 : zs);
        matrix = [[NSMutableArray alloc] init];
        for (int i=0; i<_xs*_ys*_zs; i++) {
            [matrix addObject: [NSNull null]];
        }
        _kind = kind;
    }
    return self;
}
- (NSString*) description {
    return [NSString stringWithFormat:@"[%i,%i,%i]",_xs,_ys,_zs];
}
- (BOOL) isValidCell: (UInt) x _: (UInt) y _: (UInt) z {
    if (x < _xs && y < _ys && z < _zs) { return YES; }
    @throw [Matrix3DExceptions exception:M3DE_OutOfRange];
}
- (id) get: (UInt) x _: (UInt) y _: (UInt) z {
    self.err = nil;
    @try {
        if ([self isValidCell:x _:y _:z]) {
            id res = [matrix objectAtIndex: x+(y*_xs)+(z*_xs*_ys) ];
            return (res == [NSNull null]) ? nil : res;
        }
    } @catch (NSException *exception) {
        self.err = [ErrorBunch errorWithName:M3DE_OutOfRange message:[NSString stringWithFormat:@"while getting x: %i, y: %i, z: %i", x, y, z] exception:exception];
        return nil;
    }
}
- set: (UInt) x _: (UInt) y _: (UInt) z value: (id) value {
    self.err = nil;
    if ((value != nil) && (![value isKindOfClass:[_kind class]])) {
        self.err = [ErrorBunch errorWithName:M3DE_BadObjectType message:[NSString stringWithFormat:@"while setting x: %i, y: %i, z: %i", x, y, z] exception:nil];
    }
    @try {
        if ([self isValidCell:x _:y _:z]) {
            id val = (value != nil) ? value : [NSNull null];
            [matrix replaceObjectAtIndex: x+(y*_xs)+(z*_xs*_ys) withObject:val];
        }
    } @catch (NSException *exception) {
        self.err = [ErrorBunch errorWithName:M3DE_OutOfRange message:[NSString stringWithFormat:@"while setting x: %i, y: %i, z: %i", x, y, z] exception:exception];
    }
}

@end


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        [Matrix3DExceptions setNames];
        
        Matrix3D *m1 = [[Matrix3D alloc] initWithXs:3 Ys:3 Zs:3 ofKind:(id)[NSNumber numberWithInt:0]];
        
        id val = [m1 get:0 _:0 _:0];
        
        if (m1.err != nil) {
            if (m1.err.err_exception != nil) {
                printf("%s\n",_c(m1.err.description));
            }
        } else {
            NSLog(@"%@\n", val);
        }
        
        [m1 set:1 _:0 _:0 value:[NSNumber numberWithInt:10]];
        if (m1.err != nil) { printf("1- %s\n",_c(m1.err.description)); }
        
        printf("%s\n", _n([m1 get:1 _:0 _:4]));
        if (m1.err != nil) { printf("2- %s\n",_c(m1.err.description)); }
        
        [m1 set:2 _:2 _:2 value:[NSNumber numberWithInt:10000000]];
        if (m1.err != nil) { printf("3- %s\n",_c(m1.err.description)); }
        
        printf("%s\n", _n([m1 get:2 _:2 _:2]));
        if (m1.err != nil) { printf("4- %s\n",_c(m1.err.description)); }
        
        printf("%s\n", _n([m1 get:1 _:1 _:1]));
        if (m1.err != nil) { printf("5- %s\n",_c(m1.err.description)); }
        
        [m1 set:2 _:2 _:2 value:@"1"];
        if (m1.err != nil) { printf("6- %s\n",_c(m1.err.description)); }
        
    }
    return 0;
}

