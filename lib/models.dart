const List<String> kCategories = ['کتان', 'مخمل', 'کرپ', 'لینن', 'ساتن', 'سایر'];

class Fabric {
  final String id;
  final String code;
  final String name;
  final String category;
  final String status;
  final double meters;
  final int pricePerMeter; // ریال
  final String color;
  final int widthCm;
  final String location;
  final String lastCountDate;
  final String image;
  final List<String>? images;
  final String? description;
  final int? minMetersAlert;
  final String? supplier;
  final bool archived;
  /// true = موجودی این کالا «تعداد تاقه» است (نه متر)؛ عدد موجودی در فیلد meters ذخیره می‌شود و قیمت، قیمت هر تاقه است.
  final bool byTaqeh;

  const Fabric({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.status,
    required this.meters,
    required this.pricePerMeter,
    this.color = 'استاندارد',
    this.widthCm = 150,
    this.location = 'نامشخص',
    this.lastCountDate = 'امروز',
    this.image = '',
    this.images,
    this.description,
    this.minMetersAlert,
    this.supplier,
    this.archived = false,
    this.byTaqeh = false,
  });

  String get unit => byTaqeh ? 'تاقه' : 'متر';
  String get unitShort => byTaqeh ? 'تاقه' : 'م';

  Fabric copyWith({String? status, double? meters, int? pricePerMeter, String? lastCountDate, bool? archived}) => Fabric(
        id: id,
        code: code,
        name: name,
        category: category,
        status: status ?? this.status,
        meters: meters ?? this.meters,
        pricePerMeter: pricePerMeter ?? this.pricePerMeter,
        color: color,
        widthCm: widthCm,
        location: location,
        lastCountDate: lastCountDate ?? this.lastCountDate,
        image: image,
        images: images,
        description: description,
        minMetersAlert: minMetersAlert,
        supplier: supplier,
        archived: archived ?? this.archived,
        byTaqeh: byTaqeh,
      );

  factory Fabric.fromJson(Map<String, dynamic> j) => Fabric(
        id: j['id'].toString(),
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        category: (j['category'] ?? 'سایر').toString(),
        status: (j['status'] ?? 'موجود').toString(),
        meters: (j['meters'] as num?)?.toDouble() ?? 0,
        pricePerMeter: (j['pricePerMeter'] as num?)?.round() ?? 0,
        color: (j['color'] ?? '').toString(),
        widthCm: (j['widthCm'] as num?)?.round() ?? 150,
        location: (j['location'] ?? '').toString(),
        lastCountDate: (j['lastCountDate'] ?? '').toString(),
        image: (j['image'] ?? '').toString(),
        images: (j['images'] as List?)?.map((e) => e.toString()).toList(),
        description: j['description'] as String?,
        minMetersAlert: (j['minMetersAlert'] as num?)?.round(),
        supplier: j['supplier'] as String?,
        archived: j['archived'] == true,
        byTaqeh: j['byTaqeh'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'category': category,
        'status': status,
        'meters': meters,
        'pricePerMeter': pricePerMeter,
        'color': color,
        'widthCm': widthCm,
        'location': location,
        'lastCountDate': lastCountDate,
        'image': image,
        if (images != null) 'images': images,
        if (description != null) 'description': description,
        if (minMetersAlert != null) 'minMetersAlert': minMetersAlert,
        if (supplier != null) 'supplier': supplier,
        'archived': archived,
        if (byTaqeh) 'byTaqeh': true,
      };
}

class Tx {
  final String id;
  final String fabricId;
  final String fabricName;
  final String fabricCode;
  final String type; // ورود | خروج | اصلاح | لغو
  final double metersChange;
  final double metersAfter;
  final int? pricePerMeter;
  final String timestamp;
  final String dateStr;
  final String? at; // ISO
  final String note;
  final String? user;
  final String? supplier;
  final String? reversedBy;
  final String? reverses;
  final String? reverseReason;
  final bool byTaqeh;

  const Tx({
    required this.id,
    required this.fabricId,
    required this.fabricName,
    required this.fabricCode,
    required this.type,
    required this.metersChange,
    required this.metersAfter,
    this.pricePerMeter,
    required this.timestamp,
    required this.dateStr,
    this.at,
    this.note = '',
    this.user,
    this.supplier,
    this.reversedBy,
    this.reverses,
    this.reverseReason,
    this.byTaqeh = false,
  });

  String get unit => byTaqeh ? 'تاقه' : 'متر';
  String get unitShort => byTaqeh ? 'تاقه' : 'م';

  Tx withReversedBy(String rid) => Tx(
        id: id,
        fabricId: fabricId,
        fabricName: fabricName,
        fabricCode: fabricCode,
        type: type,
        metersChange: metersChange,
        metersAfter: metersAfter,
        pricePerMeter: pricePerMeter,
        timestamp: timestamp,
        dateStr: dateStr,
        at: at,
        note: note,
        user: user,
        supplier: supplier,
        reversedBy: rid,
        reverses: reverses,
        reverseReason: reverseReason,
        byTaqeh: byTaqeh,
      );

  factory Tx.fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'].toString(),
        fabricId: (j['fabricId'] ?? '').toString(),
        fabricName: (j['fabricName'] ?? '').toString(),
        fabricCode: (j['fabricCode'] ?? '').toString(),
        type: (j['type'] ?? 'اصلاح').toString(),
        metersChange: (j['metersChange'] as num?)?.toDouble() ?? 0,
        metersAfter: (j['metersAfter'] as num?)?.toDouble() ?? 0,
        pricePerMeter: (j['pricePerMeter'] as num?)?.round(),
        timestamp: (j['timestamp'] ?? '').toString(),
        dateStr: (j['dateStr'] ?? '').toString(),
        at: j['at'] as String?,
        note: (j['note'] ?? '').toString(),
        user: j['user'] as String?,
        supplier: j['supplier'] as String?,
        reversedBy: j['reversedBy'] as String?,
        reverses: j['reverses'] as String?,
        reverseReason: j['reverseReason'] as String?,
        byTaqeh: j['byTaqeh'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fabricId': fabricId,
        'fabricName': fabricName,
        'fabricCode': fabricCode,
        'type': type,
        'metersChange': metersChange,
        'metersAfter': metersAfter,
        if (pricePerMeter != null) 'pricePerMeter': pricePerMeter,
        'timestamp': timestamp,
        'dateStr': dateStr,
        if (at != null) 'at': at,
        'note': note,
        if (user != null) 'user': user,
        if (supplier != null) 'supplier': supplier,
        if (reversedBy != null) 'reversedBy': reversedBy,
        if (reverses != null) 'reverses': reverses,
        if (reverseReason != null) 'reverseReason': reverseReason,
        if (byTaqeh) 'byTaqeh': true,
      };
}

class Notif {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool read;
  final String type; // warning | info | success

  const Notif({required this.id, required this.title, required this.message, required this.time, this.read = false, this.type = 'info'});

  Notif asRead() => Notif(id: id, title: title, message: message, time: time, read: true, type: type);

  factory Notif.fromJson(Map<String, dynamic> j) => Notif(
        id: j['id'].toString(),
        title: (j['title'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        time: (j['time'] ?? '').toString(),
        read: j['read'] == true,
        type: (j['type'] ?? 'info').toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'message': message, 'time': time, 'read': read, 'type': type};
}
