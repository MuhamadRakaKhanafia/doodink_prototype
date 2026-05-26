# DoodInk — Multiplayer Party Game (Flutter + Supabase)

Dokumen spesifikasi untuk project kampus.

## 0) Tujuan & asumsi desain
- Gameplay terinspirasi **Gartic Phone**: chain prompt → draw → guess → draw → guess … → reveal → result.
- Semua player **aktif bersamaan** (tidak seperti turn-by-turn satu player).
- Backend memakai **Supabase**: Postgres + Row Level Security (RLS) + **Realtime** + **Storage**.
- Fokus: **sederhana, stabil, scalable** untuk demo kampus.

> Preferensi user: **Riverpod** + **rotasi berdasarkan `joined_at`**.

---

## 1) Arsitektur Flutter (Clean sederhana, tetap scalable)
### 1.1 Prinsip
- **Presentation**: UI widgets & navigasi per phase.
- **State/Controller**: orchestrate phase, timer, submit/auto-submit, listen realtime.
- **Domain**: enum, entity/model sederhana, pure logic (rotation/reveal/timer math).
- **Data**: Supabase service layer + DTO mapping.
- Semua realtime subscribe dikelola di layer `data` + disambungkan ke Riverpod state.

### 1.2 Struktur folder (disarankan)
```
lib/
  app/
    app.dart                     # root widget + providers scope
    router/
      app_router.dart            # navigation by GamePhase
    theme/
      app_theme.dart            # ThemeData + ColorScheme
      doodink_theme.dart       # gradient, card, button styles
  core/
    constants/
      game_constants.dart
    errors/
      app_exception.dart
    utils/
      time_utils.dart
      id_utils.dart             # room code, etc.
    network/
      connectivity_service.dart
  data/
    supabase/
      supabase_client.dart     # create SupabaseClient
      realtime/
        room_realtime_channel.dart  # channel subscribe/unsubscribe
      services/
        room_service.dart
        player_service.dart
        chain_service.dart
        vote_service.dart
        storage_service.dart
    dto/
      room_dto.dart
      room_player_dto.dart
      chain_dto.dart
      drawing_dto.dart
      guess_dto.dart
      vote_dto.dart
  domain/
    models/
      game_phase.dart
      room.dart
      room_player.dart
      player_prompt_chain.dart
      room_chain.dart           # aggregated chain view
      room_drawing.dart
      room_guess.dart
      room_vote.dart
    logic/
      rotation.dart
      reveal_sequencer.dart
      timer_sync.dart
  state/
    providers/
      app_providers.dart       # expose top-level providers
    controllers/
      auth_controller.dart     # username, playerId
      room_controller.dart     # room lifecycle, host/client
      game_phase_controller.dart
      timer_controller.dart
      drawing_controller.dart  # brush strokes + submit export
      guessing_controller.dart
      reveal_controller.dart
  features/
    lobby/
      lobby_screen.dart
      widgets/
        room_code_card.dart
        player_list.dart
        ready_pill.dart
    game/
      writing/
        writing_screen.dart
      drawing/
        drawing_screen.dart
        widgets/
          doodink_canvas.dart  # CustomPainter + GestureDetector
          color_picker_row.dart
          brush_tools_bar.dart
      guessing/
        guessing_screen.dart
      reveal/
        reveal_screen.dart
      result/
        result_screen.dart
  shared/
    widgets/
      doodink_card.dart
      doodink_button.dart
      gradient_background.dart
      countdown_badge.dart
      party_snackbar.dart
    animations/
      phase_transition.dart
      fade_slide_transition.dart
      glow_animation.dart
  main.dart
```

---

## 2) State management recommendation (Riverpod)
### 2.1 Konsep provider
- `playerProvider`: menyimpan `playerId` (UUID) + `username`.
- `roomProvider`: menyimpan `roomCode`, `hostPlayerId`, `phase`.
- `roomPlayersStreamProvider`: Stream realtime list `room_players`.
- `activePhaseStateProvider`: computed/derived state dari tabel phase & chain.
- `timerProvider`: menghitung sisa waktu berdasarkan `phase_started_at` + `phase_duration_ms`.

### 2.2 Kenapa Riverpod cocok
- Stream realtime → expose sebagai `StreamProvider`/`AsyncNotifierProvider`.
- Derived state (rotation plan, current chain index) dibuat dari `AsyncValue`.
- Reconnect handling: provider dapat `invalidate()` dan rehydrate state.

---

