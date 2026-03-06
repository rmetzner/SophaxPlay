#!/usr/bin/env python3
"""
SophaxPlay — Minimalist Music Player
Supports MP3 and FLAC formats.

Requirements: pip install pygame mutagen PySide6
"""

import os
import sys
from typing import Callable

import pygame
from mutagen.flac import FLAC
from mutagen.mp3 import MP3
from PySide6.QtCore import Qt, QSize, QRect, QTimer
from PySide6.QtGui import QColor, QFont, QPainter, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QFileDialog,
    QFrame,
    QHBoxLayout,
    QLabel,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QPushButton,
    QScrollArea,
    QSlider,
    QStyledItemDelegate,
    QStyleOptionViewItem,
    QVBoxLayout,
    QWidget,
)

# ── Palette — SophaxPay exact ──────────────────────────────────────────────────

BLACK = "#0a0a0a"
WHITE = "#ffffff"
GRAY1 = "#f5f5f5"
GRAY2 = "#e8e8e8"
GRAY3 = "#c0c0c0"
GRAY4 = "#888888"
MONO  = "'JetBrains Mono', 'Menlo', 'Courier New', monospace"

# ── Helpers ────────────────────────────────────────────────────────────────────

def _fmt(seconds: float) -> str:
    m, s = divmod(max(0, int(seconds)), 60)
    return f"{m}:{s:02d}"


def _read_meta(path: str) -> tuple:
    stem   = os.path.splitext(os.path.basename(path))[0]
    folder = os.path.basename(os.path.dirname(path))
    try:
        if path.lower().endswith(".mp3"):
            audio  = MP3(path)
            tags   = audio.tags or {}
            title  = str(tags.get("TIT2", stem))
            artist = str(tags.get("TPE1", "Unknown Artist"))
            album  = str(tags.get("TALB", folder))
            cover  = None
            for key in tags.keys():
                if key.startswith("APIC"):
                    cover = tags[key].data
                    break
            return title, artist, album, audio.info.length, cover
        if path.lower().endswith(".flac"):
            audio  = FLAC(path)
            title  = (audio.get("title")  or [stem])[0]
            artist = (audio.get("artist") or ["Unknown Artist"])[0]
            album  = (audio.get("album")  or [folder])[0]
            cover  = audio.pictures[0].data if audio.pictures else None
            return title, artist, album, audio.info.length, cover
    except Exception:
        pass
    return stem, "Unknown Artist", folder, 0.0, None


def _pixmap_from_bytes(data: bytes, size: int) -> QPixmap:
    px = QPixmap()
    px.loadFromData(data)
    return px.scaled(size, size, Qt.KeepAspectRatioByExpanding, Qt.SmoothTransformation)


