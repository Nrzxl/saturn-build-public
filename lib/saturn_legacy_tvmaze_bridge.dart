/// Verified TVmaze -> TMDB series identities for SATURN's legacy saved
/// catalogue. Never infer a migration from a title alone (reboots and
/// regional editions may share names).
///
/// IDs were cross-checked by external series identities and premiere year.
/// No external API keys, translations or personal records travel in this file.
class SaturnLegacyTvmazeBridge {
  const SaturnLegacyTvmazeBridge._();

  static const Map<String, String> exactIds = {
    'tvmaze:50036': 'tmdb:tv:110316', // Alice in Borderland · 2020
    'tvmaze:58876': 'tmdb:tv:132979', // Bad and Crazy · 2021
    'tvmaze:4182': 'tmdb:tv:3215', // Coffee Prince · 2007
    'tvmaze:7367': 'tmdb:tv:60956', // Doctor Stranger · 2014
    'tvmaze:118': 'tmdb:tv:1408', // House M.D. · 2004
    'tvmaze:60169': 'tmdb:tv:112833', // Juvenile Justice · 2022
    'tvmaze:62966': 'tmdb:tv:207371', // Love in the Air (Thai) · 2022
    'tvmaze:54771': 'tmdb:tv:96571', // Move to Heaven · 2021
    'tvmaze:4913': 'tmdb:tv:63767', // She Was Pretty · 2015
    'tvmaze:526': 'tmdb:tv:2316', // The Office (US) · 2005
  };

  /// Original, short PT-BR synopses for legacy TVmaze fallback results.
  /// Prefer TMDB's actual pt-BR editorial overview when present.
  static const Map<String, String> portugueseSynopses = {
    'tvmaze:50036': 'Arisu e seus amigos chegam a uma Tóquio deserta, '
        'onde precisam vencer jogos perigosos para sobreviver e descobrir '
        'o que aconteceu.',
    'tvmaze:58876': 'Um detetive ambicioso tem a vida transformada quando '
        'um homem impulsivo e obcecado por justiça começa a interferir em '
        'suas investigações.',
    'tvmaze:4182': 'Uma jovem que costuma ser confundida com um rapaz '
        'consegue trabalho em uma cafeteria e vive um romance inesperado '
        'com o proprietário.',
    'tvmaze:7367': 'Um cirurgião criado na Coreia do Norte chega à Coreia '
        'do Sul e enfrenta conflitos profissionais enquanto tenta '
        'reencontrar alguém de seu passado.',
    'tvmaze:118': 'O brilhante e controverso médico Gregory House lidera '
        'uma equipe que investiga casos clínicos complexos, enquanto '
        'desafia regras e colegas.',
    'tvmaze:60169': 'Uma juíza rígida, pouco tolerante com jovens '
        'infratores, enfrenta casos difíceis e dilemas sobre justiça '
        'em um tribunal juvenil.',
    'tvmaze:62966': 'Rain e Sky vivem romances turbulentos ao conhecer '
        'Payu e Prapai, em meio a encontros, conflitos e descobertas '
        'sobre o amor.',
    'tvmaze:54771': 'Um jovem que trabalha organizando os pertences de '
        'pessoas falecidas passa a dividir a missão com o tio, '
        'descobrindo histórias emocionantes de quem partiu.',
    'tvmaze:4913': 'Dois amigos de infância se reencontram após anos '
        'de mudanças e mal-entendidos ao trabalhar na mesma revista.',
    'tvmaze:526': 'A rotina de uma empresa de papel nos Estados Unidos '
        'é acompanhada por uma equipe de documentário, revelando '
        'amizades, rivalidades e situações absurdas no escritório.',
  };

  static String? canonicalId(String legacyId) => exactIds[legacyId];

  static Map<String, dynamic> _map(Object? input) {
    if (input is! Map) return <String, dynamic>{};
    return input.map((key, value) =>
        MapEntry(key.toString(), value));
  }

  static int _clock(Object? row) {
    if (row is Map && row['updatedAt'] is num) {
      return (row['updatedAt'] as num).toInt();
    }
    return 0;
  }

  static bool _empty(Object? value) => value == null ||
      (value is String && value.trim().isEmpty);

