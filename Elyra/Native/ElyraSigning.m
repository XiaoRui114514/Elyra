// SPDX-License-Identifier: GPL-3.0-only
#import "ElyraSigning.h"
#import "GXEntitlementsReader.h"
NSArray<NSString *> *ElyraDeclaredAppGroups(void) {
    NSURL *url = NSBundle.mainBundle.executableURL;
    if (!url) return @[];
    NSNumber *size = nil;
    if (![url getResourceValue:&size forKey:NSURLFileSizeKey error:NULL] || size.unsignedLongLongValue > 64 * 1024 * 1024) return @[];
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:NULL];
    if (!data) return @[];
    id groups = [GXEntitlementsReader entitlementsInMachOData:data][@"com.apple.security.application-groups"];
    if (![groups isKindOfClass:NSArray.class]) return @[];
    NSMutableArray<NSString *> *result = NSMutableArray.new;
    for (id group in groups) if ([group isKindOfClass:NSString.class] && [group length]) [result addObject:group];
    return result;
}
