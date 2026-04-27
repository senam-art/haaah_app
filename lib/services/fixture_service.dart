import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fixture.dart';
import '../db/database_helper.dart';

class FixtureService {
  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  // ── Fetch all fixtures (joined with venues and teams) ──

  Future<List<Fixture>> fetchFixtures() async {
    try {
      // 1. Fetch from Supabase
      final data = await _supabase
          .from('fixtures')
          .select('*, venues(*), home_team:teams!home_team_id(*), away_team:teams!away_team_id(*), match_attendance(count)')
          .order('date_time', ascending: true);

      final fixtures = (data as List).map((json) => Fixture.fromJson(json)).toList();

      // 2. Cache locally
      final sqliteMaps = fixtures.map((f) => f.toSqlite()).toList();
      await _dbHelper.cacheFixtures(sqliteMaps);

      return fixtures;
    } catch (e) {
      // 3. Fallback to SQLite
      final cachedMaps = await _dbHelper.getFixtures();
      if (cachedMaps.isNotEmpty) {
        return cachedMaps.map((map) => Fixture.fromSqlite(map)).toList();
      }
      rethrow;
    }
  }

  // ── Fetch single fixture ──

  Future<Fixture> fetchFixtureById(String id) async {
    final data = await _supabase
        .from('fixtures')
        .select('*, venues(*), home_team:teams!home_team_id(*), away_team:teams!away_team_id(*), match_attendance(count)')
        .eq('id', id)
        .single();

    final fixture = Fixture.fromJson(data);
    await _dbHelper.cacheFixtures([fixture.toSqlite()]);
    return fixture;
  }

  // ── Supabase Realtime subscription ──

  RealtimeChannel subscribeToFixtureUpdates(
      void Function(Map<String, dynamic>) onUpdate) {
    return _supabase.channel('fixtures-updates').onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'fixtures',
      callback: (payload) => onUpdate(payload.newRecord),
    ).subscribe();
  }

  // ── Attendance ──

  Future<void> recordAttendance(String fixtureId, String profileId) async {
    try {
      await _supabase.from('match_attendance').insert({
        'fixture_id': fixtureId,
        'profile_id': profileId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique violation
        throw Exception("ALREADY_SCANNED");
      }
      rethrow;
    }
  }

  Future<int> getAttendanceCount(String fixtureId) async {
    final response = await _supabase
        .from('match_attendance')
        .select('id')
        .eq('fixture_id', fixtureId)
        .count(CountOption.exact);
    return response.count;
  }
}
