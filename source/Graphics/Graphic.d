module Graphics.Graphic;

import Bitmap;

public struct Graphic {
    string key;
    string group;

    Bitmap[] bitmaps;
    ubyte bitplanes;
    ushort width;
}
