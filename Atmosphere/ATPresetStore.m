#import "ATPresetStore.h"
static NSString *const kPresets=@"ATUserPresets", *const kRecent=@"ATRecentMix";
@interface ATPresetStore () { NSUserDefaults *_defaults; }
@end
@implementation ATPresetStore
- (instancetype)init { return [self initWithUserDefaults:NSUserDefaults.standardUserDefaults]; }
- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults { if((self=[super init])) { _defaults=defaults; _builtInPresets=@[
 @{ @"name":@"Rainy Cabin", @"mix":@{ @"rain":@.42,@"thunder":@.18,@"fire":@.28}},
 @{ @"name":@"Deep Focus", @"mix":@{ @"brown":@.36,@"rain":@.16,@"cafe":@.10}},
 @{ @"name":@"Forest Morning", @"mix":@{ @"forest":@.34,@"birds":@.22,@"river":@.18}},
 @{ @"name":@"Night Train", @"mix":@{ @"train":@.32,@"rain":@.20,@"insects":@.10}},
 @{ @"name":@"Ocean Meditation", @"mix":@{ @"ocean":@.38,@"bowls":@.16,@"wind":@.12}}
 ]; } return self; }
- (BOOL)isValidMix:(id)value { if(![value isKindOfClass:NSDictionary.class])return NO;for(id key in value)if(![key isKindOfClass:NSString.class]||![value[key] isKindOfClass:NSNumber.class])return NO;return YES; }
- (NSArray *)userPresets { id stored=[_defaults objectForKey:kPresets];if(![stored isKindOfClass:NSArray.class])return @[];NSMutableArray *valid=[NSMutableArray new];for(id preset in stored)if([preset isKindOfClass:NSDictionary.class]&&[preset[@"name"] isKindOfClass:NSString.class]&&[self isValidMix:preset[@"mix"]])[valid addObject:preset];return valid; }
- (void)write:(NSArray *)a { [_defaults setObject:a forKey:kPresets]; }
- (void)savePresetNamed:(NSString *)name mix:(NSDictionary *)mix { NSMutableArray *a=self.userPresets.mutableCopy; [a addObject:@{@"name":name,@"mix":mix}]; [self write:a]; }
- (void)renamePresetAtIndex:(NSUInteger)i name:(NSString *)name { NSMutableArray *a=self.userPresets.mutableCopy; if(i<a.count){ NSMutableDictionary *p=[a[i] mutableCopy];p[@"name"]=name;a[i]=p;[self write:a];} }
- (void)deletePresetAtIndex:(NSUInteger)i { NSMutableArray *a=self.userPresets.mutableCopy;if(i<a.count){[a removeObjectAtIndex:i];[self write:a];} }
- (void)saveRecentMix:(NSDictionary *)mix { if([self isValidMix:mix])[_defaults setObject:mix forKey:kRecent]; }
- (NSDictionary *)recentMix { id mix=[_defaults objectForKey:kRecent];return [self isValidMix:mix]?mix:@{}; }
@end