## 3) SQL Schema Supabase (lengkap + relasi + index)
### 3.1 Rekomendasi extensions
- `gen_random_uuid()` via `pgcrypto`.

### 3.2 Enum
```sql
DO $$ BEGIN
  CREATE TYPE game_phase AS ENUM (
    'lobby',
    'writing',
    'drawing',
    'guessing',
    'reveal',
    'result'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
```

### 3.3 Tabel

#### 3.3.1 `rooms`
Menyimpan room metadata + sumber kebenaran phase/timer.
```sql
CREATE TABLE IF NOT EXISTS public.rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code text NOT NULL UNIQUE,

  host_player_id uuid NOT NULL,

  game_phase game_phase NOT NULL DEFAULT 'lobby',
  phase_started_at timestamptz NOT NULL DEFAULT now(),
  phase_duration_ms integer NOT NULL DEFAULT 30000,

  max_chain_length integer NOT NULL DEFAULT 5, -- jumlah chain item (prompt/draw/guess) yang akan dirender

  turn_index integer NOT NULL DEFAULT 0, -- index chain yang sedang berjalan (0..max_chain_length-1)

  rotation_version integer NOT NULL DEFAULT 1, -- placeholder untuk future

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rooms_game_phase ON public.rooms(game_phase);
CREATE INDEX IF NOT EXISTS idx_rooms_room_code ON public.rooms(room_code);
```

#### 3.3.2 `room_players`
Menyimpan player yang masuk room + ready status + order via `joined_at`.
```sql
CREATE TABLE IF NOT EXISTS public.room_players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  player_id uuid NOT NULL,                -- identitas player di client (dibuat sekali saat join)
  username text NOT NULL,

  is_host boolean NOT NULL DEFAULT false,
  is_ready boolean NOT NULL DEFAULT false,

  joined_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (room_id, player_id)
);

CREATE INDEX IF NOT EXISTS idx_room_players_room_id ON public.room_players(room_id);
CREATE INDEX IF NOT EXISTS idx_room_players_room_id_ready ON public.room_players(room_id, is_ready);
```

#### 3.3.3 `room_player_prompts`
Satu baris = satu chain item: owner prompt asli (player yang menulis prompt pada chain index tertentu).
```sql
CREATE TABLE IF NOT EXISTS public.room_player_prompts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  chain_index integer NOT NULL,

  owner_player_id uuid NOT NULL, -- siapa yang menulis prompt
  prompt_text text NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (room_id, chain_index)
);

CREATE INDEX IF NOT EXISTS idx_prompts_room_chain ON public.room_player_prompts(room_id, chain_index);
```

#### 3.3.4 `room_drawings`
Satu gambar per chain item oleh owner tertentu.
```sql
CREATE TABLE IF NOT EXISTS public.room_drawings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  chain_index integer NOT NULL,

  owner_player_id uuid NOT NULL,

  -- untuk sederhana: simpan URL/metadata PNG
  storage_path text NOT NULL,
  public_url text, -- bisa NULL jika pakai signed url di client

  canvas_width integer,
  canvas_height integer,
  stroke_count integer DEFAULT 0,

  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (room_id, chain_index, owner_player_id)
);

CREATE INDEX IF NOT EXISTS idx_drawings_room_chain ON public.room_drawings(room_id, chain_index);
```

#### 3.3.5 `room_guesses`
Guess teks untuk chain tertentu.
```sql
CREATE TABLE IF NOT EXISTS public.room_guesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  chain_index integer NOT NULL,

  guesser_player_id uuid NOT NULL,
  guess_text text NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (room_id, chain_index, guesser_player_id)
);

CREATE INDEX IF NOT EXISTS idx_guesses_room_chain ON public.room_guesses(room_id, chain_index);
```

#### 3.3.6 `room_votes`
Vote lucu/reaction (opsional skema sederhana).
```sql
CREATE TABLE IF NOT EXISTS public.room_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  chain_index integer NOT NULL,

  voter_player_id uuid NOT NULL,
  target_player_id uuid NOT NULL, -- vote untuk gambar owner tertentu
  vote_type integer NOT NULL DEFAULT 1, -- 1..N untuk jenis vote
  emoji text, -- misal '😂','🔥'

  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (room_id, chain_index, voter_player_id)
);

CREATE INDEX IF NOT EXISTS idx_votes_room_chain ON public.room_votes(room_id, chain_index);
```

---

