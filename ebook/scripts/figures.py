"""Typeset the assessment figures from figures.yaml.

These replace AI-generated infographics. Every one is emitted as real markup so
the Korean is set in Nanum by the same stylesheet as the body text: it stays
sharp at A5, reflows in the EPUB, is selectable and searchable, needs no alt
text, and a wording fix is a one-line edit in figures.yaml rather than a redraw.

Only the 4부 hi-launch figure is a picture, because it is a picture: a drawn ink
arc from scripts/make_plates.py, with no lettering in it.
"""
from __future__ import annotations

import html

import yaml

from paths import EBOOK_DIR

FIGURES_YAML = EBOOK_DIR / "figures.yaml"


def load_figures() -> dict:
    if not FIGURES_YAML.exists():
        return {}
    data = yaml.safe_load(FIGURES_YAML.read_text(encoding="utf-8")) or {}
    return data.get("figures") or {}


# Never split these tokens, including inside the typeset 2부 figures.
SWING_TERMS = ("테이크어웨이", "팔로우스루", "다운스윙", "어드레스", "임팩트", "피니시")


def wrap_terms(text: str) -> str:
    """Mark the six swing tokens so CSS can keep each one on one line.

    Safe to run more than once: an already-wrapped token is left alone.
    """
    for i, term in enumerate(SWING_TERMS):
        token = f"\x00T{i}\x00"
        text = text.replace(f'<span class="term">{term}</span>', token)
        text = text.replace(term, f'<span class="term">{term}</span>')
        text = text.replace(token, f'<span class="term">{term}</span>')
    return text


def esc(text: object) -> str:
    return wrap_terms(html.escape(str(text or "")))


def _shell(fig: dict, body: list[str], kind: str) -> str:
    """Wrap a figure in its panel: title above, closing line below."""
    out = [f'<figure class="diagram {kind}">']
    if fig.get("title"):
        out.append(f'<p class="diagram-title">{esc(fig["title"])}</p>')
    if fig.get("flow"):
        out.append(f'<p class="diagram-flow">{esc(fig["flow"])}</p>')
    out.extend(body)
    if fig.get("footer"):
        out.append(f'<p class="diagram-footer">{esc(fig["footer"])}</p>')
    out.append("</figure>")
    # One raw block, flush left, no blank lines: pandoc passes it through whole.
    return "\n".join(out)


def _steps(fig: dict) -> str:
    rows = ['<ol class="steps">']
    for step in fig.get("steps", []):
        rows.append(
            "<li>"
            f'<span class="step-title">{esc(step.get("title"))}</span>'
            f'<span class="step-body">{esc(step.get("body"))}</span>'
            "</li>"
        )
    rows.append("</ol>")
    return _shell(fig, rows, "steps")


def _paths(fig: dict) -> str:
    rows = ['<ul class="paths">']
    for row in fig.get("rows", []):
        rows.append(
            "<li>"
            f'<span class="path-label">{esc(row.get("label"))}</span>'
            f'<span class="path-route">{esc(row.get("path"))}</span>'
            "</li>"
        )
    rows.append("</ul>")
    return _shell(fig, rows, "paths")


def _stages(fig: dict) -> str:
    rows = ['<ol class="stages">']
    for stage in fig.get("stages", []):
        rows.append(
            "<li>"
            f'<span class="stage-name">{esc(stage.get("name"))}</span>'
            f'<span class="stage-question">{esc(stage.get("question"))}</span>'
            "</li>"
        )
    rows.append("</ol>")
    return _shell(fig, rows, "stages")


def _map(fig: dict) -> str:
    labels = fig.get("labels") or {}
    check_label = esc(labels.get("check") or "먼저 점검")
    chapter_label = esc(labels.get("chapters") or "3부에서 볼 챕터")
    # Three columns will not hold Korean at A5, so each problem takes a block of
    # its own with the two labelled lines under it.
    rows = ['<ul class="map">']
    for row in fig.get("rows", []):
        rows.append(
            "<li>"
            f'<span class="map-problem">{esc(row.get("problem"))}</span>'
            f'<span class="map-line"><span class="map-key">{check_label}</span>'
            f'<span class="map-value">{esc(row.get("check"))}</span></span>'
            f'<span class="map-line"><span class="map-key">{chapter_label}</span>'
            f'<span class="map-value">{esc(row.get("chapters"))}</span></span>'
            "</li>"
        )
    rows.append("</ul>")
    return _shell(fig, rows, "map")


def _plate(fig: dict) -> str:
    plate = fig.get("plate")
    if not plate or not (EBOOK_DIR / plate).exists():
        return ""
    body = [f'<img src="{plate}" alt="{esc(fig.get("alt"))}" />']
    return _shell(fig, body, "plate")


RENDERERS = {
    "steps": _steps,
    "paths": _paths,
    "stages": _stages,
    "map": _map,
    "plate": _plate,
}


def render(figure_id: str, figures: dict | None = None) -> str:
    figures = load_figures() if figures is None else figures
    fig = figures.get(figure_id)
    if not fig:
        return ""
    renderer = RENDERERS.get(fig.get("kind", ""))
    return renderer(fig) if renderer else ""
