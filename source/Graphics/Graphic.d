/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Graphics.Graphic;

import Bitmap;

public struct Graphic {
    string key;
    string group;

    Bitmap[] bitmaps;
    ubyte bitplanes;
    ushort width;
}
