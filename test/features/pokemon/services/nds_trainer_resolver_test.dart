import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';
import 'package:retrohub/features/pokemon/services/nds_trainer_resolver.dart';

void main() {
  test('resuelve clases regulares de Platino', () {
    final youngster = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.platinum,
      trainerId: 1,
      classId: 2,
    );
    final lass = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.platinum,
      trainerId: 3,
      classId: 3,
    );

    expect(youngster?.className, 'Joven');
    expect(youngster?.spritePath, endsWith('joven_sinnoh_gen4.png'));
    expect(lass?.className, 'Chica');
    expect(lass?.spritePath, endsWith('chica_sinnoh_gen4.png'));
  });

  test('resuelve clases regulares de Blanco y Negro', () {
    final youngster = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.white,
      trainerId: 5,
      classId: 2,
    );
    final schoolKid = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.black,
      trainerId: 8,
      classId: 5,
    );

    expect(youngster?.className, 'Joven');
    expect(youngster?.spritePath, endsWith('joven_unova_gen5.gif'));
    expect(schoolKid?.className, 'Escolar');
    expect(schoolKid?.spritePath, endsWith('escolar_chica_unova_gen5.gif'));
  });

  test('mantiene respaldo para clases especiales todavía no mapeadas', () {
    expect(
      NdsTrainerResolver.forClassId(
        version: PokemonGameVersion.white,
        trainerId: 39,
        classId: 39,
      ),
      isNull,
    );
  });

  test('resuelve rival y líder con su sprite propio', () {
    final barry = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.platinum,
      trainerId: 246,
      classId: 63,
    );
    final cilan = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.white,
      trainerId: 11,
      classId: 11,
    );

    expect(barry?.className, 'Barry');
    expect(barry?.spritePath, endsWith('barry_pt.gif'));
    expect(cilan?.className, 'Millo');
    expect(cilan?.spritePath, endsWith('cilan_unova.gif'));
  });

  test('resuelve clases y entrenadores especiales de HGSS', () {
    final youngster = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.heartGold,
      trainerId: 1,
      classId: 2,
    );
    final silver = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.soulSilver,
      trainerId: 10,
      classId: 23,
    );
    final lance = NdsTrainerResolver.forClassId(
      version: PokemonGameVersion.heartGold,
      trainerId: 20,
      classId: 86,
    );

    expect(youngster?.className, 'Joven');
    expect(youngster?.spritePath, endsWith('joven_johto_hgss.png'));
    expect(silver?.className, 'Silver');
    expect(silver?.spritePath, endsWith('silver_hgss.gif'));
    expect(lance?.className, 'Lance');
    expect(lance?.spritePath, endsWith('lance_johto_hgss.gif'));
  });

  test('mantiene respaldo histórico para una bandera Gen V verificada', () {
    final trainer = NdsTrainerResolver.forGen5TrainerFlag(145);

    expect(trainer?.className, 'Joven');
    expect(trainer?.spritePath, endsWith('joven_unova_gen5.gif'));
    expect(NdsTrainerResolver.forGen5TrainerFlag(144), isNull);
  });
}
