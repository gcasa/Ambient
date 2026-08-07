#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ATTimerController : NSObject
@property (nonatomic, readonly) NSTimeInterval remaining;
@property (nonatomic, readonly) BOOL running;
@property (nonatomic) BOOL fadeOut;
@property (nonatomic, copy, nullable) void (^tick)(NSTimeInterval remaining);
@property (nonatomic, copy, nullable) void (^finished)(BOOL fadeOut);
- (void)startMinutes:(NSInteger)minutes;
- (void)cancel;
@end
NS_ASSUME_NONNULL_END
