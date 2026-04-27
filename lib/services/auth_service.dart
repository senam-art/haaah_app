import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../db/database_helper.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  /// The currently authenticated user's profile (cached in memory).
  Profile? _currentProfile;
  Profile? get currentProfile => _currentProfile;

  /// Whether a user is logged in.
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ── Sign Up ──

  Future<Profile> signUp({
    required String email,
    required String password,
    required String name,
    required String position,
  }) async {
    // 1. Create auth user
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Sign up failed — no user returned.');

    // 2. Insert profile row
    final profileData = {
      'id': user.id,
      'name': name,
      'email': email,
      'position': position,
    };
    await _supabase.from('profiles').insert(profileData);

    // 3. Keep in memory
    final profile = Profile(
      id: user.id,
      name: name,
      email: email,
      position: position,
    );
    _currentProfile = profile;
    await _dbHelper.cacheProfile(profile.toSqlite());

    return profile;
  }

  // ── Sign In ──

  Future<Profile> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return await fetchAndCacheProfile();
  }

  // ── Sign Out ──

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentProfile = null;
    await _dbHelper.clearAll();
  }

  // ── Get / Refresh Profile ──

  Future<Profile> fetchAndCacheProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated.');

    try {
      // 1. Fetch from Supabase
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();

      final profile = Profile.fromJson(data);
      _currentProfile = profile;
      
      // 2. Cache Locally
      await _dbHelper.cacheProfile(profile.toSqlite());
      
      return profile;
    } catch (e) {
      // 3. Fallback to SQLite
      final cachedMap = await _dbHelper.getProfile(userId);
      if (cachedMap != null) {
        final profile = Profile.fromSqlite(cachedMap);
        _currentProfile = profile;
        return profile;
      }
      rethrow;
    }
  }

  Future<Profile> fetchProfileById(String id) async {
    try {
      final data = await _supabase.from('profiles').select().eq('id', id).single();
      return Profile.fromJson(data);
    } catch (e) {
      // Fallback to SQLite if we have it
      final cachedMap = await _dbHelper.getProfile(id);
      if (cachedMap != null) {
        return Profile.fromSqlite(cachedMap);
      }
      rethrow;
    }
  }

  // ── Upload Profile Picture ──

  Future<String> uploadProfilePicture(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    // 1. Upload to Supabase Storage
    await _supabase.storage.from('avatars').upload(
      fileName,
      imageFile,
    );

    // 2. Get Public URL
    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

    // 3. Update profiles table
    await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', user.id);

    // 4. Update memory and cache
    if (_currentProfile != null) {
      _currentProfile = Profile(
        id: _currentProfile!.id,
        name: _currentProfile!.name,
        email: _currentProfile!.email,
        position: _currentProfile!.position,
        avatarUrl: publicUrl, // updated
        goals: _currentProfile!.goals,
        assists: _currentProfile!.assists,
        appearances: _currentProfile!.appearances,
        motm: _currentProfile!.motm,
        pace: _currentProfile!.pace,
        shooting: _currentProfile!.shooting,
        dribbling: _currentProfile!.dribbling,
        physical: _currentProfile!.physical,
        createdAt: _currentProfile!.createdAt,
      );
      await _dbHelper.cacheProfile(_currentProfile!.toSqlite());
    }

    return publicUrl;
  }
}
