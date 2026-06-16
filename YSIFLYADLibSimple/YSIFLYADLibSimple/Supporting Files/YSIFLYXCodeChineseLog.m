//
//  YSIFLYXCodeChineseLog.m
//
//  Created by Jimmy on 2020/11/13.
//  Copyright © 2020 jimmy. All rights reserved.
//

#import "YSIFLYXCodeChineseLog.h"
#import <objc/runtime.h>

static inline void YSIFLY_swizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation NSString (YSIFLYXCodeChineseLog)

- (NSString *)stringByReplaceUnicode {
    NSMutableString *convertedString = [self mutableCopy];
    [convertedString replaceOccurrencesOfString:@"\\U"
                                     withString:@"\\u"
                                        options:0
                                          range:NSMakeRange(0, convertedString.length)];

    CFStringRef transform = CFSTR("Any-Hex/Java");
    CFStringTransform((__bridge CFMutableStringRef)convertedString, NULL, transform, YES);
    return convertedString;
}

@end

@implementation NSArray (YSIFLYXCodeChineseLog)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        YSIFLY_swizzleSelector(class, @selector(description), @selector(YSIFLY_description));
        YSIFLY_swizzleSelector(class, @selector(descriptionWithLocale:), @selector(YSIFLY_descriptionWithLocale:));
        YSIFLY_swizzleSelector(class, @selector(descriptionWithLocale:indent:), @selector(YSIFLY_descriptionWithLocale:indent:));
    });
}

- (NSString *)YSIFLY_description {
    return [[self YSIFLY_description] stringByReplaceUnicode];
}

- (NSString *)YSIFLY_descriptionWithLocale:(nullable id)locale {
    return [[self YSIFLY_descriptionWithLocale:locale] stringByReplaceUnicode];
}

- (NSString *)YSIFLY_descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level {
    return [[self YSIFLY_descriptionWithLocale:locale indent:level] stringByReplaceUnicode];
}

@end

@implementation NSDictionary (YSIFLYXCodeChineseLog)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        YSIFLY_swizzleSelector(class, @selector(description), @selector(YSIFLY_description));
        YSIFLY_swizzleSelector(class, @selector(descriptionWithLocale:), @selector(YSIFLY_descriptionWithLocale:));
        YSIFLY_swizzleSelector(class, @selector(descriptionWithLocale:indent:), @selector(YSIFLY_descriptionWithLocale:indent:));
    });
}

- (NSString *)YSIFLY_description {
    return [[self YSIFLY_description] stringByReplaceUnicode];
}

- (NSString *)YSIFLY_descriptionWithLocale:(nullable id)locale {
    return [[self YSIFLY_descriptionWithLocale:locale] stringByReplaceUnicode];
}

- (NSString *)YSIFLY_descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level {
    return [[self YSIFLY_descriptionWithLocale:locale indent:level] stringByReplaceUnicode];
}

@end

@implementation NSSet (YSIFLYXCodeChineseLog)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        YSIFLY_swizzleSelector(class, @selector(description), @selector(YSIFLY_description));
        YSIFLY_swizzleSelector(class, @selector(descriptionWithLocale:), @selector(YSIFLY_descriptionWithLocale:));
        YSIFLY_swizzleSelector(class, @selector(descriptionWithLocale:indent:), @selector(YSIFLY_descriptionWithLocale:indent:));
    });
}

- (NSString *)YSIFLY_description {
    return [[self YSIFLY_description] stringByReplaceUnicode];
}

- (NSString *)YSIFLY_descriptionWithLocale:(nullable id)locale {
    return [[self YSIFLY_descriptionWithLocale:locale] stringByReplaceUnicode];
}

- (NSString *)YSIFLY_descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level {
    return [[self YSIFLY_descriptionWithLocale:locale indent:level] stringByReplaceUnicode];
}

@end
