import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/trainer_class.dart';

void main() {
  group('TrainerClassResolver Alto Mando de Johto', () {
    test('resuelve los cuatro miembros con sus sprites de Gen II', () {
      const expected = <int, String>{
        0x0B: 'will_johto.png',
        0x0D: 'bruno_johto.png',
        0x0E: 'karen_johto.png',
        0x0F: 'koga_johto.png',
      };

      for (final entry in expected.entries) {
        expect(
          TrainerClassResolver.forClassId(entry.key)?.spritePath,
          'assets/sprites/characters/elite_four/gbc/${entry.value}',
        );
      }
    });
  });

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
