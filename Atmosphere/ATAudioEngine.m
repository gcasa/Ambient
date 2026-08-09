#import "ATAudioEngine.h"
#import "ATSound.h"

@interface ATVoice : NSObject
@property AVAudioNode *source; @property AVAudioPlayerNode *player; @property AVAudioMixerNode *mixer; @property AVAudioPCMBuffer *buffer; @property float volume; @property BOOL muted; @property NSUInteger rampGeneration;
@end
@implementation ATVoice @end

@interface ATAudioEngine () { AVAudioEngine *_engine; AVAudioMixerNode *_master; NSMutableDictionary<NSString*,ATVoice*> *_voices; BOOL _paused; BOOL _suspendedForSleep; BOOL _recovering; NSUInteger _masterRampGeneration; id _configurationObserver; }
@end

static float ATRand(void) { return ((float)arc4random_uniform(UINT32_MAX)/(float)UINT32_MAX)*2.f-1.f; }

@implementation ATAudioEngine
- (instancetype)init { if((self=[super init])) { _engine=[AVAudioEngine new]; _master=[AVAudioMixerNode new]; _voices=[NSMutableDictionary new]; [_engine attachNode:_master]; [_engine connect:_master to:_engine.mainMixerNode format:nil]; _masterVolume=.75; __weak typeof(self) weakSelf=self; _configurationObserver=[NSNotificationCenter.defaultCenter addObserverForName:AVAudioEngineConfigurationChangeNotification object:_engine queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note){ [weakSelf recoverFromConfigurationChange]; }]; } return self; }
- (void)dealloc { if(_configurationObserver)[NSNotificationCenter.defaultCenter removeObserver:_configurationObserver]; }
- (NSArray<NSString *> *)activeIdentifiers { return _voices.allKeys; }
- (BOOL)paused { return _paused; }
- (void)setMasterVolume:(float)v { _masterVolume=MAX(0,MIN(1,v)); _masterRampGeneration++; _master.outputVolume=_masterMuted?0:_masterVolume; }
- (void)setMasterMuted:(BOOL)masterMuted { if(_masterMuted==masterMuted)return;_masterMuted=masterMuted;_masterRampGeneration++;_master.outputVolume=masterMuted?0:_masterVolume;if(self.stateChanged)self.stateChanged(); }
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
                ATVoice *voice=[ATVoice new];voice.source=player;voice.player=player;voice.mixer=mix;voice.buffer=buffer;voice.volume=MAX(0,MIN(1,volume));mix.outputVolume=0;_voices[sound.identifier]=voice;
                if (!_engine.running&&![_engine startAndReturnError:error]) { [_voices removeObjectForKey:sound.identifier];return NO; }
                [player scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];[player play];
                [self rampVoice:voice to:voice.volume duration:.7];if(self.stateChanged)self.stateChanged();return YES;
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
            else if ([kind isEqual:@"zen_bowls"]) {
                // Three differently sized bowls, struck in turn. Each bowl includes
                // slightly detuned upper modes to give the tone a natural shimmer.
                const double frequencies[]={256.0, 320.0, 384.0};
                const double intervals[]={0.0, 4.0, 8.0};
                double cycle=fmod(phase/sr,12.0);
                for(int bowl=0;bowl<3;bowl++) {
                    double age=cycle-intervals[bowl];
                    if(age<0) age+=12.0;
                    double attack=MIN(1.0,age/.025);
                    double envelope=attack*exp(-age/(4.8+bowl*.7));
                    double angle=phase*2*M_PI*frequencies[bowl]/sr;
                    double tone=sin(angle)+.32*sin(angle*2.01)+.16*sin(angle*2.67)+.08*sin(angle*4.08);
                    x+=(float)(tone*envelope*.025);
                }
            }
            for (UInt32 b=0;b<data->mNumberBuffers;b++) ((float*)data->mBuffers[b].mData)[i]=x;
            phase++;
        } return noErr;
    }];
    AVAudioMixerNode *mix=[AVAudioMixerNode new]; [_engine attachNode:source]; [_engine attachNode:mix]; [_engine connect:source to:mix format:format]; [_engine connect:mix to:_master format:format];
    ATVoice *v=[ATVoice new]; v.source=source; v.mixer=mix; v.volume=MAX(0,MIN(1,volume)); mix.outputVolume=0; _voices[sound.identifier]=v;
    if (!_engine.running && ![_engine startAndReturnError:error]) { [_voices removeObjectForKey:sound.identifier]; return NO; }
    [self rampVoice:v to:v.volume duration:.7]; if(self.stateChanged) self.stateChanged(); return YES;
}
- (void)rampVoice:(ATVoice *)voice to:(float)target duration:(NSTimeInterval)duration {
    NSUInteger generation=++voice.rampGeneration; float start=voice.mixer.outputVolume; int steps=MAX(1,MIN(120,(int)ceil(duration*30)));
    for(int i=1;i<=steps;i++) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(duration*i/steps*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ if(voice.rampGeneration==generation)voice.mixer.outputVolume=start+(target-start)*i/steps; });
}
- (void)stopSound:(NSString *)identifier { ATVoice *v=_voices[identifier]; if(!v)return; [_voices removeObjectForKey:identifier]; [self rampVoice:v to:0 duration:.35]; NSUInteger generation=v.rampGeneration; dispatch_after(dispatch_time(DISPATCH_TIME_NOW,.4*NSEC_PER_SEC),dispatch_get_main_queue(),^{ if(v.rampGeneration!=generation)return; [v.player stop]; [self->_engine disconnectNodeOutput:v.source]; [self->_engine disconnectNodeOutput:v.mixer]; [self->_engine detachNode:v.source]; [self->_engine detachNode:v.mixer]; }); if(self.stateChanged)self.stateChanged(); }
- (void)setVolume:(float)volume forSound:(NSString *)identifier { ATVoice *v=_voices[identifier]; if(!v)return; v.volume=MAX(0,MIN(1,volume)); if(!v.muted)[self rampVoice:v to:v.volume duration:.08]; }
- (void)setMuted:(BOOL)muted forSound:(NSString *)identifier { ATVoice *v=_voices[identifier]; if(!v)return; v.muted=muted; [self rampVoice:v to:muted?0:v.volume duration:.15]; if(self.stateChanged)self.stateChanged(); }
- (void)cancelMasterRamp { _masterRampGeneration++; _master.outputVolume=_masterMuted?0:_masterVolume; }
- (void)pauseAll { if(!_paused){ [self cancelMasterRamp]; [_engine pause]; _paused=YES; if(self.stateChanged)self.stateChanged(); } }
- (BOOL)resumeAll:(NSError **)error { if(!_paused)return YES; [self cancelMasterRamp]; if(![_engine startAndReturnError:error])return NO; _paused=NO; if(self.stateChanged)self.stateChanged(); return YES; }
- (void)clear { for(NSString *key in _voices.allKeys.copy)[self stopSound:key]; }
- (void)fadeOutOver:(NSTimeInterval)duration completion:(dispatch_block_t)completion { NSUInteger generation=++_masterRampGeneration;float start=_master.outputVolume;int steps=MAX(1,MIN(600,(int)ceil(duration*20)));for(int i=1;i<=steps;i++)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(duration*i/steps*NSEC_PER_SEC)),dispatch_get_main_queue(),^{if(self->_masterRampGeneration==generation)self->_master.outputVolume=start*(1-(float)i/steps);});dispatch_after(dispatch_time(DISPATCH_TIME_NOW,duration*NSEC_PER_SEC),dispatch_get_main_queue(),^{if(self->_masterRampGeneration!=generation)return;[self pauseAll];self->_master.outputVolume=self->_masterMuted?0:self->_masterVolume;if(completion)completion();}); }
- (void)prepareForSystemSleep { _suspendedForSleep=!_paused&&_voices.count>0; if(_suspendedForSleep){[self cancelMasterRamp];[_engine pause];} }
- (void)recoverAfterSystemWake { if(!_suspendedForSleep)return; _suspendedForSleep=NO; [self recoverAudioEngine]; }
- (void)recoverFromConfigurationChange { if(_paused||_suspendedForSleep||_recovering||!_voices.count)return; [self recoverAudioEngine]; }
- (void)recoverAudioEngine { if(_recovering)return;_recovering=YES;[_engine stop];for(ATVoice *voice in _voices.allValues)if(voice.player){[voice.player stop];[voice.player scheduleBuffer:voice.buffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];}NSError *error=nil;if(![_engine startAndReturnError:&error]){_recovering=NO;if(self.errorOccurred)self.errorOccurred(error);return;}for(ATVoice *voice in _voices.allValues)if(voice.player)[voice.player play];dispatch_async(dispatch_get_main_queue(),^{self->_recovering=NO;}); }
@end