  /// Keep a preexisting TMDB rating/review, fill missing fields from TVmaze.
  /// When both reviews differ, retain BOTH exact authored texts. Re-importing
  /// old offline data will never append an identical paragraph twice.
  static Map<String, dynamic> _review(
      Map<String, dynamic> destination, Map<String, dynamic> legacy) {
    final result = <String, dynamic>{...destination};
    for (final item in legacy.entries) {
      if (_empty(result[item.key]) && !_empty(item.value)) {
        result[item.key] = item.value;
      }
    }
    final oldNote = (legacy['notes'] ?? '').toString().trim();
    final newNote = (destination['notes'] ?? '').toString().trim();
    if (oldNote.isNotEmpty && newNote.isNotEmpty &&
        oldNote != newNote && !newNote.contains(oldNote)) {
      result['notes'] =
          '$newNote\n\nResenha anterior (TVmaze):\n$oldNote';
    }
    if (legacy['rating'] is num && destination['rating'] is num &&
        legacy['rating'] != destination['rating']) {
      result.putIfAbsent('legacyTvmazeRating', () => legacy['rating']);
    }
    const completed = {'Concluído', 'Assistido', 'Lido'};
    if (completed.contains(legacy['status']) &&
        !completed.contains(destination['status'])) {
      result['status'] = legacy['status'];
    }
    final stamp = _clock(destination) > _clock(legacy)
        ? _clock(destination) : _clock(legacy);
    if (stamp > 0) result['updatedAt'] = stamp;
    return result;
  }

  static Map<String, dynamic> _flag(
      Map<String, dynamic> destination, Map<String, dynamic> legacy) {
    final a = _clock(destination);
    final b = _clock(legacy);
    if (b > a) return legacy;
    if (a > b) return destination;
    // Same timestamp: do not silently lose either person's saved flag.
    return (legacy['present'] == true && destination['present'] != true)
        ? legacy : destination;
  }

  /// Pure, repeatable migration of personal/cloud JSON, including linked
  /// collections, orbit suggestions/rituals, favorites, and both reviews.
  /// No database writes or network calls are made here.
  static Map<String, dynamic> upgrade(Map<String, dynamic> document) {
    final result = <String, dynamic>{...document};

    final saved = _map(document['catalogSaved']);
    final records = _map(document['records']);
    final watchlist = _map(document['watchlistOps']);
    final shared = _map(document['sharedOps']);
    final archived = _map(document['archivedOps']);
    final favorites = _map(document['favoriteOps']);
    final collectionItems = _map(document['collectionItemOps']);
    final collections = _map(document['collectionOps']);
    final rituals = _map(document['ritualOps']);
    final customLinks = _map(document['customTitleLinks']);

    bool modified = false;
    for (final pair in exactIds.entries) {
      final oldId = pair.key;
      final newId = pair.value;

      final oldWork = saved.remove(oldId);
      if (oldWork != null) {
        if (!saved.containsKey(newId) && oldWork is Map) {
          saved[newId] = <String, dynamic>{
            ..._map(oldWork), 'id': newId,
            // Retain old TVmaze art until the verified TMDB row is loaded.
          };
        }
        modified = true;
      }

      void move(
        Map<String, dynamic> section, String source, String dest, {
        bool isReview = false,
      }) {
        final previous = section.remove(source);
        if (previous == null) return;
        modified = true;
        final current = section[dest];
        if (current == null) {
          section[dest] = previous;
        } else if (current is Map && previous is Map) {
          section[dest] = isReview
              ? _review(_map(current), _map(previous))
              : _flag(_map(current), _map(previous));
        }
      }

      for (var profile = 0; profile < 2; profile++) {
        final src = '$profile:$oldId';
        final dst = '$profile:$newId';
        move(records, src, dst, isReview: true);
        move(watchlist, src, dst);
        move(archived, src, dst);
        move(favorites, src, dst);
      }
      move(shared, oldId, newId);

      for (final key in collectionItems.keys.toList(growable: false)) {
        if (key.endsWith('|$oldId')) {
          move(collectionItems, key,
              '${key.substring(0, key.length - oldId.length)}$newId');
        }
      }
      for (final entry in collections.entries.toList(growable: false)) {
        if (entry.value is Map &&
            (entry.value as Map)['coverWorkId'] == oldId) {
          collections[entry.key] = {
            ..._map(entry.value), 'coverWorkId': newId,
          };
          modified = true;
        }
      }
      for (final entry in rituals.entries.toList(growable: false)) {
        if (entry.value is Map && (entry.value as Map)['workId'] == oldId) {
          rituals[entry.key] = {..._map(entry.value), 'workId': newId};
          modified = true;
        }
      }
      final previousLinks = customLinks.remove(oldId);
      if (previousLinks != null) {
        customLinks[newId] = {
          ..._map(previousLinks), ..._map(customLinks[newId]),
        };
        modified = true;
      }
    }
    if (!modified) return result;

    return {
      ...result,
      'catalogSaved': saved, 'records': records,
      'watchlistOps': watchlist, 'sharedOps': shared,
      'archivedOps': archived, 'favoriteOps': favorites,
      'collectionItemOps': collectionItems,
      'collectionOps': collections, 'ritualOps': rituals,
      'customTitleLinks': customLinks,
    };
  }
}
