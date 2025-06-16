import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductModel {
  final String productId;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String sellerId;
  final DateTime createdAt;
  final String status;
  final String saleType;
  final DateTime? biddingEndDate;
  final double? currentBid;
  final String? currentBidUser;
  final int? minUsers;
  final bool isActive;
  final String? biddingWinner;

  ProductModel({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.sellerId,
    required this.createdAt,
    required this.status,
    required this.saleType,
    this.biddingEndDate,
    this.currentBid,
    this.currentBidUser,
    this.minUsers,
    required this.isActive,
    this.biddingWinner,
  });

  /// Factory method to create `ProductModel` from Firestore document.
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      productId: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      description: data['description'] ?? 'No description available',
      price: (data['price'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      sellerId: data['sellerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'unknown',
      saleType: data['saleType'] ?? 'direct',
      biddingEndDate: data['biddingEndDate'] != null
          ? (data['biddingEndDate'] as Timestamp).toDate()
          : null,
      currentBid: (data['currentBid'] ?? 0).toDouble(),
      currentBidUser: data['currentBidUser']?.toString(),
      minUsers: data['minUsers'],
      isActive: data['isActive'] ?? true,
      biddingWinner: data['biddingWinner'],
    );
  }

  /// Convert `ProductModel` to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': productId,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'sellerId': sellerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'saleType': saleType,
      'biddingEndDate': biddingEndDate != null ? Timestamp.fromDate(biddingEndDate!) : null,
      'currentBid': currentBid,
      'currentBidUser': currentBidUser,
      'minUsers': minUsers,
      'isActive': isActive,
      'biddingWinner': biddingWinner,
    };
  }

  /// Convert `ProductModel` to JSON (Map<String, dynamic>) with ISO DateTime format
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'sellerId': sellerId,
      'createdAt': createdAt.toIso8601String(), // DateTime to string
      'status': status,
      'saleType': saleType,
      'biddingEndDate': biddingEndDate?.toIso8601String(),
      'currentBid': currentBid,
      'currentBidUser': currentBidUser,
      'minUsers': minUsers,
      'isActive': isActive,
      'biddingWinner': biddingWinner,
    };
  }

  /// Method to get the current user's UID.  Returns null if no user is logged in.
  String? getCurrentUserUid() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }
}

