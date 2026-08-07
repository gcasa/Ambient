#import "ATPresetStore.h"
static NSString *const kPresets=@"ATUserPresets", *const kRecent=@"ATRecentMix";
@implementation ATPresetStore
- (instancetype)init { if((self=[super init])) _builtInPresets=@[
 @{ @"name":@"Rainy Cabin", @"mix":@{ @"rain":@.42,@"thunder":@.18,@"fire":@.28}},
 @{ @"name":@"Deep Focus", @"mix":@{ @"brown":@.36,@"rain":@.16,@"cafe":@.10}},
 @{ @"name":@"Forest Morning", @"mix":@{ @"forest":@.34,@"birds":@.22,@"river":@.18}},
 @{ @"name":@"Night Train", @"mix":@{ @"train":@.32,@"rain":@.20,@"insects":@.10}},
 @{ @"name":@"Ocean Meditation", @"mix":@{ @"ocean":@.38,@"bowls":@.16,@"wind":@.12}}
 ]; return self; }
- (NSArray *)userPresets { return [NSUserDefaults.standardUserDefaults arrayForKey:kPresets]?:@[]; }
- (void)write:(NSArray *)a { [NSUserDefaults.standardUserDefaults setObject:a forKey:kPresets]; }
- (void)savePresetNamed:(NSString *)name mix:(NSDictionary *)mix { NSMutableArray *a=self.userPresets.mutableCopy; [a addObject:@{@"name":name,@"mix":mix}]; [self write:a]; }
- (void)renamePresetAtIndex:(NSUInteger)i name:(NSString *)name { NSMutableArray *a=self.userPresets.mutableCopy; if(i<a.count){ NSMutableDictionary *p=[a[i] mutableCopy];p[@"name"]=name;a[i]=p;[self write:a];} }
- (void)deletePresetAtIndex:(NSUInteger)i { NSMutableArray *a=self.userPresets.mutableCopy;if(i<a.count){[a removeObjectAtIndex:i];[self write:a];} }
- (void)saveRecentMix:(NSDictionary *)mix { [NSUserDefaults.standardUserDefaults setObject:mix forKey:kRecent]; }
- (NSDictionary *)recentMix { return [NSUserDefaults.standardUserDefaults dictionaryForKey:kRecent]?:@{}; }
@end
