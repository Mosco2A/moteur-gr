// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StagesTable extends Stages with TableInfo<$StagesTable, Stage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageNumberMeta = const VerificationMeta(
    'stageNumber',
  );
  @override
  late final GeneratedColumn<int> stageNumber = GeneratedColumn<int>(
    'stage_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationGainMMeta = const VerificationMeta(
    'elevationGainM',
  );
  @override
  late final GeneratedColumn<int> elevationGainM = GeneratedColumn<int>(
    'elevation_gain_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationLossMMeta = const VerificationMeta(
    'elevationLossM',
  );
  @override
  late final GeneratedColumn<int> elevationLossM = GeneratedColumn<int>(
    'elevation_loss_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startLatMeta = const VerificationMeta(
    'startLat',
  );
  @override
  late final GeneratedColumn<double> startLat = GeneratedColumn<double>(
    'start_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLngMeta = const VerificationMeta(
    'startLng',
  );
  @override
  late final GeneratedColumn<double> startLng = GeneratedColumn<double>(
    'start_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLatMeta = const VerificationMeta('endLat');
  @override
  late final GeneratedColumn<double> endLat = GeneratedColumn<double>(
    'end_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLngMeta = const VerificationMeta('endLng');
  @override
  late final GeneratedColumn<double> endLng = GeneratedColumn<double>(
    'end_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('moderate'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    stageNumber,
    name,
    distanceKm,
    elevationGainM,
    elevationLossM,
    description,
    startLat,
    startLng,
    endLat,
    endLng,
    difficulty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('stage_number')) {
      context.handle(
        _stageNumberMeta,
        stageNumber.isAcceptableOrUnknown(
          data['stage_number']!,
          _stageNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('elevation_gain_m')) {
      context.handle(
        _elevationGainMMeta,
        elevationGainM.isAcceptableOrUnknown(
          data['elevation_gain_m']!,
          _elevationGainMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationGainMMeta);
    }
    if (data.containsKey('elevation_loss_m')) {
      context.handle(
        _elevationLossMMeta,
        elevationLossM.isAcceptableOrUnknown(
          data['elevation_loss_m']!,
          _elevationLossMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationLossMMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start_lat')) {
      context.handle(
        _startLatMeta,
        startLat.isAcceptableOrUnknown(data['start_lat']!, _startLatMeta),
      );
    } else if (isInserting) {
      context.missing(_startLatMeta);
    }
    if (data.containsKey('start_lng')) {
      context.handle(
        _startLngMeta,
        startLng.isAcceptableOrUnknown(data['start_lng']!, _startLngMeta),
      );
    } else if (isInserting) {
      context.missing(_startLngMeta);
    }
    if (data.containsKey('end_lat')) {
      context.handle(
        _endLatMeta,
        endLat.isAcceptableOrUnknown(data['end_lat']!, _endLatMeta),
      );
    } else if (isInserting) {
      context.missing(_endLatMeta);
    }
    if (data.containsKey('end_lng')) {
      context.handle(
        _endLngMeta,
        endLng.isAcceptableOrUnknown(data['end_lng']!, _endLngMeta),
      );
    } else if (isInserting) {
      context.missing(_endLngMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      stageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      elevationGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elevation_gain_m'],
      )!,
      elevationLossM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elevation_loss_m'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      startLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lat'],
      )!,
      startLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lng'],
      )!,
      endLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lat'],
      )!,
      endLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lng'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
    );
  }

  @override
  $StagesTable createAlias(String alias) {
    return $StagesTable(attachedDatabase, alias);
  }
}

class Stage extends DataClass implements Insertable<Stage> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Identifiant du sentier parent (ex: 'sentier-volcans')
  final String trailId;

  /// Numero de l'etape dans le sentier (1-indexed)
  final int stageNumber;

  /// Nom de l'etape (ex: 'Vizzavona - Bocognano')
  final String name;

  /// Distance en kilometres
  final double distanceKm;

  /// Denivele positif en metres
  final int elevationGainM;

  /// Denivele negatif en metres
  final int elevationLossM;

  /// Description textuelle de l'etape
  final String description;

  /// Latitude du point de depart
  final double startLat;

  /// Longitude du point de depart
  final double startLng;

  /// Latitude du point d'arrivee
  final double endLat;

  /// Longitude du point d'arrivee
  final double endLng;

  /// Difficulte (easy, moderate, hard, extreme)
  final String difficulty;
  const Stage({
    required this.id,
    required this.trailId,
    required this.stageNumber,
    required this.name,
    required this.distanceKm,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.description,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.difficulty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['stage_number'] = Variable<int>(stageNumber);
    map['name'] = Variable<String>(name);
    map['distance_km'] = Variable<double>(distanceKm);
    map['elevation_gain_m'] = Variable<int>(elevationGainM);
    map['elevation_loss_m'] = Variable<int>(elevationLossM);
    map['description'] = Variable<String>(description);
    map['start_lat'] = Variable<double>(startLat);
    map['start_lng'] = Variable<double>(startLng);
    map['end_lat'] = Variable<double>(endLat);
    map['end_lng'] = Variable<double>(endLng);
    map['difficulty'] = Variable<String>(difficulty);
    return map;
  }

  StagesCompanion toCompanion(bool nullToAbsent) {
    return StagesCompanion(
      id: Value(id),
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      name: Value(name),
      distanceKm: Value(distanceKm),
      elevationGainM: Value(elevationGainM),
      elevationLossM: Value(elevationLossM),
      description: Value(description),
      startLat: Value(startLat),
      startLng: Value(startLng),
      endLat: Value(endLat),
      endLng: Value(endLng),
      difficulty: Value(difficulty),
    );
  }

  factory Stage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stage(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      stageNumber: serializer.fromJson<int>(json['stageNumber']),
      name: serializer.fromJson<String>(json['name']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      elevationGainM: serializer.fromJson<int>(json['elevationGainM']),
      elevationLossM: serializer.fromJson<int>(json['elevationLossM']),
      description: serializer.fromJson<String>(json['description']),
      startLat: serializer.fromJson<double>(json['startLat']),
      startLng: serializer.fromJson<double>(json['startLng']),
      endLat: serializer.fromJson<double>(json['endLat']),
      endLng: serializer.fromJson<double>(json['endLng']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'stageNumber': serializer.toJson<int>(stageNumber),
      'name': serializer.toJson<String>(name),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'elevationGainM': serializer.toJson<int>(elevationGainM),
      'elevationLossM': serializer.toJson<int>(elevationLossM),
      'description': serializer.toJson<String>(description),
      'startLat': serializer.toJson<double>(startLat),
      'startLng': serializer.toJson<double>(startLng),
      'endLat': serializer.toJson<double>(endLat),
      'endLng': serializer.toJson<double>(endLng),
      'difficulty': serializer.toJson<String>(difficulty),
    };
  }

  Stage copyWith({
    int? id,
    String? trailId,
    int? stageNumber,
    String? name,
    double? distanceKm,
    int? elevationGainM,
    int? elevationLossM,
    String? description,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    String? difficulty,
  }) => Stage(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    stageNumber: stageNumber ?? this.stageNumber,
    name: name ?? this.name,
    distanceKm: distanceKm ?? this.distanceKm,
    elevationGainM: elevationGainM ?? this.elevationGainM,
    elevationLossM: elevationLossM ?? this.elevationLossM,
    description: description ?? this.description,
    startLat: startLat ?? this.startLat,
    startLng: startLng ?? this.startLng,
    endLat: endLat ?? this.endLat,
    endLng: endLng ?? this.endLng,
    difficulty: difficulty ?? this.difficulty,
  );
  Stage copyWithCompanion(StagesCompanion data) {
    return Stage(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      stageNumber: data.stageNumber.present
          ? data.stageNumber.value
          : this.stageNumber,
      name: data.name.present ? data.name.value : this.name,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      elevationGainM: data.elevationGainM.present
          ? data.elevationGainM.value
          : this.elevationGainM,
      elevationLossM: data.elevationLossM.present
          ? data.elevationLossM.value
          : this.elevationLossM,
      description: data.description.present
          ? data.description.value
          : this.description,
      startLat: data.startLat.present ? data.startLat.value : this.startLat,
      startLng: data.startLng.present ? data.startLng.value : this.startLng,
      endLat: data.endLat.present ? data.endLat.value : this.endLat,
      endLng: data.endLng.present ? data.endLng.value : this.endLng,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stage(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('name: $name, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('elevationLossM: $elevationLossM, ')
          ..write('description: $description, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('difficulty: $difficulty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trailId,
    stageNumber,
    name,
    distanceKm,
    elevationGainM,
    elevationLossM,
    description,
    startLat,
    startLng,
    endLat,
    endLng,
    difficulty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stage &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.stageNumber == this.stageNumber &&
          other.name == this.name &&
          other.distanceKm == this.distanceKm &&
          other.elevationGainM == this.elevationGainM &&
          other.elevationLossM == this.elevationLossM &&
          other.description == this.description &&
          other.startLat == this.startLat &&
          other.startLng == this.startLng &&
          other.endLat == this.endLat &&
          other.endLng == this.endLng &&
          other.difficulty == this.difficulty);
}

class StagesCompanion extends UpdateCompanion<Stage> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<int> stageNumber;
  final Value<String> name;
  final Value<double> distanceKm;
  final Value<int> elevationGainM;
  final Value<int> elevationLossM;
  final Value<String> description;
  final Value<double> startLat;
  final Value<double> startLng;
  final Value<double> endLat;
  final Value<double> endLng;
  final Value<String> difficulty;
  const StagesCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.stageNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.elevationGainM = const Value.absent(),
    this.elevationLossM = const Value.absent(),
    this.description = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLng = const Value.absent(),
    this.endLat = const Value.absent(),
    this.endLng = const Value.absent(),
    this.difficulty = const Value.absent(),
  });
  StagesCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required int stageNumber,
    required String name,
    required double distanceKm,
    required int elevationGainM,
    required int elevationLossM,
    this.description = const Value.absent(),
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    this.difficulty = const Value.absent(),
  }) : trailId = Value(trailId),
       stageNumber = Value(stageNumber),
       name = Value(name),
       distanceKm = Value(distanceKm),
       elevationGainM = Value(elevationGainM),
       elevationLossM = Value(elevationLossM),
       startLat = Value(startLat),
       startLng = Value(startLng),
       endLat = Value(endLat),
       endLng = Value(endLng);
  static Insertable<Stage> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<int>? stageNumber,
    Expression<String>? name,
    Expression<double>? distanceKm,
    Expression<int>? elevationGainM,
    Expression<int>? elevationLossM,
    Expression<String>? description,
    Expression<double>? startLat,
    Expression<double>? startLng,
    Expression<double>? endLat,
    Expression<double>? endLng,
    Expression<String>? difficulty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (stageNumber != null) 'stage_number': stageNumber,
      if (name != null) 'name': name,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (elevationGainM != null) 'elevation_gain_m': elevationGainM,
      if (elevationLossM != null) 'elevation_loss_m': elevationLossM,
      if (description != null) 'description': description,
      if (startLat != null) 'start_lat': startLat,
      if (startLng != null) 'start_lng': startLng,
      if (endLat != null) 'end_lat': endLat,
      if (endLng != null) 'end_lng': endLng,
      if (difficulty != null) 'difficulty': difficulty,
    });
  }

  StagesCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<int>? stageNumber,
    Value<String>? name,
    Value<double>? distanceKm,
    Value<int>? elevationGainM,
    Value<int>? elevationLossM,
    Value<String>? description,
    Value<double>? startLat,
    Value<double>? startLng,
    Value<double>? endLat,
    Value<double>? endLng,
    Value<String>? difficulty,
  }) {
    return StagesCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      stageNumber: stageNumber ?? this.stageNumber,
      name: name ?? this.name,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      elevationLossM: elevationLossM ?? this.elevationLossM,
      description: description ?? this.description,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (stageNumber.present) {
      map['stage_number'] = Variable<int>(stageNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (elevationGainM.present) {
      map['elevation_gain_m'] = Variable<int>(elevationGainM.value);
    }
    if (elevationLossM.present) {
      map['elevation_loss_m'] = Variable<int>(elevationLossM.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startLat.present) {
      map['start_lat'] = Variable<double>(startLat.value);
    }
    if (startLng.present) {
      map['start_lng'] = Variable<double>(startLng.value);
    }
    if (endLat.present) {
      map['end_lat'] = Variable<double>(endLat.value);
    }
    if (endLng.present) {
      map['end_lng'] = Variable<double>(endLng.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StagesCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('name: $name, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGainM: $elevationGainM, ')
          ..write('elevationLossM: $elevationLossM, ')
          ..write('description: $description, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('difficulty: $difficulty')
          ..write(')'))
        .toString();
  }
}

class $PoisTable extends Pois with TableInfo<$PoisTable, Poi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageNumberMeta = const VerificationMeta(
    'stageNumber',
  );
  @override
  late final GeneratedColumn<int> stageNumber = GeneratedColumn<int>(
    'stage_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<int> altitudeM = GeneratedColumn<int>(
    'altitude_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openingHoursMeta = const VerificationMeta(
    'openingHours',
  );
  @override
  late final GeneratedColumn<String> openingHours = GeneratedColumn<String>(
    'opening_hours',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    stageNumber,
    name,
    description,
    type,
    lat,
    lng,
    altitudeM,
    openingHours,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pois';
  @override
  VerificationContext validateIntegrity(
    Insertable<Poi> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('stage_number')) {
      context.handle(
        _stageNumberMeta,
        stageNumber.isAcceptableOrUnknown(
          data['stage_number']!,
          _stageNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    }
    if (data.containsKey('opening_hours')) {
      context.handle(
        _openingHoursMeta,
        openingHours.isAcceptableOrUnknown(
          data['opening_hours']!,
          _openingHoursMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Poi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Poi(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      stageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}altitude_m'],
      )!,
      openingHours: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_hours'],
      ),
    );
  }

  @override
  $PoisTable createAlias(String alias) {
    return $PoisTable(attachedDatabase, alias);
  }
}

class Poi extends DataClass implements Insertable<Poi> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Identifiant du sentier parent
  final String trailId;

  /// Numero de l'etape associee
  final int stageNumber;

  /// Nom du point d'interet
  final String name;

  /// Description du POI
  final String description;

  /// Type de POI (shelter, water, viewpoint, campsite, restaurant, emergency, danger, shop)
  final String type;

  /// Latitude
  final double lat;

  /// Longitude
  final double lng;

  /// Altitude en metres
  final int altitudeM;

  /// Horaires d'ouverture (nullable)
  final String? openingHours;
  const Poi({
    required this.id,
    required this.trailId,
    required this.stageNumber,
    required this.name,
    required this.description,
    required this.type,
    required this.lat,
    required this.lng,
    required this.altitudeM,
    this.openingHours,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['stage_number'] = Variable<int>(stageNumber);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['altitude_m'] = Variable<int>(altitudeM);
    if (!nullToAbsent || openingHours != null) {
      map['opening_hours'] = Variable<String>(openingHours);
    }
    return map;
  }

  PoisCompanion toCompanion(bool nullToAbsent) {
    return PoisCompanion(
      id: Value(id),
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      lat: Value(lat),
      lng: Value(lng),
      altitudeM: Value(altitudeM),
      openingHours: openingHours == null && nullToAbsent
          ? const Value.absent()
          : Value(openingHours),
    );
  }

  factory Poi.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Poi(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      stageNumber: serializer.fromJson<int>(json['stageNumber']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      altitudeM: serializer.fromJson<int>(json['altitudeM']),
      openingHours: serializer.fromJson<String?>(json['openingHours']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'stageNumber': serializer.toJson<int>(stageNumber),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'altitudeM': serializer.toJson<int>(altitudeM),
      'openingHours': serializer.toJson<String?>(openingHours),
    };
  }

  Poi copyWith({
    int? id,
    String? trailId,
    int? stageNumber,
    String? name,
    String? description,
    String? type,
    double? lat,
    double? lng,
    int? altitudeM,
    Value<String?> openingHours = const Value.absent(),
  }) => Poi(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    stageNumber: stageNumber ?? this.stageNumber,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    altitudeM: altitudeM ?? this.altitudeM,
    openingHours: openingHours.present ? openingHours.value : this.openingHours,
  );
  Poi copyWithCompanion(PoisCompanion data) {
    return Poi(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      stageNumber: data.stageNumber.present
          ? data.stageNumber.value
          : this.stageNumber,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
      openingHours: data.openingHours.present
          ? data.openingHours.value
          : this.openingHours,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Poi(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('openingHours: $openingHours')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trailId,
    stageNumber,
    name,
    description,
    type,
    lat,
    lng,
    altitudeM,
    openingHours,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Poi &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.stageNumber == this.stageNumber &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.altitudeM == this.altitudeM &&
          other.openingHours == this.openingHours);
}

class PoisCompanion extends UpdateCompanion<Poi> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<int> stageNumber;
  final Value<String> name;
  final Value<String> description;
  final Value<String> type;
  final Value<double> lat;
  final Value<double> lng;
  final Value<int> altitudeM;
  final Value<String?> openingHours;
  const PoisCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.stageNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.altitudeM = const Value.absent(),
    this.openingHours = const Value.absent(),
  });
  PoisCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required int stageNumber,
    required String name,
    this.description = const Value.absent(),
    required String type,
    required double lat,
    required double lng,
    this.altitudeM = const Value.absent(),
    this.openingHours = const Value.absent(),
  }) : trailId = Value(trailId),
       stageNumber = Value(stageNumber),
       name = Value(name),
       type = Value(type),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<Poi> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<int>? stageNumber,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<int>? altitudeM,
    Expression<String>? openingHours,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (stageNumber != null) 'stage_number': stageNumber,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (altitudeM != null) 'altitude_m': altitudeM,
      if (openingHours != null) 'opening_hours': openingHours,
    });
  }

  PoisCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<int>? stageNumber,
    Value<String>? name,
    Value<String>? description,
    Value<String>? type,
    Value<double>? lat,
    Value<double>? lng,
    Value<int>? altitudeM,
    Value<String?>? openingHours,
  }) {
    return PoisCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      stageNumber: stageNumber ?? this.stageNumber,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      altitudeM: altitudeM ?? this.altitudeM,
      openingHours: openingHours ?? this.openingHours,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (stageNumber.present) {
      map['stage_number'] = Variable<int>(stageNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<int>(altitudeM.value);
    }
    if (openingHours.present) {
      map['opening_hours'] = Variable<String>(openingHours.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoisCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('openingHours: $openingHours')
          ..write(')'))
        .toString();
  }
}

class $UserProgressEntriesTable extends UserProgressEntries
    with TableInfo<$UserProgressEntriesTable, UserProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStageMeta = const VerificationMeta(
    'currentStage',
  );
  @override
  late final GeneratedColumn<int> currentStage = GeneratedColumn<int>(
    'current_stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _totalDistanceWalkedKmMeta =
      const VerificationMeta('totalDistanceWalkedKm');
  @override
  late final GeneratedColumn<double> totalDistanceWalkedKm =
      GeneratedColumn<double>(
        'total_distance_walked_km',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _totalElevationGainedMMeta =
      const VerificationMeta('totalElevationGainedM');
  @override
  late final GeneratedColumn<int> totalElevationGainedM = GeneratedColumn<int>(
    'total_elevation_gained_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalTimeMinutesMeta = const VerificationMeta(
    'totalTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> totalTimeMinutes = GeneratedColumn<int>(
    'total_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    currentStage,
    totalDistanceWalkedKm,
    totalElevationGainedM,
    totalTimeMinutes,
    isCompleted,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('current_stage')) {
      context.handle(
        _currentStageMeta,
        currentStage.isAcceptableOrUnknown(
          data['current_stage']!,
          _currentStageMeta,
        ),
      );
    }
    if (data.containsKey('total_distance_walked_km')) {
      context.handle(
        _totalDistanceWalkedKmMeta,
        totalDistanceWalkedKm.isAcceptableOrUnknown(
          data['total_distance_walked_km']!,
          _totalDistanceWalkedKmMeta,
        ),
      );
    }
    if (data.containsKey('total_elevation_gained_m')) {
      context.handle(
        _totalElevationGainedMMeta,
        totalElevationGainedM.isAcceptableOrUnknown(
          data['total_elevation_gained_m']!,
          _totalElevationGainedMMeta,
        ),
      );
    }
    if (data.containsKey('total_time_minutes')) {
      context.handle(
        _totalTimeMinutesMeta,
        totalTimeMinutes.isAcceptableOrUnknown(
          data['total_time_minutes']!,
          _totalTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProgressEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      currentStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_stage'],
      )!,
      totalDistanceWalkedKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance_walked_km'],
      )!,
      totalElevationGainedM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_elevation_gained_m'],
      )!,
      totalTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_time_minutes'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $UserProgressEntriesTable createAlias(String alias) {
    return $UserProgressEntriesTable(attachedDatabase, alias);
  }
}

class UserProgressEntry extends DataClass
    implements Insertable<UserProgressEntry> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Identifiant du sentier
  final String trailId;

  /// Etape courante (1-indexed)
  final int currentStage;

  /// Distance totale parcourue en km
  final double totalDistanceWalkedKm;

  /// Denivele positif total cumule en metres
  final int totalElevationGainedM;

  /// Temps total de marche en minutes (ajoute en v2)
  final int totalTimeMinutes;

  /// Sentier complete ou non
  final bool isCompleted;

  /// Date de debut du sentier (nullable)
  final DateTime? startedAt;

  /// Date de fin du sentier (nullable)
  final DateTime? completedAt;
  const UserProgressEntry({
    required this.id,
    required this.trailId,
    required this.currentStage,
    required this.totalDistanceWalkedKm,
    required this.totalElevationGainedM,
    required this.totalTimeMinutes,
    required this.isCompleted,
    this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['current_stage'] = Variable<int>(currentStage);
    map['total_distance_walked_km'] = Variable<double>(totalDistanceWalkedKm);
    map['total_elevation_gained_m'] = Variable<int>(totalElevationGainedM);
    map['total_time_minutes'] = Variable<int>(totalTimeMinutes);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  UserProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return UserProgressEntriesCompanion(
      id: Value(id),
      trailId: Value(trailId),
      currentStage: Value(currentStage),
      totalDistanceWalkedKm: Value(totalDistanceWalkedKm),
      totalElevationGainedM: Value(totalElevationGainedM),
      totalTimeMinutes: Value(totalTimeMinutes),
      isCompleted: Value(isCompleted),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory UserProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProgressEntry(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      currentStage: serializer.fromJson<int>(json['currentStage']),
      totalDistanceWalkedKm: serializer.fromJson<double>(
        json['totalDistanceWalkedKm'],
      ),
      totalElevationGainedM: serializer.fromJson<int>(
        json['totalElevationGainedM'],
      ),
      totalTimeMinutes: serializer.fromJson<int>(json['totalTimeMinutes']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'currentStage': serializer.toJson<int>(currentStage),
      'totalDistanceWalkedKm': serializer.toJson<double>(totalDistanceWalkedKm),
      'totalElevationGainedM': serializer.toJson<int>(totalElevationGainedM),
      'totalTimeMinutes': serializer.toJson<int>(totalTimeMinutes),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  UserProgressEntry copyWith({
    int? id,
    String? trailId,
    int? currentStage,
    double? totalDistanceWalkedKm,
    int? totalElevationGainedM,
    int? totalTimeMinutes,
    bool? isCompleted,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => UserProgressEntry(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    currentStage: currentStage ?? this.currentStage,
    totalDistanceWalkedKm: totalDistanceWalkedKm ?? this.totalDistanceWalkedKm,
    totalElevationGainedM: totalElevationGainedM ?? this.totalElevationGainedM,
    totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
    isCompleted: isCompleted ?? this.isCompleted,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  UserProgressEntry copyWithCompanion(UserProgressEntriesCompanion data) {
    return UserProgressEntry(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      currentStage: data.currentStage.present
          ? data.currentStage.value
          : this.currentStage,
      totalDistanceWalkedKm: data.totalDistanceWalkedKm.present
          ? data.totalDistanceWalkedKm.value
          : this.totalDistanceWalkedKm,
      totalElevationGainedM: data.totalElevationGainedM.present
          ? data.totalElevationGainedM.value
          : this.totalElevationGainedM,
      totalTimeMinutes: data.totalTimeMinutes.present
          ? data.totalTimeMinutes.value
          : this.totalTimeMinutes,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressEntry(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('currentStage: $currentStage, ')
          ..write('totalDistanceWalkedKm: $totalDistanceWalkedKm, ')
          ..write('totalElevationGainedM: $totalElevationGainedM, ')
          ..write('totalTimeMinutes: $totalTimeMinutes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trailId,
    currentStage,
    totalDistanceWalkedKm,
    totalElevationGainedM,
    totalTimeMinutes,
    isCompleted,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProgressEntry &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.currentStage == this.currentStage &&
          other.totalDistanceWalkedKm == this.totalDistanceWalkedKm &&
          other.totalElevationGainedM == this.totalElevationGainedM &&
          other.totalTimeMinutes == this.totalTimeMinutes &&
          other.isCompleted == this.isCompleted &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class UserProgressEntriesCompanion extends UpdateCompanion<UserProgressEntry> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<int> currentStage;
  final Value<double> totalDistanceWalkedKm;
  final Value<int> totalElevationGainedM;
  final Value<int> totalTimeMinutes;
  final Value<bool> isCompleted;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  const UserProgressEntriesCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.currentStage = const Value.absent(),
    this.totalDistanceWalkedKm = const Value.absent(),
    this.totalElevationGainedM = const Value.absent(),
    this.totalTimeMinutes = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  UserProgressEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    this.currentStage = const Value.absent(),
    this.totalDistanceWalkedKm = const Value.absent(),
    this.totalElevationGainedM = const Value.absent(),
    this.totalTimeMinutes = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : trailId = Value(trailId);
  static Insertable<UserProgressEntry> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<int>? currentStage,
    Expression<double>? totalDistanceWalkedKm,
    Expression<int>? totalElevationGainedM,
    Expression<int>? totalTimeMinutes,
    Expression<bool>? isCompleted,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (currentStage != null) 'current_stage': currentStage,
      if (totalDistanceWalkedKm != null)
        'total_distance_walked_km': totalDistanceWalkedKm,
      if (totalElevationGainedM != null)
        'total_elevation_gained_m': totalElevationGainedM,
      if (totalTimeMinutes != null) 'total_time_minutes': totalTimeMinutes,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  UserProgressEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<int>? currentStage,
    Value<double>? totalDistanceWalkedKm,
    Value<int>? totalElevationGainedM,
    Value<int>? totalTimeMinutes,
    Value<bool>? isCompleted,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
  }) {
    return UserProgressEntriesCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      currentStage: currentStage ?? this.currentStage,
      totalDistanceWalkedKm:
          totalDistanceWalkedKm ?? this.totalDistanceWalkedKm,
      totalElevationGainedM:
          totalElevationGainedM ?? this.totalElevationGainedM,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (currentStage.present) {
      map['current_stage'] = Variable<int>(currentStage.value);
    }
    if (totalDistanceWalkedKm.present) {
      map['total_distance_walked_km'] = Variable<double>(
        totalDistanceWalkedKm.value,
      );
    }
    if (totalElevationGainedM.present) {
      map['total_elevation_gained_m'] = Variable<int>(
        totalElevationGainedM.value,
      );
    }
    if (totalTimeMinutes.present) {
      map['total_time_minutes'] = Variable<int>(totalTimeMinutes.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressEntriesCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('currentStage: $currentStage, ')
          ..write('totalDistanceWalkedKm: $totalDistanceWalkedKm, ')
          ..write('totalElevationGainedM: $totalElevationGainedM, ')
          ..write('totalTimeMinutes: $totalTimeMinutes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTable extends ChecklistItems
    with TableInfo<$ChecklistItemsTable, ChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCheckedMeta = const VerificationMeta(
    'isChecked',
  );
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
    'is_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    itemId,
    category,
    isChecked,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_checked')) {
      context.handle(
        _isCheckedMeta,
        isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checked'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ChecklistItemsTable createAlias(String alias) {
    return $ChecklistItemsTable(attachedDatabase, alias);
  }
}

class ChecklistItem extends DataClass implements Insertable<ChecklistItem> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Identifiant du sentier (ex: 'gr10')
  final String trailId;

  /// Identifiant unique de l'item (ex: 'backpack')
  final String itemId;

  /// Categorie de l'item (ex: 'equipment', 'clothing')
  final String category;

  /// Item coche ou non
  final bool isChecked;

  /// Date de derniere modification
  final DateTime? updatedAt;
  const ChecklistItem({
    required this.id,
    required this.trailId,
    required this.itemId,
    required this.category,
    required this.isChecked,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['item_id'] = Variable<String>(itemId);
    map['category'] = Variable<String>(category);
    map['is_checked'] = Variable<bool>(isChecked);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsCompanion(
      id: Value(id),
      trailId: Value(trailId),
      itemId: Value(itemId),
      category: Value(category),
      isChecked: Value(isChecked),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ChecklistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItem(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      category: serializer.fromJson<String>(json['category']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'itemId': serializer.toJson<String>(itemId),
      'category': serializer.toJson<String>(category),
      'isChecked': serializer.toJson<bool>(isChecked),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ChecklistItem copyWith({
    int? id,
    String? trailId,
    String? itemId,
    String? category,
    bool? isChecked,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => ChecklistItem(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    itemId: itemId ?? this.itemId,
    category: category ?? this.category,
    isChecked: isChecked ?? this.isChecked,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ChecklistItem copyWithCompanion(ChecklistItemsCompanion data) {
    return ChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      category: data.category.present ? data.category.value : this.category,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('itemId: $itemId, ')
          ..write('category: $category, ')
          ..write('isChecked: $isChecked, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trailId, itemId, category, isChecked, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.itemId == this.itemId &&
          other.category == this.category &&
          other.isChecked == this.isChecked &&
          other.updatedAt == this.updatedAt);
}

class ChecklistItemsCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<String> itemId;
  final Value<String> category;
  final Value<bool> isChecked;
  final Value<DateTime?> updatedAt;
  const ChecklistItemsCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.category = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChecklistItemsCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required String itemId,
    required String category,
    this.isChecked = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : trailId = Value(trailId),
       itemId = Value(itemId),
       category = Value(category);
  static Insertable<ChecklistItem> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<String>? itemId,
    Expression<String>? category,
    Expression<bool>? isChecked,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (itemId != null) 'item_id': itemId,
      if (category != null) 'category': category,
      if (isChecked != null) 'is_checked': isChecked,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChecklistItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<String>? itemId,
    Value<String>? category,
    Value<bool>? isChecked,
    Value<DateTime?>? updatedAt,
  }) {
    return ChecklistItemsCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      itemId: itemId ?? this.itemId,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('itemId: $itemId, ')
          ..write('category: $category, ')
          ..write('isChecked: $isChecked, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageNumberMeta = const VerificationMeta(
    'stageNumber',
  );
  @override
  late final GeneratedColumn<int> stageNumber = GeneratedColumn<int>(
    'stage_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoSizeBytesMeta = const VerificationMeta(
    'photoSizeBytes',
  );
  @override
  late final GeneratedColumn<int> photoSizeBytes = GeneratedColumn<int>(
    'photo_size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    stageNumber,
    content,
    photoPath,
    photoSizeBytes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('stage_number')) {
      context.handle(
        _stageNumberMeta,
        stageNumber.isAcceptableOrUnknown(
          data['stage_number']!,
          _stageNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageNumberMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('photo_size_bytes')) {
      context.handle(
        _photoSizeBytesMeta,
        photoSizeBytes.isAcceptableOrUnknown(
          data['photo_size_bytes']!,
          _photoSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      stageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_number'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      photoSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_size_bytes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntry extends DataClass implements Insertable<JournalEntry> {
  /// Clé primaire auto-incrémentée
  final int id;

  /// Identifiant du sentier (ex: 'gr10')
  final String trailId;

  /// Numéro d'étape (1-based)
  final int stageNumber;

  /// Contenu textuel de la note
  final String content;

  /// Chemin local de la photo (null si note sans photo)
  final String? photoPath;

  /// Taille de la photo en octets (pour vérifier compression < 500 Ko)
  final int? photoSizeBytes;

  /// Date de création de l'entrée
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime? updatedAt;
  const JournalEntry({
    required this.id,
    required this.trailId,
    required this.stageNumber,
    required this.content,
    this.photoPath,
    this.photoSizeBytes,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['stage_number'] = Variable<int>(stageNumber);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || photoSizeBytes != null) {
      map['photo_size_bytes'] = Variable<int>(photoSizeBytes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      content: Value(content),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      photoSizeBytes: photoSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(photoSizeBytes),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory JournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntry(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      stageNumber: serializer.fromJson<int>(json['stageNumber']),
      content: serializer.fromJson<String>(json['content']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      photoSizeBytes: serializer.fromJson<int?>(json['photoSizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'stageNumber': serializer.toJson<int>(stageNumber),
      'content': serializer.toJson<String>(content),
      'photoPath': serializer.toJson<String?>(photoPath),
      'photoSizeBytes': serializer.toJson<int?>(photoSizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  JournalEntry copyWith({
    int? id,
    String? trailId,
    int? stageNumber,
    String? content,
    Value<String?> photoPath = const Value.absent(),
    Value<int?> photoSizeBytes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => JournalEntry(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    stageNumber: stageNumber ?? this.stageNumber,
    content: content ?? this.content,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    photoSizeBytes: photoSizeBytes.present
        ? photoSizeBytes.value
        : this.photoSizeBytes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  JournalEntry copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntry(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      stageNumber: data.stageNumber.present
          ? data.stageNumber.value
          : this.stageNumber,
      content: data.content.present ? data.content.value : this.content,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      photoSizeBytes: data.photoSizeBytes.present
          ? data.photoSizeBytes.value
          : this.photoSizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntry(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('content: $content, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoSizeBytes: $photoSizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trailId,
    stageNumber,
    content,
    photoPath,
    photoSizeBytes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntry &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.stageNumber == this.stageNumber &&
          other.content == this.content &&
          other.photoPath == this.photoPath &&
          other.photoSizeBytes == this.photoSizeBytes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntry> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<int> stageNumber;
  final Value<String> content;
  final Value<String?> photoPath;
  final Value<int?> photoSizeBytes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.stageNumber = const Value.absent(),
    this.content = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoSizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required int stageNumber,
    this.content = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.photoSizeBytes = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  }) : trailId = Value(trailId),
       stageNumber = Value(stageNumber),
       createdAt = Value(createdAt);
  static Insertable<JournalEntry> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<int>? stageNumber,
    Expression<String>? content,
    Expression<String>? photoPath,
    Expression<int>? photoSizeBytes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (stageNumber != null) 'stage_number': stageNumber,
      if (content != null) 'content': content,
      if (photoPath != null) 'photo_path': photoPath,
      if (photoSizeBytes != null) 'photo_size_bytes': photoSizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<int>? stageNumber,
    Value<String>? content,
    Value<String?>? photoPath,
    Value<int?>? photoSizeBytes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      stageNumber: stageNumber ?? this.stageNumber,
      content: content ?? this.content,
      photoPath: photoPath ?? this.photoPath,
      photoSizeBytes: photoSizeBytes ?? this.photoSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (stageNumber.present) {
      map['stage_number'] = Variable<int>(stageNumber.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (photoSizeBytes.present) {
      map['photo_size_bytes'] = Variable<int>(photoSizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('content: $content, ')
          ..write('photoPath: $photoPath, ')
          ..write('photoSizeBytes: $photoSizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WeatherCacheTable extends WeatherCache
    with TableInfo<$WeatherCacheTable, WeatherCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageNumberMeta = const VerificationMeta(
    'stageNumber',
  );
  @override
  late final GeneratedColumn<int> stageNumber = GeneratedColumn<int>(
    'stage_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _forecastJsonMeta = const VerificationMeta(
    'forecastJson',
  );
  @override
  late final GeneratedColumn<String> forecastJson = GeneratedColumn<String>(
    'forecast_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    stageNumber,
    forecastJson,
    fetchedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('stage_number')) {
      context.handle(
        _stageNumberMeta,
        stageNumber.isAcceptableOrUnknown(
          data['stage_number']!,
          _stageNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageNumberMeta);
    }
    if (data.containsKey('forecast_json')) {
      context.handle(
        _forecastJsonMeta,
        forecastJson.isAcceptableOrUnknown(
          data['forecast_json']!,
          _forecastJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_forecastJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      stageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_number'],
      )!,
      forecastJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forecast_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $WeatherCacheTable createAlias(String alias) {
    return $WeatherCacheTable(attachedDatabase, alias);
  }
}

class WeatherCacheData extends DataClass
    implements Insertable<WeatherCacheData> {
  /// Clé primaire auto-incrémentée
  final int id;

  /// Identifiant du sentier (ex: 'gr10')
  final String trailId;

  /// Numéro d'étape concernée
  final int stageNumber;

  /// Données JSON brutes de la prévision météo
  final String forecastJson;

  /// Date de récupération (pour calcul TTL)
  final DateTime fetchedAt;

  /// Date d'expiration du cache (fetchedAt + 3h)
  final DateTime expiresAt;
  const WeatherCacheData({
    required this.id,
    required this.trailId,
    required this.stageNumber,
    required this.forecastJson,
    required this.fetchedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['stage_number'] = Variable<int>(stageNumber);
    map['forecast_json'] = Variable<String>(forecastJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  WeatherCacheCompanion toCompanion(bool nullToAbsent) {
    return WeatherCacheCompanion(
      id: Value(id),
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      forecastJson: Value(forecastJson),
      fetchedAt: Value(fetchedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory WeatherCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherCacheData(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      stageNumber: serializer.fromJson<int>(json['stageNumber']),
      forecastJson: serializer.fromJson<String>(json['forecastJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'stageNumber': serializer.toJson<int>(stageNumber),
      'forecastJson': serializer.toJson<String>(forecastJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  WeatherCacheData copyWith({
    int? id,
    String? trailId,
    int? stageNumber,
    String? forecastJson,
    DateTime? fetchedAt,
    DateTime? expiresAt,
  }) => WeatherCacheData(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    stageNumber: stageNumber ?? this.stageNumber,
    forecastJson: forecastJson ?? this.forecastJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  WeatherCacheData copyWithCompanion(WeatherCacheCompanion data) {
    return WeatherCacheData(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      stageNumber: data.stageNumber.present
          ? data.stageNumber.value
          : this.stageNumber,
      forecastJson: data.forecastJson.present
          ? data.forecastJson.value
          : this.forecastJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCacheData(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('forecastJson: $forecastJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trailId, stageNumber, forecastJson, fetchedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherCacheData &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.stageNumber == this.stageNumber &&
          other.forecastJson == this.forecastJson &&
          other.fetchedAt == this.fetchedAt &&
          other.expiresAt == this.expiresAt);
}

class WeatherCacheCompanion extends UpdateCompanion<WeatherCacheData> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<int> stageNumber;
  final Value<String> forecastJson;
  final Value<DateTime> fetchedAt;
  final Value<DateTime> expiresAt;
  const WeatherCacheCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.stageNumber = const Value.absent(),
    this.forecastJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  WeatherCacheCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required int stageNumber,
    required String forecastJson,
    required DateTime fetchedAt,
    required DateTime expiresAt,
  }) : trailId = Value(trailId),
       stageNumber = Value(stageNumber),
       forecastJson = Value(forecastJson),
       fetchedAt = Value(fetchedAt),
       expiresAt = Value(expiresAt);
  static Insertable<WeatherCacheData> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<int>? stageNumber,
    Expression<String>? forecastJson,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (stageNumber != null) 'stage_number': stageNumber,
      if (forecastJson != null) 'forecast_json': forecastJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  WeatherCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<int>? stageNumber,
    Value<String>? forecastJson,
    Value<DateTime>? fetchedAt,
    Value<DateTime>? expiresAt,
  }) {
    return WeatherCacheCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      stageNumber: stageNumber ?? this.stageNumber,
      forecastJson: forecastJson ?? this.forecastJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (stageNumber.present) {
      map['stage_number'] = Variable<int>(stageNumber.value);
    }
    if (forecastJson.present) {
      map['forecast_json'] = Variable<String>(forecastJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCacheCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('forecastJson: $forecastJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $FeedbackQueueTable extends FeedbackQueue
    with TableInfo<$FeedbackQueueTable, FeedbackQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedbackQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedbackTypeMeta = const VerificationMeta(
    'feedbackType',
  );
  @override
  late final GeneratedColumn<String> feedbackType = GeneratedColumn<String>(
    'feedback_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    feedbackType,
    content,
    rating,
    status,
    createdAt,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feedback_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedbackQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('feedback_type')) {
      context.handle(
        _feedbackTypeMeta,
        feedbackType.isAcceptableOrUnknown(
          data['feedback_type']!,
          _feedbackTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_feedbackTypeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedbackQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedbackQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      feedbackType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback_type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
    );
  }

  @override
  $FeedbackQueueTable createAlias(String alias) {
    return $FeedbackQueueTable(attachedDatabase, alias);
  }
}

class FeedbackQueueData extends DataClass
    implements Insertable<FeedbackQueueData> {
  /// Clé primaire auto-incrémentée
  final int id;

  /// Identifiant du sentier (ex: 'gr10')
  final String trailId;

  /// Type de feedback ('bug', 'suggestion', 'question', 'other')
  final String feedbackType;

  /// Contenu du feedback
  final String content;

  /// Note de satisfaction (1-5, nullable)
  final int? rating;

  /// Statut d'envoi ('pending', 'sent', 'failed')
  final String status;

  /// Date de création
  final DateTime createdAt;

  /// Date d'envoi effectif (null si pas encore envoyé)
  final DateTime? sentAt;
  const FeedbackQueueData({
    required this.id,
    required this.trailId,
    required this.feedbackType,
    required this.content,
    this.rating,
    required this.status,
    required this.createdAt,
    this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['feedback_type'] = Variable<String>(feedbackType);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    return map;
  }

  FeedbackQueueCompanion toCompanion(bool nullToAbsent) {
    return FeedbackQueueCompanion(
      id: Value(id),
      trailId: Value(trailId),
      feedbackType: Value(feedbackType),
      content: Value(content),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      status: Value(status),
      createdAt: Value(createdAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
    );
  }

  factory FeedbackQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedbackQueueData(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      feedbackType: serializer.fromJson<String>(json['feedbackType']),
      content: serializer.fromJson<String>(json['content']),
      rating: serializer.fromJson<int?>(json['rating']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'feedbackType': serializer.toJson<String>(feedbackType),
      'content': serializer.toJson<String>(content),
      'rating': serializer.toJson<int?>(rating),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
    };
  }

  FeedbackQueueData copyWith({
    int? id,
    String? trailId,
    String? feedbackType,
    String? content,
    Value<int?> rating = const Value.absent(),
    String? status,
    DateTime? createdAt,
    Value<DateTime?> sentAt = const Value.absent(),
  }) => FeedbackQueueData(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    feedbackType: feedbackType ?? this.feedbackType,
    content: content ?? this.content,
    rating: rating.present ? rating.value : this.rating,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
  );
  FeedbackQueueData copyWithCompanion(FeedbackQueueCompanion data) {
    return FeedbackQueueData(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      feedbackType: data.feedbackType.present
          ? data.feedbackType.value
          : this.feedbackType,
      content: data.content.present ? data.content.value : this.content,
      rating: data.rating.present ? data.rating.value : this.rating,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedbackQueueData(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('feedbackType: $feedbackType, ')
          ..write('content: $content, ')
          ..write('rating: $rating, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trailId,
    feedbackType,
    content,
    rating,
    status,
    createdAt,
    sentAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedbackQueueData &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.feedbackType == this.feedbackType &&
          other.content == this.content &&
          other.rating == this.rating &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.sentAt == this.sentAt);
}

class FeedbackQueueCompanion extends UpdateCompanion<FeedbackQueueData> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<String> feedbackType;
  final Value<String> content;
  final Value<int?> rating;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> sentAt;
  const FeedbackQueueCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.feedbackType = const Value.absent(),
    this.content = const Value.absent(),
    this.rating = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sentAt = const Value.absent(),
  });
  FeedbackQueueCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required String feedbackType,
    required String content,
    this.rating = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.sentAt = const Value.absent(),
  }) : trailId = Value(trailId),
       feedbackType = Value(feedbackType),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<FeedbackQueueData> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<String>? feedbackType,
    Expression<String>? content,
    Expression<int>? rating,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? sentAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (feedbackType != null) 'feedback_type': feedbackType,
      if (content != null) 'content': content,
      if (rating != null) 'rating': rating,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (sentAt != null) 'sent_at': sentAt,
    });
  }

  FeedbackQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<String>? feedbackType,
    Value<String>? content,
    Value<int?>? rating,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? sentAt,
  }) {
    return FeedbackQueueCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      feedbackType: feedbackType ?? this.feedbackType,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (feedbackType.present) {
      map['feedback_type'] = Variable<String>(feedbackType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedbackQueueCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('feedbackType: $feedbackType, ')
          ..write('content: $content, ')
          ..write('rating: $rating, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }
}

class $TrailMetaTable extends TrailMeta
    with TableInfo<$TrailMetaTable, TrailMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _dataVersionMeta = const VerificationMeta(
    'dataVersion',
  );
  @override
  late final GeneratedColumn<int> dataVersion = GeneratedColumn<int>(
    'data_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncMeta = const VerificationMeta(
    'lastSync',
  );
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
    'last_sync',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    dataVersion,
    lastSync,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('data_version')) {
      context.handle(
        _dataVersionMeta,
        dataVersion.isAcceptableOrUnknown(
          data['data_version']!,
          _dataVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataVersionMeta);
    }
    if (data.containsKey('last_sync')) {
      context.handle(
        _lastSyncMeta,
        lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      dataVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_version'],
      )!,
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $TrailMetaTable createAlias(String alias) {
    return $TrailMetaTable(attachedDatabase, alias);
  }
}

class TrailMetaData extends DataClass implements Insertable<TrailMetaData> {
  /// Identifiant unique (UUID Firestore)
  final String id;

  /// Code unique du sentier (ex: 'gr10', 'tmb')
  final String code;

  /// Version des donnees (incremente a chaque maj serveur)
  final int dataVersion;

  /// Date de derniere synchronisation (ISO 8601, nullable)
  final String? lastSync;

  /// Statut du sentier ('active', 'archived', 'draft')
  final String status;
  const TrailMetaData({
    required this.id,
    required this.code,
    required this.dataVersion,
    this.lastSync,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['data_version'] = Variable<int>(dataVersion);
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<String>(lastSync);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  TrailMetaCompanion toCompanion(bool nullToAbsent) {
    return TrailMetaCompanion(
      id: Value(id),
      code: Value(code),
      dataVersion: Value(dataVersion),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
      status: Value(status),
    );
  }

  factory TrailMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailMetaData(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      dataVersion: serializer.fromJson<int>(json['dataVersion']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'dataVersion': serializer.toJson<int>(dataVersion),
      'lastSync': serializer.toJson<String?>(lastSync),
      'status': serializer.toJson<String>(status),
    };
  }

  TrailMetaData copyWith({
    String? id,
    String? code,
    int? dataVersion,
    Value<String?> lastSync = const Value.absent(),
    String? status,
  }) => TrailMetaData(
    id: id ?? this.id,
    code: code ?? this.code,
    dataVersion: dataVersion ?? this.dataVersion,
    lastSync: lastSync.present ? lastSync.value : this.lastSync,
    status: status ?? this.status,
  );
  TrailMetaData copyWithCompanion(TrailMetaCompanion data) {
    return TrailMetaData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      dataVersion: data.dataVersion.present
          ? data.dataVersion.value
          : this.dataVersion,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailMetaData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('lastSync: $lastSync, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, dataVersion, lastSync, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailMetaData &&
          other.id == this.id &&
          other.code == this.code &&
          other.dataVersion == this.dataVersion &&
          other.lastSync == this.lastSync &&
          other.status == this.status);
}

class TrailMetaCompanion extends UpdateCompanion<TrailMetaData> {
  final Value<String> id;
  final Value<String> code;
  final Value<int> dataVersion;
  final Value<String?> lastSync;
  final Value<String> status;
  final Value<int> rowid;
  const TrailMetaCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.dataVersion = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailMetaCompanion.insert({
    required String id,
    required String code,
    required int dataVersion,
    this.lastSync = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       dataVersion = Value(dataVersion);
  static Insertable<TrailMetaData> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<int>? dataVersion,
    Expression<String>? lastSync,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (dataVersion != null) 'data_version': dataVersion,
      if (lastSync != null) 'last_sync': lastSync,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailMetaCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<int>? dataVersion,
    Value<String?>? lastSync,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return TrailMetaCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      dataVersion: dataVersion ?? this.dataVersion,
      lastSync: lastSync ?? this.lastSync,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (dataVersion.present) {
      map['data_version'] = Variable<int>(dataVersion.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<String>(lastSync.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailMetaCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('lastSync: $lastSync, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrailItinerariesTable extends TrailItineraries
    with TableInfo<$TrailItinerariesTable, TrailItinerary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailItinerariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
    'name_de',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEsMeta = const VerificationMeta('nameEs');
  @override
  late final GeneratedColumn<String> nameEs = GeneratedColumn<String>(
    'name_es',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationGainMeta = const VerificationMeta(
    'elevationGain',
  );
  @override
  late final GeneratedColumn<int> elevationGain = GeneratedColumn<int>(
    'elevation_gain',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageCountMeta = const VerificationMeta(
    'stageCount',
  );
  @override
  late final GeneratedColumn<int> stageCount = GeneratedColumn<int>(
    'stage_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    code,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    distanceKm,
    elevationGain,
    stageCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_itineraries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailItinerary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_fr')) {
      context.handle(
        _nameFrMeta,
        nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameFrMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_de')) {
      context.handle(
        _nameDeMeta,
        nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta),
      );
    } else if (isInserting) {
      context.missing(_nameDeMeta);
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('name_es')) {
      context.handle(
        _nameEsMeta,
        nameEs.isAcceptableOrUnknown(data['name_es']!, _nameEsMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEsMeta);
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('elevation_gain')) {
      context.handle(
        _elevationGainMeta,
        elevationGain.isAcceptableOrUnknown(
          data['elevation_gain']!,
          _elevationGainMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationGainMeta);
    }
    if (data.containsKey('stage_count')) {
      context.handle(
        _stageCountMeta,
        stageCount.isAcceptableOrUnknown(data['stage_count']!, _stageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_stageCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailItinerary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailItinerary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_fr'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_de'],
      )!,
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      nameEs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_es'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      elevationGain: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elevation_gain'],
      )!,
      stageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_count'],
      )!,
    );
  }

  @override
  $TrailItinerariesTable createAlias(String alias) {
    return $TrailItinerariesTable(attachedDatabase, alias);
  }
}

class TrailItinerary extends DataClass implements Insertable<TrailItinerary> {
  /// Identifiant unique (UUID Firestore)
  final String id;

  /// Reference vers trail_meta.id
  final String trailId;

  /// Code de l'itineraire (ex: 'ns', 'sn')
  final String code;

  /// Nom en francais
  final String nameFr;

  /// Nom en anglais
  final String nameEn;

  /// Nom en allemand
  final String nameDe;

  /// Nom en italien
  final String nameIt;

  /// Nom en espagnol
  final String nameEs;

  /// Distance totale en kilometres
  final double distanceKm;

  /// Denivele positif total en metres
  final int elevationGain;

  /// Nombre d'etapes
  final int stageCount;
  const TrailItinerary({
    required this.id,
    required this.trailId,
    required this.code,
    required this.nameFr,
    required this.nameEn,
    required this.nameDe,
    required this.nameIt,
    required this.nameEs,
    required this.distanceKm,
    required this.elevationGain,
    required this.stageCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['code'] = Variable<String>(code);
    map['name_fr'] = Variable<String>(nameFr);
    map['name_en'] = Variable<String>(nameEn);
    map['name_de'] = Variable<String>(nameDe);
    map['name_it'] = Variable<String>(nameIt);
    map['name_es'] = Variable<String>(nameEs);
    map['distance_km'] = Variable<double>(distanceKm);
    map['elevation_gain'] = Variable<int>(elevationGain);
    map['stage_count'] = Variable<int>(stageCount);
    return map;
  }

  TrailItinerariesCompanion toCompanion(bool nullToAbsent) {
    return TrailItinerariesCompanion(
      id: Value(id),
      trailId: Value(trailId),
      code: Value(code),
      nameFr: Value(nameFr),
      nameEn: Value(nameEn),
      nameDe: Value(nameDe),
      nameIt: Value(nameIt),
      nameEs: Value(nameEs),
      distanceKm: Value(distanceKm),
      elevationGain: Value(elevationGain),
      stageCount: Value(stageCount),
    );
  }

  factory TrailItinerary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailItinerary(
      id: serializer.fromJson<String>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      code: serializer.fromJson<String>(json['code']),
      nameFr: serializer.fromJson<String>(json['nameFr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameDe: serializer.fromJson<String>(json['nameDe']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      nameEs: serializer.fromJson<String>(json['nameEs']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      elevationGain: serializer.fromJson<int>(json['elevationGain']),
      stageCount: serializer.fromJson<int>(json['stageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trailId': serializer.toJson<String>(trailId),
      'code': serializer.toJson<String>(code),
      'nameFr': serializer.toJson<String>(nameFr),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameDe': serializer.toJson<String>(nameDe),
      'nameIt': serializer.toJson<String>(nameIt),
      'nameEs': serializer.toJson<String>(nameEs),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'elevationGain': serializer.toJson<int>(elevationGain),
      'stageCount': serializer.toJson<int>(stageCount),
    };
  }

  TrailItinerary copyWith({
    String? id,
    String? trailId,
    String? code,
    String? nameFr,
    String? nameEn,
    String? nameDe,
    String? nameIt,
    String? nameEs,
    double? distanceKm,
    int? elevationGain,
    int? stageCount,
  }) => TrailItinerary(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    code: code ?? this.code,
    nameFr: nameFr ?? this.nameFr,
    nameEn: nameEn ?? this.nameEn,
    nameDe: nameDe ?? this.nameDe,
    nameIt: nameIt ?? this.nameIt,
    nameEs: nameEs ?? this.nameEs,
    distanceKm: distanceKm ?? this.distanceKm,
    elevationGain: elevationGain ?? this.elevationGain,
    stageCount: stageCount ?? this.stageCount,
  );
  TrailItinerary copyWithCompanion(TrailItinerariesCompanion data) {
    return TrailItinerary(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      code: data.code.present ? data.code.value : this.code,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      nameEs: data.nameEs.present ? data.nameEs.value : this.nameEs,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      elevationGain: data.elevationGain.present
          ? data.elevationGain.value
          : this.elevationGain,
      stageCount: data.stageCount.present
          ? data.stageCount.value
          : this.stageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailItinerary(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('code: $code, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('stageCount: $stageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trailId,
    code,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    distanceKm,
    elevationGain,
    stageCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailItinerary &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.code == this.code &&
          other.nameFr == this.nameFr &&
          other.nameEn == this.nameEn &&
          other.nameDe == this.nameDe &&
          other.nameIt == this.nameIt &&
          other.nameEs == this.nameEs &&
          other.distanceKm == this.distanceKm &&
          other.elevationGain == this.elevationGain &&
          other.stageCount == this.stageCount);
}

class TrailItinerariesCompanion extends UpdateCompanion<TrailItinerary> {
  final Value<String> id;
  final Value<String> trailId;
  final Value<String> code;
  final Value<String> nameFr;
  final Value<String> nameEn;
  final Value<String> nameDe;
  final Value<String> nameIt;
  final Value<String> nameEs;
  final Value<double> distanceKm;
  final Value<int> elevationGain;
  final Value<int> stageCount;
  final Value<int> rowid;
  const TrailItinerariesCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.code = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.nameEs = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.elevationGain = const Value.absent(),
    this.stageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailItinerariesCompanion.insert({
    required String id,
    required String trailId,
    required String code,
    required String nameFr,
    required String nameEn,
    required String nameDe,
    required String nameIt,
    required String nameEs,
    required double distanceKm,
    required int elevationGain,
    required int stageCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       trailId = Value(trailId),
       code = Value(code),
       nameFr = Value(nameFr),
       nameEn = Value(nameEn),
       nameDe = Value(nameDe),
       nameIt = Value(nameIt),
       nameEs = Value(nameEs),
       distanceKm = Value(distanceKm),
       elevationGain = Value(elevationGain),
       stageCount = Value(stageCount);
  static Insertable<TrailItinerary> custom({
    Expression<String>? id,
    Expression<String>? trailId,
    Expression<String>? code,
    Expression<String>? nameFr,
    Expression<String>? nameEn,
    Expression<String>? nameDe,
    Expression<String>? nameIt,
    Expression<String>? nameEs,
    Expression<double>? distanceKm,
    Expression<int>? elevationGain,
    Expression<int>? stageCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (code != null) 'code': code,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameEn != null) 'name_en': nameEn,
      if (nameDe != null) 'name_de': nameDe,
      if (nameIt != null) 'name_it': nameIt,
      if (nameEs != null) 'name_es': nameEs,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (elevationGain != null) 'elevation_gain': elevationGain,
      if (stageCount != null) 'stage_count': stageCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailItinerariesCompanion copyWith({
    Value<String>? id,
    Value<String>? trailId,
    Value<String>? code,
    Value<String>? nameFr,
    Value<String>? nameEn,
    Value<String>? nameDe,
    Value<String>? nameIt,
    Value<String>? nameEs,
    Value<double>? distanceKm,
    Value<int>? elevationGain,
    Value<int>? stageCount,
    Value<int>? rowid,
  }) {
    return TrailItinerariesCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      code: code ?? this.code,
      nameFr: nameFr ?? this.nameFr,
      nameEn: nameEn ?? this.nameEn,
      nameDe: nameDe ?? this.nameDe,
      nameIt: nameIt ?? this.nameIt,
      nameEs: nameEs ?? this.nameEs,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGain: elevationGain ?? this.elevationGain,
      stageCount: stageCount ?? this.stageCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (nameEs.present) {
      map['name_es'] = Variable<String>(nameEs.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (elevationGain.present) {
      map['elevation_gain'] = Variable<int>(elevationGain.value);
    }
    if (stageCount.present) {
      map['stage_count'] = Variable<int>(stageCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailItinerariesCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('code: $code, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('stageCount: $stageCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrailStagesTable extends TrailStages
    with TableInfo<$TrailStagesTable, TrailStage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailStagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itineraryIdMeta = const VerificationMeta(
    'itineraryId',
  );
  @override
  late final GeneratedColumn<String> itineraryId = GeneratedColumn<String>(
    'itinerary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageNumberMeta = const VerificationMeta(
    'stageNumber',
  );
  @override
  late final GeneratedColumn<int> stageNumber = GeneratedColumn<int>(
    'stage_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
    'name_de',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEsMeta = const VerificationMeta('nameEs');
  @override
  late final GeneratedColumn<String> nameEs = GeneratedColumn<String>(
    'name_es',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLatMeta = const VerificationMeta(
    'startLat',
  );
  @override
  late final GeneratedColumn<double> startLat = GeneratedColumn<double>(
    'start_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLngMeta = const VerificationMeta(
    'startLng',
  );
  @override
  late final GeneratedColumn<double> startLng = GeneratedColumn<double>(
    'start_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLatMeta = const VerificationMeta('endLat');
  @override
  late final GeneratedColumn<double> endLat = GeneratedColumn<double>(
    'end_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLngMeta = const VerificationMeta('endLng');
  @override
  late final GeneratedColumn<double> endLng = GeneratedColumn<double>(
    'end_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationGainMeta = const VerificationMeta(
    'elevationGain',
  );
  @override
  late final GeneratedColumn<int> elevationGain = GeneratedColumn<int>(
    'elevation_gain',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationLossMeta = const VerificationMeta(
    'elevationLoss',
  );
  @override
  late final GeneratedColumn<int> elevationLoss = GeneratedColumn<int>(
    'elevation_loss',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itineraryId,
    stageNumber,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    startLat,
    startLng,
    endLat,
    endLng,
    distanceKm,
    elevationGain,
    elevationLoss,
    durationMinutes,
    difficulty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailStage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('itinerary_id')) {
      context.handle(
        _itineraryIdMeta,
        itineraryId.isAcceptableOrUnknown(
          data['itinerary_id']!,
          _itineraryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itineraryIdMeta);
    }
    if (data.containsKey('stage_number')) {
      context.handle(
        _stageNumberMeta,
        stageNumber.isAcceptableOrUnknown(
          data['stage_number']!,
          _stageNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stageNumberMeta);
    }
    if (data.containsKey('name_fr')) {
      context.handle(
        _nameFrMeta,
        nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameFrMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_de')) {
      context.handle(
        _nameDeMeta,
        nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta),
      );
    } else if (isInserting) {
      context.missing(_nameDeMeta);
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('name_es')) {
      context.handle(
        _nameEsMeta,
        nameEs.isAcceptableOrUnknown(data['name_es']!, _nameEsMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEsMeta);
    }
    if (data.containsKey('start_lat')) {
      context.handle(
        _startLatMeta,
        startLat.isAcceptableOrUnknown(data['start_lat']!, _startLatMeta),
      );
    } else if (isInserting) {
      context.missing(_startLatMeta);
    }
    if (data.containsKey('start_lng')) {
      context.handle(
        _startLngMeta,
        startLng.isAcceptableOrUnknown(data['start_lng']!, _startLngMeta),
      );
    } else if (isInserting) {
      context.missing(_startLngMeta);
    }
    if (data.containsKey('end_lat')) {
      context.handle(
        _endLatMeta,
        endLat.isAcceptableOrUnknown(data['end_lat']!, _endLatMeta),
      );
    } else if (isInserting) {
      context.missing(_endLatMeta);
    }
    if (data.containsKey('end_lng')) {
      context.handle(
        _endLngMeta,
        endLng.isAcceptableOrUnknown(data['end_lng']!, _endLngMeta),
      );
    } else if (isInserting) {
      context.missing(_endLngMeta);
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('elevation_gain')) {
      context.handle(
        _elevationGainMeta,
        elevationGain.isAcceptableOrUnknown(
          data['elevation_gain']!,
          _elevationGainMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationGainMeta);
    }
    if (data.containsKey('elevation_loss')) {
      context.handle(
        _elevationLossMeta,
        elevationLoss.isAcceptableOrUnknown(
          data['elevation_loss']!,
          _elevationLossMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationLossMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailStage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailStage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itineraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}itinerary_id'],
      )!,
      stageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_number'],
      )!,
      nameFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_fr'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_de'],
      )!,
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      nameEs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_es'],
      )!,
      startLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lat'],
      )!,
      startLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_lng'],
      )!,
      endLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lat'],
      )!,
      endLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_lng'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      elevationGain: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elevation_gain'],
      )!,
      elevationLoss: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elevation_loss'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
    );
  }

  @override
  $TrailStagesTable createAlias(String alias) {
    return $TrailStagesTable(attachedDatabase, alias);
  }
}

class TrailStage extends DataClass implements Insertable<TrailStage> {
  /// Identifiant unique (UUID Firestore)
  final String id;

  /// Reference vers trail_itineraries.id
  final String itineraryId;

  /// Numero de l'etape dans l'itineraire (1-indexed)
  final int stageNumber;

  /// Nom en francais
  final String nameFr;

  /// Nom en anglais
  final String nameEn;

  /// Nom en allemand
  final String nameDe;

  /// Nom en italien
  final String nameIt;

  /// Nom en espagnol
  final String nameEs;

  /// Latitude du point de depart
  final double startLat;

  /// Longitude du point de depart
  final double startLng;

  /// Latitude du point d'arrivee
  final double endLat;

  /// Longitude du point d'arrivee
  final double endLng;

  /// Distance en kilometres
  final double distanceKm;

  /// Denivele positif en metres
  final int elevationGain;

  /// Denivele negatif en metres
  final int elevationLoss;

  /// Duree estimee en minutes
  final int durationMinutes;

  /// Difficulte (easy, moderate, hard, extreme)
  final String difficulty;
  const TrailStage({
    required this.id,
    required this.itineraryId,
    required this.stageNumber,
    required this.nameFr,
    required this.nameEn,
    required this.nameDe,
    required this.nameIt,
    required this.nameEs,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.distanceKm,
    required this.elevationGain,
    required this.elevationLoss,
    required this.durationMinutes,
    required this.difficulty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['itinerary_id'] = Variable<String>(itineraryId);
    map['stage_number'] = Variable<int>(stageNumber);
    map['name_fr'] = Variable<String>(nameFr);
    map['name_en'] = Variable<String>(nameEn);
    map['name_de'] = Variable<String>(nameDe);
    map['name_it'] = Variable<String>(nameIt);
    map['name_es'] = Variable<String>(nameEs);
    map['start_lat'] = Variable<double>(startLat);
    map['start_lng'] = Variable<double>(startLng);
    map['end_lat'] = Variable<double>(endLat);
    map['end_lng'] = Variable<double>(endLng);
    map['distance_km'] = Variable<double>(distanceKm);
    map['elevation_gain'] = Variable<int>(elevationGain);
    map['elevation_loss'] = Variable<int>(elevationLoss);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['difficulty'] = Variable<String>(difficulty);
    return map;
  }

  TrailStagesCompanion toCompanion(bool nullToAbsent) {
    return TrailStagesCompanion(
      id: Value(id),
      itineraryId: Value(itineraryId),
      stageNumber: Value(stageNumber),
      nameFr: Value(nameFr),
      nameEn: Value(nameEn),
      nameDe: Value(nameDe),
      nameIt: Value(nameIt),
      nameEs: Value(nameEs),
      startLat: Value(startLat),
      startLng: Value(startLng),
      endLat: Value(endLat),
      endLng: Value(endLng),
      distanceKm: Value(distanceKm),
      elevationGain: Value(elevationGain),
      elevationLoss: Value(elevationLoss),
      durationMinutes: Value(durationMinutes),
      difficulty: Value(difficulty),
    );
  }

  factory TrailStage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailStage(
      id: serializer.fromJson<String>(json['id']),
      itineraryId: serializer.fromJson<String>(json['itineraryId']),
      stageNumber: serializer.fromJson<int>(json['stageNumber']),
      nameFr: serializer.fromJson<String>(json['nameFr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameDe: serializer.fromJson<String>(json['nameDe']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      nameEs: serializer.fromJson<String>(json['nameEs']),
      startLat: serializer.fromJson<double>(json['startLat']),
      startLng: serializer.fromJson<double>(json['startLng']),
      endLat: serializer.fromJson<double>(json['endLat']),
      endLng: serializer.fromJson<double>(json['endLng']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      elevationGain: serializer.fromJson<int>(json['elevationGain']),
      elevationLoss: serializer.fromJson<int>(json['elevationLoss']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itineraryId': serializer.toJson<String>(itineraryId),
      'stageNumber': serializer.toJson<int>(stageNumber),
      'nameFr': serializer.toJson<String>(nameFr),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameDe': serializer.toJson<String>(nameDe),
      'nameIt': serializer.toJson<String>(nameIt),
      'nameEs': serializer.toJson<String>(nameEs),
      'startLat': serializer.toJson<double>(startLat),
      'startLng': serializer.toJson<double>(startLng),
      'endLat': serializer.toJson<double>(endLat),
      'endLng': serializer.toJson<double>(endLng),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'elevationGain': serializer.toJson<int>(elevationGain),
      'elevationLoss': serializer.toJson<int>(elevationLoss),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'difficulty': serializer.toJson<String>(difficulty),
    };
  }

  TrailStage copyWith({
    String? id,
    String? itineraryId,
    int? stageNumber,
    String? nameFr,
    String? nameEn,
    String? nameDe,
    String? nameIt,
    String? nameEs,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? distanceKm,
    int? elevationGain,
    int? elevationLoss,
    int? durationMinutes,
    String? difficulty,
  }) => TrailStage(
    id: id ?? this.id,
    itineraryId: itineraryId ?? this.itineraryId,
    stageNumber: stageNumber ?? this.stageNumber,
    nameFr: nameFr ?? this.nameFr,
    nameEn: nameEn ?? this.nameEn,
    nameDe: nameDe ?? this.nameDe,
    nameIt: nameIt ?? this.nameIt,
    nameEs: nameEs ?? this.nameEs,
    startLat: startLat ?? this.startLat,
    startLng: startLng ?? this.startLng,
    endLat: endLat ?? this.endLat,
    endLng: endLng ?? this.endLng,
    distanceKm: distanceKm ?? this.distanceKm,
    elevationGain: elevationGain ?? this.elevationGain,
    elevationLoss: elevationLoss ?? this.elevationLoss,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    difficulty: difficulty ?? this.difficulty,
  );
  TrailStage copyWithCompanion(TrailStagesCompanion data) {
    return TrailStage(
      id: data.id.present ? data.id.value : this.id,
      itineraryId: data.itineraryId.present
          ? data.itineraryId.value
          : this.itineraryId,
      stageNumber: data.stageNumber.present
          ? data.stageNumber.value
          : this.stageNumber,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      nameEs: data.nameEs.present ? data.nameEs.value : this.nameEs,
      startLat: data.startLat.present ? data.startLat.value : this.startLat,
      startLng: data.startLng.present ? data.startLng.value : this.startLng,
      endLat: data.endLat.present ? data.endLat.value : this.endLat,
      endLng: data.endLng.present ? data.endLng.value : this.endLng,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      elevationGain: data.elevationGain.present
          ? data.elevationGain.value
          : this.elevationGain,
      elevationLoss: data.elevationLoss.present
          ? data.elevationLoss.value
          : this.elevationLoss,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailStage(')
          ..write('id: $id, ')
          ..write('itineraryId: $itineraryId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('elevationLoss: $elevationLoss, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('difficulty: $difficulty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itineraryId,
    stageNumber,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    startLat,
    startLng,
    endLat,
    endLng,
    distanceKm,
    elevationGain,
    elevationLoss,
    durationMinutes,
    difficulty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailStage &&
          other.id == this.id &&
          other.itineraryId == this.itineraryId &&
          other.stageNumber == this.stageNumber &&
          other.nameFr == this.nameFr &&
          other.nameEn == this.nameEn &&
          other.nameDe == this.nameDe &&
          other.nameIt == this.nameIt &&
          other.nameEs == this.nameEs &&
          other.startLat == this.startLat &&
          other.startLng == this.startLng &&
          other.endLat == this.endLat &&
          other.endLng == this.endLng &&
          other.distanceKm == this.distanceKm &&
          other.elevationGain == this.elevationGain &&
          other.elevationLoss == this.elevationLoss &&
          other.durationMinutes == this.durationMinutes &&
          other.difficulty == this.difficulty);
}

class TrailStagesCompanion extends UpdateCompanion<TrailStage> {
  final Value<String> id;
  final Value<String> itineraryId;
  final Value<int> stageNumber;
  final Value<String> nameFr;
  final Value<String> nameEn;
  final Value<String> nameDe;
  final Value<String> nameIt;
  final Value<String> nameEs;
  final Value<double> startLat;
  final Value<double> startLng;
  final Value<double> endLat;
  final Value<double> endLng;
  final Value<double> distanceKm;
  final Value<int> elevationGain;
  final Value<int> elevationLoss;
  final Value<int> durationMinutes;
  final Value<String> difficulty;
  final Value<int> rowid;
  const TrailStagesCompanion({
    this.id = const Value.absent(),
    this.itineraryId = const Value.absent(),
    this.stageNumber = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.nameEs = const Value.absent(),
    this.startLat = const Value.absent(),
    this.startLng = const Value.absent(),
    this.endLat = const Value.absent(),
    this.endLng = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.elevationGain = const Value.absent(),
    this.elevationLoss = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailStagesCompanion.insert({
    required String id,
    required String itineraryId,
    required int stageNumber,
    required String nameFr,
    required String nameEn,
    required String nameDe,
    required String nameIt,
    required String nameEs,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required double distanceKm,
    required int elevationGain,
    required int elevationLoss,
    required int durationMinutes,
    required String difficulty,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itineraryId = Value(itineraryId),
       stageNumber = Value(stageNumber),
       nameFr = Value(nameFr),
       nameEn = Value(nameEn),
       nameDe = Value(nameDe),
       nameIt = Value(nameIt),
       nameEs = Value(nameEs),
       startLat = Value(startLat),
       startLng = Value(startLng),
       endLat = Value(endLat),
       endLng = Value(endLng),
       distanceKm = Value(distanceKm),
       elevationGain = Value(elevationGain),
       elevationLoss = Value(elevationLoss),
       durationMinutes = Value(durationMinutes),
       difficulty = Value(difficulty);
  static Insertable<TrailStage> custom({
    Expression<String>? id,
    Expression<String>? itineraryId,
    Expression<int>? stageNumber,
    Expression<String>? nameFr,
    Expression<String>? nameEn,
    Expression<String>? nameDe,
    Expression<String>? nameIt,
    Expression<String>? nameEs,
    Expression<double>? startLat,
    Expression<double>? startLng,
    Expression<double>? endLat,
    Expression<double>? endLng,
    Expression<double>? distanceKm,
    Expression<int>? elevationGain,
    Expression<int>? elevationLoss,
    Expression<int>? durationMinutes,
    Expression<String>? difficulty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itineraryId != null) 'itinerary_id': itineraryId,
      if (stageNumber != null) 'stage_number': stageNumber,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameEn != null) 'name_en': nameEn,
      if (nameDe != null) 'name_de': nameDe,
      if (nameIt != null) 'name_it': nameIt,
      if (nameEs != null) 'name_es': nameEs,
      if (startLat != null) 'start_lat': startLat,
      if (startLng != null) 'start_lng': startLng,
      if (endLat != null) 'end_lat': endLat,
      if (endLng != null) 'end_lng': endLng,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (elevationGain != null) 'elevation_gain': elevationGain,
      if (elevationLoss != null) 'elevation_loss': elevationLoss,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (difficulty != null) 'difficulty': difficulty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailStagesCompanion copyWith({
    Value<String>? id,
    Value<String>? itineraryId,
    Value<int>? stageNumber,
    Value<String>? nameFr,
    Value<String>? nameEn,
    Value<String>? nameDe,
    Value<String>? nameIt,
    Value<String>? nameEs,
    Value<double>? startLat,
    Value<double>? startLng,
    Value<double>? endLat,
    Value<double>? endLng,
    Value<double>? distanceKm,
    Value<int>? elevationGain,
    Value<int>? elevationLoss,
    Value<int>? durationMinutes,
    Value<String>? difficulty,
    Value<int>? rowid,
  }) {
    return TrailStagesCompanion(
      id: id ?? this.id,
      itineraryId: itineraryId ?? this.itineraryId,
      stageNumber: stageNumber ?? this.stageNumber,
      nameFr: nameFr ?? this.nameFr,
      nameEn: nameEn ?? this.nameEn,
      nameDe: nameDe ?? this.nameDe,
      nameIt: nameIt ?? this.nameIt,
      nameEs: nameEs ?? this.nameEs,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itineraryId.present) {
      map['itinerary_id'] = Variable<String>(itineraryId.value);
    }
    if (stageNumber.present) {
      map['stage_number'] = Variable<int>(stageNumber.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (nameEs.present) {
      map['name_es'] = Variable<String>(nameEs.value);
    }
    if (startLat.present) {
      map['start_lat'] = Variable<double>(startLat.value);
    }
    if (startLng.present) {
      map['start_lng'] = Variable<double>(startLng.value);
    }
    if (endLat.present) {
      map['end_lat'] = Variable<double>(endLat.value);
    }
    if (endLng.present) {
      map['end_lng'] = Variable<double>(endLng.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (elevationGain.present) {
      map['elevation_gain'] = Variable<int>(elevationGain.value);
    }
    if (elevationLoss.present) {
      map['elevation_loss'] = Variable<int>(elevationLoss.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailStagesCompanion(')
          ..write('id: $id, ')
          ..write('itineraryId: $itineraryId, ')
          ..write('stageNumber: $stageNumber, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('startLat: $startLat, ')
          ..write('startLng: $startLng, ')
          ..write('endLat: $endLat, ')
          ..write('endLng: $endLng, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('elevationGain: $elevationGain, ')
          ..write('elevationLoss: $elevationLoss, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrailAccommodationsTable extends TrailAccommodations
    with TableInfo<$TrailAccommodationsTable, TrailAccommodation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailAccommodationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<String> stageId = GeneratedColumn<String>(
    'stage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
    'name_de',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEsMeta = const VerificationMeta('nameEs');
  @override
  late final GeneratedColumn<String> nameEs = GeneratedColumn<String>(
    'name_es',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _websiteMeta = const VerificationMeta(
    'website',
  );
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
    'website',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capacityMeta = const VerificationMeta(
    'capacity',
  );
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
    'capacity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceRangeMeta = const VerificationMeta(
    'priceRange',
  );
  @override
  late final GeneratedColumn<String> priceRange = GeneratedColumn<String>(
    'price_range',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookingUrlMeta = const VerificationMeta(
    'bookingUrl',
  );
  @override
  late final GeneratedColumn<String> bookingUrl = GeneratedColumn<String>(
    'booking_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stageId,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    type,
    lat,
    lng,
    phone,
    email,
    website,
    capacity,
    priceRange,
    bookingUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_accommodations';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailAccommodation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('stage_id')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['stage_id']!, _stageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stageIdMeta);
    }
    if (data.containsKey('name_fr')) {
      context.handle(
        _nameFrMeta,
        nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameFrMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_de')) {
      context.handle(
        _nameDeMeta,
        nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta),
      );
    } else if (isInserting) {
      context.missing(_nameDeMeta);
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('name_es')) {
      context.handle(
        _nameEsMeta,
        nameEs.isAcceptableOrUnknown(data['name_es']!, _nameEsMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEsMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('website')) {
      context.handle(
        _websiteMeta,
        website.isAcceptableOrUnknown(data['website']!, _websiteMeta),
      );
    }
    if (data.containsKey('capacity')) {
      context.handle(
        _capacityMeta,
        capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta),
      );
    }
    if (data.containsKey('price_range')) {
      context.handle(
        _priceRangeMeta,
        priceRange.isAcceptableOrUnknown(data['price_range']!, _priceRangeMeta),
      );
    }
    if (data.containsKey('booking_url')) {
      context.handle(
        _bookingUrlMeta,
        bookingUrl.isAcceptableOrUnknown(data['booking_url']!, _bookingUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailAccommodation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailAccommodation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_id'],
      )!,
      nameFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_fr'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_de'],
      )!,
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      nameEs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_es'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      website: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website'],
      ),
      capacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capacity'],
      ),
      priceRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price_range'],
      ),
      bookingUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booking_url'],
      ),
    );
  }

  @override
  $TrailAccommodationsTable createAlias(String alias) {
    return $TrailAccommodationsTable(attachedDatabase, alias);
  }
}

class TrailAccommodation extends DataClass
    implements Insertable<TrailAccommodation> {
  /// Identifiant unique (UUID Firestore)
  final String id;

  /// Reference vers trail_stages.id
  final String stageId;

  /// Nom en francais
  final String nameFr;

  /// Nom en anglais
  final String nameEn;

  /// Nom en allemand
  final String nameDe;

  /// Nom en italien
  final String nameIt;

  /// Nom en espagnol
  final String nameEs;

  /// Type d'hebergement (refuge, gite, hotel, camping, bivouac)
  final String type;

  /// Latitude
  final double lat;

  /// Longitude
  final double lng;

  /// Telephone (nullable)
  final String? phone;

  /// Email (nullable)
  final String? email;

  /// Site web (nullable)
  final String? website;

  /// Capacite d'accueil (nullable)
  final int? capacity;

  /// Fourchette de prix (nullable, ex: '30-50EUR')
  final String? priceRange;

  /// URL de reservation (nullable)
  final String? bookingUrl;
  const TrailAccommodation({
    required this.id,
    required this.stageId,
    required this.nameFr,
    required this.nameEn,
    required this.nameDe,
    required this.nameIt,
    required this.nameEs,
    required this.type,
    required this.lat,
    required this.lng,
    this.phone,
    this.email,
    this.website,
    this.capacity,
    this.priceRange,
    this.bookingUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['stage_id'] = Variable<String>(stageId);
    map['name_fr'] = Variable<String>(nameFr);
    map['name_en'] = Variable<String>(nameEn);
    map['name_de'] = Variable<String>(nameDe);
    map['name_it'] = Variable<String>(nameIt);
    map['name_es'] = Variable<String>(nameEs);
    map['type'] = Variable<String>(type);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || website != null) {
      map['website'] = Variable<String>(website);
    }
    if (!nullToAbsent || capacity != null) {
      map['capacity'] = Variable<int>(capacity);
    }
    if (!nullToAbsent || priceRange != null) {
      map['price_range'] = Variable<String>(priceRange);
    }
    if (!nullToAbsent || bookingUrl != null) {
      map['booking_url'] = Variable<String>(bookingUrl);
    }
    return map;
  }

  TrailAccommodationsCompanion toCompanion(bool nullToAbsent) {
    return TrailAccommodationsCompanion(
      id: Value(id),
      stageId: Value(stageId),
      nameFr: Value(nameFr),
      nameEn: Value(nameEn),
      nameDe: Value(nameDe),
      nameIt: Value(nameIt),
      nameEs: Value(nameEs),
      type: Value(type),
      lat: Value(lat),
      lng: Value(lng),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      website: website == null && nullToAbsent
          ? const Value.absent()
          : Value(website),
      capacity: capacity == null && nullToAbsent
          ? const Value.absent()
          : Value(capacity),
      priceRange: priceRange == null && nullToAbsent
          ? const Value.absent()
          : Value(priceRange),
      bookingUrl: bookingUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(bookingUrl),
    );
  }

  factory TrailAccommodation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailAccommodation(
      id: serializer.fromJson<String>(json['id']),
      stageId: serializer.fromJson<String>(json['stageId']),
      nameFr: serializer.fromJson<String>(json['nameFr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameDe: serializer.fromJson<String>(json['nameDe']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      nameEs: serializer.fromJson<String>(json['nameEs']),
      type: serializer.fromJson<String>(json['type']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      website: serializer.fromJson<String?>(json['website']),
      capacity: serializer.fromJson<int?>(json['capacity']),
      priceRange: serializer.fromJson<String?>(json['priceRange']),
      bookingUrl: serializer.fromJson<String?>(json['bookingUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stageId': serializer.toJson<String>(stageId),
      'nameFr': serializer.toJson<String>(nameFr),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameDe': serializer.toJson<String>(nameDe),
      'nameIt': serializer.toJson<String>(nameIt),
      'nameEs': serializer.toJson<String>(nameEs),
      'type': serializer.toJson<String>(type),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'website': serializer.toJson<String?>(website),
      'capacity': serializer.toJson<int?>(capacity),
      'priceRange': serializer.toJson<String?>(priceRange),
      'bookingUrl': serializer.toJson<String?>(bookingUrl),
    };
  }

  TrailAccommodation copyWith({
    String? id,
    String? stageId,
    String? nameFr,
    String? nameEn,
    String? nameDe,
    String? nameIt,
    String? nameEs,
    String? type,
    double? lat,
    double? lng,
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> website = const Value.absent(),
    Value<int?> capacity = const Value.absent(),
    Value<String?> priceRange = const Value.absent(),
    Value<String?> bookingUrl = const Value.absent(),
  }) => TrailAccommodation(
    id: id ?? this.id,
    stageId: stageId ?? this.stageId,
    nameFr: nameFr ?? this.nameFr,
    nameEn: nameEn ?? this.nameEn,
    nameDe: nameDe ?? this.nameDe,
    nameIt: nameIt ?? this.nameIt,
    nameEs: nameEs ?? this.nameEs,
    type: type ?? this.type,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    website: website.present ? website.value : this.website,
    capacity: capacity.present ? capacity.value : this.capacity,
    priceRange: priceRange.present ? priceRange.value : this.priceRange,
    bookingUrl: bookingUrl.present ? bookingUrl.value : this.bookingUrl,
  );
  TrailAccommodation copyWithCompanion(TrailAccommodationsCompanion data) {
    return TrailAccommodation(
      id: data.id.present ? data.id.value : this.id,
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      nameEs: data.nameEs.present ? data.nameEs.value : this.nameEs,
      type: data.type.present ? data.type.value : this.type,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      website: data.website.present ? data.website.value : this.website,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      priceRange: data.priceRange.present
          ? data.priceRange.value
          : this.priceRange,
      bookingUrl: data.bookingUrl.present
          ? data.bookingUrl.value
          : this.bookingUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailAccommodation(')
          ..write('id: $id, ')
          ..write('stageId: $stageId, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('capacity: $capacity, ')
          ..write('priceRange: $priceRange, ')
          ..write('bookingUrl: $bookingUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stageId,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    type,
    lat,
    lng,
    phone,
    email,
    website,
    capacity,
    priceRange,
    bookingUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailAccommodation &&
          other.id == this.id &&
          other.stageId == this.stageId &&
          other.nameFr == this.nameFr &&
          other.nameEn == this.nameEn &&
          other.nameDe == this.nameDe &&
          other.nameIt == this.nameIt &&
          other.nameEs == this.nameEs &&
          other.type == this.type &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.website == this.website &&
          other.capacity == this.capacity &&
          other.priceRange == this.priceRange &&
          other.bookingUrl == this.bookingUrl);
}

class TrailAccommodationsCompanion extends UpdateCompanion<TrailAccommodation> {
  final Value<String> id;
  final Value<String> stageId;
  final Value<String> nameFr;
  final Value<String> nameEn;
  final Value<String> nameDe;
  final Value<String> nameIt;
  final Value<String> nameEs;
  final Value<String> type;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> website;
  final Value<int?> capacity;
  final Value<String?> priceRange;
  final Value<String?> bookingUrl;
  final Value<int> rowid;
  const TrailAccommodationsCompanion({
    this.id = const Value.absent(),
    this.stageId = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.nameEs = const Value.absent(),
    this.type = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.capacity = const Value.absent(),
    this.priceRange = const Value.absent(),
    this.bookingUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailAccommodationsCompanion.insert({
    required String id,
    required String stageId,
    required String nameFr,
    required String nameEn,
    required String nameDe,
    required String nameIt,
    required String nameEs,
    required String type,
    required double lat,
    required double lng,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.capacity = const Value.absent(),
    this.priceRange = const Value.absent(),
    this.bookingUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       stageId = Value(stageId),
       nameFr = Value(nameFr),
       nameEn = Value(nameEn),
       nameDe = Value(nameDe),
       nameIt = Value(nameIt),
       nameEs = Value(nameEs),
       type = Value(type),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<TrailAccommodation> custom({
    Expression<String>? id,
    Expression<String>? stageId,
    Expression<String>? nameFr,
    Expression<String>? nameEn,
    Expression<String>? nameDe,
    Expression<String>? nameIt,
    Expression<String>? nameEs,
    Expression<String>? type,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? website,
    Expression<int>? capacity,
    Expression<String>? priceRange,
    Expression<String>? bookingUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stageId != null) 'stage_id': stageId,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameEn != null) 'name_en': nameEn,
      if (nameDe != null) 'name_de': nameDe,
      if (nameIt != null) 'name_it': nameIt,
      if (nameEs != null) 'name_es': nameEs,
      if (type != null) 'type': type,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (capacity != null) 'capacity': capacity,
      if (priceRange != null) 'price_range': priceRange,
      if (bookingUrl != null) 'booking_url': bookingUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailAccommodationsCompanion copyWith({
    Value<String>? id,
    Value<String>? stageId,
    Value<String>? nameFr,
    Value<String>? nameEn,
    Value<String>? nameDe,
    Value<String>? nameIt,
    Value<String>? nameEs,
    Value<String>? type,
    Value<double>? lat,
    Value<double>? lng,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? website,
    Value<int?>? capacity,
    Value<String?>? priceRange,
    Value<String?>? bookingUrl,
    Value<int>? rowid,
  }) {
    return TrailAccommodationsCompanion(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      nameFr: nameFr ?? this.nameFr,
      nameEn: nameEn ?? this.nameEn,
      nameDe: nameDe ?? this.nameDe,
      nameIt: nameIt ?? this.nameIt,
      nameEs: nameEs ?? this.nameEs,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      capacity: capacity ?? this.capacity,
      priceRange: priceRange ?? this.priceRange,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stageId.present) {
      map['stage_id'] = Variable<String>(stageId.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (nameEs.present) {
      map['name_es'] = Variable<String>(nameEs.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (priceRange.present) {
      map['price_range'] = Variable<String>(priceRange.value);
    }
    if (bookingUrl.present) {
      map['booking_url'] = Variable<String>(bookingUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailAccommodationsCompanion(')
          ..write('id: $id, ')
          ..write('stageId: $stageId, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('capacity: $capacity, ')
          ..write('priceRange: $priceRange, ')
          ..write('bookingUrl: $bookingUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrailPoisTable extends TrailPois
    with TableInfo<$TrailPoisTable, TrailPoi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailPoisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<String> stageId = GeneratedColumn<String>(
    'stage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
    'name_de',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEsMeta = const VerificationMeta('nameEs');
  @override
  late final GeneratedColumn<String> nameEs = GeneratedColumn<String>(
    'name_es',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionFrMeta = const VerificationMeta(
    'descriptionFr',
  );
  @override
  late final GeneratedColumn<String> descriptionFr = GeneratedColumn<String>(
    'description_fr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionEnMeta = const VerificationMeta(
    'descriptionEn',
  );
  @override
  late final GeneratedColumn<String> descriptionEn = GeneratedColumn<String>(
    'description_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionDeMeta = const VerificationMeta(
    'descriptionDe',
  );
  @override
  late final GeneratedColumn<String> descriptionDe = GeneratedColumn<String>(
    'description_de',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionItMeta = const VerificationMeta(
    'descriptionIt',
  );
  @override
  late final GeneratedColumn<String> descriptionIt = GeneratedColumn<String>(
    'description_it',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionEsMeta = const VerificationMeta(
    'descriptionEs',
  );
  @override
  late final GeneratedColumn<String> descriptionEs = GeneratedColumn<String>(
    'description_es',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationMeta = const VerificationMeta(
    'elevation',
  );
  @override
  late final GeneratedColumn<double> elevation = GeneratedColumn<double>(
    'elevation',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stageId,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    descriptionFr,
    descriptionEn,
    descriptionDe,
    descriptionIt,
    descriptionEs,
    type,
    lat,
    lng,
    elevation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_pois';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailPoi> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('stage_id')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['stage_id']!, _stageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stageIdMeta);
    }
    if (data.containsKey('name_fr')) {
      context.handle(
        _nameFrMeta,
        nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameFrMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_de')) {
      context.handle(
        _nameDeMeta,
        nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta),
      );
    } else if (isInserting) {
      context.missing(_nameDeMeta);
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('name_es')) {
      context.handle(
        _nameEsMeta,
        nameEs.isAcceptableOrUnknown(data['name_es']!, _nameEsMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEsMeta);
    }
    if (data.containsKey('description_fr')) {
      context.handle(
        _descriptionFrMeta,
        descriptionFr.isAcceptableOrUnknown(
          data['description_fr']!,
          _descriptionFrMeta,
        ),
      );
    }
    if (data.containsKey('description_en')) {
      context.handle(
        _descriptionEnMeta,
        descriptionEn.isAcceptableOrUnknown(
          data['description_en']!,
          _descriptionEnMeta,
        ),
      );
    }
    if (data.containsKey('description_de')) {
      context.handle(
        _descriptionDeMeta,
        descriptionDe.isAcceptableOrUnknown(
          data['description_de']!,
          _descriptionDeMeta,
        ),
      );
    }
    if (data.containsKey('description_it')) {
      context.handle(
        _descriptionItMeta,
        descriptionIt.isAcceptableOrUnknown(
          data['description_it']!,
          _descriptionItMeta,
        ),
      );
    }
    if (data.containsKey('description_es')) {
      context.handle(
        _descriptionEsMeta,
        descriptionEs.isAcceptableOrUnknown(
          data['description_es']!,
          _descriptionEsMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('elevation')) {
      context.handle(
        _elevationMeta,
        elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailPoi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailPoi(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_id'],
      )!,
      nameFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_fr'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_de'],
      )!,
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      nameEs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_es'],
      )!,
      descriptionFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_fr'],
      ),
      descriptionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_en'],
      ),
      descriptionDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_de'],
      ),
      descriptionIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_it'],
      ),
      descriptionEs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_es'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      elevation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation'],
      ),
    );
  }

  @override
  $TrailPoisTable createAlias(String alias) {
    return $TrailPoisTable(attachedDatabase, alias);
  }
}

class TrailPoi extends DataClass implements Insertable<TrailPoi> {
  /// Identifiant unique (UUID Firestore)
  final String id;

  /// Reference vers trail_stages.id
  final String stageId;

  /// Nom en francais
  final String nameFr;

  /// Nom en anglais
  final String nameEn;

  /// Nom en allemand
  final String nameDe;

  /// Nom en italien
  final String nameIt;

  /// Nom en espagnol
  final String nameEs;

  /// Description en francais (nullable)
  final String? descriptionFr;

  /// Description en anglais (nullable)
  final String? descriptionEn;

  /// Description en allemand (nullable)
  final String? descriptionDe;

  /// Description en italien (nullable)
  final String? descriptionIt;

  /// Description en espagnol (nullable)
  final String? descriptionEs;

  /// Type de POI (water, viewpoint, shelter, danger, info, etc.)
  final String type;

  /// Latitude
  final double lat;

  /// Longitude
  final double lng;

  /// Altitude en metres (nullable)
  final double? elevation;
  const TrailPoi({
    required this.id,
    required this.stageId,
    required this.nameFr,
    required this.nameEn,
    required this.nameDe,
    required this.nameIt,
    required this.nameEs,
    this.descriptionFr,
    this.descriptionEn,
    this.descriptionDe,
    this.descriptionIt,
    this.descriptionEs,
    required this.type,
    required this.lat,
    required this.lng,
    this.elevation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['stage_id'] = Variable<String>(stageId);
    map['name_fr'] = Variable<String>(nameFr);
    map['name_en'] = Variable<String>(nameEn);
    map['name_de'] = Variable<String>(nameDe);
    map['name_it'] = Variable<String>(nameIt);
    map['name_es'] = Variable<String>(nameEs);
    if (!nullToAbsent || descriptionFr != null) {
      map['description_fr'] = Variable<String>(descriptionFr);
    }
    if (!nullToAbsent || descriptionEn != null) {
      map['description_en'] = Variable<String>(descriptionEn);
    }
    if (!nullToAbsent || descriptionDe != null) {
      map['description_de'] = Variable<String>(descriptionDe);
    }
    if (!nullToAbsent || descriptionIt != null) {
      map['description_it'] = Variable<String>(descriptionIt);
    }
    if (!nullToAbsent || descriptionEs != null) {
      map['description_es'] = Variable<String>(descriptionEs);
    }
    map['type'] = Variable<String>(type);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || elevation != null) {
      map['elevation'] = Variable<double>(elevation);
    }
    return map;
  }

  TrailPoisCompanion toCompanion(bool nullToAbsent) {
    return TrailPoisCompanion(
      id: Value(id),
      stageId: Value(stageId),
      nameFr: Value(nameFr),
      nameEn: Value(nameEn),
      nameDe: Value(nameDe),
      nameIt: Value(nameIt),
      nameEs: Value(nameEs),
      descriptionFr: descriptionFr == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionFr),
      descriptionEn: descriptionEn == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionEn),
      descriptionDe: descriptionDe == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionDe),
      descriptionIt: descriptionIt == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionIt),
      descriptionEs: descriptionEs == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionEs),
      type: Value(type),
      lat: Value(lat),
      lng: Value(lng),
      elevation: elevation == null && nullToAbsent
          ? const Value.absent()
          : Value(elevation),
    );
  }

  factory TrailPoi.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailPoi(
      id: serializer.fromJson<String>(json['id']),
      stageId: serializer.fromJson<String>(json['stageId']),
      nameFr: serializer.fromJson<String>(json['nameFr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameDe: serializer.fromJson<String>(json['nameDe']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      nameEs: serializer.fromJson<String>(json['nameEs']),
      descriptionFr: serializer.fromJson<String?>(json['descriptionFr']),
      descriptionEn: serializer.fromJson<String?>(json['descriptionEn']),
      descriptionDe: serializer.fromJson<String?>(json['descriptionDe']),
      descriptionIt: serializer.fromJson<String?>(json['descriptionIt']),
      descriptionEs: serializer.fromJson<String?>(json['descriptionEs']),
      type: serializer.fromJson<String>(json['type']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      elevation: serializer.fromJson<double?>(json['elevation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stageId': serializer.toJson<String>(stageId),
      'nameFr': serializer.toJson<String>(nameFr),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameDe': serializer.toJson<String>(nameDe),
      'nameIt': serializer.toJson<String>(nameIt),
      'nameEs': serializer.toJson<String>(nameEs),
      'descriptionFr': serializer.toJson<String?>(descriptionFr),
      'descriptionEn': serializer.toJson<String?>(descriptionEn),
      'descriptionDe': serializer.toJson<String?>(descriptionDe),
      'descriptionIt': serializer.toJson<String?>(descriptionIt),
      'descriptionEs': serializer.toJson<String?>(descriptionEs),
      'type': serializer.toJson<String>(type),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'elevation': serializer.toJson<double?>(elevation),
    };
  }

  TrailPoi copyWith({
    String? id,
    String? stageId,
    String? nameFr,
    String? nameEn,
    String? nameDe,
    String? nameIt,
    String? nameEs,
    Value<String?> descriptionFr = const Value.absent(),
    Value<String?> descriptionEn = const Value.absent(),
    Value<String?> descriptionDe = const Value.absent(),
    Value<String?> descriptionIt = const Value.absent(),
    Value<String?> descriptionEs = const Value.absent(),
    String? type,
    double? lat,
    double? lng,
    Value<double?> elevation = const Value.absent(),
  }) => TrailPoi(
    id: id ?? this.id,
    stageId: stageId ?? this.stageId,
    nameFr: nameFr ?? this.nameFr,
    nameEn: nameEn ?? this.nameEn,
    nameDe: nameDe ?? this.nameDe,
    nameIt: nameIt ?? this.nameIt,
    nameEs: nameEs ?? this.nameEs,
    descriptionFr: descriptionFr.present
        ? descriptionFr.value
        : this.descriptionFr,
    descriptionEn: descriptionEn.present
        ? descriptionEn.value
        : this.descriptionEn,
    descriptionDe: descriptionDe.present
        ? descriptionDe.value
        : this.descriptionDe,
    descriptionIt: descriptionIt.present
        ? descriptionIt.value
        : this.descriptionIt,
    descriptionEs: descriptionEs.present
        ? descriptionEs.value
        : this.descriptionEs,
    type: type ?? this.type,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    elevation: elevation.present ? elevation.value : this.elevation,
  );
  TrailPoi copyWithCompanion(TrailPoisCompanion data) {
    return TrailPoi(
      id: data.id.present ? data.id.value : this.id,
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      nameEs: data.nameEs.present ? data.nameEs.value : this.nameEs,
      descriptionFr: data.descriptionFr.present
          ? data.descriptionFr.value
          : this.descriptionFr,
      descriptionEn: data.descriptionEn.present
          ? data.descriptionEn.value
          : this.descriptionEn,
      descriptionDe: data.descriptionDe.present
          ? data.descriptionDe.value
          : this.descriptionDe,
      descriptionIt: data.descriptionIt.present
          ? data.descriptionIt.value
          : this.descriptionIt,
      descriptionEs: data.descriptionEs.present
          ? data.descriptionEs.value
          : this.descriptionEs,
      type: data.type.present ? data.type.value : this.type,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailPoi(')
          ..write('id: $id, ')
          ..write('stageId: $stageId, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('descriptionFr: $descriptionFr, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('descriptionDe: $descriptionDe, ')
          ..write('descriptionIt: $descriptionIt, ')
          ..write('descriptionEs: $descriptionEs, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('elevation: $elevation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stageId,
    nameFr,
    nameEn,
    nameDe,
    nameIt,
    nameEs,
    descriptionFr,
    descriptionEn,
    descriptionDe,
    descriptionIt,
    descriptionEs,
    type,
    lat,
    lng,
    elevation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailPoi &&
          other.id == this.id &&
          other.stageId == this.stageId &&
          other.nameFr == this.nameFr &&
          other.nameEn == this.nameEn &&
          other.nameDe == this.nameDe &&
          other.nameIt == this.nameIt &&
          other.nameEs == this.nameEs &&
          other.descriptionFr == this.descriptionFr &&
          other.descriptionEn == this.descriptionEn &&
          other.descriptionDe == this.descriptionDe &&
          other.descriptionIt == this.descriptionIt &&
          other.descriptionEs == this.descriptionEs &&
          other.type == this.type &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.elevation == this.elevation);
}

class TrailPoisCompanion extends UpdateCompanion<TrailPoi> {
  final Value<String> id;
  final Value<String> stageId;
  final Value<String> nameFr;
  final Value<String> nameEn;
  final Value<String> nameDe;
  final Value<String> nameIt;
  final Value<String> nameEs;
  final Value<String?> descriptionFr;
  final Value<String?> descriptionEn;
  final Value<String?> descriptionDe;
  final Value<String?> descriptionIt;
  final Value<String?> descriptionEs;
  final Value<String> type;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double?> elevation;
  final Value<int> rowid;
  const TrailPoisCompanion({
    this.id = const Value.absent(),
    this.stageId = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.nameEs = const Value.absent(),
    this.descriptionFr = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.descriptionDe = const Value.absent(),
    this.descriptionIt = const Value.absent(),
    this.descriptionEs = const Value.absent(),
    this.type = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.elevation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailPoisCompanion.insert({
    required String id,
    required String stageId,
    required String nameFr,
    required String nameEn,
    required String nameDe,
    required String nameIt,
    required String nameEs,
    this.descriptionFr = const Value.absent(),
    this.descriptionEn = const Value.absent(),
    this.descriptionDe = const Value.absent(),
    this.descriptionIt = const Value.absent(),
    this.descriptionEs = const Value.absent(),
    required String type,
    required double lat,
    required double lng,
    this.elevation = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       stageId = Value(stageId),
       nameFr = Value(nameFr),
       nameEn = Value(nameEn),
       nameDe = Value(nameDe),
       nameIt = Value(nameIt),
       nameEs = Value(nameEs),
       type = Value(type),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<TrailPoi> custom({
    Expression<String>? id,
    Expression<String>? stageId,
    Expression<String>? nameFr,
    Expression<String>? nameEn,
    Expression<String>? nameDe,
    Expression<String>? nameIt,
    Expression<String>? nameEs,
    Expression<String>? descriptionFr,
    Expression<String>? descriptionEn,
    Expression<String>? descriptionDe,
    Expression<String>? descriptionIt,
    Expression<String>? descriptionEs,
    Expression<String>? type,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? elevation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stageId != null) 'stage_id': stageId,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameEn != null) 'name_en': nameEn,
      if (nameDe != null) 'name_de': nameDe,
      if (nameIt != null) 'name_it': nameIt,
      if (nameEs != null) 'name_es': nameEs,
      if (descriptionFr != null) 'description_fr': descriptionFr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (descriptionDe != null) 'description_de': descriptionDe,
      if (descriptionIt != null) 'description_it': descriptionIt,
      if (descriptionEs != null) 'description_es': descriptionEs,
      if (type != null) 'type': type,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (elevation != null) 'elevation': elevation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailPoisCompanion copyWith({
    Value<String>? id,
    Value<String>? stageId,
    Value<String>? nameFr,
    Value<String>? nameEn,
    Value<String>? nameDe,
    Value<String>? nameIt,
    Value<String>? nameEs,
    Value<String?>? descriptionFr,
    Value<String?>? descriptionEn,
    Value<String?>? descriptionDe,
    Value<String?>? descriptionIt,
    Value<String?>? descriptionEs,
    Value<String>? type,
    Value<double>? lat,
    Value<double>? lng,
    Value<double?>? elevation,
    Value<int>? rowid,
  }) {
    return TrailPoisCompanion(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      nameFr: nameFr ?? this.nameFr,
      nameEn: nameEn ?? this.nameEn,
      nameDe: nameDe ?? this.nameDe,
      nameIt: nameIt ?? this.nameIt,
      nameEs: nameEs ?? this.nameEs,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionDe: descriptionDe ?? this.descriptionDe,
      descriptionIt: descriptionIt ?? this.descriptionIt,
      descriptionEs: descriptionEs ?? this.descriptionEs,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      elevation: elevation ?? this.elevation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stageId.present) {
      map['stage_id'] = Variable<String>(stageId.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (nameEs.present) {
      map['name_es'] = Variable<String>(nameEs.value);
    }
    if (descriptionFr.present) {
      map['description_fr'] = Variable<String>(descriptionFr.value);
    }
    if (descriptionEn.present) {
      map['description_en'] = Variable<String>(descriptionEn.value);
    }
    if (descriptionDe.present) {
      map['description_de'] = Variable<String>(descriptionDe.value);
    }
    if (descriptionIt.present) {
      map['description_it'] = Variable<String>(descriptionIt.value);
    }
    if (descriptionEs.present) {
      map['description_es'] = Variable<String>(descriptionEs.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<double>(elevation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailPoisCompanion(')
          ..write('id: $id, ')
          ..write('stageId: $stageId, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameDe: $nameDe, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEs: $nameEs, ')
          ..write('descriptionFr: $descriptionFr, ')
          ..write('descriptionEn: $descriptionEn, ')
          ..write('descriptionDe: $descriptionDe, ')
          ..write('descriptionIt: $descriptionIt, ')
          ..write('descriptionEs: $descriptionEs, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('elevation: $elevation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrailGpxTracksTable extends TrailGpxTracks
    with TableInfo<$TrailGpxTracksTable, TrailGpxTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailGpxTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itineraryIdMeta = const VerificationMeta(
    'itineraryId',
  );
  @override
  late final GeneratedColumn<String> itineraryId = GeneratedColumn<String>(
    'itinerary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, itineraryId, name, sourceUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_gpx_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailGpxTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('itinerary_id')) {
      context.handle(
        _itineraryIdMeta,
        itineraryId.isAcceptableOrUnknown(
          data['itinerary_id']!,
          _itineraryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itineraryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailGpxTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailGpxTrack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itineraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}itinerary_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
    );
  }

  @override
  $TrailGpxTracksTable createAlias(String alias) {
    return $TrailGpxTracksTable(attachedDatabase, alias);
  }
}

class TrailGpxTrack extends DataClass implements Insertable<TrailGpxTrack> {
  /// Identifiant unique (UUID Firestore)
  final String id;

  /// Reference vers trail_itineraries.id
  final String itineraryId;

  /// Nom de la trace
  final String name;

  /// URL source du fichier GPX (nullable)
  final String? sourceUrl;
  const TrailGpxTrack({
    required this.id,
    required this.itineraryId,
    required this.name,
    this.sourceUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['itinerary_id'] = Variable<String>(itineraryId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    return map;
  }

  TrailGpxTracksCompanion toCompanion(bool nullToAbsent) {
    return TrailGpxTracksCompanion(
      id: Value(id),
      itineraryId: Value(itineraryId),
      name: Value(name),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
    );
  }

  factory TrailGpxTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailGpxTrack(
      id: serializer.fromJson<String>(json['id']),
      itineraryId: serializer.fromJson<String>(json['itineraryId']),
      name: serializer.fromJson<String>(json['name']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itineraryId': serializer.toJson<String>(itineraryId),
      'name': serializer.toJson<String>(name),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
    };
  }

  TrailGpxTrack copyWith({
    String? id,
    String? itineraryId,
    String? name,
    Value<String?> sourceUrl = const Value.absent(),
  }) => TrailGpxTrack(
    id: id ?? this.id,
    itineraryId: itineraryId ?? this.itineraryId,
    name: name ?? this.name,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
  );
  TrailGpxTrack copyWithCompanion(TrailGpxTracksCompanion data) {
    return TrailGpxTrack(
      id: data.id.present ? data.id.value : this.id,
      itineraryId: data.itineraryId.present
          ? data.itineraryId.value
          : this.itineraryId,
      name: data.name.present ? data.name.value : this.name,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailGpxTrack(')
          ..write('id: $id, ')
          ..write('itineraryId: $itineraryId, ')
          ..write('name: $name, ')
          ..write('sourceUrl: $sourceUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itineraryId, name, sourceUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailGpxTrack &&
          other.id == this.id &&
          other.itineraryId == this.itineraryId &&
          other.name == this.name &&
          other.sourceUrl == this.sourceUrl);
}

class TrailGpxTracksCompanion extends UpdateCompanion<TrailGpxTrack> {
  final Value<String> id;
  final Value<String> itineraryId;
  final Value<String> name;
  final Value<String?> sourceUrl;
  final Value<int> rowid;
  const TrailGpxTracksCompanion({
    this.id = const Value.absent(),
    this.itineraryId = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailGpxTracksCompanion.insert({
    required String id,
    required String itineraryId,
    required String name,
    this.sourceUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itineraryId = Value(itineraryId),
       name = Value(name);
  static Insertable<TrailGpxTrack> custom({
    Expression<String>? id,
    Expression<String>? itineraryId,
    Expression<String>? name,
    Expression<String>? sourceUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itineraryId != null) 'itinerary_id': itineraryId,
      if (name != null) 'name': name,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailGpxTracksCompanion copyWith({
    Value<String>? id,
    Value<String>? itineraryId,
    Value<String>? name,
    Value<String?>? sourceUrl,
    Value<int>? rowid,
  }) {
    return TrailGpxTracksCompanion(
      id: id ?? this.id,
      itineraryId: itineraryId ?? this.itineraryId,
      name: name ?? this.name,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itineraryId.present) {
      map['itinerary_id'] = Variable<String>(itineraryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailGpxTracksCompanion(')
          ..write('id: $id, ')
          ..write('itineraryId: $itineraryId, ')
          ..write('name: $name, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrailGpxPointsTable extends TrailGpxPoints
    with TableInfo<$TrailGpxPointsTable, TrailGpxPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailGpxPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevationMeta = const VerificationMeta(
    'elevation',
  );
  @override
  late final GeneratedColumn<double> elevation = GeneratedColumn<double>(
    'elevation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceIndexMeta = const VerificationMeta(
    'sequenceIndex',
  );
  @override
  late final GeneratedColumn<int> sequenceIndex = GeneratedColumn<int>(
    'sequence_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    lat,
    lng,
    elevation,
    sequenceIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_gpx_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailGpxPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('elevation')) {
      context.handle(
        _elevationMeta,
        elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta),
      );
    } else if (isInserting) {
      context.missing(_elevationMeta);
    }
    if (data.containsKey('sequence_index')) {
      context.handle(
        _sequenceIndexMeta,
        sequenceIndex.isAcceptableOrUnknown(
          data['sequence_index']!,
          _sequenceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailGpxPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailGpxPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      elevation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation'],
      )!,
      sequenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_index'],
      )!,
    );
  }

  @override
  $TrailGpxPointsTable createAlias(String alias) {
    return $TrailGpxPointsTable(attachedDatabase, alias);
  }
}

class TrailGpxPoint extends DataClass implements Insertable<TrailGpxPoint> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Reference vers trail_gpx_tracks.id
  final String trackId;

  /// Latitude
  final double lat;

  /// Longitude
  final double lng;

  /// Altitude en metres
  final double elevation;

  /// Index de sequence pour l'ordre des points
  final int sequenceIndex;
  const TrailGpxPoint({
    required this.id,
    required this.trackId,
    required this.lat,
    required this.lng,
    required this.elevation,
    required this.sequenceIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['elevation'] = Variable<double>(elevation);
    map['sequence_index'] = Variable<int>(sequenceIndex);
    return map;
  }

  TrailGpxPointsCompanion toCompanion(bool nullToAbsent) {
    return TrailGpxPointsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      lat: Value(lat),
      lng: Value(lng),
      elevation: Value(elevation),
      sequenceIndex: Value(sequenceIndex),
    );
  }

  factory TrailGpxPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailGpxPoint(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      elevation: serializer.fromJson<double>(json['elevation']),
      sequenceIndex: serializer.fromJson<int>(json['sequenceIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'elevation': serializer.toJson<double>(elevation),
      'sequenceIndex': serializer.toJson<int>(sequenceIndex),
    };
  }

  TrailGpxPoint copyWith({
    int? id,
    String? trackId,
    double? lat,
    double? lng,
    double? elevation,
    int? sequenceIndex,
  }) => TrailGpxPoint(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    elevation: elevation ?? this.elevation,
    sequenceIndex: sequenceIndex ?? this.sequenceIndex,
  );
  TrailGpxPoint copyWithCompanion(TrailGpxPointsCompanion data) {
    return TrailGpxPoint(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      sequenceIndex: data.sequenceIndex.present
          ? data.sequenceIndex.value
          : this.sequenceIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailGpxPoint(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('elevation: $elevation, ')
          ..write('sequenceIndex: $sequenceIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trackId, lat, lng, elevation, sequenceIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailGpxPoint &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.elevation == this.elevation &&
          other.sequenceIndex == this.sequenceIndex);
}

class TrailGpxPointsCompanion extends UpdateCompanion<TrailGpxPoint> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double> elevation;
  final Value<int> sequenceIndex;
  const TrailGpxPointsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.elevation = const Value.absent(),
    this.sequenceIndex = const Value.absent(),
  });
  TrailGpxPointsCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required double lat,
    required double lng,
    required double elevation,
    required int sequenceIndex,
  }) : trackId = Value(trackId),
       lat = Value(lat),
       lng = Value(lng),
       elevation = Value(elevation),
       sequenceIndex = Value(sequenceIndex);
  static Insertable<TrailGpxPoint> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? elevation,
    Expression<int>? sequenceIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (elevation != null) 'elevation': elevation,
      if (sequenceIndex != null) 'sequence_index': sequenceIndex,
    });
  }

  TrailGpxPointsCompanion copyWith({
    Value<int>? id,
    Value<String>? trackId,
    Value<double>? lat,
    Value<double>? lng,
    Value<double>? elevation,
    Value<int>? sequenceIndex,
  }) {
    return TrailGpxPointsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      elevation: elevation ?? this.elevation,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<double>(elevation.value);
    }
    if (sequenceIndex.present) {
      map['sequence_index'] = Variable<int>(sequenceIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailGpxPointsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('elevation: $elevation, ')
          ..write('sequenceIndex: $sequenceIndex')
          ..write(')'))
        .toString();
  }
}

class $TrailManifestsTable extends TrailManifests
    with TableInfo<$TrailManifestsTable, TrailManifest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailManifestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataVersionMeta = const VerificationMeta(
    'dataVersion',
  );
  @override
  late final GeneratedColumn<int> dataVersion = GeneratedColumn<int>(
    'data_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<String> lastUpdated = GeneratedColumn<String>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trailId,
    dataVersion,
    hash,
    filePath,
    fileSize,
    status,
    lastUpdated,
    localVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_manifests';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailManifest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('data_version')) {
      context.handle(
        _dataVersionMeta,
        dataVersion.isAcceptableOrUnknown(
          data['data_version']!,
          _dataVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataVersionMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trailId};
  @override
  TrailManifest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailManifest(
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      dataVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_version'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated'],
      )!,
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      ),
    );
  }

  @override
  $TrailManifestsTable createAlias(String alias) {
    return $TrailManifestsTable(attachedDatabase, alias);
  }
}

class TrailManifest extends DataClass implements Insertable<TrailManifest> {
  /// Identifiant unique du sentier (cle primaire)
  final String trailId;

  /// Version des donnees distantes
  final int dataVersion;

  /// Hash SHA-256 du fichier distant
  final String hash;

  /// Chemin du fichier sur le serveur
  final String filePath;

  /// Taille du fichier en octets
  final int fileSize;

  /// Statut du sentier ('active', 'draft', 'archived')
  final String status;

  /// Date de derniere mise a jour (ISO 8601)
  final String lastUpdated;

  /// Version telechargee localement (null = jamais telecharge)
  final int? localVersion;
  const TrailManifest({
    required this.trailId,
    required this.dataVersion,
    required this.hash,
    required this.filePath,
    required this.fileSize,
    required this.status,
    required this.lastUpdated,
    this.localVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trail_id'] = Variable<String>(trailId);
    map['data_version'] = Variable<int>(dataVersion);
    map['hash'] = Variable<String>(hash);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['status'] = Variable<String>(status);
    map['last_updated'] = Variable<String>(lastUpdated);
    if (!nullToAbsent || localVersion != null) {
      map['local_version'] = Variable<int>(localVersion);
    }
    return map;
  }

  TrailManifestsCompanion toCompanion(bool nullToAbsent) {
    return TrailManifestsCompanion(
      trailId: Value(trailId),
      dataVersion: Value(dataVersion),
      hash: Value(hash),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      status: Value(status),
      lastUpdated: Value(lastUpdated),
      localVersion: localVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(localVersion),
    );
  }

  factory TrailManifest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailManifest(
      trailId: serializer.fromJson<String>(json['trailId']),
      dataVersion: serializer.fromJson<int>(json['dataVersion']),
      hash: serializer.fromJson<String>(json['hash']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      status: serializer.fromJson<String>(json['status']),
      lastUpdated: serializer.fromJson<String>(json['lastUpdated']),
      localVersion: serializer.fromJson<int?>(json['localVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trailId': serializer.toJson<String>(trailId),
      'dataVersion': serializer.toJson<int>(dataVersion),
      'hash': serializer.toJson<String>(hash),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'status': serializer.toJson<String>(status),
      'lastUpdated': serializer.toJson<String>(lastUpdated),
      'localVersion': serializer.toJson<int?>(localVersion),
    };
  }

  TrailManifest copyWith({
    String? trailId,
    int? dataVersion,
    String? hash,
    String? filePath,
    int? fileSize,
    String? status,
    String? lastUpdated,
    Value<int?> localVersion = const Value.absent(),
  }) => TrailManifest(
    trailId: trailId ?? this.trailId,
    dataVersion: dataVersion ?? this.dataVersion,
    hash: hash ?? this.hash,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    status: status ?? this.status,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    localVersion: localVersion.present ? localVersion.value : this.localVersion,
  );
  TrailManifest copyWithCompanion(TrailManifestsCompanion data) {
    return TrailManifest(
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      dataVersion: data.dataVersion.present
          ? data.dataVersion.value
          : this.dataVersion,
      hash: data.hash.present ? data.hash.value : this.hash,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      status: data.status.present ? data.status.value : this.status,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailManifest(')
          ..write('trailId: $trailId, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('hash: $hash, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('status: $status, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('localVersion: $localVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trailId,
    dataVersion,
    hash,
    filePath,
    fileSize,
    status,
    lastUpdated,
    localVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailManifest &&
          other.trailId == this.trailId &&
          other.dataVersion == this.dataVersion &&
          other.hash == this.hash &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.status == this.status &&
          other.lastUpdated == this.lastUpdated &&
          other.localVersion == this.localVersion);
}

class TrailManifestsCompanion extends UpdateCompanion<TrailManifest> {
  final Value<String> trailId;
  final Value<int> dataVersion;
  final Value<String> hash;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<String> status;
  final Value<String> lastUpdated;
  final Value<int?> localVersion;
  final Value<int> rowid;
  const TrailManifestsCompanion({
    this.trailId = const Value.absent(),
    this.dataVersion = const Value.absent(),
    this.hash = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.status = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailManifestsCompanion.insert({
    required String trailId,
    required int dataVersion,
    required String hash,
    required String filePath,
    required int fileSize,
    required String status,
    required String lastUpdated,
    this.localVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trailId = Value(trailId),
       dataVersion = Value(dataVersion),
       hash = Value(hash),
       filePath = Value(filePath),
       fileSize = Value(fileSize),
       status = Value(status),
       lastUpdated = Value(lastUpdated);
  static Insertable<TrailManifest> custom({
    Expression<String>? trailId,
    Expression<int>? dataVersion,
    Expression<String>? hash,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<String>? status,
    Expression<String>? lastUpdated,
    Expression<int>? localVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trailId != null) 'trail_id': trailId,
      if (dataVersion != null) 'data_version': dataVersion,
      if (hash != null) 'hash': hash,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (status != null) 'status': status,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (localVersion != null) 'local_version': localVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailManifestsCompanion copyWith({
    Value<String>? trailId,
    Value<int>? dataVersion,
    Value<String>? hash,
    Value<String>? filePath,
    Value<int>? fileSize,
    Value<String>? status,
    Value<String>? lastUpdated,
    Value<int?>? localVersion,
    Value<int>? rowid,
  }) {
    return TrailManifestsCompanion(
      trailId: trailId ?? this.trailId,
      dataVersion: dataVersion ?? this.dataVersion,
      hash: hash ?? this.hash,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      localVersion: localVersion ?? this.localVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (dataVersion.present) {
      map['data_version'] = Variable<int>(dataVersion.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<String>(lastUpdated.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailManifestsCompanion(')
          ..write('trailId: $trailId, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('hash: $hash, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('status: $status, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('localVersion: $localVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trailId,
    action,
    status,
    payload,
    createdAt,
    completedAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Identifiant du sentier concerne
  final String trailId;

  /// Action a executer ('insert_trail_meta', 'insert_stages', etc.)
  final String action;

  /// Statut de l'action ('pending', 'completed', 'failed')
  final String status;

  /// Donnees JSON de l'action (nullable, contenu a inserer)
  final String? payload;

  /// Date de creation (ISO 8601)
  final String createdAt;

  /// Date de completion (ISO 8601, nullable)
  final String? completedAt;

  /// Nombre de tentatives echouees
  final int retryCount;
  const SyncQueueData({
    required this.id,
    required this.trailId,
    required this.action,
    required this.status,
    this.payload,
    required this.createdAt,
    this.completedAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['action'] = Variable<String>(action);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      trailId: Value(trailId),
      action: Value(action),
      status: Value(status),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      retryCount: Value(retryCount),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      action: serializer.fromJson<String>(json['action']),
      status: serializer.fromJson<String>(json['status']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'action': serializer.toJson<String>(action),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<String>(createdAt),
      'completedAt': serializer.toJson<String?>(completedAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? trailId,
    String? action,
    String? status,
    Value<String?> payload = const Value.absent(),
    String? createdAt,
    Value<String?> completedAt = const Value.absent(),
    int? retryCount,
  }) => SyncQueueData(
    id: id ?? this.id,
    trailId: trailId ?? this.trailId,
    action: action ?? this.action,
    status: status ?? this.status,
    payload: payload.present ? payload.value : this.payload,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    retryCount: retryCount ?? this.retryCount,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      action: data.action.present ? data.action.value : this.action,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('action: $action, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trailId,
    action,
    status,
    payload,
    createdAt,
    completedAt,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.action == this.action &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.retryCount == this.retryCount);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<String> action;
  final Value<String> status;
  final Value<String?> payload;
  final Value<String> createdAt;
  final Value<String?> completedAt;
  final Value<int> retryCount;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.action = const Value.absent(),
    this.status = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required String action,
    this.status = const Value.absent(),
    this.payload = const Value.absent(),
    required String createdAt,
    this.completedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  }) : trailId = Value(trailId),
       action = Value(action),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<String>? action,
    Expression<String>? status,
    Expression<String>? payload,
    Expression<String>? createdAt,
    Expression<String>? completedAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (action != null) 'action': action,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<String>? action,
    Value<String>? status,
    Value<String?>? payload,
    Value<String>? createdAt,
    Value<String?>? completedAt,
    Value<int>? retryCount,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      action: action ?? this.action,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('action: $action, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $ReviewRequestsTable extends ReviewRequests
    with TableInfo<$ReviewRequestsTable, ReviewRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trailIdMeta = const VerificationMeta(
    'trailId',
  );
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
    'trail_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, trailId, requestedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(
        _trailIdMeta,
        trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewRequest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trail_id'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
    );
  }

  @override
  $ReviewRequestsTable createAlias(String alias) {
    return $ReviewRequestsTable(attachedDatabase, alias);
  }
}

class ReviewRequest extends DataClass implements Insertable<ReviewRequest> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Identifiant du sentier (ex: 'gr10-2026-001')
  final String trailId;

  /// Date de la demande de review
  final DateTime requestedAt;
  const ReviewRequest({
    required this.id,
    required this.trailId,
    required this.requestedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['requested_at'] = Variable<DateTime>(requestedAt);
    return map;
  }

  ReviewRequestsCompanion toCompanion(bool nullToAbsent) {
    return ReviewRequestsCompanion(
      id: Value(id),
      trailId: Value(trailId),
      requestedAt: Value(requestedAt),
    );
  }

  factory ReviewRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewRequest(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trailId': serializer.toJson<String>(trailId),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
    };
  }

  ReviewRequest copyWith({int? id, String? trailId, DateTime? requestedAt}) =>
      ReviewRequest(
        id: id ?? this.id,
        trailId: trailId ?? this.trailId,
        requestedAt: requestedAt ?? this.requestedAt,
      );
  ReviewRequest copyWithCompanion(ReviewRequestsCompanion data) {
    return ReviewRequest(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewRequest(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('requestedAt: $requestedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trailId, requestedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewRequest &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.requestedAt == this.requestedAt);
}

class ReviewRequestsCompanion extends UpdateCompanion<ReviewRequest> {
  final Value<int> id;
  final Value<String> trailId;
  final Value<DateTime> requestedAt;
  const ReviewRequestsCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.requestedAt = const Value.absent(),
  });
  ReviewRequestsCompanion.insert({
    this.id = const Value.absent(),
    required String trailId,
    required DateTime requestedAt,
  }) : trailId = Value(trailId),
       requestedAt = Value(requestedAt);
  static Insertable<ReviewRequest> custom({
    Expression<int>? id,
    Expression<String>? trailId,
    Expression<DateTime>? requestedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trailId != null) 'trail_id': trailId,
      if (requestedAt != null) 'requested_at': requestedAt,
    });
  }

  ReviewRequestsCompanion copyWith({
    Value<int>? id,
    Value<String>? trailId,
    Value<DateTime>? requestedAt,
  }) {
    return ReviewRequestsCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewRequestsCompanion(')
          ..write('id: $id, ')
          ..write('trailId: $trailId, ')
          ..write('requestedAt: $requestedAt')
          ..write(')'))
        .toString();
  }
}

class $HealthInfoEntriesTable extends HealthInfoEntries
    with TableInfo<$HealthInfoEntriesTable, HealthInfoEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthInfoEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bloodTypeMeta = const VerificationMeta(
    'bloodType',
  );
  @override
  late final GeneratedColumn<String> bloodType = GeneratedColumn<String>(
    'blood_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _allergiesMeta = const VerificationMeta(
    'allergies',
  );
  @override
  late final GeneratedColumn<String> allergies = GeneratedColumn<String>(
    'allergies',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _treatmentsMeta = const VerificationMeta(
    'treatments',
  );
  @override
  late final GeneratedColumn<String> treatments = GeneratedColumn<String>(
    'treatments',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _doctorContactMeta = const VerificationMeta(
    'doctorContact',
  );
  @override
  late final GeneratedColumn<String> doctorContact = GeneratedColumn<String>(
    'doctor_contact',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _insuranceNumberMeta = const VerificationMeta(
    'insuranceNumber',
  );
  @override
  late final GeneratedColumn<String> insuranceNumber = GeneratedColumn<String>(
    'insurance_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bloodType,
    allergies,
    treatments,
    doctorContact,
    insuranceNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_info_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthInfoEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('blood_type')) {
      context.handle(
        _bloodTypeMeta,
        bloodType.isAcceptableOrUnknown(data['blood_type']!, _bloodTypeMeta),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('treatments')) {
      context.handle(
        _treatmentsMeta,
        treatments.isAcceptableOrUnknown(data['treatments']!, _treatmentsMeta),
      );
    }
    if (data.containsKey('doctor_contact')) {
      context.handle(
        _doctorContactMeta,
        doctorContact.isAcceptableOrUnknown(
          data['doctor_contact']!,
          _doctorContactMeta,
        ),
      );
    }
    if (data.containsKey('insurance_number')) {
      context.handle(
        _insuranceNumberMeta,
        insuranceNumber.isAcceptableOrUnknown(
          data['insurance_number']!,
          _insuranceNumberMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthInfoEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthInfoEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bloodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_type'],
      )!,
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      )!,
      treatments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}treatments'],
      )!,
      doctorContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_contact'],
      )!,
      insuranceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insurance_number'],
      )!,
    );
  }

  @override
  $HealthInfoEntriesTable createAlias(String alias) {
    return $HealthInfoEntriesTable(attachedDatabase, alias);
  }
}

class HealthInfoEntry extends DataClass implements Insertable<HealthInfoEntry> {
  /// Cle primaire auto-incrementee
  final int id;

  /// Groupe sanguin (ex: 'A+', 'O-', 'AB+')
  final String bloodType;

  /// Allergies connues (texte libre)
  final String allergies;

  /// Traitements en cours (texte libre)
  final String treatments;

  /// Contact du medecin traitant (nom + telephone)
  final String doctorContact;

  /// Numero d'assurance / mutuelle / carte europeenne
  final String insuranceNumber;
  const HealthInfoEntry({
    required this.id,
    required this.bloodType,
    required this.allergies,
    required this.treatments,
    required this.doctorContact,
    required this.insuranceNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['blood_type'] = Variable<String>(bloodType);
    map['allergies'] = Variable<String>(allergies);
    map['treatments'] = Variable<String>(treatments);
    map['doctor_contact'] = Variable<String>(doctorContact);
    map['insurance_number'] = Variable<String>(insuranceNumber);
    return map;
  }

  HealthInfoEntriesCompanion toCompanion(bool nullToAbsent) {
    return HealthInfoEntriesCompanion(
      id: Value(id),
      bloodType: Value(bloodType),
      allergies: Value(allergies),
      treatments: Value(treatments),
      doctorContact: Value(doctorContact),
      insuranceNumber: Value(insuranceNumber),
    );
  }

  factory HealthInfoEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthInfoEntry(
      id: serializer.fromJson<int>(json['id']),
      bloodType: serializer.fromJson<String>(json['bloodType']),
      allergies: serializer.fromJson<String>(json['allergies']),
      treatments: serializer.fromJson<String>(json['treatments']),
      doctorContact: serializer.fromJson<String>(json['doctorContact']),
      insuranceNumber: serializer.fromJson<String>(json['insuranceNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bloodType': serializer.toJson<String>(bloodType),
      'allergies': serializer.toJson<String>(allergies),
      'treatments': serializer.toJson<String>(treatments),
      'doctorContact': serializer.toJson<String>(doctorContact),
      'insuranceNumber': serializer.toJson<String>(insuranceNumber),
    };
  }

  HealthInfoEntry copyWith({
    int? id,
    String? bloodType,
    String? allergies,
    String? treatments,
    String? doctorContact,
    String? insuranceNumber,
  }) => HealthInfoEntry(
    id: id ?? this.id,
    bloodType: bloodType ?? this.bloodType,
    allergies: allergies ?? this.allergies,
    treatments: treatments ?? this.treatments,
    doctorContact: doctorContact ?? this.doctorContact,
    insuranceNumber: insuranceNumber ?? this.insuranceNumber,
  );
  HealthInfoEntry copyWithCompanion(HealthInfoEntriesCompanion data) {
    return HealthInfoEntry(
      id: data.id.present ? data.id.value : this.id,
      bloodType: data.bloodType.present ? data.bloodType.value : this.bloodType,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      treatments: data.treatments.present
          ? data.treatments.value
          : this.treatments,
      doctorContact: data.doctorContact.present
          ? data.doctorContact.value
          : this.doctorContact,
      insuranceNumber: data.insuranceNumber.present
          ? data.insuranceNumber.value
          : this.insuranceNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthInfoEntry(')
          ..write('id: $id, ')
          ..write('bloodType: $bloodType, ')
          ..write('allergies: $allergies, ')
          ..write('treatments: $treatments, ')
          ..write('doctorContact: $doctorContact, ')
          ..write('insuranceNumber: $insuranceNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bloodType,
    allergies,
    treatments,
    doctorContact,
    insuranceNumber,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthInfoEntry &&
          other.id == this.id &&
          other.bloodType == this.bloodType &&
          other.allergies == this.allergies &&
          other.treatments == this.treatments &&
          other.doctorContact == this.doctorContact &&
          other.insuranceNumber == this.insuranceNumber);
}

class HealthInfoEntriesCompanion extends UpdateCompanion<HealthInfoEntry> {
  final Value<int> id;
  final Value<String> bloodType;
  final Value<String> allergies;
  final Value<String> treatments;
  final Value<String> doctorContact;
  final Value<String> insuranceNumber;
  const HealthInfoEntriesCompanion({
    this.id = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.treatments = const Value.absent(),
    this.doctorContact = const Value.absent(),
    this.insuranceNumber = const Value.absent(),
  });
  HealthInfoEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.treatments = const Value.absent(),
    this.doctorContact = const Value.absent(),
    this.insuranceNumber = const Value.absent(),
  });
  static Insertable<HealthInfoEntry> custom({
    Expression<int>? id,
    Expression<String>? bloodType,
    Expression<String>? allergies,
    Expression<String>? treatments,
    Expression<String>? doctorContact,
    Expression<String>? insuranceNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bloodType != null) 'blood_type': bloodType,
      if (allergies != null) 'allergies': allergies,
      if (treatments != null) 'treatments': treatments,
      if (doctorContact != null) 'doctor_contact': doctorContact,
      if (insuranceNumber != null) 'insurance_number': insuranceNumber,
    });
  }

  HealthInfoEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? bloodType,
    Value<String>? allergies,
    Value<String>? treatments,
    Value<String>? doctorContact,
    Value<String>? insuranceNumber,
  }) {
    return HealthInfoEntriesCompanion(
      id: id ?? this.id,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      treatments: treatments ?? this.treatments,
      doctorContact: doctorContact ?? this.doctorContact,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bloodType.present) {
      map['blood_type'] = Variable<String>(bloodType.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (treatments.present) {
      map['treatments'] = Variable<String>(treatments.value);
    }
    if (doctorContact.present) {
      map['doctor_contact'] = Variable<String>(doctorContact.value);
    }
    if (insuranceNumber.present) {
      map['insurance_number'] = Variable<String>(insuranceNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthInfoEntriesCompanion(')
          ..write('id: $id, ')
          ..write('bloodType: $bloodType, ')
          ..write('allergies: $allergies, ')
          ..write('treatments: $treatments, ')
          ..write('doctorContact: $doctorContact, ')
          ..write('insuranceNumber: $insuranceNumber')
          ..write(')'))
        .toString();
  }
}

class $FollowSessionsTable extends FollowSessions
    with TableInfo<$FollowSessionsTable, FollowSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trekkerUserIdMeta = const VerificationMeta(
    'trekkerUserId',
  );
  @override
  late final GeneratedColumn<String> trekkerUserId = GeneratedColumn<String>(
    'trekker_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareCodeMeta = const VerificationMeta(
    'shareCode',
  );
  @override
  late final GeneratedColumn<String> shareCode = GeneratedColumn<String>(
    'share_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<String> expiresAt = GeneratedColumn<String>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trekkerUserId,
    shareCode,
    createdAt,
    expiresAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follow_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trekker_user_id')) {
      context.handle(
        _trekkerUserIdMeta,
        trekkerUserId.isAcceptableOrUnknown(
          data['trekker_user_id']!,
          _trekkerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trekkerUserIdMeta);
    }
    if (data.containsKey('share_code')) {
      context.handle(
        _shareCodeMeta,
        shareCode.isAcceptableOrUnknown(data['share_code']!, _shareCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_shareCodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FollowSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trekkerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trekker_user_id'],
      )!,
      shareCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expires_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $FollowSessionsTable createAlias(String alias) {
    return $FollowSessionsTable(attachedDatabase, alias);
  }
}

class FollowSessionRow extends DataClass
    implements Insertable<FollowSessionRow> {
  /// Identifiant unique (UUID)
  final String id;

  /// UID (anonymise) du randonneur suivi
  final String trekkerUserId;

  /// Code de partage unique (6 caracteres alphanum)
  final String shareCode;

  /// Date de creation (ISO 8601)
  final String createdAt;

  /// Date d expiration (ISO 8601)
  final String expiresAt;

  /// Session active ou terminee
  final bool isActive;
  const FollowSessionRow({
    required this.id,
    required this.trekkerUserId,
    required this.shareCode,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trekker_user_id'] = Variable<String>(trekkerUserId);
    map['share_code'] = Variable<String>(shareCode);
    map['created_at'] = Variable<String>(createdAt);
    map['expires_at'] = Variable<String>(expiresAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  FollowSessionsCompanion toCompanion(bool nullToAbsent) {
    return FollowSessionsCompanion(
      id: Value(id),
      trekkerUserId: Value(trekkerUserId),
      shareCode: Value(shareCode),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
      isActive: Value(isActive),
    );
  }

  factory FollowSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowSessionRow(
      id: serializer.fromJson<String>(json['id']),
      trekkerUserId: serializer.fromJson<String>(json['trekkerUserId']),
      shareCode: serializer.fromJson<String>(json['shareCode']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      expiresAt: serializer.fromJson<String>(json['expiresAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trekkerUserId': serializer.toJson<String>(trekkerUserId),
      'shareCode': serializer.toJson<String>(shareCode),
      'createdAt': serializer.toJson<String>(createdAt),
      'expiresAt': serializer.toJson<String>(expiresAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  FollowSessionRow copyWith({
    String? id,
    String? trekkerUserId,
    String? shareCode,
    String? createdAt,
    String? expiresAt,
    bool? isActive,
  }) => FollowSessionRow(
    id: id ?? this.id,
    trekkerUserId: trekkerUserId ?? this.trekkerUserId,
    shareCode: shareCode ?? this.shareCode,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    isActive: isActive ?? this.isActive,
  );
  FollowSessionRow copyWithCompanion(FollowSessionsCompanion data) {
    return FollowSessionRow(
      id: data.id.present ? data.id.value : this.id,
      trekkerUserId: data.trekkerUserId.present
          ? data.trekkerUserId.value
          : this.trekkerUserId,
      shareCode: data.shareCode.present ? data.shareCode.value : this.shareCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowSessionRow(')
          ..write('id: $id, ')
          ..write('trekkerUserId: $trekkerUserId, ')
          ..write('shareCode: $shareCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trekkerUserId, shareCode, createdAt, expiresAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowSessionRow &&
          other.id == this.id &&
          other.trekkerUserId == this.trekkerUserId &&
          other.shareCode == this.shareCode &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.isActive == this.isActive);
}

class FollowSessionsCompanion extends UpdateCompanion<FollowSessionRow> {
  final Value<String> id;
  final Value<String> trekkerUserId;
  final Value<String> shareCode;
  final Value<String> createdAt;
  final Value<String> expiresAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const FollowSessionsCompanion({
    this.id = const Value.absent(),
    this.trekkerUserId = const Value.absent(),
    this.shareCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FollowSessionsCompanion.insert({
    required String id,
    required String trekkerUserId,
    required String shareCode,
    required String createdAt,
    required String expiresAt,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       trekkerUserId = Value(trekkerUserId),
       shareCode = Value(shareCode),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt);
  static Insertable<FollowSessionRow> custom({
    Expression<String>? id,
    Expression<String>? trekkerUserId,
    Expression<String>? shareCode,
    Expression<String>? createdAt,
    Expression<String>? expiresAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trekkerUserId != null) 'trekker_user_id': trekkerUserId,
      if (shareCode != null) 'share_code': shareCode,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FollowSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? trekkerUserId,
    Value<String>? shareCode,
    Value<String>? createdAt,
    Value<String>? expiresAt,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return FollowSessionsCompanion(
      id: id ?? this.id,
      trekkerUserId: trekkerUserId ?? this.trekkerUserId,
      shareCode: shareCode ?? this.shareCode,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trekkerUserId.present) {
      map['trekker_user_id'] = Variable<String>(trekkerUserId.value);
    }
    if (shareCode.present) {
      map['share_code'] = Variable<String>(shareCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<String>(expiresAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowSessionsCompanion(')
          ..write('id: $id, ')
          ..write('trekkerUserId: $trekkerUserId, ')
          ..write('shareCode: $shareCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FollowerSlotsTable extends FollowerSlots
    with TableInfo<$FollowerSlotsTable, FollowerSlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowerSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _followerNameMeta = const VerificationMeta(
    'followerName',
  );
  @override
  late final GeneratedColumn<String> followerName = GeneratedColumn<String>(
    'follower_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPaidMeta = const VerificationMeta('isPaid');
  @override
  late final GeneratedColumn<bool> isPaid = GeneratedColumn<bool>(
    'is_paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _adSupportedMeta = const VerificationMeta(
    'adSupported',
  );
  @override
  late final GeneratedColumn<bool> adSupported = GeneratedColumn<bool>(
    'ad_supported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ad_supported" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    followerName,
    isPaid,
    adSupported,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follower_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<FollowerSlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('follower_name')) {
      context.handle(
        _followerNameMeta,
        followerName.isAcceptableOrUnknown(
          data['follower_name']!,
          _followerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_followerNameMeta);
    }
    if (data.containsKey('is_paid')) {
      context.handle(
        _isPaidMeta,
        isPaid.isAcceptableOrUnknown(data['is_paid']!, _isPaidMeta),
      );
    }
    if (data.containsKey('ad_supported')) {
      context.handle(
        _adSupportedMeta,
        adSupported.isAcceptableOrUnknown(
          data['ad_supported']!,
          _adSupportedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FollowerSlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FollowerSlotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      followerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follower_name'],
      )!,
      isPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paid'],
      )!,
      adSupported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ad_supported'],
      )!,
    );
  }

  @override
  $FollowerSlotsTable createAlias(String alias) {
    return $FollowerSlotsTable(attachedDatabase, alias);
  }
}

class FollowerSlotRow extends DataClass implements Insertable<FollowerSlotRow> {
  /// Identifiant unique (UUID)
  final String id;

  /// Reference vers la session de suivi
  final String sessionId;

  /// Nom du suiveur
  final String followerName;

  /// Slot paye (pass web ou app complementaire)
  final bool isPaid;

  /// Slot supporte par la publicite (3eme suiveur et plus)
  final bool adSupported;
  const FollowerSlotRow({
    required this.id,
    required this.sessionId,
    required this.followerName,
    required this.isPaid,
    required this.adSupported,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['follower_name'] = Variable<String>(followerName);
    map['is_paid'] = Variable<bool>(isPaid);
    map['ad_supported'] = Variable<bool>(adSupported);
    return map;
  }

  FollowerSlotsCompanion toCompanion(bool nullToAbsent) {
    return FollowerSlotsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      followerName: Value(followerName),
      isPaid: Value(isPaid),
      adSupported: Value(adSupported),
    );
  }

  factory FollowerSlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FollowerSlotRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      followerName: serializer.fromJson<String>(json['followerName']),
      isPaid: serializer.fromJson<bool>(json['isPaid']),
      adSupported: serializer.fromJson<bool>(json['adSupported']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'followerName': serializer.toJson<String>(followerName),
      'isPaid': serializer.toJson<bool>(isPaid),
      'adSupported': serializer.toJson<bool>(adSupported),
    };
  }

  FollowerSlotRow copyWith({
    String? id,
    String? sessionId,
    String? followerName,
    bool? isPaid,
    bool? adSupported,
  }) => FollowerSlotRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    followerName: followerName ?? this.followerName,
    isPaid: isPaid ?? this.isPaid,
    adSupported: adSupported ?? this.adSupported,
  );
  FollowerSlotRow copyWithCompanion(FollowerSlotsCompanion data) {
    return FollowerSlotRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      followerName: data.followerName.present
          ? data.followerName.value
          : this.followerName,
      isPaid: data.isPaid.present ? data.isPaid.value : this.isPaid,
      adSupported: data.adSupported.present
          ? data.adSupported.value
          : this.adSupported,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FollowerSlotRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('followerName: $followerName, ')
          ..write('isPaid: $isPaid, ')
          ..write('adSupported: $adSupported')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, followerName, isPaid, adSupported);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FollowerSlotRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.followerName == this.followerName &&
          other.isPaid == this.isPaid &&
          other.adSupported == this.adSupported);
}

class FollowerSlotsCompanion extends UpdateCompanion<FollowerSlotRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> followerName;
  final Value<bool> isPaid;
  final Value<bool> adSupported;
  final Value<int> rowid;
  const FollowerSlotsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.followerName = const Value.absent(),
    this.isPaid = const Value.absent(),
    this.adSupported = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FollowerSlotsCompanion.insert({
    required String id,
    required String sessionId,
    required String followerName,
    this.isPaid = const Value.absent(),
    this.adSupported = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       followerName = Value(followerName);
  static Insertable<FollowerSlotRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? followerName,
    Expression<bool>? isPaid,
    Expression<bool>? adSupported,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (followerName != null) 'follower_name': followerName,
      if (isPaid != null) 'is_paid': isPaid,
      if (adSupported != null) 'ad_supported': adSupported,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FollowerSlotsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? followerName,
    Value<bool>? isPaid,
    Value<bool>? adSupported,
    Value<int>? rowid,
  }) {
    return FollowerSlotsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      followerName: followerName ?? this.followerName,
      isPaid: isPaid ?? this.isPaid,
      adSupported: adSupported ?? this.adSupported,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (followerName.present) {
      map['follower_name'] = Variable<String>(followerName.value);
    }
    if (isPaid.present) {
      map['is_paid'] = Variable<bool>(isPaid.value);
    }
    if (adSupported.present) {
      map['ad_supported'] = Variable<bool>(adSupported.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowerSlotsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('followerName: $followerName, ')
          ..write('isPaid: $isPaid, ')
          ..write('adSupported: $adSupported, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StagesTable stages = $StagesTable(this);
  late final $PoisTable pois = $PoisTable(this);
  late final $UserProgressEntriesTable userProgressEntries =
      $UserProgressEntriesTable(this);
  late final $ChecklistItemsTable checklistItems = $ChecklistItemsTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $WeatherCacheTable weatherCache = $WeatherCacheTable(this);
  late final $FeedbackQueueTable feedbackQueue = $FeedbackQueueTable(this);
  late final $TrailMetaTable trailMeta = $TrailMetaTable(this);
  late final $TrailItinerariesTable trailItineraries = $TrailItinerariesTable(
    this,
  );
  late final $TrailStagesTable trailStages = $TrailStagesTable(this);
  late final $TrailAccommodationsTable trailAccommodations =
      $TrailAccommodationsTable(this);
  late final $TrailPoisTable trailPois = $TrailPoisTable(this);
  late final $TrailGpxTracksTable trailGpxTracks = $TrailGpxTracksTable(this);
  late final $TrailGpxPointsTable trailGpxPoints = $TrailGpxPointsTable(this);
  late final $TrailManifestsTable trailManifests = $TrailManifestsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $ReviewRequestsTable reviewRequests = $ReviewRequestsTable(this);
  late final $HealthInfoEntriesTable healthInfoEntries =
      $HealthInfoEntriesTable(this);
  late final $FollowSessionsTable followSessions = $FollowSessionsTable(this);
  late final $FollowerSlotsTable followerSlots = $FollowerSlotsTable(this);
  late final StagesDao stagesDao = StagesDao(this as AppDatabase);
  late final PoisDao poisDao = PoisDao(this as AppDatabase);
  late final ProgressDao progressDao = ProgressDao(this as AppDatabase);
  late final ChecklistDao checklistDao = ChecklistDao(this as AppDatabase);
  late final JournalDao journalDao = JournalDao(this as AppDatabase);
  late final WeatherCacheDao weatherCacheDao = WeatherCacheDao(
    this as AppDatabase,
  );
  late final FeedbackQueueDao feedbackQueueDao = FeedbackQueueDao(
    this as AppDatabase,
  );
  late final TrailMetaDao trailMetaDao = TrailMetaDao(this as AppDatabase);
  late final TrailItinerariesDao trailItinerariesDao = TrailItinerariesDao(
    this as AppDatabase,
  );
  late final TrailStagesDao trailStagesDao = TrailStagesDao(
    this as AppDatabase,
  );
  late final TrailAccommodationsDao trailAccommodationsDao =
      TrailAccommodationsDao(this as AppDatabase);
  late final TrailPoisDao trailPoisDao = TrailPoisDao(this as AppDatabase);
  late final TrailGpxTracksDao trailGpxTracksDao = TrailGpxTracksDao(
    this as AppDatabase,
  );
  late final TrailGpxPointsDao trailGpxPointsDao = TrailGpxPointsDao(
    this as AppDatabase,
  );
  late final TrailManifestsDao trailManifestsDao = TrailManifestsDao(
    this as AppDatabase,
  );
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final ReviewRequestsDao reviewRequestsDao = ReviewRequestsDao(
    this as AppDatabase,
  );
  late final HealthInfoDao healthInfoDao = HealthInfoDao(this as AppDatabase);
  late final FollowSessionsDao followSessionsDao = FollowSessionsDao(
    this as AppDatabase,
  );
  late final FollowerSlotsDao followerSlotsDao = FollowerSlotsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stages,
    pois,
    userProgressEntries,
    checklistItems,
    journalEntries,
    weatherCache,
    feedbackQueue,
    trailMeta,
    trailItineraries,
    trailStages,
    trailAccommodations,
    trailPois,
    trailGpxTracks,
    trailGpxPoints,
    trailManifests,
    syncQueue,
    reviewRequests,
    healthInfoEntries,
    followSessions,
    followerSlots,
  ];
}

typedef $$StagesTableCreateCompanionBuilder =
    StagesCompanion Function({
      Value<int> id,
      required String trailId,
      required int stageNumber,
      required String name,
      required double distanceKm,
      required int elevationGainM,
      required int elevationLossM,
      Value<String> description,
      required double startLat,
      required double startLng,
      required double endLat,
      required double endLng,
      Value<String> difficulty,
    });
typedef $$StagesTableUpdateCompanionBuilder =
    StagesCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<int> stageNumber,
      Value<String> name,
      Value<double> distanceKm,
      Value<int> elevationGainM,
      Value<int> elevationLossM,
      Value<String> description,
      Value<double> startLat,
      Value<double> startLng,
      Value<double> endLat,
      Value<double> endLng,
      Value<String> difficulty,
    });

class $$StagesTableFilterComposer
    extends Composer<_$AppDatabase, $StagesTable> {
  $$StagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elevationLossM => $composableBuilder(
    column: $table.elevationLossM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StagesTableOrderingComposer
    extends Composer<_$AppDatabase, $StagesTable> {
  $$StagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elevationLossM => $composableBuilder(
    column: $table.elevationLossM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StagesTable> {
  $$StagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elevationLossM => $composableBuilder(
    column: $table.elevationLossM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get startLat =>
      $composableBuilder(column: $table.startLat, builder: (column) => column);

  GeneratedColumn<double> get startLng =>
      $composableBuilder(column: $table.startLng, builder: (column) => column);

  GeneratedColumn<double> get endLat =>
      $composableBuilder(column: $table.endLat, builder: (column) => column);

  GeneratedColumn<double> get endLng =>
      $composableBuilder(column: $table.endLng, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );
}

class $$StagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StagesTable,
          Stage,
          $$StagesTableFilterComposer,
          $$StagesTableOrderingComposer,
          $$StagesTableAnnotationComposer,
          $$StagesTableCreateCompanionBuilder,
          $$StagesTableUpdateCompanionBuilder,
          (Stage, BaseReferences<_$AppDatabase, $StagesTable, Stage>),
          Stage,
          PrefetchHooks Function()
        > {
  $$StagesTableTableManager(_$AppDatabase db, $StagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<int> stageNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<int> elevationGainM = const Value.absent(),
                Value<int> elevationLossM = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> startLat = const Value.absent(),
                Value<double> startLng = const Value.absent(),
                Value<double> endLat = const Value.absent(),
                Value<double> endLng = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
              }) => StagesCompanion(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                name: name,
                distanceKm: distanceKm,
                elevationGainM: elevationGainM,
                elevationLossM: elevationLossM,
                description: description,
                startLat: startLat,
                startLng: startLng,
                endLat: endLat,
                endLng: endLng,
                difficulty: difficulty,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required int stageNumber,
                required String name,
                required double distanceKm,
                required int elevationGainM,
                required int elevationLossM,
                Value<String> description = const Value.absent(),
                required double startLat,
                required double startLng,
                required double endLat,
                required double endLng,
                Value<String> difficulty = const Value.absent(),
              }) => StagesCompanion.insert(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                name: name,
                distanceKm: distanceKm,
                elevationGainM: elevationGainM,
                elevationLossM: elevationLossM,
                description: description,
                startLat: startLat,
                startLng: startLng,
                endLat: endLat,
                endLng: endLng,
                difficulty: difficulty,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StagesTable,
      Stage,
      $$StagesTableFilterComposer,
      $$StagesTableOrderingComposer,
      $$StagesTableAnnotationComposer,
      $$StagesTableCreateCompanionBuilder,
      $$StagesTableUpdateCompanionBuilder,
      (Stage, BaseReferences<_$AppDatabase, $StagesTable, Stage>),
      Stage,
      PrefetchHooks Function()
    >;
typedef $$PoisTableCreateCompanionBuilder =
    PoisCompanion Function({
      Value<int> id,
      required String trailId,
      required int stageNumber,
      required String name,
      Value<String> description,
      required String type,
      required double lat,
      required double lng,
      Value<int> altitudeM,
      Value<String?> openingHours,
    });
typedef $$PoisTableUpdateCompanionBuilder =
    PoisCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<int> stageNumber,
      Value<String> name,
      Value<String> description,
      Value<String> type,
      Value<double> lat,
      Value<double> lng,
      Value<int> altitudeM,
      Value<String?> openingHours,
    });

class $$PoisTableFilterComposer extends Composer<_$AppDatabase, $PoisTable> {
  $$PoisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingHours => $composableBuilder(
    column: $table.openingHours,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PoisTableOrderingComposer extends Composer<_$AppDatabase, $PoisTable> {
  $$PoisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingHours => $composableBuilder(
    column: $table.openingHours,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PoisTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoisTable> {
  $$PoisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<int> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  GeneratedColumn<String> get openingHours => $composableBuilder(
    column: $table.openingHours,
    builder: (column) => column,
  );
}

class $$PoisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoisTable,
          Poi,
          $$PoisTableFilterComposer,
          $$PoisTableOrderingComposer,
          $$PoisTableAnnotationComposer,
          $$PoisTableCreateCompanionBuilder,
          $$PoisTableUpdateCompanionBuilder,
          (Poi, BaseReferences<_$AppDatabase, $PoisTable, Poi>),
          Poi,
          PrefetchHooks Function()
        > {
  $$PoisTableTableManager(_$AppDatabase db, $PoisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<int> stageNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<int> altitudeM = const Value.absent(),
                Value<String?> openingHours = const Value.absent(),
              }) => PoisCompanion(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                name: name,
                description: description,
                type: type,
                lat: lat,
                lng: lng,
                altitudeM: altitudeM,
                openingHours: openingHours,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required int stageNumber,
                required String name,
                Value<String> description = const Value.absent(),
                required String type,
                required double lat,
                required double lng,
                Value<int> altitudeM = const Value.absent(),
                Value<String?> openingHours = const Value.absent(),
              }) => PoisCompanion.insert(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                name: name,
                description: description,
                type: type,
                lat: lat,
                lng: lng,
                altitudeM: altitudeM,
                openingHours: openingHours,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PoisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoisTable,
      Poi,
      $$PoisTableFilterComposer,
      $$PoisTableOrderingComposer,
      $$PoisTableAnnotationComposer,
      $$PoisTableCreateCompanionBuilder,
      $$PoisTableUpdateCompanionBuilder,
      (Poi, BaseReferences<_$AppDatabase, $PoisTable, Poi>),
      Poi,
      PrefetchHooks Function()
    >;
typedef $$UserProgressEntriesTableCreateCompanionBuilder =
    UserProgressEntriesCompanion Function({
      Value<int> id,
      required String trailId,
      Value<int> currentStage,
      Value<double> totalDistanceWalkedKm,
      Value<int> totalElevationGainedM,
      Value<int> totalTimeMinutes,
      Value<bool> isCompleted,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
    });
typedef $$UserProgressEntriesTableUpdateCompanionBuilder =
    UserProgressEntriesCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<int> currentStage,
      Value<double> totalDistanceWalkedKm,
      Value<int> totalElevationGainedM,
      Value<int> totalTimeMinutes,
      Value<bool> isCompleted,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
    });

class $$UserProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProgressEntriesTable> {
  $$UserProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStage => $composableBuilder(
    column: $table.currentStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistanceWalkedKm => $composableBuilder(
    column: $table.totalDistanceWalkedKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalElevationGainedM => $composableBuilder(
    column: $table.totalElevationGainedM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTimeMinutes => $composableBuilder(
    column: $table.totalTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProgressEntriesTable> {
  $$UserProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStage => $composableBuilder(
    column: $table.currentStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistanceWalkedKm => $composableBuilder(
    column: $table.totalDistanceWalkedKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalElevationGainedM => $composableBuilder(
    column: $table.totalElevationGainedM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTimeMinutes => $composableBuilder(
    column: $table.totalTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProgressEntriesTable> {
  $$UserProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<int> get currentStage => $composableBuilder(
    column: $table.currentStage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistanceWalkedKm => $composableBuilder(
    column: $table.totalDistanceWalkedKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalElevationGainedM => $composableBuilder(
    column: $table.totalElevationGainedM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTimeMinutes => $composableBuilder(
    column: $table.totalTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$UserProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProgressEntriesTable,
          UserProgressEntry,
          $$UserProgressEntriesTableFilterComposer,
          $$UserProgressEntriesTableOrderingComposer,
          $$UserProgressEntriesTableAnnotationComposer,
          $$UserProgressEntriesTableCreateCompanionBuilder,
          $$UserProgressEntriesTableUpdateCompanionBuilder,
          (
            UserProgressEntry,
            BaseReferences<
              _$AppDatabase,
              $UserProgressEntriesTable,
              UserProgressEntry
            >,
          ),
          UserProgressEntry,
          PrefetchHooks Function()
        > {
  $$UserProgressEntriesTableTableManager(
    _$AppDatabase db,
    $UserProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProgressEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProgressEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserProgressEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<int> currentStage = const Value.absent(),
                Value<double> totalDistanceWalkedKm = const Value.absent(),
                Value<int> totalElevationGainedM = const Value.absent(),
                Value<int> totalTimeMinutes = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => UserProgressEntriesCompanion(
                id: id,
                trailId: trailId,
                currentStage: currentStage,
                totalDistanceWalkedKm: totalDistanceWalkedKm,
                totalElevationGainedM: totalElevationGainedM,
                totalTimeMinutes: totalTimeMinutes,
                isCompleted: isCompleted,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                Value<int> currentStage = const Value.absent(),
                Value<double> totalDistanceWalkedKm = const Value.absent(),
                Value<int> totalElevationGainedM = const Value.absent(),
                Value<int> totalTimeMinutes = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => UserProgressEntriesCompanion.insert(
                id: id,
                trailId: trailId,
                currentStage: currentStage,
                totalDistanceWalkedKm: totalDistanceWalkedKm,
                totalElevationGainedM: totalElevationGainedM,
                totalTimeMinutes: totalTimeMinutes,
                isCompleted: isCompleted,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProgressEntriesTable,
      UserProgressEntry,
      $$UserProgressEntriesTableFilterComposer,
      $$UserProgressEntriesTableOrderingComposer,
      $$UserProgressEntriesTableAnnotationComposer,
      $$UserProgressEntriesTableCreateCompanionBuilder,
      $$UserProgressEntriesTableUpdateCompanionBuilder,
      (
        UserProgressEntry,
        BaseReferences<
          _$AppDatabase,
          $UserProgressEntriesTable,
          UserProgressEntry
        >,
      ),
      UserProgressEntry,
      PrefetchHooks Function()
    >;
typedef $$ChecklistItemsTableCreateCompanionBuilder =
    ChecklistItemsCompanion Function({
      Value<int> id,
      required String trailId,
      required String itemId,
      required String category,
      Value<bool> isChecked,
      Value<DateTime?> updatedAt,
    });
typedef $$ChecklistItemsTableUpdateCompanionBuilder =
    ChecklistItemsCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<String> itemId,
      Value<String> category,
      Value<bool> isChecked,
      Value<DateTime?> updatedAt,
    });

class $$ChecklistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChecklistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChecklistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChecklistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistItemsTable,
          ChecklistItem,
          $$ChecklistItemsTableFilterComposer,
          $$ChecklistItemsTableOrderingComposer,
          $$ChecklistItemsTableAnnotationComposer,
          $$ChecklistItemsTableCreateCompanionBuilder,
          $$ChecklistItemsTableUpdateCompanionBuilder,
          (
            ChecklistItem,
            BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem>,
          ),
          ChecklistItem,
          PrefetchHooks Function()
        > {
  $$ChecklistItemsTableTableManager(
    _$AppDatabase db,
    $ChecklistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ChecklistItemsCompanion(
                id: id,
                trailId: trailId,
                itemId: itemId,
                category: category,
                isChecked: isChecked,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required String itemId,
                required String category,
                Value<bool> isChecked = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ChecklistItemsCompanion.insert(
                id: id,
                trailId: trailId,
                itemId: itemId,
                category: category,
                isChecked: isChecked,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChecklistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistItemsTable,
      ChecklistItem,
      $$ChecklistItemsTableFilterComposer,
      $$ChecklistItemsTableOrderingComposer,
      $$ChecklistItemsTableAnnotationComposer,
      $$ChecklistItemsTableCreateCompanionBuilder,
      $$ChecklistItemsTableUpdateCompanionBuilder,
      (
        ChecklistItem,
        BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem>,
      ),
      ChecklistItem,
      PrefetchHooks Function()
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      required String trailId,
      required int stageNumber,
      Value<String> content,
      Value<String?> photoPath,
      Value<int?> photoSizeBytes,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<int> stageNumber,
      Value<String> content,
      Value<String?> photoPath,
      Value<int?> photoSizeBytes,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get photoSizeBytes => $composableBuilder(
    column: $table.photoSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get photoSizeBytes => $composableBuilder(
    column: $table.photoSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<int> get photoSizeBytes => $composableBuilder(
    column: $table.photoSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTable,
          JournalEntry,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalEntry,
            BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>,
          ),
          JournalEntry,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$AppDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<int> stageNumber = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int?> photoSizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                content: content,
                photoPath: photoPath,
                photoSizeBytes: photoSizeBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required int stageNumber,
                Value<String> content = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int?> photoSizeBytes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => JournalEntriesCompanion.insert(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                content: content,
                photoPath: photoPath,
                photoSizeBytes: photoSizeBytes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTable,
      JournalEntry,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalEntry,
        BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>,
      ),
      JournalEntry,
      PrefetchHooks Function()
    >;
typedef $$WeatherCacheTableCreateCompanionBuilder =
    WeatherCacheCompanion Function({
      Value<int> id,
      required String trailId,
      required int stageNumber,
      required String forecastJson,
      required DateTime fetchedAt,
      required DateTime expiresAt,
    });
typedef $$WeatherCacheTableUpdateCompanionBuilder =
    WeatherCacheCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<int> stageNumber,
      Value<String> forecastJson,
      Value<DateTime> fetchedAt,
      Value<DateTime> expiresAt,
    });

class $$WeatherCacheTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherCacheTable> {
  $$WeatherCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forecastJson => $composableBuilder(
    column: $table.forecastJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherCacheTable> {
  $$WeatherCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forecastJson => $composableBuilder(
    column: $table.forecastJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherCacheTable> {
  $$WeatherCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get forecastJson => $composableBuilder(
    column: $table.forecastJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$WeatherCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherCacheTable,
          WeatherCacheData,
          $$WeatherCacheTableFilterComposer,
          $$WeatherCacheTableOrderingComposer,
          $$WeatherCacheTableAnnotationComposer,
          $$WeatherCacheTableCreateCompanionBuilder,
          $$WeatherCacheTableUpdateCompanionBuilder,
          (
            WeatherCacheData,
            BaseReferences<_$AppDatabase, $WeatherCacheTable, WeatherCacheData>,
          ),
          WeatherCacheData,
          PrefetchHooks Function()
        > {
  $$WeatherCacheTableTableManager(_$AppDatabase db, $WeatherCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<int> stageNumber = const Value.absent(),
                Value<String> forecastJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
              }) => WeatherCacheCompanion(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                forecastJson: forecastJson,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required int stageNumber,
                required String forecastJson,
                required DateTime fetchedAt,
                required DateTime expiresAt,
              }) => WeatherCacheCompanion.insert(
                id: id,
                trailId: trailId,
                stageNumber: stageNumber,
                forecastJson: forecastJson,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherCacheTable,
      WeatherCacheData,
      $$WeatherCacheTableFilterComposer,
      $$WeatherCacheTableOrderingComposer,
      $$WeatherCacheTableAnnotationComposer,
      $$WeatherCacheTableCreateCompanionBuilder,
      $$WeatherCacheTableUpdateCompanionBuilder,
      (
        WeatherCacheData,
        BaseReferences<_$AppDatabase, $WeatherCacheTable, WeatherCacheData>,
      ),
      WeatherCacheData,
      PrefetchHooks Function()
    >;
typedef $$FeedbackQueueTableCreateCompanionBuilder =
    FeedbackQueueCompanion Function({
      Value<int> id,
      required String trailId,
      required String feedbackType,
      required String content,
      Value<int?> rating,
      Value<String> status,
      required DateTime createdAt,
      Value<DateTime?> sentAt,
    });
typedef $$FeedbackQueueTableUpdateCompanionBuilder =
    FeedbackQueueCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<String> feedbackType,
      Value<String> content,
      Value<int?> rating,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> sentAt,
    });

class $$FeedbackQueueTableFilterComposer
    extends Composer<_$AppDatabase, $FeedbackQueueTable> {
  $$FeedbackQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedbackType => $composableBuilder(
    column: $table.feedbackType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeedbackQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedbackQueueTable> {
  $$FeedbackQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedbackType => $composableBuilder(
    column: $table.feedbackType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeedbackQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedbackQueueTable> {
  $$FeedbackQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<String> get feedbackType => $composableBuilder(
    column: $table.feedbackType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$FeedbackQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedbackQueueTable,
          FeedbackQueueData,
          $$FeedbackQueueTableFilterComposer,
          $$FeedbackQueueTableOrderingComposer,
          $$FeedbackQueueTableAnnotationComposer,
          $$FeedbackQueueTableCreateCompanionBuilder,
          $$FeedbackQueueTableUpdateCompanionBuilder,
          (
            FeedbackQueueData,
            BaseReferences<
              _$AppDatabase,
              $FeedbackQueueTable,
              FeedbackQueueData
            >,
          ),
          FeedbackQueueData,
          PrefetchHooks Function()
        > {
  $$FeedbackQueueTableTableManager(_$AppDatabase db, $FeedbackQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedbackQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedbackQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedbackQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<String> feedbackType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
              }) => FeedbackQueueCompanion(
                id: id,
                trailId: trailId,
                feedbackType: feedbackType,
                content: content,
                rating: rating,
                status: status,
                createdAt: createdAt,
                sentAt: sentAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required String feedbackType,
                required String content,
                Value<int?> rating = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> sentAt = const Value.absent(),
              }) => FeedbackQueueCompanion.insert(
                id: id,
                trailId: trailId,
                feedbackType: feedbackType,
                content: content,
                rating: rating,
                status: status,
                createdAt: createdAt,
                sentAt: sentAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedbackQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedbackQueueTable,
      FeedbackQueueData,
      $$FeedbackQueueTableFilterComposer,
      $$FeedbackQueueTableOrderingComposer,
      $$FeedbackQueueTableAnnotationComposer,
      $$FeedbackQueueTableCreateCompanionBuilder,
      $$FeedbackQueueTableUpdateCompanionBuilder,
      (
        FeedbackQueueData,
        BaseReferences<_$AppDatabase, $FeedbackQueueTable, FeedbackQueueData>,
      ),
      FeedbackQueueData,
      PrefetchHooks Function()
    >;
typedef $$TrailMetaTableCreateCompanionBuilder =
    TrailMetaCompanion Function({
      required String id,
      required String code,
      required int dataVersion,
      Value<String?> lastSync,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$TrailMetaTableUpdateCompanionBuilder =
    TrailMetaCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<int> dataVersion,
      Value<String?> lastSync,
      Value<String> status,
      Value<int> rowid,
    });

class $$TrailMetaTableFilterComposer
    extends Composer<_$AppDatabase, $TrailMetaTable> {
  $$TrailMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailMetaTable> {
  $$TrailMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailMetaTable> {
  $$TrailMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$TrailMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailMetaTable,
          TrailMetaData,
          $$TrailMetaTableFilterComposer,
          $$TrailMetaTableOrderingComposer,
          $$TrailMetaTableAnnotationComposer,
          $$TrailMetaTableCreateCompanionBuilder,
          $$TrailMetaTableUpdateCompanionBuilder,
          (
            TrailMetaData,
            BaseReferences<_$AppDatabase, $TrailMetaTable, TrailMetaData>,
          ),
          TrailMetaData,
          PrefetchHooks Function()
        > {
  $$TrailMetaTableTableManager(_$AppDatabase db, $TrailMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<int> dataVersion = const Value.absent(),
                Value<String?> lastSync = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailMetaCompanion(
                id: id,
                code: code,
                dataVersion: dataVersion,
                lastSync: lastSync,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required int dataVersion,
                Value<String?> lastSync = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailMetaCompanion.insert(
                id: id,
                code: code,
                dataVersion: dataVersion,
                lastSync: lastSync,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailMetaTable,
      TrailMetaData,
      $$TrailMetaTableFilterComposer,
      $$TrailMetaTableOrderingComposer,
      $$TrailMetaTableAnnotationComposer,
      $$TrailMetaTableCreateCompanionBuilder,
      $$TrailMetaTableUpdateCompanionBuilder,
      (
        TrailMetaData,
        BaseReferences<_$AppDatabase, $TrailMetaTable, TrailMetaData>,
      ),
      TrailMetaData,
      PrefetchHooks Function()
    >;
typedef $$TrailItinerariesTableCreateCompanionBuilder =
    TrailItinerariesCompanion Function({
      required String id,
      required String trailId,
      required String code,
      required String nameFr,
      required String nameEn,
      required String nameDe,
      required String nameIt,
      required String nameEs,
      required double distanceKm,
      required int elevationGain,
      required int stageCount,
      Value<int> rowid,
    });
typedef $$TrailItinerariesTableUpdateCompanionBuilder =
    TrailItinerariesCompanion Function({
      Value<String> id,
      Value<String> trailId,
      Value<String> code,
      Value<String> nameFr,
      Value<String> nameEn,
      Value<String> nameDe,
      Value<String> nameIt,
      Value<String> nameEs,
      Value<double> distanceKm,
      Value<int> elevationGain,
      Value<int> stageCount,
      Value<int> rowid,
    });

class $$TrailItinerariesTableFilterComposer
    extends Composer<_$AppDatabase, $TrailItinerariesTable> {
  $$TrailItinerariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageCount => $composableBuilder(
    column: $table.stageCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailItinerariesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailItinerariesTable> {
  $$TrailItinerariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageCount => $composableBuilder(
    column: $table.stageCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailItinerariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailItinerariesTable> {
  $$TrailItinerariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameDe =>
      $composableBuilder(column: $table.nameDe, builder: (column) => column);

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get nameEs =>
      $composableBuilder(column: $table.nameEs, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stageCount => $composableBuilder(
    column: $table.stageCount,
    builder: (column) => column,
  );
}

class $$TrailItinerariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailItinerariesTable,
          TrailItinerary,
          $$TrailItinerariesTableFilterComposer,
          $$TrailItinerariesTableOrderingComposer,
          $$TrailItinerariesTableAnnotationComposer,
          $$TrailItinerariesTableCreateCompanionBuilder,
          $$TrailItinerariesTableUpdateCompanionBuilder,
          (
            TrailItinerary,
            BaseReferences<
              _$AppDatabase,
              $TrailItinerariesTable,
              TrailItinerary
            >,
          ),
          TrailItinerary,
          PrefetchHooks Function()
        > {
  $$TrailItinerariesTableTableManager(
    _$AppDatabase db,
    $TrailItinerariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailItinerariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailItinerariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailItinerariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameFr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameDe = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String> nameEs = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<int> elevationGain = const Value.absent(),
                Value<int> stageCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailItinerariesCompanion(
                id: id,
                trailId: trailId,
                code: code,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                distanceKm: distanceKm,
                elevationGain: elevationGain,
                stageCount: stageCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String trailId,
                required String code,
                required String nameFr,
                required String nameEn,
                required String nameDe,
                required String nameIt,
                required String nameEs,
                required double distanceKm,
                required int elevationGain,
                required int stageCount,
                Value<int> rowid = const Value.absent(),
              }) => TrailItinerariesCompanion.insert(
                id: id,
                trailId: trailId,
                code: code,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                distanceKm: distanceKm,
                elevationGain: elevationGain,
                stageCount: stageCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailItinerariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailItinerariesTable,
      TrailItinerary,
      $$TrailItinerariesTableFilterComposer,
      $$TrailItinerariesTableOrderingComposer,
      $$TrailItinerariesTableAnnotationComposer,
      $$TrailItinerariesTableCreateCompanionBuilder,
      $$TrailItinerariesTableUpdateCompanionBuilder,
      (
        TrailItinerary,
        BaseReferences<_$AppDatabase, $TrailItinerariesTable, TrailItinerary>,
      ),
      TrailItinerary,
      PrefetchHooks Function()
    >;
typedef $$TrailStagesTableCreateCompanionBuilder =
    TrailStagesCompanion Function({
      required String id,
      required String itineraryId,
      required int stageNumber,
      required String nameFr,
      required String nameEn,
      required String nameDe,
      required String nameIt,
      required String nameEs,
      required double startLat,
      required double startLng,
      required double endLat,
      required double endLng,
      required double distanceKm,
      required int elevationGain,
      required int elevationLoss,
      required int durationMinutes,
      required String difficulty,
      Value<int> rowid,
    });
typedef $$TrailStagesTableUpdateCompanionBuilder =
    TrailStagesCompanion Function({
      Value<String> id,
      Value<String> itineraryId,
      Value<int> stageNumber,
      Value<String> nameFr,
      Value<String> nameEn,
      Value<String> nameDe,
      Value<String> nameIt,
      Value<String> nameEs,
      Value<double> startLat,
      Value<double> startLng,
      Value<double> endLat,
      Value<double> endLng,
      Value<double> distanceKm,
      Value<int> elevationGain,
      Value<int> elevationLoss,
      Value<int> durationMinutes,
      Value<String> difficulty,
      Value<int> rowid,
    });

class $$TrailStagesTableFilterComposer
    extends Composer<_$AppDatabase, $TrailStagesTable> {
  $$TrailStagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elevationLoss => $composableBuilder(
    column: $table.elevationLoss,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailStagesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailStagesTable> {
  $$TrailStagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLat => $composableBuilder(
    column: $table.startLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startLng => $composableBuilder(
    column: $table.startLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLat => $composableBuilder(
    column: $table.endLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endLng => $composableBuilder(
    column: $table.endLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elevationLoss => $composableBuilder(
    column: $table.elevationLoss,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailStagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailStagesTable> {
  $$TrailStagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stageNumber => $composableBuilder(
    column: $table.stageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameDe =>
      $composableBuilder(column: $table.nameDe, builder: (column) => column);

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get nameEs =>
      $composableBuilder(column: $table.nameEs, builder: (column) => column);

  GeneratedColumn<double> get startLat =>
      $composableBuilder(column: $table.startLat, builder: (column) => column);

  GeneratedColumn<double> get startLng =>
      $composableBuilder(column: $table.startLng, builder: (column) => column);

  GeneratedColumn<double> get endLat =>
      $composableBuilder(column: $table.endLat, builder: (column) => column);

  GeneratedColumn<double> get endLng =>
      $composableBuilder(column: $table.endLng, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elevationGain => $composableBuilder(
    column: $table.elevationGain,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elevationLoss => $composableBuilder(
    column: $table.elevationLoss,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );
}

class $$TrailStagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailStagesTable,
          TrailStage,
          $$TrailStagesTableFilterComposer,
          $$TrailStagesTableOrderingComposer,
          $$TrailStagesTableAnnotationComposer,
          $$TrailStagesTableCreateCompanionBuilder,
          $$TrailStagesTableUpdateCompanionBuilder,
          (
            TrailStage,
            BaseReferences<_$AppDatabase, $TrailStagesTable, TrailStage>,
          ),
          TrailStage,
          PrefetchHooks Function()
        > {
  $$TrailStagesTableTableManager(_$AppDatabase db, $TrailStagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailStagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailStagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailStagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itineraryId = const Value.absent(),
                Value<int> stageNumber = const Value.absent(),
                Value<String> nameFr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameDe = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String> nameEs = const Value.absent(),
                Value<double> startLat = const Value.absent(),
                Value<double> startLng = const Value.absent(),
                Value<double> endLat = const Value.absent(),
                Value<double> endLng = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<int> elevationGain = const Value.absent(),
                Value<int> elevationLoss = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailStagesCompanion(
                id: id,
                itineraryId: itineraryId,
                stageNumber: stageNumber,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                startLat: startLat,
                startLng: startLng,
                endLat: endLat,
                endLng: endLng,
                distanceKm: distanceKm,
                elevationGain: elevationGain,
                elevationLoss: elevationLoss,
                durationMinutes: durationMinutes,
                difficulty: difficulty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itineraryId,
                required int stageNumber,
                required String nameFr,
                required String nameEn,
                required String nameDe,
                required String nameIt,
                required String nameEs,
                required double startLat,
                required double startLng,
                required double endLat,
                required double endLng,
                required double distanceKm,
                required int elevationGain,
                required int elevationLoss,
                required int durationMinutes,
                required String difficulty,
                Value<int> rowid = const Value.absent(),
              }) => TrailStagesCompanion.insert(
                id: id,
                itineraryId: itineraryId,
                stageNumber: stageNumber,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                startLat: startLat,
                startLng: startLng,
                endLat: endLat,
                endLng: endLng,
                distanceKm: distanceKm,
                elevationGain: elevationGain,
                elevationLoss: elevationLoss,
                durationMinutes: durationMinutes,
                difficulty: difficulty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailStagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailStagesTable,
      TrailStage,
      $$TrailStagesTableFilterComposer,
      $$TrailStagesTableOrderingComposer,
      $$TrailStagesTableAnnotationComposer,
      $$TrailStagesTableCreateCompanionBuilder,
      $$TrailStagesTableUpdateCompanionBuilder,
      (
        TrailStage,
        BaseReferences<_$AppDatabase, $TrailStagesTable, TrailStage>,
      ),
      TrailStage,
      PrefetchHooks Function()
    >;
typedef $$TrailAccommodationsTableCreateCompanionBuilder =
    TrailAccommodationsCompanion Function({
      required String id,
      required String stageId,
      required String nameFr,
      required String nameEn,
      required String nameDe,
      required String nameIt,
      required String nameEs,
      required String type,
      required double lat,
      required double lng,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> website,
      Value<int?> capacity,
      Value<String?> priceRange,
      Value<String?> bookingUrl,
      Value<int> rowid,
    });
typedef $$TrailAccommodationsTableUpdateCompanionBuilder =
    TrailAccommodationsCompanion Function({
      Value<String> id,
      Value<String> stageId,
      Value<String> nameFr,
      Value<String> nameEn,
      Value<String> nameDe,
      Value<String> nameIt,
      Value<String> nameEs,
      Value<String> type,
      Value<double> lat,
      Value<double> lng,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> website,
      Value<int?> capacity,
      Value<String?> priceRange,
      Value<String?> bookingUrl,
      Value<int> rowid,
    });

class $$TrailAccommodationsTableFilterComposer
    extends Composer<_$AppDatabase, $TrailAccommodationsTable> {
  $$TrailAccommodationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priceRange => $composableBuilder(
    column: $table.priceRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookingUrl => $composableBuilder(
    column: $table.bookingUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailAccommodationsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailAccommodationsTable> {
  $$TrailAccommodationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priceRange => $composableBuilder(
    column: $table.priceRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookingUrl => $composableBuilder(
    column: $table.bookingUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailAccommodationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailAccommodationsTable> {
  $$TrailAccommodationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stageId =>
      $composableBuilder(column: $table.stageId, builder: (column) => column);

  GeneratedColumn<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameDe =>
      $composableBuilder(column: $table.nameDe, builder: (column) => column);

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get nameEs =>
      $composableBuilder(column: $table.nameEs, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get priceRange => $composableBuilder(
    column: $table.priceRange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookingUrl => $composableBuilder(
    column: $table.bookingUrl,
    builder: (column) => column,
  );
}

class $$TrailAccommodationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailAccommodationsTable,
          TrailAccommodation,
          $$TrailAccommodationsTableFilterComposer,
          $$TrailAccommodationsTableOrderingComposer,
          $$TrailAccommodationsTableAnnotationComposer,
          $$TrailAccommodationsTableCreateCompanionBuilder,
          $$TrailAccommodationsTableUpdateCompanionBuilder,
          (
            TrailAccommodation,
            BaseReferences<
              _$AppDatabase,
              $TrailAccommodationsTable,
              TrailAccommodation
            >,
          ),
          TrailAccommodation,
          PrefetchHooks Function()
        > {
  $$TrailAccommodationsTableTableManager(
    _$AppDatabase db,
    $TrailAccommodationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailAccommodationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailAccommodationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TrailAccommodationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> stageId = const Value.absent(),
                Value<String> nameFr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameDe = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String> nameEs = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<int?> capacity = const Value.absent(),
                Value<String?> priceRange = const Value.absent(),
                Value<String?> bookingUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailAccommodationsCompanion(
                id: id,
                stageId: stageId,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                type: type,
                lat: lat,
                lng: lng,
                phone: phone,
                email: email,
                website: website,
                capacity: capacity,
                priceRange: priceRange,
                bookingUrl: bookingUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String stageId,
                required String nameFr,
                required String nameEn,
                required String nameDe,
                required String nameIt,
                required String nameEs,
                required String type,
                required double lat,
                required double lng,
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<int?> capacity = const Value.absent(),
                Value<String?> priceRange = const Value.absent(),
                Value<String?> bookingUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailAccommodationsCompanion.insert(
                id: id,
                stageId: stageId,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                type: type,
                lat: lat,
                lng: lng,
                phone: phone,
                email: email,
                website: website,
                capacity: capacity,
                priceRange: priceRange,
                bookingUrl: bookingUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailAccommodationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailAccommodationsTable,
      TrailAccommodation,
      $$TrailAccommodationsTableFilterComposer,
      $$TrailAccommodationsTableOrderingComposer,
      $$TrailAccommodationsTableAnnotationComposer,
      $$TrailAccommodationsTableCreateCompanionBuilder,
      $$TrailAccommodationsTableUpdateCompanionBuilder,
      (
        TrailAccommodation,
        BaseReferences<
          _$AppDatabase,
          $TrailAccommodationsTable,
          TrailAccommodation
        >,
      ),
      TrailAccommodation,
      PrefetchHooks Function()
    >;
typedef $$TrailPoisTableCreateCompanionBuilder =
    TrailPoisCompanion Function({
      required String id,
      required String stageId,
      required String nameFr,
      required String nameEn,
      required String nameDe,
      required String nameIt,
      required String nameEs,
      Value<String?> descriptionFr,
      Value<String?> descriptionEn,
      Value<String?> descriptionDe,
      Value<String?> descriptionIt,
      Value<String?> descriptionEs,
      required String type,
      required double lat,
      required double lng,
      Value<double?> elevation,
      Value<int> rowid,
    });
typedef $$TrailPoisTableUpdateCompanionBuilder =
    TrailPoisCompanion Function({
      Value<String> id,
      Value<String> stageId,
      Value<String> nameFr,
      Value<String> nameEn,
      Value<String> nameDe,
      Value<String> nameIt,
      Value<String> nameEs,
      Value<String?> descriptionFr,
      Value<String?> descriptionEn,
      Value<String?> descriptionDe,
      Value<String?> descriptionIt,
      Value<String?> descriptionEs,
      Value<String> type,
      Value<double> lat,
      Value<double> lng,
      Value<double?> elevation,
      Value<int> rowid,
    });

class $$TrailPoisTableFilterComposer
    extends Composer<_$AppDatabase, $TrailPoisTable> {
  $$TrailPoisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionFr => $composableBuilder(
    column: $table.descriptionFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionDe => $composableBuilder(
    column: $table.descriptionDe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionIt => $composableBuilder(
    column: $table.descriptionIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionEs => $composableBuilder(
    column: $table.descriptionEs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailPoisTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailPoisTable> {
  $$TrailPoisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameDe => $composableBuilder(
    column: $table.nameDe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEs => $composableBuilder(
    column: $table.nameEs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionFr => $composableBuilder(
    column: $table.descriptionFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionDe => $composableBuilder(
    column: $table.descriptionDe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionIt => $composableBuilder(
    column: $table.descriptionIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionEs => $composableBuilder(
    column: $table.descriptionEs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailPoisTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailPoisTable> {
  $$TrailPoisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stageId =>
      $composableBuilder(column: $table.stageId, builder: (column) => column);

  GeneratedColumn<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameDe =>
      $composableBuilder(column: $table.nameDe, builder: (column) => column);

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get nameEs =>
      $composableBuilder(column: $table.nameEs, builder: (column) => column);

  GeneratedColumn<String> get descriptionFr => $composableBuilder(
    column: $table.descriptionFr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionEn => $composableBuilder(
    column: $table.descriptionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionDe => $composableBuilder(
    column: $table.descriptionDe,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionIt => $composableBuilder(
    column: $table.descriptionIt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descriptionEs => $composableBuilder(
    column: $table.descriptionEs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);
}

class $$TrailPoisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailPoisTable,
          TrailPoi,
          $$TrailPoisTableFilterComposer,
          $$TrailPoisTableOrderingComposer,
          $$TrailPoisTableAnnotationComposer,
          $$TrailPoisTableCreateCompanionBuilder,
          $$TrailPoisTableUpdateCompanionBuilder,
          (TrailPoi, BaseReferences<_$AppDatabase, $TrailPoisTable, TrailPoi>),
          TrailPoi,
          PrefetchHooks Function()
        > {
  $$TrailPoisTableTableManager(_$AppDatabase db, $TrailPoisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailPoisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailPoisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailPoisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> stageId = const Value.absent(),
                Value<String> nameFr = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameDe = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String> nameEs = const Value.absent(),
                Value<String?> descriptionFr = const Value.absent(),
                Value<String?> descriptionEn = const Value.absent(),
                Value<String?> descriptionDe = const Value.absent(),
                Value<String?> descriptionIt = const Value.absent(),
                Value<String?> descriptionEs = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double?> elevation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailPoisCompanion(
                id: id,
                stageId: stageId,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                descriptionFr: descriptionFr,
                descriptionEn: descriptionEn,
                descriptionDe: descriptionDe,
                descriptionIt: descriptionIt,
                descriptionEs: descriptionEs,
                type: type,
                lat: lat,
                lng: lng,
                elevation: elevation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String stageId,
                required String nameFr,
                required String nameEn,
                required String nameDe,
                required String nameIt,
                required String nameEs,
                Value<String?> descriptionFr = const Value.absent(),
                Value<String?> descriptionEn = const Value.absent(),
                Value<String?> descriptionDe = const Value.absent(),
                Value<String?> descriptionIt = const Value.absent(),
                Value<String?> descriptionEs = const Value.absent(),
                required String type,
                required double lat,
                required double lng,
                Value<double?> elevation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailPoisCompanion.insert(
                id: id,
                stageId: stageId,
                nameFr: nameFr,
                nameEn: nameEn,
                nameDe: nameDe,
                nameIt: nameIt,
                nameEs: nameEs,
                descriptionFr: descriptionFr,
                descriptionEn: descriptionEn,
                descriptionDe: descriptionDe,
                descriptionIt: descriptionIt,
                descriptionEs: descriptionEs,
                type: type,
                lat: lat,
                lng: lng,
                elevation: elevation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailPoisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailPoisTable,
      TrailPoi,
      $$TrailPoisTableFilterComposer,
      $$TrailPoisTableOrderingComposer,
      $$TrailPoisTableAnnotationComposer,
      $$TrailPoisTableCreateCompanionBuilder,
      $$TrailPoisTableUpdateCompanionBuilder,
      (TrailPoi, BaseReferences<_$AppDatabase, $TrailPoisTable, TrailPoi>),
      TrailPoi,
      PrefetchHooks Function()
    >;
typedef $$TrailGpxTracksTableCreateCompanionBuilder =
    TrailGpxTracksCompanion Function({
      required String id,
      required String itineraryId,
      required String name,
      Value<String?> sourceUrl,
      Value<int> rowid,
    });
typedef $$TrailGpxTracksTableUpdateCompanionBuilder =
    TrailGpxTracksCompanion Function({
      Value<String> id,
      Value<String> itineraryId,
      Value<String> name,
      Value<String?> sourceUrl,
      Value<int> rowid,
    });

class $$TrailGpxTracksTableFilterComposer
    extends Composer<_$AppDatabase, $TrailGpxTracksTable> {
  $$TrailGpxTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailGpxTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailGpxTracksTable> {
  $$TrailGpxTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailGpxTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailGpxTracksTable> {
  $$TrailGpxTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);
}

class $$TrailGpxTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailGpxTracksTable,
          TrailGpxTrack,
          $$TrailGpxTracksTableFilterComposer,
          $$TrailGpxTracksTableOrderingComposer,
          $$TrailGpxTracksTableAnnotationComposer,
          $$TrailGpxTracksTableCreateCompanionBuilder,
          $$TrailGpxTracksTableUpdateCompanionBuilder,
          (
            TrailGpxTrack,
            BaseReferences<_$AppDatabase, $TrailGpxTracksTable, TrailGpxTrack>,
          ),
          TrailGpxTrack,
          PrefetchHooks Function()
        > {
  $$TrailGpxTracksTableTableManager(
    _$AppDatabase db,
    $TrailGpxTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailGpxTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailGpxTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailGpxTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itineraryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailGpxTracksCompanion(
                id: id,
                itineraryId: itineraryId,
                name: name,
                sourceUrl: sourceUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itineraryId,
                required String name,
                Value<String?> sourceUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailGpxTracksCompanion.insert(
                id: id,
                itineraryId: itineraryId,
                name: name,
                sourceUrl: sourceUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailGpxTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailGpxTracksTable,
      TrailGpxTrack,
      $$TrailGpxTracksTableFilterComposer,
      $$TrailGpxTracksTableOrderingComposer,
      $$TrailGpxTracksTableAnnotationComposer,
      $$TrailGpxTracksTableCreateCompanionBuilder,
      $$TrailGpxTracksTableUpdateCompanionBuilder,
      (
        TrailGpxTrack,
        BaseReferences<_$AppDatabase, $TrailGpxTracksTable, TrailGpxTrack>,
      ),
      TrailGpxTrack,
      PrefetchHooks Function()
    >;
typedef $$TrailGpxPointsTableCreateCompanionBuilder =
    TrailGpxPointsCompanion Function({
      Value<int> id,
      required String trackId,
      required double lat,
      required double lng,
      required double elevation,
      required int sequenceIndex,
    });
typedef $$TrailGpxPointsTableUpdateCompanionBuilder =
    TrailGpxPointsCompanion Function({
      Value<int> id,
      Value<String> trackId,
      Value<double> lat,
      Value<double> lng,
      Value<double> elevation,
      Value<int> sequenceIndex,
    });

class $$TrailGpxPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrailGpxPointsTable> {
  $$TrailGpxPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailGpxPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailGpxPointsTable> {
  $$TrailGpxPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevation => $composableBuilder(
    column: $table.elevation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailGpxPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailGpxPointsTable> {
  $$TrailGpxPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => column,
  );
}

class $$TrailGpxPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailGpxPointsTable,
          TrailGpxPoint,
          $$TrailGpxPointsTableFilterComposer,
          $$TrailGpxPointsTableOrderingComposer,
          $$TrailGpxPointsTableAnnotationComposer,
          $$TrailGpxPointsTableCreateCompanionBuilder,
          $$TrailGpxPointsTableUpdateCompanionBuilder,
          (
            TrailGpxPoint,
            BaseReferences<_$AppDatabase, $TrailGpxPointsTable, TrailGpxPoint>,
          ),
          TrailGpxPoint,
          PrefetchHooks Function()
        > {
  $$TrailGpxPointsTableTableManager(
    _$AppDatabase db,
    $TrailGpxPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailGpxPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailGpxPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailGpxPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double> elevation = const Value.absent(),
                Value<int> sequenceIndex = const Value.absent(),
              }) => TrailGpxPointsCompanion(
                id: id,
                trackId: trackId,
                lat: lat,
                lng: lng,
                elevation: elevation,
                sequenceIndex: sequenceIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trackId,
                required double lat,
                required double lng,
                required double elevation,
                required int sequenceIndex,
              }) => TrailGpxPointsCompanion.insert(
                id: id,
                trackId: trackId,
                lat: lat,
                lng: lng,
                elevation: elevation,
                sequenceIndex: sequenceIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailGpxPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailGpxPointsTable,
      TrailGpxPoint,
      $$TrailGpxPointsTableFilterComposer,
      $$TrailGpxPointsTableOrderingComposer,
      $$TrailGpxPointsTableAnnotationComposer,
      $$TrailGpxPointsTableCreateCompanionBuilder,
      $$TrailGpxPointsTableUpdateCompanionBuilder,
      (
        TrailGpxPoint,
        BaseReferences<_$AppDatabase, $TrailGpxPointsTable, TrailGpxPoint>,
      ),
      TrailGpxPoint,
      PrefetchHooks Function()
    >;
typedef $$TrailManifestsTableCreateCompanionBuilder =
    TrailManifestsCompanion Function({
      required String trailId,
      required int dataVersion,
      required String hash,
      required String filePath,
      required int fileSize,
      required String status,
      required String lastUpdated,
      Value<int?> localVersion,
      Value<int> rowid,
    });
typedef $$TrailManifestsTableUpdateCompanionBuilder =
    TrailManifestsCompanion Function({
      Value<String> trailId,
      Value<int> dataVersion,
      Value<String> hash,
      Value<String> filePath,
      Value<int> fileSize,
      Value<String> status,
      Value<String> lastUpdated,
      Value<int?> localVersion,
      Value<int> rowid,
    });

class $$TrailManifestsTableFilterComposer
    extends Composer<_$AppDatabase, $TrailManifestsTable> {
  $$TrailManifestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailManifestsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrailManifestsTable> {
  $$TrailManifestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailManifestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrailManifestsTable> {
  $$TrailManifestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );
}

class $$TrailManifestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrailManifestsTable,
          TrailManifest,
          $$TrailManifestsTableFilterComposer,
          $$TrailManifestsTableOrderingComposer,
          $$TrailManifestsTableAnnotationComposer,
          $$TrailManifestsTableCreateCompanionBuilder,
          $$TrailManifestsTableUpdateCompanionBuilder,
          (
            TrailManifest,
            BaseReferences<_$AppDatabase, $TrailManifestsTable, TrailManifest>,
          ),
          TrailManifest,
          PrefetchHooks Function()
        > {
  $$TrailManifestsTableTableManager(
    _$AppDatabase db,
    $TrailManifestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailManifestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailManifestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailManifestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trailId = const Value.absent(),
                Value<int> dataVersion = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> lastUpdated = const Value.absent(),
                Value<int?> localVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailManifestsCompanion(
                trailId: trailId,
                dataVersion: dataVersion,
                hash: hash,
                filePath: filePath,
                fileSize: fileSize,
                status: status,
                lastUpdated: lastUpdated,
                localVersion: localVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trailId,
                required int dataVersion,
                required String hash,
                required String filePath,
                required int fileSize,
                required String status,
                required String lastUpdated,
                Value<int?> localVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailManifestsCompanion.insert(
                trailId: trailId,
                dataVersion: dataVersion,
                hash: hash,
                filePath: filePath,
                fileSize: fileSize,
                status: status,
                lastUpdated: lastUpdated,
                localVersion: localVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailManifestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrailManifestsTable,
      TrailManifest,
      $$TrailManifestsTableFilterComposer,
      $$TrailManifestsTableOrderingComposer,
      $$TrailManifestsTableAnnotationComposer,
      $$TrailManifestsTableCreateCompanionBuilder,
      $$TrailManifestsTableUpdateCompanionBuilder,
      (
        TrailManifest,
        BaseReferences<_$AppDatabase, $TrailManifestsTable, TrailManifest>,
      ),
      TrailManifest,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String trailId,
      required String action,
      Value<String> status,
      Value<String?> payload,
      required String createdAt,
      Value<String?> completedAt,
      Value<int> retryCount,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<String> action,
      Value<String> status,
      Value<String?> payload,
      Value<String> createdAt,
      Value<String?> completedAt,
      Value<int> retryCount,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                trailId: trailId,
                action: action,
                status: status,
                payload: payload,
                createdAt: createdAt,
                completedAt: completedAt,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required String action,
                Value<String> status = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                required String createdAt,
                Value<String?> completedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                trailId: trailId,
                action: action,
                status: status,
                payload: payload,
                createdAt: createdAt,
                completedAt: completedAt,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$ReviewRequestsTableCreateCompanionBuilder =
    ReviewRequestsCompanion Function({
      Value<int> id,
      required String trailId,
      required DateTime requestedAt,
    });
typedef $$ReviewRequestsTableUpdateCompanionBuilder =
    ReviewRequestsCompanion Function({
      Value<int> id,
      Value<String> trailId,
      Value<DateTime> requestedAt,
    });

class $$ReviewRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewRequestsTable> {
  $$ReviewRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewRequestsTable> {
  $$ReviewRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trailId => $composableBuilder(
    column: $table.trailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewRequestsTable> {
  $$ReviewRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );
}

class $$ReviewRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewRequestsTable,
          ReviewRequest,
          $$ReviewRequestsTableFilterComposer,
          $$ReviewRequestsTableOrderingComposer,
          $$ReviewRequestsTableAnnotationComposer,
          $$ReviewRequestsTableCreateCompanionBuilder,
          $$ReviewRequestsTableUpdateCompanionBuilder,
          (
            ReviewRequest,
            BaseReferences<_$AppDatabase, $ReviewRequestsTable, ReviewRequest>,
          ),
          ReviewRequest,
          PrefetchHooks Function()
        > {
  $$ReviewRequestsTableTableManager(
    _$AppDatabase db,
    $ReviewRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trailId = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
              }) => ReviewRequestsCompanion(
                id: id,
                trailId: trailId,
                requestedAt: requestedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trailId,
                required DateTime requestedAt,
              }) => ReviewRequestsCompanion.insert(
                id: id,
                trailId: trailId,
                requestedAt: requestedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewRequestsTable,
      ReviewRequest,
      $$ReviewRequestsTableFilterComposer,
      $$ReviewRequestsTableOrderingComposer,
      $$ReviewRequestsTableAnnotationComposer,
      $$ReviewRequestsTableCreateCompanionBuilder,
      $$ReviewRequestsTableUpdateCompanionBuilder,
      (
        ReviewRequest,
        BaseReferences<_$AppDatabase, $ReviewRequestsTable, ReviewRequest>,
      ),
      ReviewRequest,
      PrefetchHooks Function()
    >;
typedef $$HealthInfoEntriesTableCreateCompanionBuilder =
    HealthInfoEntriesCompanion Function({
      Value<int> id,
      Value<String> bloodType,
      Value<String> allergies,
      Value<String> treatments,
      Value<String> doctorContact,
      Value<String> insuranceNumber,
    });
typedef $$HealthInfoEntriesTableUpdateCompanionBuilder =
    HealthInfoEntriesCompanion Function({
      Value<int> id,
      Value<String> bloodType,
      Value<String> allergies,
      Value<String> treatments,
      Value<String> doctorContact,
      Value<String> insuranceNumber,
    });

class $$HealthInfoEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HealthInfoEntriesTable> {
  $$HealthInfoEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bloodType => $composableBuilder(
    column: $table.bloodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treatments => $composableBuilder(
    column: $table.treatments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctorContact => $composableBuilder(
    column: $table.doctorContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get insuranceNumber => $composableBuilder(
    column: $table.insuranceNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthInfoEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthInfoEntriesTable> {
  $$HealthInfoEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bloodType => $composableBuilder(
    column: $table.bloodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treatments => $composableBuilder(
    column: $table.treatments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctorContact => $composableBuilder(
    column: $table.doctorContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get insuranceNumber => $composableBuilder(
    column: $table.insuranceNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthInfoEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthInfoEntriesTable> {
  $$HealthInfoEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bloodType =>
      $composableBuilder(column: $table.bloodType, builder: (column) => column);

  GeneratedColumn<String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<String> get treatments => $composableBuilder(
    column: $table.treatments,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doctorContact => $composableBuilder(
    column: $table.doctorContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get insuranceNumber => $composableBuilder(
    column: $table.insuranceNumber,
    builder: (column) => column,
  );
}

class $$HealthInfoEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthInfoEntriesTable,
          HealthInfoEntry,
          $$HealthInfoEntriesTableFilterComposer,
          $$HealthInfoEntriesTableOrderingComposer,
          $$HealthInfoEntriesTableAnnotationComposer,
          $$HealthInfoEntriesTableCreateCompanionBuilder,
          $$HealthInfoEntriesTableUpdateCompanionBuilder,
          (
            HealthInfoEntry,
            BaseReferences<
              _$AppDatabase,
              $HealthInfoEntriesTable,
              HealthInfoEntry
            >,
          ),
          HealthInfoEntry,
          PrefetchHooks Function()
        > {
  $$HealthInfoEntriesTableTableManager(
    _$AppDatabase db,
    $HealthInfoEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthInfoEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthInfoEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthInfoEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bloodType = const Value.absent(),
                Value<String> allergies = const Value.absent(),
                Value<String> treatments = const Value.absent(),
                Value<String> doctorContact = const Value.absent(),
                Value<String> insuranceNumber = const Value.absent(),
              }) => HealthInfoEntriesCompanion(
                id: id,
                bloodType: bloodType,
                allergies: allergies,
                treatments: treatments,
                doctorContact: doctorContact,
                insuranceNumber: insuranceNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bloodType = const Value.absent(),
                Value<String> allergies = const Value.absent(),
                Value<String> treatments = const Value.absent(),
                Value<String> doctorContact = const Value.absent(),
                Value<String> insuranceNumber = const Value.absent(),
              }) => HealthInfoEntriesCompanion.insert(
                id: id,
                bloodType: bloodType,
                allergies: allergies,
                treatments: treatments,
                doctorContact: doctorContact,
                insuranceNumber: insuranceNumber,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthInfoEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthInfoEntriesTable,
      HealthInfoEntry,
      $$HealthInfoEntriesTableFilterComposer,
      $$HealthInfoEntriesTableOrderingComposer,
      $$HealthInfoEntriesTableAnnotationComposer,
      $$HealthInfoEntriesTableCreateCompanionBuilder,
      $$HealthInfoEntriesTableUpdateCompanionBuilder,
      (
        HealthInfoEntry,
        BaseReferences<_$AppDatabase, $HealthInfoEntriesTable, HealthInfoEntry>,
      ),
      HealthInfoEntry,
      PrefetchHooks Function()
    >;
typedef $$FollowSessionsTableCreateCompanionBuilder =
    FollowSessionsCompanion Function({
      required String id,
      required String trekkerUserId,
      required String shareCode,
      required String createdAt,
      required String expiresAt,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$FollowSessionsTableUpdateCompanionBuilder =
    FollowSessionsCompanion Function({
      Value<String> id,
      Value<String> trekkerUserId,
      Value<String> shareCode,
      Value<String> createdAt,
      Value<String> expiresAt,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$FollowSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FollowSessionsTable> {
  $$FollowSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trekkerUserId => $composableBuilder(
    column: $table.trekkerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareCode => $composableBuilder(
    column: $table.shareCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowSessionsTable> {
  $$FollowSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trekkerUserId => $composableBuilder(
    column: $table.trekkerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareCode => $composableBuilder(
    column: $table.shareCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowSessionsTable> {
  $$FollowSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trekkerUserId => $composableBuilder(
    column: $table.trekkerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shareCode =>
      $composableBuilder(column: $table.shareCode, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$FollowSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowSessionsTable,
          FollowSessionRow,
          $$FollowSessionsTableFilterComposer,
          $$FollowSessionsTableOrderingComposer,
          $$FollowSessionsTableAnnotationComposer,
          $$FollowSessionsTableCreateCompanionBuilder,
          $$FollowSessionsTableUpdateCompanionBuilder,
          (
            FollowSessionRow,
            BaseReferences<
              _$AppDatabase,
              $FollowSessionsTable,
              FollowSessionRow
            >,
          ),
          FollowSessionRow,
          PrefetchHooks Function()
        > {
  $$FollowSessionsTableTableManager(
    _$AppDatabase db,
    $FollowSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> trekkerUserId = const Value.absent(),
                Value<String> shareCode = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> expiresAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowSessionsCompanion(
                id: id,
                trekkerUserId: trekkerUserId,
                shareCode: shareCode,
                createdAt: createdAt,
                expiresAt: expiresAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String trekkerUserId,
                required String shareCode,
                required String createdAt,
                required String expiresAt,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowSessionsCompanion.insert(
                id: id,
                trekkerUserId: trekkerUserId,
                shareCode: shareCode,
                createdAt: createdAt,
                expiresAt: expiresAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowSessionsTable,
      FollowSessionRow,
      $$FollowSessionsTableFilterComposer,
      $$FollowSessionsTableOrderingComposer,
      $$FollowSessionsTableAnnotationComposer,
      $$FollowSessionsTableCreateCompanionBuilder,
      $$FollowSessionsTableUpdateCompanionBuilder,
      (
        FollowSessionRow,
        BaseReferences<_$AppDatabase, $FollowSessionsTable, FollowSessionRow>,
      ),
      FollowSessionRow,
      PrefetchHooks Function()
    >;
typedef $$FollowerSlotsTableCreateCompanionBuilder =
    FollowerSlotsCompanion Function({
      required String id,
      required String sessionId,
      required String followerName,
      Value<bool> isPaid,
      Value<bool> adSupported,
      Value<int> rowid,
    });
typedef $$FollowerSlotsTableUpdateCompanionBuilder =
    FollowerSlotsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> followerName,
      Value<bool> isPaid,
      Value<bool> adSupported,
      Value<int> rowid,
    });

class $$FollowerSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $FollowerSlotsTable> {
  $$FollowerSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followerName => $composableBuilder(
    column: $table.followerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get adSupported => $composableBuilder(
    column: $table.adSupported,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowerSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowerSlotsTable> {
  $$FollowerSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followerName => $composableBuilder(
    column: $table.followerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaid => $composableBuilder(
    column: $table.isPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get adSupported => $composableBuilder(
    column: $table.adSupported,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowerSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowerSlotsTable> {
  $$FollowerSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get followerName => $composableBuilder(
    column: $table.followerName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaid =>
      $composableBuilder(column: $table.isPaid, builder: (column) => column);

  GeneratedColumn<bool> get adSupported => $composableBuilder(
    column: $table.adSupported,
    builder: (column) => column,
  );
}

class $$FollowerSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowerSlotsTable,
          FollowerSlotRow,
          $$FollowerSlotsTableFilterComposer,
          $$FollowerSlotsTableOrderingComposer,
          $$FollowerSlotsTableAnnotationComposer,
          $$FollowerSlotsTableCreateCompanionBuilder,
          $$FollowerSlotsTableUpdateCompanionBuilder,
          (
            FollowerSlotRow,
            BaseReferences<_$AppDatabase, $FollowerSlotsTable, FollowerSlotRow>,
          ),
          FollowerSlotRow,
          PrefetchHooks Function()
        > {
  $$FollowerSlotsTableTableManager(_$AppDatabase db, $FollowerSlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowerSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowerSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowerSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> followerName = const Value.absent(),
                Value<bool> isPaid = const Value.absent(),
                Value<bool> adSupported = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowerSlotsCompanion(
                id: id,
                sessionId: sessionId,
                followerName: followerName,
                isPaid: isPaid,
                adSupported: adSupported,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String followerName,
                Value<bool> isPaid = const Value.absent(),
                Value<bool> adSupported = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowerSlotsCompanion.insert(
                id: id,
                sessionId: sessionId,
                followerName: followerName,
                isPaid: isPaid,
                adSupported: adSupported,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowerSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowerSlotsTable,
      FollowerSlotRow,
      $$FollowerSlotsTableFilterComposer,
      $$FollowerSlotsTableOrderingComposer,
      $$FollowerSlotsTableAnnotationComposer,
      $$FollowerSlotsTableCreateCompanionBuilder,
      $$FollowerSlotsTableUpdateCompanionBuilder,
      (
        FollowerSlotRow,
        BaseReferences<_$AppDatabase, $FollowerSlotsTable, FollowerSlotRow>,
      ),
      FollowerSlotRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StagesTableTableManager get stages =>
      $$StagesTableTableManager(_db, _db.stages);
  $$PoisTableTableManager get pois => $$PoisTableTableManager(_db, _db.pois);
  $$UserProgressEntriesTableTableManager get userProgressEntries =>
      $$UserProgressEntriesTableTableManager(_db, _db.userProgressEntries);
  $$ChecklistItemsTableTableManager get checklistItems =>
      $$ChecklistItemsTableTableManager(_db, _db.checklistItems);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$WeatherCacheTableTableManager get weatherCache =>
      $$WeatherCacheTableTableManager(_db, _db.weatherCache);
  $$FeedbackQueueTableTableManager get feedbackQueue =>
      $$FeedbackQueueTableTableManager(_db, _db.feedbackQueue);
  $$TrailMetaTableTableManager get trailMeta =>
      $$TrailMetaTableTableManager(_db, _db.trailMeta);
  $$TrailItinerariesTableTableManager get trailItineraries =>
      $$TrailItinerariesTableTableManager(_db, _db.trailItineraries);
  $$TrailStagesTableTableManager get trailStages =>
      $$TrailStagesTableTableManager(_db, _db.trailStages);
  $$TrailAccommodationsTableTableManager get trailAccommodations =>
      $$TrailAccommodationsTableTableManager(_db, _db.trailAccommodations);
  $$TrailPoisTableTableManager get trailPois =>
      $$TrailPoisTableTableManager(_db, _db.trailPois);
  $$TrailGpxTracksTableTableManager get trailGpxTracks =>
      $$TrailGpxTracksTableTableManager(_db, _db.trailGpxTracks);
  $$TrailGpxPointsTableTableManager get trailGpxPoints =>
      $$TrailGpxPointsTableTableManager(_db, _db.trailGpxPoints);
  $$TrailManifestsTableTableManager get trailManifests =>
      $$TrailManifestsTableTableManager(_db, _db.trailManifests);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$ReviewRequestsTableTableManager get reviewRequests =>
      $$ReviewRequestsTableTableManager(_db, _db.reviewRequests);
  $$HealthInfoEntriesTableTableManager get healthInfoEntries =>
      $$HealthInfoEntriesTableTableManager(_db, _db.healthInfoEntries);
  $$FollowSessionsTableTableManager get followSessions =>
      $$FollowSessionsTableTableManager(_db, _db.followSessions);
  $$FollowerSlotsTableTableManager get followerSlots =>
      $$FollowerSlotsTableTableManager(_db, _db.followerSlots);
}
