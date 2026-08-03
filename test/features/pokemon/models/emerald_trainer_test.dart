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
    expect(
      EmeraldTrainerResolver.forTrainerId(818).name,
      'Brandon',
    );
    expect(
      EmeraldTrainerResolver.forTrainerId(818).kind,
      EmeraldTrainerKind.frontierBrain,
    );
  });

  test('distingue a Steven como combate especial', () {
    final trainer = EmeraldTrainerResolver.forTrainerId(804);
    expect(trainer.name, 'Steven');
    expect(trainer.kind, EmeraldTrainerKind.specialTrainer);
    expect(trainer.spritePath, contains('steven_hoenn.png'));
  });

  test('resuelve el Cazabichos Rick de Ruta 102', () {
    final trainer = EmeraldTrainerResolver.forTrainerId(615);
    expect(trainer.kind, EmeraldTrainerKind.regular);
    expect(trainer.name, 'Cazabichos Rick');
    expect(
      trainer.spritePath,
      'assets/sprites/characters/trainers/gba/Hoenn/bug_catcher.png',
    );
  });

  test('usa los sprites reales de los reclutas Aqua y Magma', () {
    final aquaMale = EmeraldTrainerResolver.forTrainerId(2);
    final aquaFemale = EmeraldTrainerResolver.forTrainerId(14);
    final magmaMale = EmeraldTrainerResolver.forTrainerId(22);

    expect(aquaMale.name, 'Recluta del Equipo Aqua');
    expect(
      aquaMale.spritePath,
      'assets/sprites/characters/villains/aqua/grunt_male.png',
    );
    expect(
      aquaFemale.spritePath,
      'assets/sprites/characters/villains/aqua/grunt_female.png',
    );
    expect(magmaMale.name, 'Recluta del Equipo Magma');
    expect(
      magmaMale.spritePath,
      'assets/sprites/characters/villains/magma/grunt_male.png',
    );
  });

  test('conserva el ID cuando el entrenador no existe', () {
    final trainer = EmeraldTrainerResolver.forTrainerId(9999);
    expect(trainer.kind, EmeraldTrainerKind.regular);
    expect(trainer.name, 'Entrenador #9999');
    expect(trainer.spritePath, isNull);
  });
}