### 3.4 Relasi ringkas
- `rooms (1) — (many) room_players`
- `rooms (1) — (many) room_player_prompts`
- `rooms (1) — (many) room_drawings`
- `rooms (1) — (many) room_guesses`
- `rooms (1) — (many) room_votes`

Mapping gameplay (sederhana):
- Chain item `chain_index = i` memiliki:
  - `room_player_prompts[i]` (prompt original dari owner A)
  - `room_drawings[i]` (gambar oleh owner B untuk chain i)
  - `room_guesses[i]` (guess oleh owner C/D/...) untuk chain i
  - `room_votes[i]` (vote di reveal/result)

> Catatan: Untuk versi kampus yang sederhana, tidak wajib semua player menebak per chain item. Tapi schema memungkinkan.

---

### 3.5 Contoh data minimal
```sql
-- assume sudah ada host
INSERT INTO public.rooms (room_code, host_player_id, game_phase, phase_duration_ms, max_chain_length)
VALUES ('ABCD', '00000000-0000-0000-0000-000000000001', 'lobby', 45000, 4);

-- players (joined_at penting untuk rotation)
INSERT INTO public.room_players (room_id, player_id, username, is_host, is_ready, joined_at)
VALUES
  ('<room_id>', '00000000-0000-0000-0000-000000000001', 'Host', true, true, now() - interval '10 minutes'),
  ('<room_id>', '00000000-0000-0000-0000-000000000002', 'P2', false, true, now() - interval '9 minutes'),
  ('<room_id>', '00000000-0000-0000-0000-000000000003', 'P3', false, false, now() - interval '8 minutes');

-- writing phase: chain_index 0
INSERT INTO public.room_player_prompts (room_id, chain_index, owner_player_id, prompt_text)
VALUES ('<room_id>', 0, '00000000-0000-0000-0000-000000000001', 'Kucing naik motor');

-- drawing phase: chain_index 0 by player 2 (receiver)
INSERT INTO public.room_drawings (room_id, chain_index, owner_player_id, storage_path, public_url, canvas_width, canvas_height)
VALUES ('<room_id>', 0, '00000000-0000-0000-0000-000000000002', 'room/<room_id>/chain/0/player/<player_id>.png', null, 1024, 768);

-- guessing phase: chain_index 0 guesses
INSERT INTO public.room_guesses (room_id, chain_index, guesser_player_id, guess_text)
VALUES
  ('<room_id>', 0, '00000000-0000-0000-0000-000000000003', 'Kucing balapan');

-- reveal: vote
INSERT INTO public.room_votes (room_id, chain_index, voter_player_id, target_player_id, vote_type, emoji)
VALUES ('<room_id>', 0, '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 1, '😂');
```

---

## 4) Realtime synchronization strategy (Supabase Realtime)
### 4.1 Kanal realtime per room
- Subscribe pada:
  1. `rooms` baris room yang aktif (untuk perubahan `game_phase`, `phase_started_at`, `turn_index`).
  2. `room_players` baris yang relevan (player list, ready, host).
  3. Data chain yang sedang aktif:
     - `room_player_prompts` untuk `chain_index = rooms.turn_index`
     - `room_drawings` untuk `chain_index = rooms.turn_index`
     - `room_guesses` untuk `chain_index = rooms.turn_index`
     - (opsional) `room_votes` hanya saat reveal/result

> Agar sederhana: gunakan filter berdasarkan `room_id` dan `chain_index` di query subscription.

### 4.2 Client flow dari realtime state
- `GamePhaseController` mendengar perubahan `rooms.game_phase`.
- Ketika phase berubah:
  - reset local timer
  - load necessary chain data
  - update UI phase screen

### 4.3 Reconnect handling sederhana
- Saat app reconnect:
  1. Fetch ulang `rooms` by `room_code`.
  2. Fetch `room_players`.
  3. Fetch data chain untuk `turn_index` dan phase terkait.
  4. Re-subscribe realtime channel (hindari duplicate subscription).

---

## 5) Timer synchronization (server-authoritative via timestamptz)
### 5.1 Model timer
- Simpan di `rooms`:
  - `phase_started_at` (timestamptz dari server)
  - `phase_duration_ms`
- Di client:
  - `now = DateTime.now().toUtc()` (perkiraan)
  - `elapsed = now - phase_started_at`
  - `remaining = phase_duration_ms - elapsed`

### 5.2 Auto-submit saat timer habis
- Drawing phase:
  - user submit drawing sebelum deadline.
  - jika timer mencapai 0 dan user belum submit:
    - auto submit drawing saat ini (atau submit placeholder kosong) 

