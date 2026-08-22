import 'pokedex_models.dart';

/// Temporary compatibility mapping for datasets generated with the old
/// Gen III `internalId - 25` assumption. Hoenn's internal species order is
/// not National Dex order, so moves/TM-HM/encounters must come from the
/// record that actually belongs to the requested species.
const Map<int, int> gen3NationalToLegacyGeneratedId = {
  276: 279, // TAILLOW
  277: 280, // SWELLOW
  278: 284, // WINGULL
  279: 285, // PELIPPER
  280: 367, // RALTS
  281: 368, // KIRLIA
  282: 369, // GARDEVOIR
  283: 286, // SURSKIT
  284: 287, // MASQUERAIN
  285: 281, // SHROOMISH
  286: 282, // BRELOOM
  287: 339, // SLAKOTH
  288: 340, // VIGOROTH
  289: 341, // SLAKING
  290: 276, // NINCADA
  291: 277, // NINJASK
  292: 278, // SHEDINJA
  293: 345, // WHISMUR
  294: 346, // LOUDRED
  295: 347, // EXPLOUD
  296: 310, // MAKUHITA
  297: 311, // HARIYAMA
  298: 325, // AZURILL
  299: 295, // NOSEPASS
  300: 290, // SKITTY
  301: 291, // DELCATTY
  302: 297, // SABLEYE
  303: 330, // MAWILE
  304: 357, // ARON
  305: 358, // LAIRON
  306: 359, // AGGRON
  307: 331, // MEDITITE
  308: 332, // MEDICHAM
  309: 312, // ELECTRIKE
  310: 313, // MANECTRIC
  311: 328, // PLUSLE
  312: 329, // MINUN
  313: 361, // VOLBEAT
  314: 362, // ILLUMISE
  315: 338, // ROSELIA
  316: 342, // GULPIN
  317: 343, // SWALOT
  318: 305, // CARVANHA
  319: 306, // SHARPEDO
  320: 288, // WAILMER
  321: 289, // WAILORD
  322: 314, // NUMEL
  323: 315, // CAMERUPT
  324: 296, // TORKOAL
  325: 326, // SPOINK
  326: 327, // GRUMPIG
  327: 283, // SPINDA
  328: 307, // TRAPINCH
  329: 308, // VIBRAVA
  330: 309, // FLYGON
  331: 319, // CACNEA
  332: 320, // CACTURNE
  335: 355, // ZANGOOSE
  336: 354, // SEVIPER
  337: 323, // LUNATONE
  338: 324, // SOLROCK
  339: 298, // BARBOACH
  340: 299, // WHISCASH
  341: 301, // CORPHISH
  342: 302, // CRAWDAUNT
  343: 293, // BALTOY
  344: 294, // CLAYDOL
  345: 363, // LILEEP
  346: 364, // CRADILY
  347: 365, // ANORITH
  348: 366, // ARMALDO
  349: 303, // FEEBAS
  350: 304, // MILOTIC
  351: 360, // CASTFORM
  352: 292, // KECLEON
  353: 352, // SHUPPET
  354: 353, // BANETTE
  355: 336, // DUSKULL
  356: 337, // DUSCLOPS
  357: 344, // TROPIUS
  358: 386, // CHIMECHO
  359: 351, // ABSOL
  360: 335, // WYNAUT
  361: 321, // SNORUNT
  362: 322, // GLALIE
  363: 316, // SPHEAL
  364: 317, // SEALEO
  365: 318, // WALREIN
  366: 348, // CLAMPERL
  367: 349, // HUNTAIL
  368: 350, // GOREBYSS
  369: 356, // RELICANTH
  370: 300, // LUVDISC
  371: 370, // BAGON
  372: 371, // SHELGON
  373: 372, // SALAMENCE
  374: 373, // BELDUM
  375: 374, // METANG
  376: 375, // METAGROSS
  377: 376, // REGIROCK
  378: 377, // REGICE
  379: 378, // REGISTEEL
  380: 382, // LATIAS
  381: 383, // LATIOS
  382: 379, // KYOGRE
  383: 380, // GROUDON
  384: 381, // RAYQUAZA
  385: 384, // JIRACHI
  386: 385, // DEOXYS
};

PokedexSpeciesDetail correctedGen3Detail(
  Map<int, PokedexSpeciesDetail> generated,
  int nationalId,
) {
  final base = generated[nationalId] ?? const PokedexSpeciesDetail();
  final sourceId = gen3NationalToLegacyGeneratedId[nationalId];
  if (sourceId == null) return base;
  final speciesData = generated[sourceId] ?? const PokedexSpeciesDetail();
  return PokedexSpeciesDetail(
    entry: base.entry,
    levelMoves: speciesData.levelMoves,
    machineMoves: speciesData.machineMoves,
    encounters: speciesData.encounters,
  );
}
