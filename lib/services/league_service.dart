import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/team.dart';
import '../models/profile.dart';
import '../db/database_helper.dart';

class LeagueService {
  final _supabase = Supabase.instance.client;
  final _dbHelper = DatabaseHelper.instance;

  // ── Fetch League Standings ──

  Future<List<Team>> fetchStandings() async {
    try {
      // 1. Fetch from Supabase
      final data = await _supabase
          .from('teams')
          .select()
          .order('points', ascending: false)
          .order('won', ascending: false);

      final teams = (data as List).map((json) => Team.fromJson(json)).toList();

      // 2. Cache locally
      final sqliteMaps = teams.map((t) => t.toSqlite()).toList();
      await _dbHelper.cacheTeams(sqliteMaps);

      return teams;
    } catch (e) {
      // 3. Fallback to SQLite
      final cachedMaps = await _dbHelper.getTeams();
      if (cachedMaps.isNotEmpty) {
        return cachedMaps.map((map) => Team.fromSqlite(map)).toList();
      }
      rethrow;
    }
  }

  // ── Register a new Team ──

  Future<Team> registerTeam({
    required String name,
    required String managerId,
    String? logoUrl,
    bool isPlayingManager = true,
    String managerPosition = 'SUB',
  }) async {
    final data = await _supabase
        .from('teams')
        .insert({
          'name': name,
          'manager_id': managerId,
          'logo_url': logoUrl,
        })
        .select()
        .single();

    final team = Team.fromJson(data);
    await _dbHelper.cacheTeams([team.toSqlite()]);

    // Automatically add the manager as a CONFIRMED player on the team
    await _supabase.from('team_players').insert({
      'team_id': team.id,
      'profile_id': managerId,
      'status': 'CONFIRMED',
      'position': isPlayingManager ? managerPosition : 'MANAGER',
    });

    return team;
  }

  // ── Search Profiles ──

  Future<List<Profile>> searchProfiles(String query) async {
    if (query.isEmpty) return [];

    final data = await _supabase
        .from('profiles')
        .select()
        .ilike('name', '%$query%')
        .limit(10);

    return (data as List).map((json) => Profile.fromJson(json)).toList();
  }

  // ── Invite Players to Team ──

  Future<void> invitePlayersToTeam(String teamId, List<Profile> players) async {
    final inserts = players.map((p) => {
      'team_id': teamId,
      'profile_id': p.id,
      'position': p.position,
      'status': 'INVITED',
    }).toList();

    await _supabase.from('team_players').insert(inserts);
  }

  // ── Manage Invitations ──

  Future<List<Map<String, dynamic>>> getPendingInvites(String profileId) async {
    final data = await _supabase
        .from('team_players')
        .select('*, teams(*)')
        .eq('profile_id', profileId)
        .eq('status', 'INVITED');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> respondToInvite(String inviteId, bool accept) async {
    if (accept) {
      await _supabase
          .from('team_players')
          .update({'status': 'CONFIRMED'})
          .eq('id', inviteId);
    } else {
      await _supabase
          .from('team_players')
          .delete()
          .eq('id', inviteId);
    }
  }

  // ── Teams & Green Light Logic ──

  Future<List<Map<String, dynamic>>> getUserTeams(String profileId) async {
    final data = await _supabase
        .from('team_players')
        .select('*, teams(*)')
        .eq('profile_id', profileId)
        .eq('status', 'CONFIRMED');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<bool> isTeamGreenLit(String teamId) async {
    // A team is green lit if NO members have status = 'INVITED'
    final response = await _supabase
        .from('team_players')
        .select('id')
        .eq('team_id', teamId)
        .eq('status', 'INVITED')
        .limit(1);
    
    // If we find any 'INVITED' players, it is NOT green lit.
    return (response as List).isEmpty;
  }

  Future<List<Map<String, dynamic>>> getTeamRoster(String teamId) async {
    final data = await _supabase
        .from('team_players')
        .select('*, profiles(*)')
        .eq('team_id', teamId);
    return List<Map<String, dynamic>>.from(data);
  }
}
