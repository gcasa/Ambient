#import "ATTimerController.h"
@interface ATTimerController () { NSTimer *_timer; NSDate *_end; }
@end
@implementation ATTimerController
- (BOOL)running{return _timer!=nil;} - (NSTimeInterval)remaining{return MAX(0,[_end timeIntervalSinceNow]);}
- (void)startMinutes:(NSInteger)m { [self startDuration:m*60]; }
- (void)startDuration:(NSTimeInterval)duration { [self cancel];duration=MAX(0,duration);_end=[NSDate dateWithTimeIntervalSinceNow:duration];NSTimeInterval interval=MIN(1,MAX(.01,duration));_timer=[NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer *t){ NSTimeInterval r=self.remaining;if(self.tick)self.tick(r);if(r<=0){BOOL f=self.fadeOut;[self cancel];if(self.finished)self.finished(f);}}];if(self.tick)self.tick(self.remaining); }
- (void)cancel { [_timer invalidate];_timer=nil;_end=nil;if(self.tick)self.tick(0); }
@end