> Praktis untuk kampus: gunakan auto-submit hanya kalau user sudah menggambar minimal stroke_count > 0.

---

## 6) Rotation system (Gartic Phone-like, A→B→C...)
### 6.1 Definisi receiver
- Urutan player: ascending `joined_at`.
- Misal index player = [0..N-1].
- Untuk chain_index i:
  - Owner prompt untuk chain 0 ditentukan oleh `player_index_of_host` atau player pertama join (opsi stabil).
  - Untuk simplicity & user request: player pertama yang join menjadi index pertama, sehingga rotation dimulai dari player_index 0.

### 6.2 Algoritma receiver sederhana
Misal:
- `playersOrdered = roomPlayers sorted by joined_at`
- `promptOwnerIndex = (i % N)`
- `drawerIndex = ((i + 1) % N)`
- `guesserStartIndex = ((i + 2) % N)`

Namun karena gameplay Anda: chain berjalan prompt → draw → guess → draw → guess ...
Untuk versi sederhana yang stabil:
- Chain item `i` memiliki:
  - prompt owner = `(i % N)`
  - drawing owner = `((i + 1) % N)`
  - guessers = semua player kecuali drawing owner (atau semua player selain drawing owner)

---

## 7) Reveal chain system (sekuensial, animasi)
### 7.1 Data yang ditampilkan
Untuk setiap `chain_index` dari 0..max_chain_length-1:
- prompt (dari `room_player_prompts[chain_index]`)
- gambar (dari `room_drawings[chain_index]` owner sesuai algoritma)
- guess ringkas (misalnya top guess berdasarkan vote atau heuristik sederhana)

### 7.2 Urutan reveal
- `revealIndex` local state
- Saat phase reveal dimulai:
  - setiap X ms update `revealIndex`
  - render chain item dengan `AnimatedSwitcher` atau `PageView`.

---

## 8) Multiplayer lifecycle (room lifecycle)
### 8.1 Main menu
- Input `username`
- Create room:
  - buat `playerId` lokal sekali (UUID)
  - create room row + set `host_player_id = playerId`
  - insert `room_players` untuk host
- Join room:
  - fetch room by code
  - insert row `room_players` dengan `playerId` & username

### 8.2 Lobby
- Listen realtime `room_players`:
  - tampilkan daftar + ready status
- Host toggle ready/start
- Start button:
  - host set `rooms.game_phase = writing`
  - set `phase_started_at = now()` server
  - set `phase_duration_ms` writing/drawing/guessing sesuai design
  - set `turn_index = 0`

### 8.3 Writing phase
- Prompt dibuat sekali di awal game (untuk chain 0) atau tiap chain.
- Untuk versi kampus yang stabil:
  - chain 0 prompt ditulis oleh promptOwner untuk `chain_index 0`
  - sisanya di-advance otomatis ketika phase berubah.

### 8.4 Drawing phase
- Receiver menggambar prompt yang diterima
- Export PNG → upload Storage → insert/update `room_drawings` untuk `(room_id, chain_index, owner_player_id)`

### 8.5 Guessing phase
- Semua player lain melihat drawing image
- Submit guess → insert `room_guesses`

### 8.6 Rotation advance
- Saat guessing phase selesai:
  - host mengubah `turn_index += 1`
  - set phase berikutnya (drawing/guessing/writing sesuai pattern)

### 8.7 Reveal → Result
- host set `rooms.game_phase='reveal'` ketika semua chain selesai
- display chain progression
- result: leaderboard / funniest drawing (berdasarkan vote)

---

## 9) Flow game lengkap (diagram)
### 9.1 Fase
1. lobby
2. writing (prompt untuk chain i)
3. drawing (gambar untuk chain i)
4. guessing (guess untuk chain i)
5. reveal (semua chain)
6. result

### 9.2 Diagram teks
```
Lobby
  -> (host start)
writing (turn_index=0)
  -> drawing (turn_index=0)
      -> guessing (turn_index=0)
          -> drawing (turn_index=1)
              -> guessing (turn_index=1)
                  ... until max_chain_length-1
                      -> reveal
                          -> result
```

---

## 10) Model Dart class (sesuai schema)
### 10.1 Enum
```dart
enum GamePhase { lobby, writing, drawing, guessing, reveal, result }
```

