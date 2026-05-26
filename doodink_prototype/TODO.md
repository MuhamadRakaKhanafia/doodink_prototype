# TODO - DoodInk Multiplayer (Flutter + Supabase)

## Step 1 — Repo dasar
- [x] Observasi: repo masih template Flutter (hanya `lib/main.dart`)

## Step 2 — Brainstorm plan final
- [x] Konfirmasi: Riverpod + rotation berdasarkan `joined_at`

## Step 3 — Spesifikasi folder & arsitektur Flutter
- [x] Buat struktur folder scalable (clean architecture sederhana)

## Step 4 — SQL schema Supabase lengkap
- [x] Tabel: rooms, room_players, room_player_prompts, room_drawings, room_guesses, room_votes
- [x] Relasi, index, constraint, dan contoh data


## Step 5 — Realtime strategy + timer logic
- [x] Rencana subscription per fase & reconnection strategy
- [x] Timer sync menggunakan `phase_started_at` + `phase_duration_ms`
- [x] Auto submit saat timer habis


## Step 6 — Model Dart
- [x] Enum GamePhase
- [x] Dart models sesuai schema


## Step 7 — Supabase service layer
- [x] Service layer (skeleton) + Supabase Realtime subscriptions (strategi)
- [x] Service layer: RoomService, PlayerService, ChainService, VoteService, StorageService


## Step 8 — Logic multiplayer & lifecycle
- [x] Room lifecycle (create/join/ready/start/rotate/reveal/result)
- [x] Rotation algorithm A→B→C→…→A berdasarkan joined_at


## Step 9 — Drawing save/upload
- [ ] CustomPainter canvas plan
- [ ] Export PNG dan upload ke Storage
- [ ] Kaitkan update tabel room_drawings

## Step 10 — Reveal sequencing & UI/UX
- [x] Reveal chain sequencing
- [x] Flow diagram + widget/animation strategy


## Step 11 — Theme & reusable UI components
- [x] Design system ala Gartic Phone
- [x] ThemeData, color palette, button/card/widgets


## Step 12 — Output final sesuai request
- [ ] Semua item: arsitektur, DB, logic, flow, best practices, responsive UI, animation, styling

