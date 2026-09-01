import 'dart:convert';

class Gen2RedChallengeEvent {
  final String type;
  final DateTime createdAt;
  final String? metadataJson;

  const Gen2RedChallengeEvent({
    required this.type,
    required this.createdAt,
    this.metadataJson,
  });
}

class Gen2RedChallengeProgress {
  final bool redDefeated;
  final int leagueWinsAfterRed;
  final Set<String> claimedRewards;

  const Gen2RedChallengeProgress({
    required this.redDefeated,
    required this.leagueWinsAfterRed,
    required this.claimedRewards,
  });

  factory Gen2RedChallengeProgress.fromEvents(
    Iterable<Gen2RedChallengeEvent> events,
  ) {
    final eventList = events.toList(growable: false);
    DateTime? redDefeatedAt;
    final claimed = <String>{};
    for (final event in eventList) {
      Map<dynamic, dynamic>? metadata;
      try {
        final decoded = jsonDecode(event.metadataJson ?? '');
        if (decoded is Map) metadata = decoded;
      } catch (_) {}
      if (event.type == 'trainer_defeated' &&
          metadata?['trainerClassId']?.toString() == '63' &&
          (redDefeatedAt == null || event.createdAt.isBefore(redDefeatedAt))) {
        redDefeatedAt = event.createdAt;
      } else if (event.type == 'red_reward_received') {
        final key = metadata?['rewardKey']?.toString();
        if (key != null) claimed.add(key);
      }
    }
    final wins = redDefeatedAt == null
        ? 0
        : eventList.where((event) =>
            event.type == 'champion_defeated' &&
            event.createdAt.isAfter(redDefeatedAt!)).length;
    return Gen2RedChallengeProgress(
      redDefeated: redDefeatedAt != null,
      leagueWinsAfterRed: wins,
      claimedRewards: claimed,
    );
  }
}
