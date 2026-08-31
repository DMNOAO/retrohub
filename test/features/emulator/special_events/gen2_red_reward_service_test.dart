import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/special_events/gen2_red_reward.dart';
import 'package:retrohub/features/emulator/special_events/gen2_red_reward_service.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  const service = Gen2RedRewardService();

  test('the ten rewards are ordered from Articuno through Mew', () {
    expect(Gen2RedReward.values, hasLength(10));
    expect(Gen2RedReward.values.first, Gen2RedReward.articuno);
    expect(Gen2RedReward.values.last, Gen2RedReward.mew);
    expect(
      Gen2RedReward.values.map((reward) => reward.requiredLeagueWins),
      orderedEquals(List<int>.generate(10, (index) => index + 1)),
    );
  });

  test('inspect requires an open party slot', () {
    final bytes = Uint8List(0x8000)..[0x2865] = 6;
    expect(
      service.inspectBytes(bytes, version: PokemonGameVersion.crystal),
      Gen2RedRewardStatus.partyFull,
    );
  });

  test('Crystal delivery writes shiny Pokémon, mirrors save and backs up', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub-gen2-');
    addTearDown(() => directory.delete(recursive: true));
    final save = File('${directory.path}/crystal.srm');
    await save.writeAsBytes(Uint8List(0x8000));

    final result = await service.deliver(
      savePath: save.path,
      version: PokemonGameVersion.crystal,
      reward: Gen2RedReward.articuno,
    );
    final bytes = await save.readAsBytes();
    const party = 0x2865;
    const record = party + 8;

    expect(result.status, Gen2RedRewardStatus.delivered);
    expect(await File(result.backupPath!).exists(), isTrue);
    expect(bytes[party], 1);
    expect(bytes[party + 1], 144);
    expect(bytes[record], 144);
    expect(bytes[record + 21], 0xAA);
    expect(bytes[record + 22], 0xAA);
    expect(bytes.sublist(0x1209, 0x1D83), bytes.sublist(0x2009, 0x2B83));
    expect(_readLittleEndian16(bytes, 0x2D0D), _sum(bytes, 0x2009, 0x2B83));
    expect(_readLittleEndian16(bytes, 0x1F0D), _sum(bytes, 0x1209, 0x1D83));
  });

  test('Gold delivery updates the split backup and checksum', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub-gen2-');
    addTearDown(() => directory.delete(recursive: true));
    final save = File('${directory.path}/gold.srm');
    await save.writeAsBytes(Uint8List(0x8000));

    await service.deliver(
      savePath: save.path,
      version: PokemonGameVersion.gold,
      reward: Gen2RedReward.mew,
    );
    final bytes = await save.readAsBytes();

    expect(bytes[0x288A], 1);
    expect(bytes[0x288B], 151);
    expect(bytes[0x10E8], 1);
    expect(bytes[0x10E9], 151);
    expect(_readLittleEndian16(bytes, 0x2D69), _sum(bytes, 0x2009, 0x2D69));
  });
}

int _sum(List<int> bytes, int start, int end) {
  var sum = 0;
  for (var index = start; index < end; index++) {
    sum = (sum + bytes[index]) & 0xFFFF;
  }
  return sum;
}

int _readLittleEndian16(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);
