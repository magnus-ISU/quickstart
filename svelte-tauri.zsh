#!/bin/zsh

appname=my-app
echo appname
vared appname

bun create svelte-with-args --name="$appname" --template=skeleton --types=typescript --prettier --eslint --no-playwright --no-vitest --svelte5
cd "$appname"
bun install --save-dev @sveltejs/adapter-static
sd adapter-auto adapter-static svelte.config.js
cat <<! >src/routes/+layout.ts
export const prerender = true
export const ssr = false
!

cat <<!
"$appname"
"$appname"
../build
http://localhost:5173
bun run dev
bun run build
!
cargo tauri init --app-name "$appname" --window-title "$appname" --dev-path http://localhost:5173 --dist-dir ../build --before-dev-command 'bun run dev' --before-build-command 'bun run build'

bun add @tauri-apps/api

# cargo tauri dev # To fix dependencies? No
# bun install @tauri-apps/cli@next
# bun run tauri migrate

cat <<"!" >.prettierrc
{
	"useTabs": true,
	"trailingComma": "all",
	"printWidth": 200,
	"semi": false,
	"plugins": ["prettier-plugin-svelte"],
	"overrides": [{ "files": "*.svelte", "options": { "parser": "svelte" } }]
}
!

cat <<"!" >src-tauri/rustfmt.toml
hard_tabs=true
!

cat <<"!" >src/routes/+page.svelte
<script lang="ts">
	import App from "$lib/App.svelte"
</script>

<App />
!

cat <<"!" >src/lib/App.svelte
<script lang="ts">
	import { invoke } from '@tauri-apps/api/tauri'

	let name = ''
	let greetMsg = ''

	async function greet() {
		greetMsg = await invoke('greet', { name })
	}
</script>

<div>
	<input id="greet-input" placeholder="Enter a name..." bind:value="{name}" />
	<button on:click="{greet}">Greet</button>
	<p>{greetMsg}</p>
</div>
!

cat <<"!" >src-tauri/src/main.rs
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
	tauri::Builder::default()
		.invoke_handler(tauri::generate_handler![greet])
		.run(tauri::generate_context!())
		.expect("error while running tauri application");
}

#[tauri::command]
fn greet(name: &str) -> String {
	format!("Hello, {}!", name)
}
!

git init .
git add .
git commit -m "x"

cargo tauri dev
