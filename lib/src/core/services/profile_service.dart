import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileService {
  ProfileService(this._supabase);

  final SupabaseClient _supabase;

  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      debugPrint('[API] Fetch profile failed: $e');
      return null;
    }
  }

  Future<void> updateProfile(String userId, UserProfile profile) async {
    await _supabase.from('profiles').upsert({
      'id': userId,
      'owner_name': profile.fullName,
      'business_name': profile.businessName,
      'whatsapp': profile.whatsapp,
      'email': profile.email,
    });
  }

  Future<void> signOut() => _supabase.auth.signOut();
}
