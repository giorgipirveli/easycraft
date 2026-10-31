#!/usr/bin/env python3
"""Gives new block pages the import settings of an existing page (the [params] section of each .import file): the
pixel page and the realistic albedo lossless with mipmaps and detect-3D off, the normal map as a normal map at half
size (M5 Task 3). Godot's --import writes its defaults for a new PNG; run this after it, then --import again.

  python3 tools/copy_page_import.py dragon moon [boing rainbow ...]    (the first name is the model page)
"""
import sys

DIR = "data/blocks/pages/"


def params(path: str) -> str:
    text = open(path).read()
    return text[text.index("[params]"):]


def main() -> None:
    model, pages = sys.argv[1], sys.argv[2:]
    for suffix in ("", "_albedo", "_normal"):
        wanted = params(f"{DIR}{model}{suffix}.png.import")
        for page in pages:
            path = f"{DIR}{page}{suffix}.png.import"
            text = open(path).read()
            new = text[:text.index("[params]")] + wanted
            if new != text:
                open(path, "w").write(new)
                print("COPY_IMPORT", path)


if __name__ == "__main__":
    main()
