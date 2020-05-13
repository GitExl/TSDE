/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Palettes.PaletteList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Palettes.Palette;

public class PaletteList : ListInterface!Palette {

    private Palette[] _palettes;
    private Palette[][string] _paletteByGroup;

    public void readWith(ListReaderInterface!Palette reader) {
        _palettes = reader.read();
        
        foreach (int index, Palette pal; _palettes) {
            _paletteByGroup[pal.group] ~= pal;
        }
    }

    public void writeWith(ListWriterInterface!Palette writer) {
        writer.write(_palettes);
    }

    public string getKeyByIndex(immutable int index) {
        return _palettes[index].key;
    }

    public string getKeyByGroupIndex(string group, immutable int index) {
        return _paletteByGroup[group][index].key;
    }

}
