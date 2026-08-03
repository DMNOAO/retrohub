import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/emerald_trainer.dart';

void main() {
  test('resuelve rivales de Esmeralda y sus sprites', () {
    final brendan = EmeraldTrainerResolver.forTrainerId(520);
    final may = EmeraldTrainerResolver.forTrainerId(529);
    final wally = EmeraldTrainerResolver.forTrainerId(656);

    expect(brendan.kind, EmeraldTrainerKind.rival);
    expect(brendan.spritePath, contains('brendan_emerald.png'));
    expect(may.kind, EmeraldTrainerKind.rival);
    expect(may.spritePath, contains('may_emerald.png'));
    expect(wally.kind, EmeraldTrainerKind.rival);
    expect(wally.spritePath, contains('wally_hoenn.png'));
  });

  test('resuelve Liga, líderes, revancha y Frente Batalla', () {
    expect(
      EmeraldTrainerResolver.forTrainerId(261).kind,
      EmeraldTrainerKind.eliteFour,
    );
    expect(
      EmeraldTrainerResolver.forTrainerId(335).kind,
      EmeraldTrainerKind.champion,
    );
    expect(
      EmeraldTrainerResolver.forTrainerId(770).name,
      'Roxanne',
    );
    expect(
      EmeraldTrainerResolver.forTrainerId(811).kind,
      EmeraldTrainerKind.frontierBrain,
    );
  });

  test('conserva el ID de un entrenador corriente', () {
    final trainer = EmeraldTrainerResolver.forTrainerId(42);
    expect(trainer.kind, EmeraldTrainerKind.regular);
    expect(trainer.name, 'Entrenador #42');
  });
}
