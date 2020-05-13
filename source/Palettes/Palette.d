module Palettes.Palette;

public struct Color {
    ubyte r;
    ubyte g;
    ubyte b;
}

public struct Palette {
    string group;
    string key;
    Color[] colors;

    public static Palette fromGrayScale(immutable uint size) {
        Palette pal;

        const double step = 255.0 / (size - 1);

        pal.colors = new Color[size];
        foreach (int index, ref Color color; pal.colors) {
            const ubyte value = cast(ubyte)(step * index);
            color.b = color.g = color.r = value;
        }

        return pal;
    }
}
