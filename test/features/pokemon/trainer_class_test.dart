import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/trainer_class.dart';

void main() {
  group('TrainerClassResolver Team Rocket de Gen II', () {
    test('resuelve el Científico con su sprite de Johto', () {
      final trainer = TrainerClassResolver.forClassId(0x14);

      expect(trainer?.name, 'Científico');
      expect(
        trainer?.spritePath,
        'assets/sprites/characters/villains/rocket/scientist_johto.png',
      );
    });

    test('resuelve Ejecutivo y Ejecutiva con sus sprites de Gen II', () {
      final executiveMale = TrainerClassResolver.forClassId(0x33);
      final executiveFemale = TrainerClassResolver.forClassId(0x37);

      expect(executiveMale?.name, 'Ejecutivo (M)');
      expect(
        executiveMale?.spritePath,
        'assets/sprites/characters/villains/rocket/archer_johto.png',
      );
      expect(executiveFemale?.name, 'Ejecutiva (F)');
      expect(
        executiveFemale?.spritePath,
        'assets/sprites/characters/villains/rocket/ariana_johto.png',
      );
    });
  });
}
