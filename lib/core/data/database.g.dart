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
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trailIdMeta =
      const VerificationMeta('trailId');
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
      'trail_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stageNumberMeta =
      const VerificationMeta('stageNumber');
  @override
  late final GeneratedColumn<int> stageNumber = GeneratedColumn<int>(
      'stage_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distanceKmMeta =
      const VerificationMeta('distanceKm');
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
      'distance_km', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _elevationGainMMeta =
      const VerificationMeta('elevationGainM');
  @override
  late final GeneratedColumn<int> elevationGainM = GeneratedColumn<int>(
      'elevation_gain_m', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _elevationLossMMeta =
      const VerificationMeta('elevationLossM');
  @override
  late final GeneratedColumn<int> elevationLossM = GeneratedColumn<int>(
      'elevation_loss_m', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _startLatMeta =
      const VerificationMeta('startLat');
  @override
  late final GeneratedColumn<double> startLat = GeneratedColumn<double>(
      'start_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _startLngMeta =
      const VerificationMeta('startLng');
  @override
  late final GeneratedColumn<double> startLng = GeneratedColumn<double>(
      'start_lng', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _endLatMeta = const VerificationMeta('endLat');
  @override
  late final GeneratedColumn<double> endLat = GeneratedColumn<double>(
      'end_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _endLngMeta = const VerificationMeta('endLng');
  @override
  late final GeneratedColumn<double> endLng = GeneratedColumn<double>(
      'end_lng', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('moderate'));
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
        difficulty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stages';
  @override
  VerificationContext validateIntegrity(Insertable<Stage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(_trailIdMeta,
          trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta));
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('stage_number')) {
      context.handle(
          _stageNumberMeta,
          stageNumber.isAcceptableOrUnknown(
              data['stage_number']!, _stageNumberMeta));
    } else if (isInserting) {
      context.missing(_stageNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('distance_km')) {
      context.handle(
          _distanceKmMeta,
          distanceKm.isAcceptableOrUnknown(
              data['distance_km']!, _distanceKmMeta));
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('elevation_gain_m')) {
      context.handle(
          _elevationGainMMeta,
          elevationGainM.isAcceptableOrUnknown(
              data['elevation_gain_m']!, _elevationGainMMeta));
    } else if (isInserting) {
      context.missing(_elevationGainMMeta);
    }
    if (data.containsKey('elevation_loss_m')) {
      context.handle(
          _elevationLossMMeta,
          elevationLossM.isAcceptableOrUnknown(
              data['elevation_loss_m']!, _elevationLossMMeta));
    } else if (isInserting) {
      context.missing(_elevationLossMMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_lat')) {
      context.handle(_startLatMeta,
          startLat.isAcceptableOrUnknown(data['start_lat']!, _startLatMeta));
    } else if (isInserting) {
      context.missing(_startLatMeta);
    }
    if (data.containsKey('start_lng')) {
      context.handle(_startLngMeta,
          startLng.isAcceptableOrUnknown(data['start_lng']!, _startLngMeta));
    } else if (isInserting) {
      context.missing(_startLngMeta);
    }
    if (data.containsKey('end_lat')) {
      context.handle(_endLatMeta,
          endLat.isAcceptableOrUnknown(data['end_lat']!, _endLatMeta));
    } else if (isInserting) {
      context.missing(_endLatMeta);
    }
    if (data.containsKey('end_lng')) {
      context.handle(_endLngMeta,
          endLng.isAcceptableOrUnknown(data['end_lng']!, _endLngMeta));
    } else if (isInserting) {
      context.missing(_endLngMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trailId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trail_id'])!,
      stageNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stage_number'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      distanceKm: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_km'])!,
      elevationGainM: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elevation_gain_m'])!,
      elevationLossM: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elevation_loss_m'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      startLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_lat'])!,
      startLng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}start_lng'])!,
      endLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}end_lat'])!,
      endLng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}end_lng'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
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

  /// Identifiant du sentier parent (ex: 'mare_a_mare')
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
  const Stage(
      {required this.id,
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
      required this.difficulty});
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

  factory Stage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  Stage copyWith(
          {int? id,
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
          String? difficulty}) =>
      Stage(
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
      stageNumber:
          data.stageNumber.present ? data.stageNumber.value : this.stageNumber,
      name: data.name.present ? data.name.value : this.name,
      distanceKm:
          data.distanceKm.present ? data.distanceKm.value : this.distanceKm,
      elevationGainM: data.elevationGainM.present
          ? data.elevationGainM.value
          : this.elevationGainM,
      elevationLossM: data.elevationLossM.present
          ? data.elevationLossM.value
          : this.elevationLossM,
      description:
          data.description.present ? data.description.value : this.description,
      startLat: data.startLat.present ? data.startLat.value : this.startLat,
      startLng: data.startLng.present ? data.startLng.value : this.startLng,
      endLat: data.endLat.present ? data.endLat.value : this.endLat,
      endLng: data.endLng.present ? data.endLng.value : this.endLng,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
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
      difficulty);
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
  })  : trailId = Value(trailId),
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

  StagesCompanion copyWith(
      {Value<int>? id,
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
      Value<String>? difficulty}) {
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
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trailIdMeta =
      const VerificationMeta('trailId');
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
      'trail_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stageNumberMeta =
      const VerificationMeta('stageNumber');
  @override
  late final GeneratedColumn<int> stageNumber = GeneratedColumn<int>(
      'stage_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
      'lng', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _altitudeMMeta =
      const VerificationMeta('altitudeM');
  @override
  late final GeneratedColumn<int> altitudeM = GeneratedColumn<int>(
      'altitude_m', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _openingHoursMeta =
      const VerificationMeta('openingHours');
  @override
  late final GeneratedColumn<String> openingHours = GeneratedColumn<String>(
      'opening_hours', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        openingHours
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pois';
  @override
  VerificationContext validateIntegrity(Insertable<Poi> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(_trailIdMeta,
          trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta));
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('stage_number')) {
      context.handle(
          _stageNumberMeta,
          stageNumber.isAcceptableOrUnknown(
              data['stage_number']!, _stageNumberMeta));
    } else if (isInserting) {
      context.missing(_stageNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
          _lngMeta, lng.isAcceptableOrUnknown(data['lng']!, _lngMeta));
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('altitude_m')) {
      context.handle(_altitudeMMeta,
          altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta));
    }
    if (data.containsKey('opening_hours')) {
      context.handle(
          _openingHoursMeta,
          openingHours.isAcceptableOrUnknown(
              data['opening_hours']!, _openingHoursMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Poi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Poi(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trailId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trail_id'])!,
      stageNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stage_number'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lng'])!,
      altitudeM: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}altitude_m'])!,
      openingHours: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opening_hours']),
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
  const Poi(
      {required this.id,
      required this.trailId,
      required this.stageNumber,
      required this.name,
      required this.description,
      required this.type,
      required this.lat,
      required this.lng,
      required this.altitudeM,
      this.openingHours});
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

  factory Poi.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  Poi copyWith(
          {int? id,
          String? trailId,
          int? stageNumber,
          String? name,
          String? description,
          String? type,
          double? lat,
          double? lng,
          int? altitudeM,
          Value<String?> openingHours = const Value.absent()}) =>
      Poi(
        id: id ?? this.id,
        trailId: trailId ?? this.trailId,
        stageNumber: stageNumber ?? this.stageNumber,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        altitudeM: altitudeM ?? this.altitudeM,
        openingHours:
            openingHours.present ? openingHours.value : this.openingHours,
      );
  Poi copyWithCompanion(PoisCompanion data) {
    return Poi(
      id: data.id.present ? data.id.value : this.id,
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      stageNumber:
          data.stageNumber.present ? data.stageNumber.value : this.stageNumber,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
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
  int get hashCode => Object.hash(id, trailId, stageNumber, name, description,
      type, lat, lng, altitudeM, openingHours);
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
  })  : trailId = Value(trailId),
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

  PoisCompanion copyWith(
      {Value<int>? id,
      Value<String>? trailId,
      Value<int>? stageNumber,
      Value<String>? name,
      Value<String>? description,
      Value<String>? type,
      Value<double>? lat,
      Value<double>? lng,
      Value<int>? altitudeM,
      Value<String?>? openingHours}) {
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
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trailIdMeta =
      const VerificationMeta('trailId');
  @override
  late final GeneratedColumn<String> trailId =
      GeneratedColumn<String>('trail_id', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _currentStageMeta =
      const VerificationMeta('currentStage');
  @override
  late final GeneratedColumn<int> currentStage = GeneratedColumn<int>(
      'current_stage', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _totalDistanceWalkedKmMeta =
      const VerificationMeta('totalDistanceWalkedKm');
  @override
  late final GeneratedColumn<double> totalDistanceWalkedKm =
      GeneratedColumn<double>('total_distance_walked_km', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _totalElevationGainedMMeta =
      const VerificationMeta('totalElevationGainedM');
  @override
  late final GeneratedColumn<int> totalElevationGainedM = GeneratedColumn<int>(
      'total_elevation_gained_m', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        trailId,
        currentStage,
        totalDistanceWalkedKm,
        totalElevationGainedM,
        isCompleted,
        startedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_progress_entries';
  @override
  VerificationContext validateIntegrity(Insertable<UserProgressEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trail_id')) {
      context.handle(_trailIdMeta,
          trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta));
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('current_stage')) {
      context.handle(
          _currentStageMeta,
          currentStage.isAcceptableOrUnknown(
              data['current_stage']!, _currentStageMeta));
    }
    if (data.containsKey('total_distance_walked_km')) {
      context.handle(
          _totalDistanceWalkedKmMeta,
          totalDistanceWalkedKm.isAcceptableOrUnknown(
              data['total_distance_walked_km']!, _totalDistanceWalkedKmMeta));
    }
    if (data.containsKey('total_elevation_gained_m')) {
      context.handle(
          _totalElevationGainedMMeta,
          totalElevationGainedM.isAcceptableOrUnknown(
              data['total_elevation_gained_m']!, _totalElevationGainedMMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProgressEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trailId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trail_id'])!,
      currentStage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_stage'])!,
      totalDistanceWalkedKm: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}total_distance_walked_km'])!,
      totalElevationGainedM: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}total_elevation_gained_m'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
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

  /// Sentier complete ou non
  final bool isCompleted;

  /// Date de debut du sentier (nullable)
  final DateTime? startedAt;

  /// Date de fin du sentier (nullable)
  final DateTime? completedAt;
  const UserProgressEntry(
      {required this.id,
      required this.trailId,
      required this.currentStage,
      required this.totalDistanceWalkedKm,
      required this.totalElevationGainedM,
      required this.isCompleted,
      this.startedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trail_id'] = Variable<String>(trailId);
    map['current_stage'] = Variable<int>(currentStage);
    map['total_distance_walked_km'] = Variable<double>(totalDistanceWalkedKm);
    map['total_elevation_gained_m'] = Variable<int>(totalElevationGainedM);
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
      isCompleted: Value(isCompleted),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory UserProgressEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProgressEntry(
      id: serializer.fromJson<int>(json['id']),
      trailId: serializer.fromJson<String>(json['trailId']),
      currentStage: serializer.fromJson<int>(json['currentStage']),
      totalDistanceWalkedKm:
          serializer.fromJson<double>(json['totalDistanceWalkedKm']),
      totalElevationGainedM:
          serializer.fromJson<int>(json['totalElevationGainedM']),
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
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  UserProgressEntry copyWith(
          {int? id,
          String? trailId,
          int? currentStage,
          double? totalDistanceWalkedKm,
          int? totalElevationGainedM,
          bool? isCompleted,
          Value<DateTime?> startedAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent()}) =>
      UserProgressEntry(
        id: id ?? this.id,
        trailId: trailId ?? this.trailId,
        currentStage: currentStage ?? this.currentStage,
        totalDistanceWalkedKm:
            totalDistanceWalkedKm ?? this.totalDistanceWalkedKm,
        totalElevationGainedM:
            totalElevationGainedM ?? this.totalElevationGainedM,
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
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
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
      isCompleted,
      startedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProgressEntry &&
          other.id == this.id &&
          other.trailId == this.trailId &&
          other.currentStage == this.currentStage &&
          other.totalDistanceWalkedKm == this.totalDistanceWalkedKm &&
          other.totalElevationGainedM == this.totalElevationGainedM &&
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
  final Value<bool> isCompleted;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  const UserProgressEntriesCompanion({
    this.id = const Value.absent(),
    this.trailId = const Value.absent(),
    this.currentStage = const Value.absent(),
    this.totalDistanceWalkedKm = const Value.absent(),
    this.totalElevationGainedM = const Value.absent(),
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
      if (isCompleted != null) 'is_completed': isCompleted,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  UserProgressEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? trailId,
      Value<int>? currentStage,
      Value<double>? totalDistanceWalkedKm,
      Value<int>? totalElevationGainedM,
      Value<bool>? isCompleted,
      Value<DateTime?>? startedAt,
      Value<DateTime?>? completedAt}) {
    return UserProgressEntriesCompanion(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      currentStage: currentStage ?? this.currentStage,
      totalDistanceWalkedKm:
          totalDistanceWalkedKm ?? this.totalDistanceWalkedKm,
      totalElevationGainedM:
          totalElevationGainedM ?? this.totalElevationGainedM,
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
      map['total_distance_walked_km'] =
          Variable<double>(totalDistanceWalkedKm.value);
    }
    if (totalElevationGainedM.present) {
      map['total_elevation_gained_m'] =
          Variable<int>(totalElevationGainedM.value);
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
          ..write('isCompleted: $isCompleted, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
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
  late final StagesDao stagesDao = StagesDao(this as AppDatabase);
  late final PoisDao poisDao = PoisDao(this as AppDatabase);
  late final ProgressDao progressDao = ProgressDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [stages, pois, userProgressEntries];
}

typedef $$StagesTableCreateCompanionBuilder = StagesCompanion Function({
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
typedef $$StagesTableUpdateCompanionBuilder = StagesCompanion Function({
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stageNumber => $composableBuilder(
      column: $table.stageNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elevationGainM => $composableBuilder(
      column: $table.elevationGainM,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elevationLossM => $composableBuilder(
      column: $table.elevationLossM,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startLat => $composableBuilder(
      column: $table.startLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startLng => $composableBuilder(
      column: $table.startLng, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get endLat => $composableBuilder(
      column: $table.endLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get endLng => $composableBuilder(
      column: $table.endLng, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stageNumber => $composableBuilder(
      column: $table.stageNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elevationGainM => $composableBuilder(
      column: $table.elevationGainM,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elevationLossM => $composableBuilder(
      column: $table.elevationLossM,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startLat => $composableBuilder(
      column: $table.startLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startLng => $composableBuilder(
      column: $table.startLng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get endLat => $composableBuilder(
      column: $table.endLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get endLng => $composableBuilder(
      column: $table.endLng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));
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
      column: $table.stageNumber, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
      column: $table.distanceKm, builder: (column) => column);

  GeneratedColumn<int> get elevationGainM => $composableBuilder(
      column: $table.elevationGainM, builder: (column) => column);

  GeneratedColumn<int> get elevationLossM => $composableBuilder(
      column: $table.elevationLossM, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get startLat =>
      $composableBuilder(column: $table.startLat, builder: (column) => column);

  GeneratedColumn<double> get startLng =>
      $composableBuilder(column: $table.startLng, builder: (column) => column);

  GeneratedColumn<double> get endLat =>
      $composableBuilder(column: $table.endLat, builder: (column) => column);

  GeneratedColumn<double> get endLng =>
      $composableBuilder(column: $table.endLng, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);
}

class $$StagesTableTableManager extends RootTableManager<
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
    PrefetchHooks Function()> {
  $$StagesTableTableManager(_$AppDatabase db, $StagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
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
          }) =>
              StagesCompanion(
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
          createCompanionCallback: ({
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
          }) =>
              StagesCompanion.insert(
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
        ));
}

typedef $$StagesTableProcessedTableManager = ProcessedTableManager<
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
    PrefetchHooks Function()>;
typedef $$PoisTableCreateCompanionBuilder = PoisCompanion Function({
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
typedef $$PoisTableUpdateCompanionBuilder = PoisCompanion Function({
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stageNumber => $composableBuilder(
      column: $table.stageNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get altitudeM => $composableBuilder(
      column: $table.altitudeM, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get openingHours => $composableBuilder(
      column: $table.openingHours, builder: (column) => ColumnFilters(column));
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stageNumber => $composableBuilder(
      column: $table.stageNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get altitudeM => $composableBuilder(
      column: $table.altitudeM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get openingHours => $composableBuilder(
      column: $table.openingHours,
      builder: (column) => ColumnOrderings(column));
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
      column: $table.stageNumber, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<int> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  GeneratedColumn<String> get openingHours => $composableBuilder(
      column: $table.openingHours, builder: (column) => column);
}

class $$PoisTableTableManager extends RootTableManager<
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
    PrefetchHooks Function()> {
  $$PoisTableTableManager(_$AppDatabase db, $PoisTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
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
          }) =>
              PoisCompanion(
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
          createCompanionCallback: ({
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
          }) =>
              PoisCompanion.insert(
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
        ));
}

typedef $$PoisTableProcessedTableManager = ProcessedTableManager<
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
    PrefetchHooks Function()>;
typedef $$UserProgressEntriesTableCreateCompanionBuilder
    = UserProgressEntriesCompanion Function({
  Value<int> id,
  required String trailId,
  Value<int> currentStage,
  Value<double> totalDistanceWalkedKm,
  Value<int> totalElevationGainedM,
  Value<bool> isCompleted,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
});
typedef $$UserProgressEntriesTableUpdateCompanionBuilder
    = UserProgressEntriesCompanion Function({
  Value<int> id,
  Value<String> trailId,
  Value<int> currentStage,
  Value<double> totalDistanceWalkedKm,
  Value<int> totalElevationGainedM,
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStage => $composableBuilder(
      column: $table.currentStage, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDistanceWalkedKm => $composableBuilder(
      column: $table.totalDistanceWalkedKm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalElevationGainedM => $composableBuilder(
      column: $table.totalElevationGainedM,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStage => $composableBuilder(
      column: $table.currentStage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDistanceWalkedKm => $composableBuilder(
      column: $table.totalDistanceWalkedKm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalElevationGainedM => $composableBuilder(
      column: $table.totalElevationGainedM,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
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
      column: $table.currentStage, builder: (column) => column);

  GeneratedColumn<double> get totalDistanceWalkedKm => $composableBuilder(
      column: $table.totalDistanceWalkedKm, builder: (column) => column);

  GeneratedColumn<int> get totalElevationGainedM => $composableBuilder(
      column: $table.totalElevationGainedM, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$UserProgressEntriesTableTableManager extends RootTableManager<
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
      BaseReferences<_$AppDatabase, $UserProgressEntriesTable,
          UserProgressEntry>
    ),
    UserProgressEntry,
    PrefetchHooks Function()> {
  $$UserProgressEntriesTableTableManager(
      _$AppDatabase db, $UserProgressEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProgressEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProgressEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProgressEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> trailId = const Value.absent(),
            Value<int> currentStage = const Value.absent(),
            Value<double> totalDistanceWalkedKm = const Value.absent(),
            Value<int> totalElevationGainedM = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              UserProgressEntriesCompanion(
            id: id,
            trailId: trailId,
            currentStage: currentStage,
            totalDistanceWalkedKm: totalDistanceWalkedKm,
            totalElevationGainedM: totalElevationGainedM,
            isCompleted: isCompleted,
            startedAt: startedAt,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String trailId,
            Value<int> currentStage = const Value.absent(),
            Value<double> totalDistanceWalkedKm = const Value.absent(),
            Value<int> totalElevationGainedM = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              UserProgressEntriesCompanion.insert(
            id: id,
            trailId: trailId,
            currentStage: currentStage,
            totalDistanceWalkedKm: totalDistanceWalkedKm,
            totalElevationGainedM: totalElevationGainedM,
            isCompleted: isCompleted,
            startedAt: startedAt,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProgressEntriesTableProcessedTableManager = ProcessedTableManager<
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
      BaseReferences<_$AppDatabase, $UserProgressEntriesTable,
          UserProgressEntry>
    ),
    UserProgressEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StagesTableTableManager get stages =>
      $$StagesTableTableManager(_db, _db.stages);
  $$PoisTableTableManager get pois => $$PoisTableTableManager(_db, _db.pois);
  $$UserProgressEntriesTableTableManager get userProgressEntries =>
      $$UserProgressEntriesTableTableManager(_db, _db.userProgressEntries);
}
