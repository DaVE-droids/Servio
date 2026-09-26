"""Rebuilds assets/geo/ — the country and state lists the placement form uses.

Servio needs four things: a country's ISO code and name, each state's name,
and which country it belongs to. The `country_state_city` package supplied
these but bundled a 24 MB list of world cities with them, which Servio never
reads and which was shipped inside every Android and iOS download. This
script keeps the same source data and writes only the parts used, about
97 KB in total.

Source: the countries-states-cities database
(https://github.com/dr5hn/countries-states-cities-database), which is what
that package packaged.

Usage — point it at a directory holding `country.json` and `state.json`:

    python3 tool/generate_geo_assets.py path/to/data

With no argument it looks for the old package in the pub cache, which works
as long as a copy is still there:

    python3 tool/generate_geo_assets.py
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def _source_directory() -> pathlib.Path:
    if len(sys.argv) > 1:
        return pathlib.Path(sys.argv[1]).expanduser()
    cached = sorted(
        (pathlib.Path.home() / ".pub-cache/hosted/pub.dev").glob(
            "country_state_city-*/lib/assets"
        )
    )
    if not cached:
        sys.exit(
            "No source data found. Pass a directory containing country.json "
            "and state.json — see the note at the top of this file."
        )
    return cached[-1]


def main() -> None:
    source = _source_directory()
    countries = json.loads((source / "country.json").read_text())
    states = json.loads((source / "state.json").read_text())

    # "c" and "n" rather than "isoCode"/"name": with ~5,000 entries the key
    # names alone would add tens of kilobytes.
    trimmed_countries = sorted(
        ({"c": c["isoCode"], "n": c["name"]} for c in countries),
        key=lambda c: c["n"],
    )
    by_country: dict[str, list[str]] = {}
    for state in states:
        by_country.setdefault(state["countryCode"], []).append(state["name"])
    trimmed_states = {
        code: sorted(set(names)) for code, names in sorted(by_country.items())
    }

    out = ROOT / "assets" / "geo"
    out.mkdir(parents=True, exist_ok=True)
    (out / "countries.json").write_text(
        json.dumps(trimmed_countries, separators=(",", ":"), ensure_ascii=False)
    )
    (out / "states.json").write_text(
        json.dumps(trimmed_states, separators=(",", ":"), ensure_ascii=False)
    )
    print(
        f"Wrote {len(trimmed_countries)} countries and "
        f"{sum(len(v) for v in trimmed_states.values())} states to {out}."
    )


if __name__ == "__main__":
    main()
