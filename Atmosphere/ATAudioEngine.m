#import "ATAudioEngine.h"
#import "ATSound.h"

@interface ATVoice : NSObject
@property AVAudioNode *source; @property AVAudioPlayerNode *player; @property AVAudioMixerNode *mixer; @property float volume; @property BOOL muted;
@end
@implementation ATVoice @end

@interface ATAudioEngine () { AVAudioEngine *_engine; AVAudioMixerNode *_master; NSMutableDictionary<NSString*,ATVoice*> *_voices; BOOL _paused; }
@end

static float ATRand(void) { return ((float)arc4random_uniform(UINT32_MAX)/(float)UINT32_MAX)*2.f-1.f; }

@implementation ATAudioEngine
- (instancetype)init { if((self=[super init])) { _engine=[AVAudioEngine new]; _master=[AVAudioMixerNode new]; _voices=[NSMutableDictionary new]; [_engine attachNode:_master]; [_engine connect:_master to:_engine.mainMixerNode format:nil]; _masterVolume=.75; } return self; }
- (NSArray<NSString *> *)activeIdentifiers { return _voices.allKeys; }
- (BOOL)paused { return _paused; }
- (void)setMasterVolume:(float)v { _masterVolume=MAX(0,MIN(1,v)); _master.outputVolume=_masterVolume; }
- (BOOL)isActive:(NSString *)identifier { return _voices[identifier]!=nil; }
- (float)volumeForSound:(NSString *)identifier { return _voices[identifier].volume; }
- (BOOL)isMuted:(NSString *)identifier { return _voices[identifier].muted; }
- (BOOL)startSound:(ATSound *)sound volume:(float)volume error:(NSError **)error {
    if (_voices[sound.identifier]) return YES;
    if (sound.resourceName.length) {
        NSURL *url=[NSBundle.mainBundle URLForResource:sound.resourceName.stringByDeletingPathExtension withExtension:sound.resourceName.pathExtension subdirectory:@"Audio"];
        AVAudioFile *file=url?[[AVAudioFile alloc]initForReading:url error:error]:nil;
        if (file) {
            AVAudioPCMBuffer *buffer=[[AVAudioPCMBuffer alloc]initWithPCMFormat:file.processingFormat frameCapacity:(AVAudioFrameCount)file.length];
            if ([file readIntoBuffer:buffer error:error]) {
                AVAudioPlayerNode *player=[AVAudioPlayerNode new]; AVAudioMixerNode *mix=[AVAudioMixerNode new];
                [_engine attachNode:player];[_engine attachNode:mix];[_engine connect:player to:mix format:buffer.format];[_engine connect:mix to:_master format:buffer.format];
                ATVoice *voice=[ATVoice new];voice.source=player;voice.player=player;voice.mixer=mix;voice.volume=MAX(0,MIN(1,volume));mix.outputVolume=0;_voices[sound.identifier]=voice;
                if (!_engine.running&&![_engine startAndReturnError:error]) { [_voices removeObjectForKey:sound.identifier];return NO; }
                [player scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];[player play];
                [self rampMixer:mix to:voice.volume duration:.7];if(self.stateChanged)self.stateChanged();return YES;
            }
        }
        // If a bundled sample is missing or unreadable, continue with synthesis.
    }
    __block double phase=0, phase2=0, filtered=0, slow=0; NSString *kind=sound.generator;
    AVAudioFormat *format=[[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    AVAudioSourceNode *source=[[AVAudioSourceNode alloc] initWithFormat:format renderBlock:^OSStatus(BOOL *silent, const AudioTimeStamp *ts, AVAudioFrameCount count, AudioBufferList *data) {
        float sr=44100.f;
        for (AVAudioFrameCount i=0;i<count;i++) {
            float white=ATRand(), x=0; slow=slow*.9995+white*.0005; filtered=filtered*.98+white*.02;
            if ([kind isEqual:@"white"]) x=white*.19;
            else if ([kind isEqual:@"brown"]) x=slow*2.5;
            else if ([kind isEqual:@"pink"]) x=(filtered*.65+white*.06);
            else if ([kind isEqual:@"rain"]) x=white*(.08+.05*sin(phase*.00008));
            else if ([kind isEqual:@"thunder"]) x=slow*2.0 + sin(phase*.00023)*.025;
            else if ([kind isEqual:@"wind"]) x=filtered*(.6+.3*sin(phase*.00004));
            else if ([kind isEqual:@"ocean"]) x=filtered*(.35+.4*(sin(phase*.00011)+1)/2);
            else if ([kind isEqual:@"river"]) x=white*.035+filtered*.45;
            else if ([kind isEqual:@"fire"]) x=filtered*.22 + (arc4random_uniform(9000)==1?white*.7:0);
            else if ([kind isEqual:@"airplane"]) x=filtered*.25+sin(phase*2*M_PI*82/sr)*.04;
            else if ([kind isEqual:@"train"]) x=filtered*.14+sin(phase*2*M_PI*3.1/sr)*.05;
            else if ([kind isEqual:@"city"]||[kind isEqual:@"cafe"]) x=filtered*.18+white*.018;
            else if ([kind isEqual:@"forest"]) x=filtered*.16+(arc4random_uniform(12000)==1?sin(phase2)*.15:0);
            else if ([kind isEqual:@"birds"]) { double f=1600+500*sin(phase*.00012); x=sin(phase2)*(.015+.04*(sin(phase*.0005)>0.96)); phase2+=2*M_PI*f/sr; }
            else if ([kind isEqual:@"insects"]) { x=sin(phase2)*(.025+.025*sin(phase*.00017)); phase2+=2*M_PI*4800/sr; }
            else if ([kind isEqual:@"piano"]) { double env=.5+.5*sin(phase*.000035); x=(sin(phase*2*M_PI*220/sr)+.5*sin(phase*2*M_PI*330/sr))*.035*env; }
            else if ([kind isEqual:@"bowls"]) { x=(sin(phase*2*M_PI*432/sr)+.3*sin(phase*2*M_PI*864/sr))*.045; }
            for (UInt32 b=0;b<data->mNumberBuffers;b++) ((float*)data->mBuffers[b].mData)[i]=x;
            phase++;
        } return noErr;
    }];
    AVAudioMixerNode *mix=[AVAudioMixerNode new]; [_engine attachNode:source]; [_engine attachNode:mix]; [_engine connect:source to:mix format:format]; [_engine connect:mix to:_master format:format];
    ATVoice *v=[ATVoice new]; v.source=source; v.mixer=mix; v.volume=MAX(0,MIN(1,volume)); mix.outputVolume=0; _voices[sound.identifier]=v;
    if (!_engine.running && ![_engine startAndReturnError:error]) { [_voices removeObjectForKey:sound.identifier]; return NO; }
    [self rampMixer:mix to:v.volume duration:.7]; if(self.stateChanged) self.stateChanged(); return YES;
}
- (void)rampMixer:(AVAudioMixerNode *)mixer to:(float)target duration:(NSTimeInterval)duration {
    float start=mixer.outputVolume; int steps=20; for(int i=1;i<=steps;i++) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(duration*i/steps*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ mixer.outputVolume=start+(target-start)*i/steps; });
}
- (void)stopSound:(NSString *)identifier { ATVoice *v=_voices[identifier]; if(!v)return; [_voices removeObjectForKey:identifier]; [self rampMixer:v.mixer to:0 duration:.35]; dispatch_after(dispatch_time(DISPATCH_TIME_NOW,.4*NSEC_PER_SEC),dispatch_get_main_queue(),^{ [self->_engine disconnectNodeOutput:v.source]; [self->_engine disconnectNodeOutput:v.mixer]; [self->_engine detachNode:v.source]; [self->_engine detachNode:v.mixer]; }); if(self.stateChanged)self.stateChanged(); }
- (void)setVolume:(float)volume forSound:(NSString *)identifier { ATVoice *v=_voices[identifier]; if(!v)return; v.volume=MAX(0,MIN(1,volume)); if(!v.muted)[self rampMixer:v.mixer to:v.volume duration:.08]; if(self.stateChanged)self.stateChanged(); }
- (void)setMuted:(BOOL)muted forSound:(NSString *)identifier { ATVoice *v=_voices[identifier]; v.muted=muted; [self rampMixer:v.mixer to:muted?0:v.volume duration:.15]; if(self.stateChanged)self.stateChanged(); }
- (void)pauseAll { if(!_paused){ [_engine pause]; _paused=YES; if(self.stateChanged)self.stateChanged(); } }
- (void)resumeAll { if(_paused){ NSError *e; [_engine startAndReturnError:&e]; _paused=NO; if(self.stateChanged)self.stateChanged(); } }
- (void)clear { for(NSString *key in _voices.allKeys.copy)[self stopSound:key]; }
- (void)fadeOutOver:(NSTimeInterval)duration completion:(dispatch_block_t)completion { [self rampMixer:_master to:0 duration:duration]; dispatch_after(dispatch_time(DISPATCH_TIME_NOW,duration*NSEC_PER_SEC),dispatch_get_main_queue(),^{ [self pauseAll]; self->_master.outputVolume=self->_masterVolume; if(completion)completion(); }); }
@end
