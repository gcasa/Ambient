#import "ATTimerController.h"
@interface ATTimerController () { NSTimer *_timer; NSDate *_end; }
@end
@implementation ATTimerController
- (BOOL)running{return _timer!=nil;} - (NSTimeInterval)remaining{return MAX(0,[_end timeIntervalSinceNow]);}
- (void)startMinutes:(NSInteger)m { [self cancel];_end=[NSDate dateWithTimeIntervalSinceNow:m*60];_timer=[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *t){ NSTimeInterval r=self.remaining;if(self.tick)self.tick(r);if(r<=0){BOOL f=self.fadeOut;[self cancel];if(self.finished)self.finished(f);}}]; if(self.tick)self.tick(self.remaining); }
- (void)cancel { [_timer invalidate];_timer=nil;_end=nil;if(self.tick)self.tick(0); }
@end
