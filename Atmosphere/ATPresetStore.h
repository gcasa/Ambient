#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ATPresetStore : NSObject
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *builtInPresets;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *userPresets;
- (void)savePresetNamed:(NSString *)name mix:(NSDictionary *)mix;
- (void)renamePresetAtIndex:(NSUInteger)index name:(NSString *)name;
- (void)deletePresetAtIndex:(NSUInteger)index;
- (void)saveRecentMix:(NSDictionary *)mix;
- (NSDictionary *)recentMix;
@end
NS_ASSUME_NONNULL_END
