# assets_new/ — "New" version overrides

This folder mirrors `assets/`. When the game is in **NEW** mode (toggle with **F1**,
indicator shown top-right), any texture whose path is `res://assets/<x>` is
transparently redirected to `res://assets_new/<x>` **if that file exists**.
Anything not overridden falls back to the original art automatically.

Resolution happens in `GameState.resolve_asset()`; every `_load_texture()` is routed
through it. Preference persists in `user://version_pref.cfg`.