### 10.2 Core models
```dart
class Room {
  final String id;
  final String roomCode;
  final String hostPlayerId;

  final GamePhase gamePhase;
  final DateTime phaseStartedAt;
  final int phaseDurationMs;

  final int maxChainLength;
  final int turnIndex;

  const Room({
    required this.id,
    required this.roomCode,
    required this.hostPlayerId,
    required this.gamePhase,
    required this.phaseStartedAt,
    required this.phaseDurationMs,
    required this.maxChainLength,
    required this.turnIndex,
  });
}

class RoomPlayer {
  final String id; // pk id
  final String roomId;
  final String playerId; // client identity
  final String username;

  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;
}

class PlayerPromptChain {
  final String id;
  final String roomId;
  final int chainIndex;
  final String ownerPlayerId;
  final String promptText;
  final DateTime createdAt;
}

class RoomDrawing {
  final String id;
  final String roomId;
  final int chainIndex;
  final String ownerPlayerId;

  final String storagePath;
  final String? publicUrl;
  final int? canvasWidth;
  final int? canvasHeight;
  final int strokeCount;
  final DateTime createdAt;
}

class RoomGuess {
  final String id;
  final String roomId;
  final int chainIndex;
  final String guesserPlayerId;
  final String guessText;
  final DateTime createdAt;
}

class RoomVote {
  final String id;
  final String roomId;
  final int chainIndex;
  final String voterPlayerId;
  final String targetPlayerId;
  final int voteType;
  final String? emoji;
  final DateTime createdAt;
}
```

---

## 11) Supabase service layer (skeleton)
### 11.1 Supabase client factory
- gunakan `SupabaseClient` dari package `supabase_flutter`.

### 11.2 Service interfaces
- `RoomService`
  - createRoom, joinRoom, startGame, setPhase
  - getRoomByCode
  - listenRoomChanges(roomId)
- `PlayerService`
  - setReady
  - listRoomPlayers
- `ChainService`
  - upsertPrompt(chainIndex)
  - upsertDrawing(chainIndex)
  - submitGuess(chainIndex)
- `VoteService`
  - submitVote
  - compute leaderboard (client side sederhana)
- `StorageService`
  - uploadDrawingPng(storagePath)
  - buildPublicUrl or create signed url

### 11.3 Realtime channel strategy
- `RoomRealtimeChannel`:
  - subscribe `rooms` row for phase/timer
  - subscribe `room_players` for player list
  - subscribe chain tables untuk `turn_index`
  - unsubscribe/recreate ketika `turn_index` berubah (opsional) untuk mengurangi event noise

---

## 12) Pseudocode multiplayer logic (controller orchestration)
### 12.1 Join/Create
```dart
playerId = uuidV4(); // dibuat sekali saat join

createRoom(username):
  room = rooms.insert(room_code, host_player_id=playerId, game_phase='lobby')
  room_players.insert(room_id=room.id, player_id=playerId, username, is_host=true)
  goToLobby(roomCode)

joinRoom(roomCode, username):
  room = rooms.selectByRoomCode(roomCode)
  room_players.insert(room_id=room.id, player_id=playerId, username, is_host=false)
  goToLobby(roomCode)
```

### 12.2 Ready system
```dart
onToggleReady():
  room_players.update(set is_ready=true/false)

hostStartIfAllReady():
  if all(room_players.is_ready):
    rooms.update(game_phase='writing', phase_started_at=serverNow, phase_duration_ms=WRITING_MS, turn_index=0)
```

### 12.3 Phase advance
```dart
onPhaseTimeoutOrAllSubmissionsReady(phase):
  if phase == 'writing':
     rooms.update(game_phase='drawing', phase_started_at=serverNow, phase_duration_ms=DRAWING_MS)
  if phase == 'drawing':
     rooms.update(game_phase='guessing', phase_started_at=serverNow, phase_duration_ms=GUESSING_MS)
  if phase == 'guessing':
     if turn_index + 1 < max_chain_length:
        rooms.update(game_phase='writing_or_drawing_next', phase_started_at=serverNow, phase_duration_ms=NEXT_MS, turn_index=turn_index+1)
     else:
        rooms.update(game_phase='reveal', phase_started_at=serverNow)
```

---

## 13) Drawing save/upload (CustomPainter)
### 13.1 Data canvas
- Untuk sederhana: simpan final PNG.
- Canvas menggunakan `CustomPainter` dengan model:
  - `List<Stroke>` setiap stroke berisi points, color, brushSize.

