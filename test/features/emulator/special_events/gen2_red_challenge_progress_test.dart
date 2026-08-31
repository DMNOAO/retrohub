import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/special_events/gen2_red_challenge_progress.dart';

void main() {
  final beforeRed = DateTime(2026, 1, 1, 12);
  final red = DateTime(2026, 1, 2, 12);
  final afterRed = DateTime(2026, 1, 3, 12);

  test('ignora las victorias de Liga anteriores a Rojo', () {
    final progress = Gen2RedChallengeProgress.fromEvents([
      Gen2RedChallengeEvent(
        type: 'champion_defeated',
        createdAt: beforeRed,
      ),
    ]);
    expect(progress.redDefeated, isFalse);
    expect(progress.leagueWinsAfterRed, 0);
  });

  test('cuenta únicamente las Ligas ganadas después de Rojo', () {
    final progress = Gen2RedChallengeProgress.fromEvents([
      Gen2RedChallengeEvent(
        type: 'champion_defeated',
        createdAt: beforeRed,
      ),
      Gen2RedChallengeEvent(
        type: 'trainer_defeated',
        createdAt: red,
        metadataJson: '{"trainerClassId":63}',
      ),
      Gen2RedChallengeEvent(
        type: 'champion_defeated',
        createdAt: afterRed,
      ),
    ]);
    expect(progress.redDefeated, isTrue);
    expect(progress.leagueWinsAfterRed, 1);
  });

  test('conserva los premios que ya fueron recibidos', () {
    final progress = Gen2RedChallengeProgress.fromEvents([
      Gen2RedChallengeEvent(
        type: 'red_reward_received',
        createdAt: afterRed,
        metadataJson: '{"rewardKey":"gen2_red_reward_articuno"}',
      ),
    ]);
    expect(progress.claimedRewards, {'gen2_red_reward_articuno'});
  });
}
