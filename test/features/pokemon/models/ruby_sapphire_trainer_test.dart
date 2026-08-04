import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/emerald_trainer.dart';
import 'package:retrohub/features/pokemon/models/ruby_sapphire_trainer.dart';

void main() {
  group('Entrenadores especiales de Ruby/Sapphire', () {
    test('resuelve campeón, Alto Mando y líderes con sus IDs propios', () {
      expect(
        RubySapphireTrainerResolver.forTrainerId(335).name,
        'Steven',
      );
      expect(
        RubySapphireTrainerResolver.forTrainerId(261).kind,
        EmeraldTrainerKind.eliteFour,
      );
      expect(
        RubySapphireTrainerResolver.forTrainerId(272).kind,
        EmeraldTrainerKind.gymLeader,
      );
    });

    test('usa sprites de rival propios de Ruby/Sapphire', () {
      expect(
        RubySapphireTrainerResolver.forTrainerId(520).spritePath,
        'assets/sprites/characters/rivals/brendan_ruby_sapphire.png',
      );
      expect(
        RubySapphireTrainerResolver.forTrainerId(529).spritePath,
        'assets/sprites/characters/rivals/may_ruby_sapphire.png',
      );
    });

    test('no confunde IDs corrientes con la tabla de Emerald', () {
      final trainer = RubySapphireTrainerResolver.forTrainerId(100);
      expect(trainer.name, 'Entrenador #100');
      expect(trainer.kind, EmeraldTrainerKind.regular);
      expect(trainer.spritePath, isNull);
    });
  });
}
