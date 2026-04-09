#!/usr/bin/env bash
# Monitor Spotify track changes via MPRIS and send notifications with album art.
# Requires: playerctl, libnotify (notify-send), curl

tmp_icon=""

cleanup() {
    [[ -n "$tmp_icon" ]] && rm -f "$tmp_icon"
}
trap cleanup EXIT

playerctl --player=spotify --follow metadata --format $'{{artist}} - {{title}}\t{{mpris:artUrl}}' \
    | while IFS=$'\t' read -r track art_url; do
        [[ -z "$track" ]] && continue

        icon="spotify"

        if [[ -n "$art_url" ]]; then
            if [[ "$art_url" == file://* ]]; then
                icon="${art_url#file://}"
            elif [[ "$art_url" == http* ]]; then
                tmp_icon=$(mktemp /tmp/spotify-art-XXXXXX.jpg)
                curl -sf -o "$tmp_icon" "$art_url" && icon="$tmp_icon"
            fi
        fi

        notify-send --icon="$icon" --app-name=Spotify "Now Playing" "$track" --expire-time 10000
    done
