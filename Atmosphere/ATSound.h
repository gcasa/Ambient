#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ATSound : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *generator;
@property (nonatomic, copy, nullable) NSString *resourceName;
@property (nonatomic, copy) NSArray<NSString *> *tags;
+ (instancetype)sound:(NSString *)identifier name:(NSString *)name category:(NSString *)category symbol:(NSString *)symbol generator:(NSString *)generator tags:(NSArray<NSString *> *)tags;
@end

@interface ATSoundCatalog : NSObject
@property (nonatomic, copy, readonly) NSArray<ATSound *> *sounds;
@property (nonatomic, copy, readonly) NSArray<NSString *> *categories;
- (nullable ATSound *)soundWithIdentifier:(NSString *)identifier;
@end

NS_ASSUME_NONNULL_END
