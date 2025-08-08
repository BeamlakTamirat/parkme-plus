import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../config/firebase_config.dart';
import '../utils/simple_logger.dart';

/// Firestore database service for all database operations
class FirestoreService {
  static FirestoreService? _instance;
  late final FirebaseFirestore _firestore;

  FirestoreService._internal() {
    _firestore = FirebaseConfig.firestore;
  }

  static FirestoreService get instance {
    _instance ??= FirestoreService._internal();
    return _instance!;
  }

  // Generic CRUD operations

  /// Create a document
  Future<DatabaseResult<String>> createDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      logger.info('Creating document in collection: $collection');

      final docRef = documentId != null
          ? _firestore.collection(collection).doc(documentId)
          : _firestore.collection(collection).doc();

      // Add timestamps
      final timestampedData = {
        ...data,
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      };

      await docRef.set(timestampedData);

      logger.info('Document created successfully: ${docRef.id}');
      
      return DatabaseResult.success(docRef.id);
    } catch (e) {
      logger.error('Error creating document: $e');
      return DatabaseResult.error('Failed to create document: $e');
    }
  }

  /// Read a document
  Future<DatabaseResult<Map<String, dynamic>?>> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      logger.info('Getting document: $collection/$documentId');

      final docSnapshot = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data[FirestoreFields.id] = docSnapshot.id;
        
        logger.info('Document retrieved successfully');
        return DatabaseResult.success(data);
      } else {
        logger.info('Document not found');
        return DatabaseResult.success(null);
      }
    } catch (e) {
      logger.error('Error getting document: $e');
      return DatabaseResult.error('Failed to get document: $e');
    }
  }

  /// Update a document
  Future<DatabaseResult<void>> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      logger.info('Updating document: $collection/$documentId');

      // Add update timestamp
      final timestampedData = {
        ...data,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(collection)
          .doc(documentId)
          .update(timestampedData);

      logger.info('Document updated successfully');
      return DatabaseResult.success(null);
    } catch (e) {
      logger.error('Error updating document: $e');
      return DatabaseResult.error('Failed to update document: $e');
    }
  }

  /// Delete a document
  Future<DatabaseResult<void>> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      logger.info('Deleting document: $collection/$documentId');

      await _firestore
          .collection(collection)
          .doc(documentId)
          .delete();

      logger.info('Document deleted successfully');
      return DatabaseResult.success(null);
    } catch (e) {
      logger.error('Error deleting document: $e');
      return DatabaseResult.error('Failed to delete document: $e');
    }
  }

  /// Query documents
  Future<DatabaseResult<List<Map<String, dynamic>>>> queryDocuments({
    required String collection,
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      logger.info('Querying documents in collection: $collection');

      Query query = _firestore.collection(collection);

      // Apply where conditions
      if (where != null) {
        where.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      
      final documents = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data[FirestoreFields.id] = doc.id;
        return data;
      }).toList();

      logger.info('Query completed: ${documents.length} documents found');
      return DatabaseResult.success(documents);
    } catch (e) {
      logger.error('Error querying documents: $e');
      return DatabaseResult.error('Failed to query documents: $e');
    }
  }

  /// Stream documents
  Stream<DatabaseResult<List<Map<String, dynamic>>>> streamDocuments({
    required String collection,
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      logger.info('Streaming documents from collection: $collection');

      Query query = _firestore.collection(collection);

      // Apply where conditions
      if (where != null) {
        where.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((querySnapshot) {
        final documents = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data[FirestoreFields.id] = doc.id;
          return data;
        }).toList();

        return DatabaseResult.success(documents);
      });
    } catch (e) {
      logger.error('Error streaming documents: $e');
      return Stream.value(DatabaseResult.error('Failed to stream documents: $e'));
    }
  }

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      if (!kIsWeb) {
        await _firestore.enablePersistence();
        logger.info('Offline persistence enabled');
      }
    } catch (e) {
      logger.error('Error enabling offline persistence: $e');
    }
  }

  /// Clear offline cache
  Future<void> clearOfflineCache() async {
    try {
      await _firestore.clearPersistence();
      logger.info('Offline cache cleared');
    } catch (e) {
      logger.error('Error clearing offline cache: $e');
    }
  }
}

/// Database operation result
class DatabaseResult<T> {
  final bool success;
  final T? data;
  final String? error;

  DatabaseResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory DatabaseResult.success(T data) {
    return DatabaseResult._(
      success: true,
      data: data,
    );
  }

  factory DatabaseResult.error(String error) {
    return DatabaseResult._(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'DatabaseResult(success: $success, data: $data, error: $error)';
  }
}
