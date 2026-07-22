#!/usr/bin/env bash
set -euo pipefail

xdg-mime default org.kde.dolphin.desktop inode/directory

xdg-mime default org.kde.kwrite.desktop text/plain
xdg-mime default org.kde.kwrite.desktop text/markdown

xdg-mime default zen.desktop text/html
xdg-mime default zen.desktop x-scheme-handler/http
xdg-mime default zen.desktop x-scheme-handler/https

xdg-mime default org.kde.gwenview.desktop image/png
xdg-mime default org.kde.gwenview.desktop image/jpeg
xdg-mime default org.kde.gwenview.desktop image/webp
xdg-mime default org.kde.gwenview.desktop image/avif

xdg-mime default audacious.desktop audio/mpeg
xdg-mime default audacious.desktop audio/ogg
xdg-mime default audacious.desktop audio/flac
xdg-mime default audacious.desktop audio/x-flac

xdg-mime default org.kde.haruna.desktop video/mp4
xdg-mime default org.kde.haruna.desktop video/webm
xdg-mime default org.kde.haruna.desktop video/x-matroska

xdg-mime default okularApplication_pdf.desktop application/pdf
