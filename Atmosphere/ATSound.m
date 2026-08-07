#import "ATSound.h"

@implementation ATSound
+ (instancetype)sound:(NSString *)identifier name:(NSString *)name category:(NSString *)category symbol:(NSString *)symbol generator:(NSString *)generator tags:(NSArray<NSString *> *)tags {
    ATSound *s = [ATSound new]; s.identifier=identifier; s.name=name; s.category=category; s.symbol=symbol; s.generator=generator; s.tags=tags; return s;
}
@end

@implementation ATSoundCatalog
- (instancetype)init {
    if ((self=[super init])) {
        _categories=@[@"Nature", @"Weather", @"Places", @"Noise", @"Music"];
        _sounds=@[
          [ATSound sound:@"rain" name:@"Rain" category:@"Weather" symbol:@"cloud.rain.fill" generator:@"rain" tags:@[@"water",@"calm"]],
          [ATSound sound:@"thunder" name:@"Thunder" category:@"Weather" symbol:@"cloud.bolt.rain.fill" generator:@"thunder" tags:@[@"storm",@"deep"]],
          [ATSound sound:@"wind" name:@"Wind" category:@"Weather" symbol:@"wind" generator:@"wind" tags:@[@"air",@"calm"]],
          [ATSound sound:@"ocean" name:@"Ocean waves" category:@"Nature" symbol:@"water.waves" generator:@"ocean" tags:@[@"water",@"coast"]],
          [ATSound sound:@"forest" name:@"Forest" category:@"Nature" symbol:@"tree.fill" generator:@"forest" tags:@[@"leaves",@"calm"]],
          [ATSound sound:@"fire" name:@"Fireplace" category:@"Nature" symbol:@"flame.fill" generator:@"fire" tags:@[@"warm",@"crackle"]],
          [ATSound sound:@"river" name:@"River" category:@"Nature" symbol:@"drop.fill" generator:@"river" tags:@[@"water",@"flow"]],
          [ATSound sound:@"birds" name:@"Birds" category:@"Nature" symbol:@"bird.fill" generator:@"birds" tags:@[@"morning",@"forest"]],
          [ATSound sound:@"insects" name:@"Night insects" category:@"Nature" symbol:@"moon.stars.fill" generator:@"insects" tags:@[@"night",@"crickets"]],
          [ATSound sound:@"cafe" name:@"Coffee shop" category:@"Places" symbol:@"cup.and.saucer.fill" generator:@"cafe" tags:@[@"people",@"focus"]],
          [ATSound sound:@"train" name:@"Train" category:@"Places" symbol:@"tram.fill" generator:@"train" tags:@[@"travel",@"rhythm"]],
          [ATSound sound:@"city" name:@"City traffic" category:@"Places" symbol:@"building.2.fill" generator:@"city" tags:@[@"urban",@"traffic"]],
          [ATSound sound:@"airplane" name:@"Airplane cabin" category:@"Places" symbol:@"airplane" generator:@"airplane" tags:@[@"travel",@"hum"]],
          [ATSound sound:@"white" name:@"White noise" category:@"Noise" symbol:@"waveform" generator:@"white" tags:@[@"focus",@"sleep"]],
          [ATSound sound:@"brown" name:@"Brown noise" category:@"Noise" symbol:@"waveform.path" generator:@"brown" tags:@[@"deep",@"focus"]],
          [ATSound sound:@"pink" name:@"Pink noise" category:@"Noise" symbol:@"waveform.circle.fill" generator:@"pink" tags:@[@"balanced",@"sleep"]],
          [ATSound sound:@"piano" name:@"Soft piano" category:@"Music" symbol:@"pianokeys" generator:@"piano" tags:@[@"music",@"gentle"]],
          [ATSound sound:@"bowls" name:@"Meditation bowls" category:@"Music" symbol:@"bell.fill" generator:@"bowls" tags:@[@"meditation",@"calm"]]
        ];
    } return self;
}
- (ATSound *)soundWithIdentifier:(NSString *)identifier { for (ATSound *s in _sounds) if ([s.identifier isEqual:identifier]) return s; return nil; }
@end
