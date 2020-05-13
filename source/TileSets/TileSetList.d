/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module TileSets.TileSetList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import TileSets.TileSet;

public class TileSetList : ListInterface!TileSet {

    private TileSet[] _sets;

    public void readWith(ListReaderInterface!TileSet reader) {
        _sets = reader.read();
    }

    public void writeWith(ListWriterInterface!TileSet writer) {
        writer.write(_sets);
    }

    public string getKeyByIndex(immutable int index) {
        return _sets[index].key;
    }

}
