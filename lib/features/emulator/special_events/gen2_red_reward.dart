enum Gen2RedReward {
  articuno(1, 144, 'Articuno', 50),
  zapdos(2, 145, 'Zapdos', 50),
  moltres(3, 146, 'Moltres', 50),
  raikou(4, 243, 'Raikou', 40),
  entei(5, 244, 'Entei', 40),
  suicune(6, 245, 'Suicune', 40),
  lugia(7, 249, 'Lugia', 40),
  hoOh(8, 250, 'Ho-Oh', 40),
  mewtwo(9, 150, 'Mewtwo', 70),
  mew(10, 151, 'Mew', 5);

  final int requiredLeagueWins;
  final int speciesId;
  final String name;
  final int level;

  const Gen2RedReward(
    this.requiredLeagueWins,
    this.speciesId,
    this.name,
    this.level,
  );

  String get eventKey => 'gen2_red_reward_${name.toLowerCase().replaceAll('-', '_')}';

  static Gen2RedReward? forLeagueWin(int leagueWins) {
    for (final reward in values) {
      if (reward.requiredLeagueWins == leagueWins) return reward;
    }
    return null;
  }
}
