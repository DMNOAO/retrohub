import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/libretro_bridge.dart';
import '../presentation/widget/libretro_game_view.dart';

enum MemorySearchFormat { decimal, hexadecimal, bcd }

enum MemorySearchFilter {
  exact,
  changed,
  unchanged,
  increased,
  decreased,
}

class MemorySearchCandidate {
  final int offset;
  final int width;
  final int previousValue;
  final int currentValue;
  final Uint8List previousBytes;
  final Uint8List currentBytes;

  const MemorySearchCandidate({
    required this.offset,
    required this.width,
    required this.previousValue,
    required this.currentValue,
    required this.previousBytes,
    required this.currentBytes,
  });

  int get delta => currentValue - previousValue;

  MemorySearchCandidate copyWith({
    int? previousValue,
    int? currentValue,
    Uint8List? previousBytes,
    Uint8List? currentBytes,
  }) {
    return MemorySearchCandidate(
      offset: offset,
      width: width,
      previousValue: previousValue ?? this.previousValue,
      currentValue: currentValue ?? this.currentValue,
      previousBytes: previousBytes ?? this.previousBytes,
      currentBytes: currentBytes ?? this.currentBytes,
    );
  }
}

class MemoryFavorite {
  final int memoryId;
  final String regionName;
  final int offset;
  final int width;
  final MemorySearchFormat format;
  final String label;

  const MemoryFavorite({
    required this.memoryId,
    required this.regionName,
    required this.offset,
    required this.width,
    required this.format,
    required this.label,
  });
}

class MemoryInspectorPage extends StatefulWidget {
  final LibretroGameController controller;

  const MemoryInspectorPage({
    super.key,
    required this.controller,
  });

  @override
  State<MemoryInspectorPage> createState() => _MemoryInspectorPageState();
}