### 13.2 Export PNG
- gunakan `RepaintBoundary` / `ui.PictureRecorder` untuk capture.
- export sebagai `Uint8List pngBytes`.

### 13.3 Upload
- bucket: `room-drawings`
- storage path: 
  - `room/{roomId}/chain/{chainIndex}/player/{ownerPlayerId}.png`
- Setelah upload:
  - update insert ke `room_drawings`.

---

## 14) Auto submit saat timer habis
- drawing phase:
  - jika stroke_count >= MIN_STROKE:
    - export PNG dan submit.
  - else:
    - submit placeholder (misal image kosong) atau block.
- guessing phase:
  - bila guess kosong saat timer habis:
    - auto submit teks default: `"(no guess)"` atau tetap insert kosong (tapi schema butuh NOT NULL).

---

## 15) Best practices realtime multiplayer Flutter + Supabase
- **Server authoritative timer**: phase_started_at + duration di DB.
- Realtime subscriptions dibatasi per fase/chain index.
- Pastikan idempotency:
  - upsert drawing/guess dengan constraint UNIQUE.
- RLS:
  - batasi akses berdasarkan `room_id` & membership player.
- Penggunaan Storage:
  - simpan `storage_path` di DB, bukan memercayakan URL.
- Reconnect:
  - rehydrate state dari DB, bukan mengandalkan local only.
- Rate limit UI submit:
  - disable submit button setelah sukses.

---

## 16) UI/UX design system ala Gartic Phone
### 16.1 Theme & color palette (rekomendasi)
- Background gradient: ungu (#6D28D9) → biru muda (#38BDF8) → pink (#EC4899)
- Accent: kuning (#FACC15)
- Card: semi-transparan putih dengan blur jika memungkinkan
- Text: putih + hitam untuk kontras

Contoh warna:
```dart
const doodinkPurple = Color(0xFF7C3AED);
const doodinkSky = Color(0xFF38BDF8);
const doodinkPink = Color(0xFFEC4899);
const doodinkYellow = Color(0xFFFACC15);
```

### 16.2 Reusable widgets
- `DoodinkButton` (primary/secondary)
- `DoodinkCard` (rounded besar + shadow)
- `GradientBackground` (full screen)
- `CountdownBadge` (timer)
- `PartyProgress` (reveal index)

### 16.3 Widget recommendation modern
- `AnimatedSwitcher` untuk perubahan phase
- `Hero` untuk transisi logo
- `PageView` untuk reveal sequencing
- `StreamBuilder`/Riverpod `ConsumerWidget` untuk realtime state

### 16.4 Animation strategy
- Phase transition:
  - fade + slide pendek (200–350ms)
- Reveal:
  - `AnimatedSwitcher` per chain item
  - optional stagger fade in
- Button micro-interactions:
  - `TweenAnimationBuilder` scaling saat pressed

### 16.5 Responsive UI
- Gunakan `LayoutBuilder`:
  - jika layar kecil → canvas full height, tools collapsible
- `SafeArea` + spacing via `MediaQuery.size.width`

---

## 17) Flow diagram (ringkas untuk presentasi)
**Lifecycle**
```
Main Menu
  -> Create/Join Room
    -> Lobby (Realtime players + ready)
      -> Host Start
        -> Writing (turn i prompt owner)
          -> Drawing (receiver draws prompt)
            -> Guessing (others submit guesses)
              -> (repeat for i+1)
                -> Reveal (sequence chain)
                  -> Result (leaderboard + votes/emoji)
```

---

## 18) Deliverables checklist (sesuai permintaan user)
- [x] Arsitektur Flutter (folder & clean architecture)
- [x] State management recommendation (Riverpod)
- [x] Struktur database Supabase (tabel & relasi)
- [x] SQL schema lengkap (DDL)
- [x] Logic multiplayer sederhana (pseudocode & lifecycle)
- [x] Lobby room system (alur & realtime)
- [x] Realtime synchronization strategy
- [x] Drawing save/upload plan
- [x] Rotation system (joined_at)
- [x] Reveal chain system
- [x] Timer synchronization + auto submit
- [x] Model Dart class
- [x] Supabase service layer (skeleton)
- [x] Reconnect handling sederhana
- [x] UI/UX design system ala Gartic Phone (theme, widgets, animation, responsive)

Catatan: dokumen ini adalah spesifikasi awal (foundation). Implementasi kode Flutter + dependencies akan menyusul jika Anda ingin langsung mulai scaffold project.

