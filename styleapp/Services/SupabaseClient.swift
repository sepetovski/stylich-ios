import Foundation
import Supabase

// Add your keys in Config.swift (which is gitignored)
let supabase = SupabaseClient(
    supabaseURL: URL(string: Config.supabaseURL)!,
    supabaseKey: Config.supabaseKey
)
