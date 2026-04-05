import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/enums.dart';
import '../services/firebase_service.dart';

class GroupsRepo {
  CollectionReference<Map<String, dynamic>> get _groups => Fb.col('groups');

  CollectionReference<Map<String, dynamic>> _members(String groupId) =>
      _groups.doc(groupId).collection('members');

  CollectionReference<Map<String, dynamic>> _activity(String groupId) =>
      _groups.doc(groupId).collection('activity');

  // ── Groups ──────────────────────────────────────────────────────────────────

  Future<List<Group>> discoverGroups({
    WellnessGoal? goal,
    int limit = 30,
  }) async {
    Query<Map<String, dynamic>> q = _groups;
    if (goal != null) {
      q = q.where('goalCategory', isEqualTo: goal.index);
    }
    final snap = await q
        .orderBy('memberCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Group.fromMap(d.id, d.data())).toList();
  }

  /// Returns all groups the user is a member of.
  /// Uses a collectionGroup query on the `members` sub-collection,
  /// filtering by the `userId` field stored in each member document.
  Future<List<Group>> groupsForUser(String userId) async {
    final memberSnaps = await Fb.db
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .get();

    if (memberSnaps.docs.isEmpty) return [];

    final groupIds = memberSnaps.docs
        .map((d) => d.reference.parent.parent!.id)
        .toSet()
        .toList();

    final groupDocs = await Future.wait(
      groupIds.map((id) => _groups.doc(id).get()),
    );

    return groupDocs
        .where((d) => d.exists)
        .map((d) => Group.fromMap(d.id, d.data()!))
        .toList();
  }

  Future<Group?> getGroup(String groupId) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists) return null;
    return Group.fromMap(doc.id, doc.data()!);
  }

  /// Creates a new group and adds the creator as the first member.
  Future<Group> createGroup({
    required String name,
    String? description,
    required WellnessGoal goalCategory,
    required String userId,
    bool isAnonymousAllowed = true,
  }) async {
    final now = DateTime.now();
    final ref = _groups.doc();
    final group = Group(
      id: ref.id,
      name: name,
      description: description,
      goalCategory: goalCategory,
      memberCount: 1,
      createdBy: userId,
      createdAt: now,
      isAnonymousAllowed: isAnonymousAllowed,
    );
    final alias = aliasFor(userId);
    final batch = Fb.db.batch();
    batch.set(ref, group.toMap());
    batch.set(
      _members(ref.id).doc(userId),
      GroupMember(
        groupId: ref.id,
        userId: userId,
        alias: alias,
        joinedAt: now,
      ).toMap(),
    );
    await batch.commit();
    return group;
  }

  // ── Membership ───────────────────────────────────────────────────────────────

  Future<bool> isMember(String groupId, String userId) async {
    final doc = await _members(groupId).doc(userId).get();
    return doc.exists;
  }

  Future<String?> getMemberAlias(String groupId, String userId) async {
    final doc = await _members(groupId).doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['alias'] as String?;
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final alias = aliasFor(userId);
    final batch = Fb.db.batch();
    batch.set(
      _members(groupId).doc(userId),
      GroupMember(
        groupId: groupId,
        userId: userId,
        alias: alias,
        joinedAt: DateTime.now(),
      ).toMap(),
    );
    batch.update(
      _groups.doc(groupId),
      {'memberCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    final batch = Fb.db.batch();
    batch.delete(_members(groupId).doc(userId));
    batch.update(
      _groups.doc(groupId),
      {'memberCount': FieldValue.increment(-1)},
    );
    await batch.commit();
  }

  // ── Activity feed ────────────────────────────────────────────────────────────

  Future<List<GroupActivity>> getActivity(String groupId,
      {int limit = 40}) async {
    final snap = await _activity(groupId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => GroupActivity.fromMap(d.id, d.data()))
        .toList();
  }

  /// Posts an anonymous activity item. No userId is stored in the document.
  Future<void> postActivity({
    required String groupId,
    required String userId,
    required GroupPostType postType,
    required String activityText,
  }) async {
    final alias = aliasFor(userId);
    final ref = _activity(groupId).doc();
    await ref.set(GroupActivity(
      id: ref.id,
      groupId: groupId,
      alias: alias,
      postType: postType,
      activityText: activityText,
      timestamp: DateTime.now(),
    ).toMap());
  }
}