class _MemoryInspectorPageState extends State<MemoryInspectorPage>
    with SingleTickerProviderStateMixin {
  static const int _bytesPerRow = 16;
  static const int _pageSize = 256;
  static const int _maximumVisibleResults = 5000;

  static const Map<String, int> _memoryIds = {
    'SYSTEM RAM': LibretroMemoryRegion.systemRam,
    'SAVE RAM': LibretroMemoryRegion.saveRam,
    'VIDEO RAM': LibretroMemoryRegion.videoRam,
    'RTC': LibretroMemoryRegion.rtc,
  };

  final TextEditingController _offsetController =
      TextEditingController(text: '0000');
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _favoriteLabelController =
      TextEditingController();

  late final TabController _tabController;
  Timer? _timer;

  String _selectedRegion = 'SYSTEM RAM';
  int _regionSize = 0;
  int _offset = 0;

  Uint8List _bytes = Uint8List(0);
  Uint8List? _referenceBytes;
  Set<int> _changedIndexes = <int>{};

  bool _paused = false;
  bool _showOnlyChanged = false;
  bool _comparisonEnabled = false;
  bool _searching = false;

  String? _errorMessage;
  String? _statusMessage;

  MemorySearchFormat _searchFormat = MemorySearchFormat.decimal;
  MemorySearchFilter _searchFilter = MemorySearchFilter.exact;
  int _searchWidth = 1;
  bool _littleEndian = true;

  Uint8List? _searchSnapshot;
  List<MemorySearchCandidate> _searchCandidates = <MemorySearchCandidate>[];
  final List<MemoryFavorite> _favorites = <MemoryFavorite>[];

  int get _selectedMemoryId => _memoryIds[_selectedRegion]!;

  bool get _hasReference =>
      _referenceBytes != null && _referenceBytes!.isNotEmpty;

  bool get _hasActiveSearch =>
      _searchSnapshot != null && _searchCandidates.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) => _readPage());

    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (!_paused && !_searching) {
          _readPage();
          if (_favorites.isNotEmpty && mounted) {
            setState(() {});
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _offsetController.dispose();
    _searchController.dispose();
    _favoriteLabelController.dispose();
    super.dispose();
  }

  int _sizeForSelectedRegion(Map<String, int> regions) {
    switch (_selectedRegion) {
      case 'SYSTEM RAM':
        return regions['systemRam'] ?? 0;
      case 'SAVE RAM':
        return regions['saveRam'] ?? 0;
      case 'VIDEO RAM':
        return regions['videoRam'] ?? 0;
      case 'RTC':
        return regions['rtc'] ?? 0;
      default:
        return 0;
    }
  }

  int _refreshRegionSize() {
    final Map<String, int> regions = widget.controller.inspectMemoryRegions();
    final int size = _sizeForSelectedRegion(regions);
    _regionSize = size;
    return size;
  }

  Uint8List _readWholeSelectedRegion() {
    final int size = _refreshRegionSize();
    if (size <= 0) {
      return Uint8List(0);
    }

    return widget.controller.readMemoryBlock(
      memoryId: _selectedMemoryId,
      offset: 0,
      length: size,
    );
  }

  void _readPage() {
    final int size = _refreshRegionSize();

    if (size <= 0) {
      if (!mounted) return;
      setState(() {
        _regionSize = 0;
        _bytes = Uint8List(0);
        _changedIndexes = <int>{};
        _errorMessage = 'La región seleccionada no está disponible.';
      });
      return;
    }

    final int safeOffset = _offset.clamp(0, _maximumPageOffset(size));
    final int length = (size - safeOffset) < _pageSize
        ? size - safeOffset
        : _pageSize;

    final Uint8List next = widget.controller.readMemoryBlock(
      memoryId: _selectedMemoryId,
      offset: safeOffset,
      length: length,
    );

    final Set<int> changed = <int>{};
    if (_comparisonEnabled && _referenceBytes != null) {
      final Uint8List reference = _referenceBytes!;
      final int comparable =
          next.length < reference.length ? next.length : reference.length;
      for (int i = 0; i < comparable; i++) {
        if (next[i] != reference[i]) changed.add(i);
      }
      for (int i = comparable; i < next.length; i++) {
        changed.add(i);
      }
    }

    if (!mounted) return;
    setState(() {
      _regionSize = size;
      _offset = safeOffset;
      _offsetController.text = _hexOffset(safeOffset);
      _bytes = next;
      _changedIndexes = changed;
      _errorMessage = next.isEmpty
          ? 'No fue posible leer esta página de memoria.'
          : null;
    });
  }

  int _maximumPageOffset(int size) {
    if (size <= _pageSize) return 0;
    return ((size - 1) ~/ _pageSize) * _pageSize;
  }

  void _changeRegion(String? value) {
    if (value == null || value == _selectedRegion) return;
    setState(() {
      _selectedRegion = value;
      _offset = 0;
      _offsetController.text = '0000';
      _bytes = Uint8List(0);
      _referenceBytes = null;
      _changedIndexes = <int>{};
      _comparisonEnabled = false;
      _showOnlyChanged = false;
      _statusMessage = null;
      _resetSearchState(showMessage: false);
    });
    _readPage();
  }

  void _previousPage() {
    if (_offset <= 0) return;
    setState(() {
      _offset = (_offset - _pageSize).clamp(0, _offset);
      _resetPageComparison();
    });
    _readPage();
  }

  void _nextPage() {
    final int max = _maximumPageOffset(_regionSize);
    if (_offset >= max) return;
    setState(() {
      _offset = (_offset + _pageSize).clamp(0, max);
      _resetPageComparison();
    });
    _readPage();
  }

  void _resetPageComparison() {
    _referenceBytes = null;
    _changedIndexes = <int>{};
    _comparisonEnabled = false;
    _showOnlyChanged = false;
    _statusMessage = null;
  }

  void _goToOffset() {
    String raw = _offsetController.text.trim().toLowerCase();
    if (raw.startsWith('0x')) raw = raw.substring(2);
    final int? parsed = int.tryParse(raw, radix: 16);

    if (parsed == null) {
      setState(() {
        _errorMessage = 'El offset debe ser hexadecimal. Ejemplo: 1A20';
      });
      return;
    }

    final int max = _maximumPageOffset(_regionSize);
    setState(() {
      _offset = ((parsed ~/ _pageSize) * _pageSize).clamp(0, max);
      _resetPageComparison();
      _errorMessage = null;
    });
    _readPage();
  }

  void _jumpToCandidate(int offset) {
    final int max = _maximumPageOffset(_regionSize);
    setState(() {
      _offset = ((offset ~/ _pageSize) * _pageSize).clamp(0, max);
      _offsetController.text = _hexOffset(offset);
      _resetPageComparison();
    });
    _tabController.animateTo(0);
    _readPage();
  }

  void _captureReference() {
    if (_bytes.isEmpty) {
      setState(() => _errorMessage = 'No hay datos disponibles para capturar.');
      return;
    }
    setState(() {
      _referenceBytes = Uint8List.fromList(_bytes);
      _changedIndexes = <int>{};
      _comparisonEnabled = false;
      _showOnlyChanged = false;
      _errorMessage = null;
      _statusMessage = 'Referencia capturada en 0x${_hexOffset(_offset)}.';
    });
  }

  void _compareWithReference() {
    if (!_hasReference) {
      setState(() => _errorMessage = 'Primero debes capturar una referencia.');
      return;
    }
    setState(() {
      _comparisonEnabled = true;
      _errorMessage = null;
      _statusMessage = 'Comparando la página actual con la referencia.';
    });
    _readPage();
  }

  void _resetComparison() {
    setState(() {
      _resetPageComparison();
      _errorMessage = null;
      _statusMessage = 'Comparación reiniciada.';
    });
  }

  Future<void> _startExactSearch() async {
    final int? searchedValue = _parseSearchValue();
    if (searchedValue == null) return;

    setState(() {
      _searching = true;
      _errorMessage = null;
      _statusMessage = 'Buscando en toda la región $_selectedRegion…';
    });

    await Future<void>.delayed(Duration.zero);
    final Uint8List snapshot = _readWholeSelectedRegion();
    if (snapshot.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _errorMessage = 'No fue posible leer la región completa.';
      });
      return;
    }

    final List<MemorySearchCandidate> results = <MemorySearchCandidate>[];
    final int width = _effectiveWidth(searchedValue);

    for (int offset = 0; offset <= snapshot.length - width; offset++) {
      final int current = _decodeValue(snapshot, offset, width, _searchFormat);
      if (current == searchedValue) {
        final Uint8List raw = Uint8List.fromList(
          snapshot.sublist(offset, offset + width),
        );
        results.add(
          MemorySearchCandidate(
            offset: offset,
            width: width,
            previousValue: current,
            currentValue: current,
            previousBytes: raw,
            currentBytes: raw,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _searchSnapshot = snapshot;
      _searchCandidates = results;
      _searching = false;
      _searchFilter = MemorySearchFilter.exact;
      _statusMessage = results.isEmpty
          ? 'No se encontraron coincidencias.'
          : 'Primera búsqueda completada: ${results.length} coincidencias.';
    });
  }

  Future<void> _filterSearch() async {
    if (_searchSnapshot == null || _searchCandidates.isEmpty) {
      setState(() {
        _errorMessage = 'Primero realiza una búsqueda exacta.';
      });
      return;
    }

    final int? searchedValue = _searchFilter == MemorySearchFilter.exact
        ? _parseSearchValue()
        : null;
    if (_searchFilter == MemorySearchFilter.exact && searchedValue == null) {
      return;
    }

    setState(() {
      _searching = true;
      _errorMessage = null;
      _statusMessage = 'Filtrando ${_searchCandidates.length} candidatos…';
    });

    await Future<void>.delayed(Duration.zero);
    final Uint8List currentSnapshot = _readWholeSelectedRegion();
    if (currentSnapshot.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _errorMessage = 'No fue posible actualizar la memoria.';
      });
      return;
    }

    final List<MemorySearchCandidate> filtered = <MemorySearchCandidate>[];
    for (final MemorySearchCandidate candidate in _searchCandidates) {
      if (candidate.offset + candidate.width > currentSnapshot.length) continue;

      final int oldValue = candidate.currentValue;
      final int newValue = _decodeValue(
        currentSnapshot,
        candidate.offset,
        candidate.width,
        _searchFormat,
      );

      bool keep;
      switch (_searchFilter) {
        case MemorySearchFilter.exact:
          keep = newValue == searchedValue;
          break;
        case MemorySearchFilter.changed:
          keep = newValue != oldValue;
          break;
        case MemorySearchFilter.unchanged:
          keep = newValue == oldValue;
          break;
        case MemorySearchFilter.increased:
          keep = newValue > oldValue;
          break;
        case MemorySearchFilter.decreased:
          keep = newValue < oldValue;
          break;
      }

      if (keep) {
        filtered.add(
          candidate.copyWith(
            previousValue: oldValue,
            currentValue: newValue,
            previousBytes: candidate.currentBytes,
            currentBytes: Uint8List.fromList(
              currentSnapshot.sublist(
                candidate.offset,
                candidate.offset + candidate.width,
              ),
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _searchSnapshot = currentSnapshot;
      _searchCandidates = filtered;
      _searching = false;
      _statusMessage = filtered.isEmpty
          ? 'El filtro eliminó todos los candidatos.'
          : 'Filtro completado: ${filtered.length} candidatos restantes.';
    });
  }

  int? _parseSearchValue() {
    final String raw = _searchController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Escribe un valor para buscar.');
      return null;
    }

    String normalized = raw.toLowerCase();
    if (normalized.startsWith('0x')) normalized = normalized.substring(2);

    final int? value = _searchFormat == MemorySearchFormat.hexadecimal
        ? int.tryParse(normalized, radix: 16)
        : int.tryParse(normalized);

    if (value == null || value < 0) {
      setState(() {
        _errorMessage = _searchFormat == MemorySearchFormat.hexadecimal
            ? 'Valor hexadecimal inválido. Ejemplo: 7B o 0x7B.'
            : 'Valor decimal inválido.';
      });
      return null;
    }

    final int width = _effectiveWidth(value);
    final int maximum = _searchFormat == MemorySearchFormat.bcd
        ? _maximumBcdValue(width)
        : _maximumBinaryValue(width);

    if (value > maximum) {
      setState(() {
        _errorMessage = 'El valor no cabe en $_searchWidth byte(s).';
      });
      return null;
    }

    return value;
  }

  int _effectiveWidth(int value) {
    if (_searchWidth > 0) return _searchWidth;
    if (_searchFormat == MemorySearchFormat.bcd) {
      final int digits = value.toString().length;
      return ((digits + 1) ~/ 2).clamp(1, 4);
    }
    if (value <= 0xFF) return 1;
    if (value <= 0xFFFF) return 2;
    if (value <= 0xFFFFFF) return 3;
    return 4;
  }

  int _maximumBinaryValue(int width) {
    if (width >= 4) return 0xFFFFFFFF;
    return (1 << (width * 8)) - 1;
  }

  int _maximumBcdValue(int width) {
    return int.parse(List<String>.filled(width * 2, '9').join());
  }

  int _decodeValue(
    Uint8List bytes,
    int offset,
    int width,
    MemorySearchFormat format,
  ) {
    if (format == MemorySearchFormat.bcd) {
      int value = 0;
      final Iterable<int> indexes = _littleEndian
          ? Iterable<int>.generate(width, (int i) => offset + width - 1 - i)
          : Iterable<int>.generate(width, (int i) => offset + i);
      for (final int index in indexes) {
        final int byte = bytes[index];
        final int high = (byte >> 4) & 0x0F;
        final int low = byte & 0x0F;
        if (high > 9 || low > 9) return -1;
        value = (value * 100) + (high * 10) + low;
      }
      return value;
    }

    int value = 0;
    if (_littleEndian) {
      for (int i = 0; i < width; i++) {
        value |= bytes[offset + i] << (8 * i);
      }
    } else {
      for (int i = 0; i < width; i++) {
        value = (value << 8) | bytes[offset + i];
      }
    }
    return value;
  }

  void _resetSearchState({bool showMessage = true}) {
    _searchSnapshot = null;
    _searchCandidates = <MemorySearchCandidate>[];
    _searchFilter = MemorySearchFilter.exact;
    if (showMessage) {
      _statusMessage = 'Búsqueda reiniciada.';
      _errorMessage = null;
    }
  }

  Future<void> _addFavorite(MemorySearchCandidate candidate) async {
    _favoriteLabelController.text = '';
    final String? label = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Guardar dirección'),
          content: TextField(
            controller: _favoriteLabelController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ejemplo: Dinero',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(_favoriteLabelController.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (label == null || label.isEmpty || !mounted) return;
    final bool exists = _favorites.any(
      (MemoryFavorite favorite) =>
          favorite.memoryId == _selectedMemoryId &&
          favorite.offset == candidate.offset &&
          favorite.width == candidate.width,
    );

    setState(() {
      if (!exists) {
        _favorites.add(
          MemoryFavorite(
            memoryId: _selectedMemoryId,
            regionName: _selectedRegion,
            offset: candidate.offset,
            width: candidate.width,
            format: _searchFormat,
            label: label,
          ),
        );
      }
      _statusMessage = exists
          ? 'La dirección ya estaba guardada.'
          : '$label guardado en 0x${_hexOffset(candidate.offset)}.';
    });
  }

  int? _readFavoriteValue(MemoryFavorite favorite) {
    final Uint8List bytes = widget.controller.readMemoryBlock(
      memoryId: favorite.memoryId,
      offset: favorite.offset,
      length: favorite.width,
    );
    if (bytes.length != favorite.width) return null;
    return _decodeValue(bytes, 0, favorite.width, favorite.format);
  }

  String _hexOffset(int value) {
    return value
        .toRadixString(16)
        .padLeft(_regionSize > 0xFFFF ? 6 : 4, '0')
        .toUpperCase();
  }

  String _rawBytes(Uint8List bytes) {
    return bytes
        .map((int value) => value.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  String _formatName(MemorySearchFormat format) {
    switch (format) {
      case MemorySearchFormat.decimal:
        return 'Decimal';
      case MemorySearchFormat.hexadecimal:
        return 'Hexadecimal';
      case MemorySearchFormat.bcd:
        return 'BCD';
    }
  }

  String _filterName(MemorySearchFilter filter) {
    switch (filter) {
      case MemorySearchFilter.exact:
        return 'Valor exacto';
      case MemorySearchFilter.changed:
        return 'Cambió';
      case MemorySearchFilter.unchanged:
        return 'No cambió';
      case MemorySearchFilter.increased:
        return 'Aumentó';
      case MemorySearchFilter.decreased:
        return 'Disminuyó';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Analyzer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Inspector'),
            Tab(icon: Icon(Icons.search_rounded), text: 'Analizador'),
            Tab(icon: Icon(Icons.star_rounded), text: 'Favoritos'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _paused ? 'Reanudar lectura' : 'Pausar lectura',
            onPressed: () {
              setState(() => _paused = !_paused);
              if (!_paused) _readPage();
            },
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _readPage,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGlobalStatus(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInspectorTab(),
                _buildAnalyzerTab(),
                _buildFavoritesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatus() {
    if (_errorMessage == null && _statusMessage == null) {
      return const SizedBox.shrink();
    }
    final bool error = _errorMessage != null;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: error
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(error ? _errorMessage! : _statusMessage!),
    );
  }

  Widget _buildRegionSelector() {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedRegion,
        decoration: const InputDecoration(
          labelText: 'Región',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: _memoryIds.keys
            .map(
              (String region) => DropdownMenuItem<String>(
                value: region,
                child: Text(region),
              ),
            )
            .toList(),
        onChanged: _searching ? null : _changeRegion,
      ),
    );
  }

  Widget _buildInspectorTab() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _buildRegionSelector(),
              SizedBox(
                width: 170,
                child: TextField(
                  controller: _offsetController,
                  decoration: const InputDecoration(
                    labelText: 'Offset hexadecimal',
                    prefixText: '0x',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _goToOffset(),
                ),
              ),
              FilledButton.icon(
                onPressed: _goToOffset,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Ir'),
              ),
              FilterChip(
                selected: _showOnlyChanged,
                label: const Text('Solo cambios'),
                avatar: const Icon(Icons.bolt_rounded, size: 18),
                onSelected: _comparisonEnabled && _changedIndexes.isNotEmpty
                    ? (bool value) =>
                        setState(() => _showOnlyChanged = value)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: _bytes.isNotEmpty ? _captureReference : null,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Capturar referencia'),
              ),
              FilledButton.tonalIcon(
                onPressed: _hasReference ? _compareWithReference : null,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('Comparar'),
              ),
              OutlinedButton.icon(
                onPressed: _hasReference ||
                        _comparisonEnabled ||
                        _changedIndexes.isNotEmpty
                    ? _resetComparison
                    : null,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reiniciar'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                _paused ? 'PAUSADO' : 'EN VIVO',
                style: TextStyle(
                  color: _paused ? Colors.orangeAccent : Colors.greenAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 18),
              Text('Tamaño: $_regionSize bytes'),
              const SizedBox(width: 18),
              Text('Página: 0x${_hexOffset(_offset)}'),
              const Spacer(),
              Text(
                _comparisonEnabled
                    ? 'Diferencias: ${_changedIndexes.length}'
                    : _hasReference
                        ? 'Referencia lista'
                        : 'Sin referencia',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildMemoryTable()),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _offset > 0 ? _previousPage : null,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Página anterior'),
              ),
              const Spacer(),
              Text(
                '0x${_hexOffset(_offset)} — '
                '0x${_hexOffset((_offset + (_bytes.isEmpty ? 0 : _bytes.length - 1)).clamp(0, _regionSize))}',
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _offset < _maximumPageOffset(_regionSize)
                    ? _nextPage
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Página siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzerTab() {
    final int visible = _searchCandidates.length > _maximumVisibleResults
        ? _maximumVisibleResults
        : _searchCandidates.length;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _buildRegionSelector(),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<MemorySearchFormat>(
                  initialValue: _searchFormat,
                  decoration: const InputDecoration(
                    labelText: 'Formato',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: MemorySearchFormat.values
                      .map(
                        (MemorySearchFormat value) => DropdownMenuItem(
                          value: value,
                          child: Text(_formatName(value)),
                        ),
                      )
                      .toList(),
                  onChanged: _hasActiveSearch
                      ? null
                      : (MemorySearchFormat? value) {
                          if (value != null) {
                            setState(() => _searchFormat = value);
                          }
                        },
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  initialValue: _searchWidth,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 byte')),
                    DropdownMenuItem(value: 2, child: Text('2 bytes')),
                    DropdownMenuItem(value: 3, child: Text('3 bytes')),
                    DropdownMenuItem(value: 4, child: Text('4 bytes')),
                  ],
                  onChanged: _hasActiveSearch
                      ? null
                      : (int? value) {
                          if (value != null) {
                            setState(() => _searchWidth = value);
                          }
                        },
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchController,
                  enabled: !_searching,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    hintText: _searchFormat == MemorySearchFormat.hexadecimal
                        ? 'Ejemplo: 7B'
                        : 'Ejemplo: 3000',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) =>
                      _hasActiveSearch ? _filterSearch() : _startExactSearch(),
                ),
              ),
              FilterChip(
                selected: _littleEndian,
                label: Text(_littleEndian ? 'Little endian' : 'Big endian'),
                avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
                onSelected: _hasActiveSearch
                    ? null
                    : (bool value) => setState(() => _littleEndian = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _searching || _hasActiveSearch
                    ? null
                    : _startExactSearch,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Primera búsqueda'),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<MemorySearchFilter>(
                  initialValue: _searchFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtro siguiente',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: MemorySearchFilter.values
                      .map(
                        (MemorySearchFilter value) => DropdownMenuItem(
                          value: value,
                          child: Text(_filterName(value)),
                        ),
                      )
                      .toList(),
                  onChanged: _hasActiveSearch && !_searching
                      ? (MemorySearchFilter? value) {
                          if (value != null) {
                            setState(() => _searchFilter = value);
                          }
                        }
                      : null,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _hasActiveSearch && !_searching
                    ? _filterSearch
                    : null,
                icon: const Icon(Icons.filter_alt_rounded),
                label: const Text('Aplicar filtro'),
              ),
              OutlinedButton.icon(
                onPressed: _searchSnapshot != null ||
                        _searchCandidates.isNotEmpty
                    ? () => setState(() => _resetSearchState())
                    : null,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Nueva búsqueda'),
              ),
              if (_searching)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Resultados: ${_searchCandidates.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_searchCandidates.length > _maximumVisibleResults) ...[
                const SizedBox(width: 12),
                Text(
                  'Mostrando los primeros $_maximumVisibleResults',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Spacer(),
              Text('Región: $_selectedRegion · $_regionSize bytes'),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: visible == 0
                ? _buildSearchEmptyState()
                : ListView.separated(
                    itemCount: visible,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      return _buildCandidateTile(_searchCandidates[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.manage_search_rounded, size: 64),
            const SizedBox(height: 14),
            Text(
              'Busca un valor conocido en toda la memoria',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ejemplo: busca el dinero actual, cambia el dinero dentro del juego y filtra por el nuevo valor, por aumentó o por disminuyó.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateTile(MemorySearchCandidate candidate) {
    final bool changed = candidate.previousValue != candidate.currentValue;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        child: Text('${candidate.width}B'),
      ),
      title: Text(
        '0x${_hexOffset(candidate.offset)}',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
      subtitle: Text(
        'Antes: ${candidate.previousValue}  ·  Ahora: ${candidate.currentValue}'
        '${changed ? '  ·  Δ ${candidate.delta >= 0 ? '+' : ''}${candidate.delta}' : ''}\n'
        'Bytes: ${_rawBytes(candidate.currentBytes)}',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Ver en Inspector',
            onPressed: () => _jumpToCandidate(candidate.offset),
            icon: const Icon(Icons.visibility_rounded),
          ),
          IconButton(
            tooltip: 'Guardar como favorito',
            onPressed: () => _addFavorite(candidate),
            icon: const Icon(Icons.star_border_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded, size: 64),
            SizedBox(height: 12),
            Text('Aún no hay direcciones guardadas.'),
            SizedBox(height: 6),
            Text('Guarda candidatos desde la pestaña Analizador.'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: _favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final MemoryFavorite favorite = _favorites[index];
        final int? value = _readFavoriteValue(favorite);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.star_rounded),
            title: Text(favorite.label),
            subtitle: Text(
              '${favorite.regionName} · 0x${_hexOffset(favorite.offset)} · '
              '${favorite.width} byte(s) · ${_formatName(favorite.format)}\n'
              'Valor actual: ${value ?? 'No disponible'}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Ver en Inspector',
                  onPressed: favorite.memoryId == _selectedMemoryId
                      ? () => _jumpToCandidate(favorite.offset)
                      : null,
                  icon: const Icon(Icons.visibility_rounded),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: () {
                    setState(() => _favorites.removeAt(index));
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemoryTable() {
    if (_bytes.isEmpty) {
      return const Center(child: Text('No hay datos disponibles.'));
    }

    final List<int> rows = <int>[];
    for (int row = 0; row * _bytesPerRow < _bytes.length; row++) {
      if (_showOnlyChanged) {
        final int start = row * _bytesPerRow;
        final int end = (start + _bytesPerRow).clamp(0, _bytes.length);
        bool hasChanged = false;
        for (int i = start; i < end; i++) {
          if (_changedIndexes.contains(i)) {
            hasChanged = true;
            break;
          }
        }
        if (!hasChanged) continue;
      }
      rows.add(row);
    }

    if (rows.isEmpty) {
      return Center(
        child: Text(
          _comparisonEnabled
              ? 'No hubo diferencias respecto de la referencia.'
              : 'Captura una referencia y luego pulsa Comparar.',
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) {
          final int row = rows[index];
          final int start = row * _bytesPerRow;
          final int end = (start + _bytesPerRow).clamp(0, _bytes.length);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 74,
                  child: Text(
                    _hexOffset(_offset + start),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (int i = start; i < end; i++)
                        Container(
                          width: 30,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _changedIndexes.contains(i)
                                ? Colors.orangeAccent.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: _changedIndexes.contains(i)
                                ? Border.all(color: Colors.orangeAccent)
                                : null,
                          ),
                          child: Text(
                            _bytes[i]
                                .toRadixString(16)
                                .padLeft(2, '0')
                                .toUpperCase(),
                            style: TextStyle(
                              color: _changedIndexes.contains(i)
                                  ? Colors.orangeAccent
                                  : Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: _changedIndexes.contains(i)
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
