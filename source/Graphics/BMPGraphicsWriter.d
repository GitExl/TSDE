module Graphics.BMPGraphicsWriter;

import std.stdio;
import std.string;
import std.file;
import std.math;

import List.ListWriterInterface;

import Graphics.Graphic;

import Palettes.Palette;

import Bitmap;

public class BMPGraphicsWriter : ListWriterInterface!Graphic {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(Graphic[] graphics) {
        mkdirRecurse(_outputPath);
        foreach (Graphic graphic; graphics) {
            if (!graphic.bitmaps.length) {
                continue;
            }

            string path = graphic.group.length ? format("%s/%s", _outputPath, graphic.group) : _outputPath;
            mkdirRecurse(path);

            string fileName;
            if (graphic.group.length) {
                fileName = format("%s/%s.bmp", path, graphic.key);
            } else {
                fileName = format("%s/%s.bmp", path, graphic.key);
            }

            Palette pal = Palette.fromGrayScale(pow(2, graphic.bitplanes));
            Bitmap output = getCombinedBitmap(graphic.bitmaps, graphic.width);
            output.writeToBMP(fileName, pal);
        }
    }

    private Bitmap getCombinedBitmap(Bitmap[] bitmaps, immutable ushort width) {
        const int height = cast(int)(ceil(bitmaps.length / (width / 8.0)) * 8.0);
        Bitmap combined = new Bitmap(width, height);
        
        int x;
        int y;
        foreach (ref Bitmap tile; bitmaps) {
            combined.blitFrom(tile, x, y);
            x += 8;
            if (x >= width) {
                x = 0;
                y += 8;
            }
        }

        return combined;
    }

}
