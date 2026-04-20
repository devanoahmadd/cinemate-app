# Application Specification Documentation — Cinemate

---

## Table of Contents

1. [Application Description](#1-application-description)
2. [Technologies Used](#2-technologies-used)
3. [Application Architecture](#3-application-architecture)
4. [Application Features](#4-application-features)
5. [APIs Used](#5-apis-used)
6. [Navigation Flow](#6-navigation-flow)
7. [Folder Structure](#7-folder-structure)
8. [How to Run the Application](#8-how-to-run-the-application)

---

## 1. Application Description

**Cinemate** is a Flutter-based mobile application for exploring movies and TV shows. Users can discover the latest, most popular, top-rated, upcoming movies, and trending TV series in real-time through integration with The Movie Database (TMDB) API. The application includes a user authentication system powered by Firebase Authentication, a personal watchlist backed by Cloud Firestore, and a fully editable profile with photo support.

| | |
|---|---|
| **Application Name** | Cinemate |
| **Platform** | Android (Flutter) |
| **Version** | 1.0.0 |
| **Programming Language** | Dart |
| **Framework** | Flutter SDK ^3.11.1 |

---

## 2. Technologies Used

### Framework & Language
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | ^3.11.1 | Primary framework for app development |
| Dart | (bundled) | Programming language |

### State Management
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^9.1.1 | BLoC pattern implementation for state management |
| `equatable` | ^2.0.5 | Object comparison based on property values |

### Networking
| Package | Version | Purpose |
|---------|---------|---------|
| `dio` | ^5.3.3 | HTTP client for TMDB API requests |

### Authentication & Backend
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^4.6.0 | Firebase SDK initialization |
| `firebase_auth` | ^6.3.0 | User authentication (login, register, logout, change password) |
| `cloud_firestore` | ^6.3.0 | Persistent watchlist and user profile data storage |
| `firebase_storage` | ^13.3.0 | Upload and store profile photos |

### Navigation
| Package | Version | Purpose |
|---------|---------|---------|
| `go_router` | ^17.2.0 | Declarative routing with automatic route protection |

### UI / Display
| Package | Version | Purpose |
|---------|---------|---------|
| `cached_network_image` | ^3.3.0 | Display and cache images from URLs |
| `shimmer` | ^3.0.0 | Skeleton loading animation while data is being fetched |
| `google_fonts` | ^8.0.2 | Custom typography (app-wide font system) |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_dotenv` | ^6.0.0 | Read secret variables from `.env` file |
| `image_picker` | ^1.1.2 | Select profile photo from gallery or camera |
| `url_launcher` | ^6.3.0 | Open trailer links and watch-provider pages in browser |
| `share_plus` | ^13.0.0 | Share movie/show details via the system share sheet |

---

## 3. Application Architecture

Cinemate uses the **BLoC (Business Logic Component)** architectural pattern combined with a **Simple Layered Architecture**.

### Architecture Diagram

```
┌─────────────────────────────────────────────┐
│            PRESENTATION LAYER               │
│         screens/ + bloc/ + widgets/         │
│  Widgets only display data & dispatch Events│
├─────────────────────────────────────────────┤
│              DATA LAYER                     │
│         data/services/ + data/models/       │
│  API communication and JSON parsing         │
├─────────────────────────────────────────────┤
│              CORE LAYER                     │
│   core/constants/ + core/routes/            │
│   core/theme/                               │
│  Shared config: routing, constants, theming │
└─────────────────────────────────────────────┘
```

### BLoC Pattern

BLoC separates business logic from the UI through three components:

- **Event** → An action dispatched from a Widget to the BLoC (e.g. `AuthLoginRequested`)
- **BLoC** → Processes Events, executes logic, calls Services
- **State** → The application condition sent back to the Widget (e.g. `AuthAuthenticated`)

```
Widget → (add Event) → BLoC → (emit State) → Widget rebuilds
```

### BLoCs Used

#### AuthBloc — Authentication
| Event | Resulting State |
|-------|----------------|
| `AuthCheckRequested` | `AuthAuthenticated` / `AuthUnauthenticated` |
| `AuthLoginRequested` | `AuthLoading` → `AuthAuthenticated` / `AuthFailure` |
| `AuthRegisterRequested` | `AuthLoading` → `AuthAuthenticated` / `AuthFailure` |
| `AuthLogoutRequested` | `AuthUnauthenticated` |

#### MovieBloc — Movie Data
| Event | Resulting State |
|-------|----------------|
| `MovieFetchHome` | `MovieLoading` → `MovieHomeLoaded` |
| `MovieFetchListPage(category, page)` | `MovieLoading` → `MovieListPageLoaded` |
| `MovieSearch(query)` | `MovieLoading` → `MovieSearchLoaded` |
| `MovieClearSearch` | `MovieInitial` |

#### TvBloc — TV Show Data
| Event | Resulting State |
|-------|----------------|
| `TvFetchHome` | `TvLoading` → `TvHomeLoaded` |
| `TvFetchListPage(category, page)` | `TvLoading` → `TvListPageLoaded` |
| `TvSearch(query)` | `TvLoading` → `TvSearchLoaded` |
| `TvClearSearch` | `TvInitial` |

#### WatchlistBloc — Personal Watchlist
| Event | Resulting State |
|-------|----------------|
| `WatchlistLoad` | `WatchlistLoading` → `WatchlistLoaded` |
| `WatchlistAdd(item)` | `WatchlistLoaded` (updated) |
| `WatchlistRemove(docId)` | `WatchlistLoaded` (updated) |
| `WatchlistCheckItem(docId)` | `WatchlistItemChecked` |

---

## 4. Application Features

### 4.1 User Authentication

**Account Registration**
- Users can create a new account using email and password
- Email format and password strength validation handled by Firebase
- After successful registration, users are redirected to the main screen

**Login**
- Users sign in using their registered email and password
- Login button is disabled during processing (prevents double requests)
- Displays informative error messages for each type of failure

**Route Protection**
- The main screen is only accessible to logged-in users
- Unauthenticated users are automatically redirected to the login screen
- Authenticated users who open the login/register page are redirected to Home

---

### 4.2 Home Screen (Home Tab)

**Hero Banner**
- Displays one featured film from Now Playing as the main banner
- The film is randomly selected from the top 8 each session
- Displays: title, star rating, release year — tappable to view movie detail
- Supports pull-to-refresh to reload and re-randomize the hero film

**Movie Categories Grid**
- 4 movie categories in a 2-column card grid: Popular, Now Playing, Top Rated, Upcoming
- Each card is tappable to open the full paginated list
- 2 TV show categories also displayed: Popular TV, Top Rated TV

**Trending Today**
- Top 5 most popular films with ranked positions (#1–#5)
- Ranking badge colors: Gold, Silver, Bronze, Gray
- Each item shows: poster, title, rating, release year

**Performance Optimization**
- Home movie data cached in the widget; re-fetch not needed when switching tabs
- Skeleton loading shown only on initial data load

---

### 4.3 Movie / TV Search (Search Tab)

- Real-time search as the user types (no button press required)
- **Actor Search Fallback**: if a query matches no titles, automatically searches by actor name and returns that actor's filmography / show credits
- Displays number of results found
- Each result shows: poster, title, rating, release year, synopsis excerpt
- Clear button (X) to reset the search state
- Keyboard appears automatically when the tab is opened
- Handles: empty results, loading, and error states

---

### 4.4 Movie / TV List Screen

- Displays content in an infinite-scroll 2-column poster grid
- **Pagination**: loads the next page automatically as the user scrolls near the bottom
- **Genre Filter Chips**: horizontal scrollable filter at the top; filtering is local (no extra API call)
- **Sort Options**: sort by Popularity, Rating, Release Date via dropdown
- Each item shows: poster, title, star rating

---

### 4.5 Movie Detail Screen

Displays complete information about a movie fetched in parallel:

- Backdrop image with gradient overlay
- Title, star rating, score (out of 10), vote count, release date
- Genres, runtime, budget, revenue, status, tagline
- Full synopsis with expand/collapse
- **Watchlist toggle** — save or remove with a single tap; state persisted in Firestore
- **Share button** — share the movie title and rating via system share sheet
- **Watch Providers** — streaming/rental/purchase options for the user's region
- **Trailer** — tappable to open the official trailer in the browser via `url_launcher`
- **Cast** — horizontal scrollable list with "See All" to open the full cast screen
- **Reviews** — first 2 reviews shown with "See All" to open paginated reviews screen
- **Similar & Recommended** — horizontal scrollable lists with "See All" for full paginated view
- **Collection** — if the movie belongs to a collection (e.g. franchise), a tappable card opens the collection screen

---

### 4.6 TV Show Detail Screen

Mirrors Movie Detail with TV-specific fields:

- Title, rating, first air date, number of seasons/episodes
- Creator, genres, networks
- Cast, Reviews, Similar, Recommended, Watch Providers, Trailers
- Watchlist toggle and Share button
- Season list with air dates

---

### 4.7 Collection Screen

- Displays all movies in a franchise/collection (e.g. "The Avengers Collection")
- Overview text of the collection
- Tappable movie posters that navigate to the respective Movie Detail

---

### 4.8 Cast Screen

- Full cast list for a movie or TV show in a scrollable grid
- Each item shows: profile photo, actor name, character name

---

### 4.9 Reviews Screen

- Paginated list of user reviews from TMDB
- Shows: reviewer avatar, username, rating, review date, review body
- Each review card supports expand/collapse for long text

---

### 4.10 Watchlist Screen

- Displays all items (movies and TV shows) saved by the user
- Backed by Cloud Firestore, persisted across sessions and devices
- Each item shows: poster, title, type badge (Movie / TV), rating
- Swipe or tap to remove from watchlist

---

### 4.11 Profile Tab & Profile Management

**Profile Tab**
- Displays user avatar, display name, and email
- Shows a horizontal preview of the watchlist (up to 6 items) with "See All"
- Quick-access cards: Edit Profile, Change Password, Watchlist, Logout

**Edit Profile Screen**
- Change display name (saved to Cloud Firestore)
- Upload a new profile photo from gallery or camera (stored in Firebase Storage)

**Change Password Screen**
- Requires current password re-authentication before setting a new password
- Uses Firebase's `reauthenticateWithCredential` + `updatePassword`

---

### 4.12 Tab Navigation

- 3 main tabs: Home, Search, Profile
- `IndexedStack` preserves each tab's scroll position and state
- Animated active/inactive indicator on tab icons and labels

---

## 5. APIs Used

### 5.1 The Movie Database (TMDB) API

**Base URL:** `https://api.themoviedb.org/3`

**Authentication:** Bearer Token (stored in `.env`, not hardcoded)

```
Authorization: Bearer {TMDB_ACCESS_TOKEN}
```

#### Movie Endpoints

| No | Endpoint | Method | Purpose |
|----|----------|--------|---------|
| 1 | `/movie/now_playing?page={p}` | GET | Currently playing movies (paginated) |
| 2 | `/movie/popular?page={p}` | GET | Most popular movies (paginated) |
| 3 | `/movie/top_rated?page={p}` | GET | Highest-rated movies (paginated) |
| 4 | `/movie/upcoming?page={p}` | GET | Upcoming movies (paginated) |
| 5 | `/trending/movie/week` | GET | Weekly trending movies |
| 6 | `/genre/movie/list` | GET | All movie genres |
| 7 | `/search/movie?query={q}` | GET | Search movies by title |
| 8 | `/search/person?query={q}` | GET | Search people (actor fallback) |
| 9 | `/person/{id}/movie_credits` | GET | Actor's movie filmography |
| 10 | `/discover/movie?sort_by={s}&with_genres={g}&page={p}` | GET | Discover with sort + genre filter |
| 11 | `/movie/{id}` | GET | Movie detail (runtime, budget, etc.) |
| 12 | `/movie/{id}/credits` | GET | Cast and crew |
| 13 | `/movie/{id}/reviews?page={p}` | GET | User reviews (paginated) |
| 14 | `/movie/{id}/similar?page={p}` | GET | Similar movies |
| 15 | `/movie/{id}/recommendations?page={p}` | GET | Recommended movies |
| 16 | `/movie/{id}/watch/providers` | GET | Streaming/rental/purchase providers |
| 17 | `/movie/{id}/videos` | GET | Trailers and clips |
| 18 | `/collection/{id}` | GET | Movie collection/franchise detail |

#### TV Show Endpoints

| No | Endpoint | Method | Purpose |
|----|----------|--------|---------|
| 1 | `/tv/airing_today?page={p}` | GET | Shows airing new episodes today |
| 2 | `/tv/on_the_air?page={p}` | GET | Shows airing within 7 days |
| 3 | `/tv/popular?page={p}` | GET | Most popular TV shows |
| 4 | `/tv/top_rated?page={p}` | GET | Highest-rated TV shows |
| 5 | `/trending/tv/week` | GET | Weekly trending TV shows |
| 6 | `/genre/tv/list` | GET | All TV genres |
| 7 | `/search/tv?query={q}` | GET | Search TV shows by title |
| 8 | `/person/{id}/tv_credits` | GET | Actor's TV show credits |
| 9 | `/discover/tv?sort_by={s}&with_genres={g}&page={p}` | GET | Discover TV with sort + genre filter |
| 10 | `/tv/{id}` | GET | TV show detail |
| 11 | `/tv/{id}/credits` | GET | Cast and crew |
| 12 | `/tv/{id}/reviews` | GET | User reviews |
| 13 | `/tv/{id}/similar` | GET | Similar shows |
| 14 | `/tv/{id}/recommendations` | GET | Recommended shows |
| 15 | `/tv/{id}/watch/providers` | GET | Streaming providers |
| 16 | `/tv/{id}/videos` | GET | Trailers and clips |
| 17 | `/tv/{id}/season/{n}` | GET | Season detail (episodes, air dates) |

**Image URLs:**
```
Poster  : https://image.tmdb.org/t/p/w500{poster_path}
Backdrop: https://image.tmdb.org/t/p/w780{backdrop_path}
Profile : https://image.tmdb.org/t/p/w185{profile_path}
```

**Parallel Fetch (Detail Screens):**
```dart
final results = await Future.wait([
  _service.getMovieDetail(id),
  _service.getCredits(id),
  _service.getReviews(id),
  _service.getSimilar(id),
  _service.getRecommendations(id),
  _service.getWatchProviders(id),
  _service.getVideos(id),
]);
```

---

### 5.2 Firebase Services

#### Firebase Authentication

**Provider:** Google Firebase — Email & Password

| Operation | Firebase Method | Description |
|-----------|----------------|-------------|
| Check login status | `FirebaseAuth.currentUser` | Called on app launch |
| Login | `signInWithEmailAndPassword()` | Authenticate a user |
| Registration | `createUserWithEmailAndPassword()` | Create a new account |
| Logout | `signOut()` | End the user session |
| Change password | `reauthenticateWithCredential()` + `updatePassword()` | Secure password update |

**Error Code Mapping:**

| Error Code | Message Shown to User |
|------------|-----------------------|
| `user-not-found` | User not found |
| `wrong-password` | Incorrect password |
| `email-already-in-use` | Email is already in use |
| `weak-password` | Password is too weak |
| `invalid-email` | Invalid email format |
| Others | An error occurred, please try again |

#### Cloud Firestore

**Collections used:**

| Collection | Purpose |
|------------|---------|
| `users/{uid}/profile` | Display name and profile photo URL |
| `users/{uid}/watchlist` | Saved movies and TV shows |

**Watchlist document structure:**
```json
{
  "docId":      "movie_12345",
  "mediaType":  "movie",
  "title":      "Interstellar",
  "posterPath": "/path.jpg",
  "voteAverage": 8.4,
  "addedAt":    Timestamp
}
```

#### Firebase Storage

- Profile photos are uploaded to `profile_photos/{uid}.jpg`
- Download URL is saved to Firestore and displayed in the Profile tab

---

## 6. Navigation Flow

```
App Launch
    │
    ▼
Splash Screen (logo animation)
    │
    ├── Already logged in? ───────────────────► /home (MainScreen)
    │                                                 │
    └── Not logged in? ──► /login (LoginScreen)       ├── Tab: Home
                               │                      ├── Tab: Search
                               ├── Login success ────►│   └── Tab: Profile
                               │
                               └── /register ──► Register success ──► /home

From Home Tab:
    ├── Tap movie category ──────────────────► /movies (MovieListScreen)
    ├── Tap TV category ─────────────────────► /tv (TvListScreen)
    ├── Tap hero / trending movie ───────────► /movies/:id (MovieDetailScreen)
    └── Tap trending TV ─────────────────────► /tv/:id (TvDetailScreen)

From MovieListScreen / TvListScreen:
    └── Tap item ────────────────────────────► /movies/:id or /tv/:id

From MovieDetailScreen / TvDetailScreen:
    ├── Tap "See All Cast" ──────────────────► /cast (CastScreen)
    ├── Tap "See All Reviews" ───────────────► /reviews (ReviewsScreen)
    ├── Tap "See All Similar/Recommended" ──► /related (MediaRelatedScreen)
    └── Tap "Collection" ────────────────────► /collection (CollectionScreen)

From Profile Tab:
    ├── Tap "Edit Profile" ──────────────────► /edit-profile (EditProfileScreen)
    ├── Tap "Change Password" ───────────────► /change-password (ChangePasswordScreen)
    └── Tap "See All Watchlist" ─────────────► /watchlist (WatchlistScreen)

From Search Tab:
    └── Tap result ──────────────────────────► /movies/:id or /tv/:id
```

**Route Protection (GoRouter Redirect):**
```
Every navigation → check auth state
    ├── Not logged in + accessing protected page → redirect to /login
    └── Logged in + accessing /login or /register → redirect to /home
```

---

## 7. Folder Structure

```
lib/
├── main.dart                                # Entry point, app & BLoC initialization
│
├── bloc/                                    # State Management (BLoC Pattern)
│   ├── auth_bloc/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   ├── movie_bloc/
│   │   ├── movie_bloc.dart
│   │   ├── movie_event.dart
│   │   └── movie_state.dart
│   ├── tv_bloc/
│   │   ├── tv_bloc.dart
│   │   ├── tv_event.dart
│   │   └── tv_state.dart
│   └── watchlist_bloc/
│       ├── watchlist_bloc.dart
│       ├── watchlist_event.dart
│       └── watchlist_state.dart
│
├── data/                                    # Data Layer
│   ├── models/
│   │   ├── movie_model.dart
│   │   ├── movie_detail_model.dart
│   │   ├── genre_model.dart
│   │   ├── cast_model.dart
│   │   ├── review_model.dart
│   │   ├── video_model.dart
│   │   ├── watch_provider_model.dart
│   │   ├── collection_detail_model.dart
│   │   ├── movie_filter.dart
│   │   ├── tv_model.dart
│   │   ├── tv_detail_model.dart
│   │   └── watchlist_model.dart
│   └── services/
│       ├── movie_service.dart               # TMDB movie API calls
│       ├── tv_service.dart                  # TMDB TV API calls
│       ├── watchlist_service.dart           # Firestore watchlist CRUD
│       └── user_service.dart               # Firestore user profile read/write
│
├── screens/                                 # Presentation Layer (UI)
│   ├── splash/
│   │   ├── splash_screen.dart
│   │   └── cinemate_logo_animation.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── main/
│   │   ├── main_screen.dart                 # 3-tab container with bottom nav
│   │   └── tabs/
│   │       ├── home_tab.dart
│   │       ├── search_tab.dart
│   │       └── profile_tab.dart
│   ├── movie/
│   │   ├── movie_list_screen.dart           # Paginated list + genre/sort filter
│   │   ├── movie_detail_screen.dart         # Full movie detail
│   │   ├── collection_screen.dart           # Movie franchise/collection
│   │   ├── cast_screen.dart                 # Full cast grid
│   │   ├── reviews_screen.dart              # Paginated reviews
│   │   └── media_related_screen.dart        # Similar / Recommendations
│   ├── tv/
│   │   ├── tv_list_screen.dart              # Paginated TV list + genre/sort filter
│   │   └── tv_detail_screen.dart            # Full TV show detail
│   └── profile/
│       ├── watchlist_screen.dart            # Full watchlist
│       ├── edit_profile_screen.dart         # Edit name + photo
│       └── change_password_screen.dart      # Secure password change
│
├── widgets/
│   └── review_card.dart                     # Reusable review card widget
│
└── core/                                    # Shared / Core Layer
    ├── constants/
    │   └── api_constants.dart               # All TMDB endpoints
    ├── routes/
    │   └── app_router.dart                  # GoRouter config & route protection
    └── theme/
        ├── theme.dart                       # Barrel export
        ├── app_theme.dart                   # ThemeData configuration
        ├── app_colors.dart                  # Color palette constants
        ├── app_typography.dart              # TextStyle definitions (Google Fonts)
        ├── app_shadows.dart                 # BoxShadow presets
        └── app_spacing.dart                 # Spacing/padding constants
```

---

## 8. How to Run the Application

### Prerequisites
- Flutter SDK version 3.11.1 or later
- Android Studio / VS Code
- A TMDB account to obtain an API token
- A Firebase project with Authentication, Firestore, and Storage enabled

### Setup Steps

**1. Clone the repository**
```bash
git clone https://github.com/username/cinemate.git
cd cinemate
```

**2. Set up environment variables**
```bash
cp .env.example .env
# Edit .env and add your TMDB token:
# TMDB_ACCESS_TOKEN=your_tmdb_bearer_token_here
```

**3. Set up Firebase**
- Create a project at [Firebase Console](https://console.firebase.google.com)
- Enable **Authentication** (Email/Password)
- Enable **Cloud Firestore** (production or test mode)
- Enable **Firebase Storage**
- Download `google-services.json` → place in `android/app/`
- Run `flutterfire configure` to regenerate `firebase_options.dart`

**4. Install dependencies**
```bash
flutter pub get
```

**5. Run the application**
```bash
flutter run
```

**6. (Optional) Build release APK**
```bash
flutter build apk --release
```

---

*This documentation was created for the Flutter Bootcamp Final Project submission — Cinemate v2.0.*