def _placeholder(size: int) -> QPixmap:
    px = QPixmap(size, size)
    px.fill(QColor(GRAY1))
    p = QPainter(px)
    p.setPen(QColor(GRAY3))
    p.setFont(QFont("Helvetica", size // 4))
    p.drawText(px.rect(), Qt.AlignCenter, "♪")
    p.end()
    return px


# ── Track list delegate ────────────────────────────────────────────────────────

class _TrackDelegate(QStyledItemDelegate):
    """Renders each track row: number | bold title | duration."""

    ROW_H = 68

    def paint(self, painter: QPainter, option: QStyleOptionViewItem, index) -> None:
        painter.save()
        r = option.rect
        selected = bool(option.state & option.state.Selected)

        # Background
        if selected:
            painter.fillRect(r, QColor(BLACK))
        elif option.state & option.state.MouseOver:
            painter.fillRect(r, QColor(GRAY1))
        else:
            painter.fillRect(r, QColor(WHITE))

        text_col  = QColor(WHITE) if selected else QColor(BLACK)
        muted_col = QColor(GRAY4) if selected else QColor(GRAY3)

        # Track number (mono, gray, right-aligned)
        num = index.data(Qt.UserRole) or ""
        painter.setFont(QFont("JetBrains Mono", 12))
        painter.setPen(muted_col)
        num_rect = QRect(r.x() + 24, r.y(), 32, r.height())
        painter.drawText(num_rect, Qt.AlignRight | Qt.AlignVCenter, num)

        # Title (Inter, bold, 17px)
        title = index.data(Qt.DisplayRole) or ""
        painter.setPen(text_col)
        painter.setFont(QFont("Inter", 17, QFont.Weight.DemiBold))
        title_rect = QRect(r.x() + 68, r.y(), r.width() - 150, r.height())
        painter.drawText(title_rect, Qt.AlignLeft | Qt.AlignVCenter, title)

        # Duration (mono, gray, right)
        dur = index.data(Qt.UserRole + 1) or ""
        painter.setPen(muted_col)
        painter.setFont(QFont("JetBrains Mono", 12))
        dur_rect = QRect(r.x() + r.width() - 76, r.y(), 68, r.height())
        painter.drawText(dur_rect, Qt.AlignRight | Qt.AlignVCenter, dur)

        # Bottom divider
        if not selected:
            painter.setPen(QColor(GRAY2))
            painter.drawLine(r.bottomLeft(), r.bottomRight())

        painter.restore()

    def sizeHint(self, option, index) -> QSize:
        return QSize(0, self.ROW_H)


# ── Album row (SophaxPay numbered step) ────────────────────────────────────────

class _AlbumRow(QFrame):

    def __init__(self, number: int, name: str, on_click: Callable) -> None:
        super().__init__()
        self._on_click = on_click
        self._active   = False
        self.setCursor(Qt.PointingHandCursor)
        self.setFixedHeight(68)

        lay = QHBoxLayout(self)
        lay.setContentsMargins(12, 10, 12, 10)
        lay.setSpacing(14)

        self._circle = QLabel(str(number))
        self._circle.setFixedSize(30, 30)
        self._circle.setAlignment(Qt.AlignCenter)
        lay.addWidget(self._circle)

        col = QWidget()
        col.setAttribute(Qt.WA_TransparentForMouseEvents)
        clay = QVBoxLayout(col)
        clay.setContentsMargins(0, 0, 0, 0)
        clay.setSpacing(2)
        self._title = QLabel(name[:32] + ("…" if len(name) > 32 else ""))
        self._sub   = QLabel("—")
        clay.addWidget(self._title)
        clay.addWidget(self._sub)
        lay.addWidget(col, 1)

        self._apply(False)

    def set_active(self, active: bool) -> None:
        self._active = active
        self._apply(active)

    def set_sub(self, text: str) -> None:
        self._sub.setText(text)

    def _apply(self, active: bool) -> None:
        if active:
            self.setStyleSheet(
                "QFrame { background: #f5f5f5; border: 1.5px solid #0a0a0a; border-radius: 4px; }"
            )
            self._circle.setStyleSheet(
                f"background: #0a0a0a; color: #ffffff; border-radius: 15px;"
                f" font-family: {MONO}; font-size: 11px; font-weight: 700;"
            )
            self._title.setStyleSheet(
                "color: #0a0a0a; font-size: 14px; font-weight: 600; background: transparent;"
            )
            self._sub.setStyleSheet(
                f"color: {GRAY4}; font-size: 11px; font-family: {MONO}; background: transparent;"
            )
        else:
            self.setStyleSheet(
                "QFrame { background: transparent; border: 1.5px solid transparent; border-radius: 4px; }"
            )
            self._circle.setStyleSheet(
                f"background: transparent; color: {GRAY4}; border: 1.5px solid {GRAY3};"
                f" border-radius: 15px; font-family: {MONO}; font-size: 11px;"
            )
            self._title.setStyleSheet(f"color: {GRAY4}; font-size: 14px; background: transparent;")
            self._sub.setStyleSheet(
                f"color: {GRAY3}; font-size: 11px; font-family: {MONO}; background: transparent;"
            )

    def enterEvent(self, _e) -> None:
        if not self._active:
            self.setStyleSheet(
                "QFrame { background: #f5f5f5; border: 1.5px solid transparent; border-radius: 4px; }"
            )
            self._title.setStyleSheet("color: #0a0a0a; font-size: 14px; background: transparent;")

    def leaveEvent(self, _e) -> None:
        if not self._active:
            self._apply(False)

    def mousePressEvent(self, _e) -> None:
        self._on_click()


# ── Global stylesheet ──────────────────────────────────────────────────────────

STYLE = f"""
* {{
    font-family: 'Inter', 'SF Pro Text', 'Helvetica Neue', Arial, sans-serif;
    font-size: 13px;
    color: {BLACK};
}}
QMainWindow, QWidget {{ background: {WHITE}; }}

/* Track list — all white, custom delegate handles drawing */
QListWidget#trackList {{
    background: {WHITE};
    border: none;
    outline: none;
}}
QListWidget#trackList::item {{ border: none; }}

/* Sidebar scrollbar */
QScrollArea#albumScroll QScrollBar:vertical {{
    background: transparent; width: 3px; border: none;
}}
QScrollArea#albumScroll QScrollBar::handle:vertical {{
    background: {GRAY2}; border-radius: 1px; min-height: 20px;
}}
QScrollArea#albumScroll QScrollBar::add-line:vertical,
QScrollArea#albumScroll QScrollBar::sub-line:vertical {{ height: 0; }}

/* Track list scrollbar */
QListWidget#trackList QScrollBar:vertical {{
    background: transparent; width: 3px; border: none;
}}
QListWidget#trackList QScrollBar::handle:vertical {{
    background: {GRAY2}; border-radius: 1px; min-height: 20px;
}}
QListWidget#trackList QScrollBar::add-line:vertical,
QListWidget#trackList QScrollBar::sub-line:vertical {{ height: 0; }}

/* Black play button */
QPushButton#playBtn {{
    background: {BLACK};
    color: {WHITE};
    border: none;
    font-family: {MONO};
    font-size: 13px;
    font-weight: 700;
    letter-spacing: 2px;
    padding: 14px 40px;
    border-radius: 3px;
    min-width: 160px;
}}
QPushButton#playBtn:hover {{ background: #222222; }}

/* Transport badge buttons */
QPushButton#ctrlBtn {{
    background: transparent;
    color: {BLACK};
    border: 1.5px solid {GRAY3};
    border-radius: 2px;
    font-family: {MONO};
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 1px;
    padding: 12px 22px;
    min-width: 72px;
}}
QPushButton#ctrlBtn:hover {{ border-color: {BLACK}; }}

/* Add files */
QPushButton#addBtn {{
    background: {WHITE};
    color: {GRAY4};
    border: none;
    border-top: 1px solid {GRAY2};
    text-align: left;
    padding: 10px 20px;
    font-family: {MONO};
    font-size: 10px;
    letter-spacing: 1px;
}}
QPushButton#addBtn:hover {{ color: {BLACK}; }}
"""


# ── Main window ────────────────────────────────────────────────────────────────

class SophaxPlay(QMainWindow):

    def __init__(self) -> None:
        super().__init__()
        pygame.mixer.pre_init(44100, -16, 2, 2048)
        pygame.mixer.init()

        self.albums:          list[str]             = []
        self.album_tracks:    dict[str, list[dict]] = {}
        self.playing_album:   str   = ""
        self.playing_idx:     int   = -1
        self.displayed_album: str   = ""
        self.is_playing:      bool  = False
        self.is_paused:       bool  = False
        self.duration:        float = 0.0
        self._seek_off:       float = 0.0
        self._seeking:        bool  = False
        self._album_rows:     list[_AlbumRow] = []

        self.setWindowTitle("SophaxPlay")
        self.setMinimumSize(780, 500)
        self.resize(1020, 640)
        self.setStyleSheet(STYLE)

        self._build_ui()

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)
        self._timer.start(300)

    # ── Layout ──────────────────────────────────────────────────────────────────

    def _build_ui(self) -> None:
        root = QWidget()
        self.setCentralWidget(root)
        vlay = QVBoxLayout(root)
        vlay.setContentsMargins(0, 0, 0, 0)
        vlay.setSpacing(0)

        vlay.addWidget(self._build_header())

        body = QWidget()
        hlay = QHBoxLayout(body)
        hlay.setContentsMargins(0, 0, 0, 0)
        hlay.setSpacing(0)
        hlay.addWidget(self._build_sidebar())
        hlay.addWidget(self._build_main(), 1)
        vlay.addWidget(body, 1)

        vlay.addWidget(self._build_footer())

    # Header ─────────────────────────────────────────────────────────────────

    def _build_header(self) -> QWidget:
        h = QWidget()
        h.setFixedHeight(64)
        h.setStyleSheet(f"background: {WHITE}; border-bottom: 1.5px solid {BLACK};")
        lay = QHBoxLayout(h)
        lay.setContentsMargins(32, 0, 32, 0)

        # Try to load logo PNG; fall back to text
        logo_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sophaxplay_logo.png")
        logo_lbl = QLabel()
        logo_lbl.setStyleSheet("background: transparent; border: none;")
        if os.path.exists(logo_path):
            px = QPixmap(logo_path)
            if not px.isNull():
                px = px.scaledToHeight(36, Qt.SmoothTransformation)
                logo_lbl.setPixmap(px)
        if logo_lbl.pixmap() is None or logo_lbl.pixmap().isNull():
            logo_lbl.setText("◆  SophaxPlay")
            logo_lbl.setStyleSheet(
                f"color: {BLACK}; font-size: 17px; font-weight: 700;"
                " letter-spacing: 0.03em; background: transparent; border: none;"
            )
        lay.addWidget(logo_lbl)
        lay.addStretch()

        badge = QLabel("PLAYER")
        badge.setStyleSheet(
            f"color: {BLACK}; font-size: 10px; font-weight: 700;"
            f" font-family: {MONO}; letter-spacing: 2px;"
            f" padding: 5px 12px; border: 1.5px solid {BLACK};"
            " border-radius: 2px; background: transparent; margin-left: 16px;"
        )
        lay.addWidget(badge)
        return h

    # Sidebar ────────────────────────────────────────────────────────────────

    def _build_sidebar(self) -> QWidget:
        w = QWidget()
        w.setFixedWidth(260)
        w.setStyleSheet(f"background: {WHITE};")
        lay = QVBoxLayout(w)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.setSpacing(0)

        # Upper area (ALBUMS label + list) — black right border stops here
        upper = QWidget()
        upper.setStyleSheet(f"background: {WHITE}; border-right: 1.5px solid {BLACK};")
        upper_lay = QVBoxLayout(upper)
        upper_lay.setContentsMargins(0, 0, 0, 0)
        upper_lay.setSpacing(0)

        lbl = QLabel("ALBUMS")
        lbl.setStyleSheet(
            f"color: {GRAY4}; font-size: 9px; font-weight: 700;"
            f" font-family: {MONO}; letter-spacing: 2px;"
            f" padding: 20px 20px 10px; background: transparent; border: none;"
        )
        upper_lay.addWidget(lbl)

        scroll = QScrollArea()
        scroll.setObjectName("albumScroll")
        scroll.setWidgetResizable(True)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll.setStyleSheet(f"QScrollArea {{ border: none; background: {WHITE}; }}")

        inner = QWidget()
        inner.setStyleSheet(f"background: {WHITE};")
        self._albums_lay = QVBoxLayout(inner)
        self._albums_lay.setContentsMargins(10, 0, 10, 10)
        self._albums_lay.setSpacing(3)
        self._albums_lay.addStretch()

        scroll.setWidget(inner)
        upper_lay.addWidget(scroll, 1)
        lay.addWidget(upper, 1)

        # Lower area (divider + ADD FILES) — no right border
        div = QFrame()
        div.setFixedHeight(1)
        div.setStyleSheet(f"background: {GRAY2}; border: none;")
        lay.addWidget(div)

        add_btn = QPushButton("＋  ADD FILES")
        add_btn.setObjectName("addBtn")
        add_btn.setFixedHeight(44)
        add_btn.clicked.connect(self.add_files)
        lay.addWidget(add_btn)
        return w

    # Main panel ─────────────────────────────────────────────────────────────

    def _build_main(self) -> QWidget:
        w = QWidget()
        lay = QVBoxLayout(w)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.setSpacing(0)

        # Album header area
        header = QWidget()
        header.setFixedHeight(180)
        header.setStyleSheet(
            f"background: {WHITE}; border-bottom: 1px solid {GRAY2};"
        )
        hl = QHBoxLayout(header)
        hl.setContentsMargins(28, 20, 28, 20)
        hl.setSpacing(24)

        # Cover
        self.cover_lbl = QLabel()
        self.cover_lbl.setFixedSize(140, 140)
        self.cover_lbl.setAlignment(Qt.AlignCenter)
        self.cover_lbl.setStyleSheet(f"background: {GRAY1}; border: none;")
        self.cover_lbl.setPixmap(_placeholder(140))
        hl.addWidget(self.cover_lbl)

        # Album info
        info_col = QWidget()
        info_col.setStyleSheet(f"background: transparent;")
        ic = QVBoxLayout(info_col)
        ic.setContentsMargins(0, 8, 0, 8)
        ic.setSpacing(4)

        self.info_album = QLabel("—")
        self.info_album.setStyleSheet(
            f"color: {BLACK}; font-size: 22px; font-weight: 700;"
            " background: transparent; border: none;"
        )
        self.info_album.setWordWrap(True)
        ic.addWidget(self.info_album)

        self.info_artist = QLabel("—")
        self.info_artist.setStyleSheet(
            f"color: {GRAY4}; font-size: 14px; font-weight: 400;"
            " background: transparent; border: none;"
        )
        ic.addWidget(self.info_artist)
        ic.addStretch()
        hl.addWidget(info_col, 1)
        lay.addWidget(header)

        # Track list
        self.track_list = QListWidget()
        self.track_list.setObjectName("trackList")
        self.track_list.setItemDelegate(_TrackDelegate())
        self.track_list.setMouseTracking(True)
        self.track_list.itemDoubleClicked.connect(self._on_track_dclick)
        self.track_list.itemClicked.connect(self._on_track_dclick)
        lay.addWidget(self.track_list, 1)

        return w

    # Footer ─────────────────────────────────────────────────────────────────

    def _build_footer(self) -> QWidget:
        bar = QWidget()
        bar.setFixedHeight(100)
        bar.setStyleSheet(f"background: {WHITE}; border-top: 1.5px solid {BLACK};")
        vlay = QVBoxLayout(bar)
        vlay.setContentsMargins(0, 0, 0, 0)
        vlay.setSpacing(0)

        # Progress bar (full width, 4px, clickable)
        self.progress = QSlider(Qt.Horizontal)
        self.progress.setRange(0, 1000)
        self.progress.setFixedHeight(4)
        self.progress.setStyleSheet(f"""
            QSlider {{ background: {GRAY2}; border: none; }}
            QSlider::groove:horizontal {{
                height: 4px; background: {GRAY2}; margin: 0; border: none;
            }}
            QSlider::sub-page:horizontal {{ background: {BLACK}; border: none; }}
            QSlider::handle:horizontal {{ width: 0px; height: 0px; margin: 0; }}
            QSlider::handle:horizontal:hover {{
                background: {BLACK}; width: 14px; height: 14px;
                margin: -5px 0; border-radius: 7px; border: none;
            }}
        """)
        self.progress.sliderPressed.connect(lambda: setattr(self, "_seeking", True))
        self.progress.sliderReleased.connect(self._on_seek_release)
        vlay.addWidget(self.progress)

        # Controls row: [time]  [stretch]  [PREV][STOP][PLAY][NEXT]  [stretch]  [VOL]
        row = QWidget()
        row.setStyleSheet(f"background: {WHITE}; border: none;")
        hlay = QHBoxLayout(row)
        hlay.setContentsMargins(28, 0, 28, 0)
        hlay.setSpacing(10)

        # Time label (left)
        self.lbl_time = QLabel("0:00 / 0:00")
        self.lbl_time.setFixedWidth(110)
        self.lbl_time.setStyleSheet(
            f"color: {GRAY4}; font-size: 12px; font-family: {MONO};"
            " background: transparent; border: none;"
        )
        hlay.addWidget(self.lbl_time)
        hlay.addStretch()

        # Transport controls (centered)
        for label, cb in [("◀ PREV", self.previous), ("■ STOP", self.stop), ("NEXT ▶", self.next_track)]:
            b = QPushButton(label)
            b.setObjectName("ctrlBtn")
            b.clicked.connect(cb)
            hlay.addWidget(b)

        hlay.addSpacing(12)

        self.btn_play = QPushButton("▶  PLAY")
        self.btn_play.setObjectName("playBtn")
        self.btn_play.clicked.connect(self.toggle_play)
        hlay.addWidget(self.btn_play)

        hlay.addStretch()

        # Volume (right)
        vol = QLabel("VOL")
        vol.setStyleSheet(
            f"color: {GRAY3}; font-size: 10px; font-family: {MONO};"
            " letter-spacing: 1px; background: transparent; border: none;"
        )
        hlay.addWidget(vol)

        self.vol_slider = QSlider(Qt.Horizontal)
        self.vol_slider.setRange(0, 100)
        self.vol_slider.setValue(70)
        self.vol_slider.setFixedWidth(100)
        self.vol_slider.setStyleSheet(f"""
            QSlider::groove:horizontal {{ height: 3px; background: {GRAY2}; border: none; }}
            QSlider::sub-page:horizontal {{ background: {BLACK}; border: none; }}
            QSlider::handle:horizontal {{
                background: {BLACK}; width: 12px; height: 12px;
                margin: -5px 0; border-radius: 6px; border: none;
            }}
        """)
        self.vol_slider.valueChanged.connect(
            lambda v: pygame.mixer.music.set_volume(v / 100)
        )
        hlay.addWidget(self.vol_slider)

        pygame.mixer.music.set_volume(0.7)
        vlay.addWidget(row, 1)
        return bar

    # ── Data ───────────────────────────────────────────────────────────────────

    def add_files(self) -> None:
        paths, _ = QFileDialog.getOpenFileNames(
            self, "Add audio files", "",
            "Audio files (*.mp3 *.flac);;MP3 (*.mp3);;FLAC (*.flac)",
        )
        for path in paths:
            title, artist, album, duration, cover = _read_meta(path)
            if album not in self.album_tracks:
                self.albums.append(album)
                self.album_tracks[album] = []
                self._add_album_row(len(self.albums), album)
            self.album_tracks[album].append(
                dict(path=path, title=title, artist=artist,
                     album=album, duration=duration, cover=cover)
            )
            idx = self.albums.index(album)
            n   = len(self.album_tracks[album])
            self._album_rows[idx].set_sub(f"{n} track{'s' if n != 1 else ''}")

        if self._album_rows and not self.displayed_album:
            self._album_rows[0].mousePressEvent(None)

    def _add_album_row(self, number: int, name: str) -> None:
        row = _AlbumRow(number, name, on_click=lambda n=name: self._on_album_click(n))
        self._albums_lay.insertWidget(len(self._album_rows), row)
        self._album_rows.append(row)

    def _on_album_click(self, album: str) -> None:
        for i, name in enumerate(self.albums):
            self._album_rows[i].set_active(name == album)

        self.displayed_album = album
        tracks = self.album_tracks[album]

        self.track_list.clear()
        for i, t in enumerate(tracks):
            title = t["title"][:48] + ("…" if len(t["title"]) > 48 else "")
            item  = QListWidgetItem(title)
            item.setData(Qt.UserRole,     str(i + 1))
            item.setData(Qt.UserRole + 1, _fmt(t["duration"]))
            self.track_list.addItem(item)

        cover_data = next((t["cover"] for t in tracks if t["cover"]), None)
        self.cover_lbl.setPixmap(
            _pixmap_from_bytes(cover_data, 140) if cover_data else _placeholder(140)
        )
        self.info_album.setText(album)
        self.info_artist.setText(tracks[0]["artist"])

    def _on_track_dclick(self, item: QListWidgetItem) -> None:
        self.playing_album = self.displayed_album
        self.play(self.track_list.row(item))

    # ── Playback ───────────────────────────────────────────────────────────────

    def play(self, index: int) -> None:
        tracks = self.album_tracks.get(self.playing_album, [])
        if not (0 <= index < len(tracks)):
            return

        self.playing_idx = index
        t = tracks[index]

        pygame.mixer.music.load(t["path"])
        pygame.mixer.music.set_volume(self.vol_slider.value() / 100)
        pygame.mixer.music.play()

        self.duration   = t["duration"]
        self._seek_off  = 0.0
        self.is_playing = True
        self.is_paused  = False
        self.btn_play.setText("⏸  PAUSE")
        self.setWindowTitle(f"{t['title']} — SophaxPlay")

        self.info_album.setText(t["album"])
        self.info_artist.setText(t["artist"])
        if t["cover"]:
            self.cover_lbl.setPixmap(_pixmap_from_bytes(t["cover"], 140))

        if self.displayed_album == self.playing_album:
            self.track_list.setCurrentRow(index)

    def toggle_play(self) -> None:
        if not self.playing_album and not self.displayed_album:
            return
        if self.playing_idx == -1:
            self.playing_album = self.displayed_album
            self.play(0)
        elif self.is_paused:
            pygame.mixer.music.unpause()
            self.is_paused  = False
            self.is_playing = True
            self.btn_play.setText("⏸  PAUSE")
        elif self.is_playing:
            pygame.mixer.music.pause()
            self.is_paused  = True
            self.is_playing = False
            self.btn_play.setText("▶  PLAY")
        else:
            self.play(self.playing_idx)

    def stop(self) -> None:
        pygame.mixer.music.stop()
        self.is_playing = False
        self.is_paused  = False
        self._seek_off  = 0.0
        self.progress.setValue(0)
        self.lbl_time.setText("0:00 / 0:00")
        self.btn_play.setText("▶  PLAY")
        self.setWindowTitle("SophaxPlay")

    def next_track(self) -> None:
        tracks = self.album_tracks.get(self.playing_album, [])
        if tracks:
            self.play((self.playing_idx + 1) % len(tracks))

    def previous(self) -> None:
        tracks = self.album_tracks.get(self.playing_album, [])
        if tracks:
            self.play((self.playing_idx - 1) % len(tracks))

    def _on_seek_release(self) -> None:
        self._seeking = False
        if self.duration <= 0 or self.playing_idx < 0:
            return
        target = self.progress.value() / 1000 * self.duration
        self._seek_off = target
        pygame.mixer.music.play(start=target)
        if self.is_paused:
            pygame.mixer.music.pause()

    # ── Update loop ────────────────────────────────────────────────────────────

    def _tick(self) -> None:
        if self.is_playing and not self.is_paused and not self._seeking:
            elapsed = pygame.mixer.music.get_pos() / 1000
            if elapsed >= 0 and self.duration > 0:
                pos = self._seek_off + elapsed
                self.progress.setValue(int(min(pos / self.duration * 1000, 1000)))
                self.lbl_time.setText(f"{_fmt(pos)} / {_fmt(self.duration)}")

            if not pygame.mixer.music.get_busy():
                self.next_track()

    def closeEvent(self, event) -> None:
        pygame.mixer.quit()
        super().closeEvent(event)


# ── Entry point ────────────────────────────────────────────────────────────────

def main() -> None:
    app = QApplication(sys.argv)
    app.setApplicationName("SophaxPlay")
    window = SophaxPlay()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
