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
          [ATSound sound:@"waterfall" name:@"Waterfall" category:@"Nature" symbol:@"drop.circle.fill" generator:@"river" tags:@[@"water",@"forest",@"powerful"]],
          [ATSound sound:@"frogs" name:@"Pond frogs" category:@"Nature" symbol:@"aqi.medium" generator:@"insects" tags:@[@"pond",@"dusk",@"wildlife"]],
          [ATSound sound:@"meadow" name:@"Sunny meadow" category:@"Nature" symbol:@"sun.max.fill" generator:@"forest" tags:@[@"birds",@"morning",@"field"]],
          [ATSound sound:@"cafe" name:@"Coffee shop" category:@"Places" symbol:@"cup.and.saucer.fill" generator:@"cafe" tags:@[@"people",@"focus"]],
          [ATSound sound:@"library" name:@"Quiet library" category:@"Places" symbol:@"books.vertical.fill" generator:@"cafe" tags:@[@"study",@"pages",@"focus"]],
          [ATSound sound:@"train" name:@"City Train" category:@"Places" symbol:@"tram.fill" generator:@"train" tags:@[@"metro",@"subway",@"travel"]],
          [ATSound sound:@"classic_train" name:@"Classic Train" category:@"Places" symbol:@"train.side.front.car" generator:@"train" tags:@[@"steam",@"whistle",@"locomotive",@"choo choo"]],
          [ATSound sound:@"city" name:@"City traffic" category:@"Places" symbol:@"building.2.fill" generator:@"city" tags:@[@"urban",@"traffic"]],
          [ATSound sound:@"airplane" name:@"Airplane cabin" category:@"Places" symbol:@"airplane" generator:@"airplane" tags:@[@"travel",@"hum"]],
          [ATSound sound:@"white" name:@"White noise" category:@"Noise" symbol:@"waveform" generator:@"white" tags:@[@"focus",@"sleep"]],
          [ATSound sound:@"brown" name:@"Brown noise" category:@"Noise" symbol:@"waveform.path" generator:@"brown" tags:@[@"deep",@"focus"]],
          [ATSound sound:@"pink" name:@"Pink noise" category:@"Noise" symbol:@"waveform.circle.fill" generator:@"pink" tags:@[@"balanced",@"sleep"]],
          [ATSound sound:@"fan" name:@"Electric fan" category:@"Noise" symbol:@"fanblades.fill" generator:@"airplane" tags:@[@"steady",@"sleep",@"hum"]],
          [ATSound sound:@"piano" name:@"Soft piano" category:@"Music" symbol:@"pianokeys" generator:@"piano" tags:@[@"music",@"gentle"]],
          [ATSound sound:@"bowls" name:@"Meditation bowl" category:@"Music" symbol:@"bell.fill" generator:@"bowls" tags:@[@"meditation",@"calm",@"single bowl"]],
          [ATSound sound:@"zen_bowls" name:@"Zen bowl harmony" category:@"Music" symbol:@"bell.and.waves.left.and.right.fill" generator:@"zen_bowls" tags:@[@"meditation",@"calm",@"multiple bowls",@"multi tone",@"harmony"]]
        ];
        NSDictionary *samples=@{@"rain":@"rain.mp3",@"thunder":@"thunder.mp3",@"wind":@"wind.mp3",@"ocean":@"ocean.mp3",@"forest":@"forest.mp3",@"fire":@"fire.mp3",@"river":@"river.mp3",@"birds":@"birds.mp3",@"insects":@"insects.mp3",@"waterfall":@"waterfall.mp3",@"frogs":@"frogs.mp3",@"meadow":@"meadow.mp3",@"cafe":@"cafe.mp3",@"library":@"library.mp3",@"train":@"train.mp3",@"classic_train":@"classic_train.mp3",@"city":@"city.mp3",@"airplane":@"airplane.mp3",@"white":@"white.mp3",@"brown":@"brown.mp3",@"pink":@"pink.mp3",@"fan":@"fan.mp3",@"piano":@"piano.mp3",@"bowls":@"bowls.mp3"};
        for(ATSound *sound in _sounds) sound.resourceName=samples[sound.identifier];
    } return self;
}
- (ATSound *)soundWithIdentifier:(NSString *)identifier { for (ATSound *s in _sounds) if ([s.identifier isEqual:identifier]) return s; return nil; }
@end
