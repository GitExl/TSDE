/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Graphics.GraphicsList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Graphics.Graphic;

public class GraphicsList : ListInterface!Graphic {

    private Graphic[] _graphics;
    private Graphic[][string] _graphicByGroup;

    public void readWith(ListReaderInterface!Graphic reader) {
        _graphics = reader.read();
        
        foreach (int index, Graphic graphic; _graphics) {
            _graphicByGroup[graphic.group] ~= graphic;
        }

    }

    public void writeWith(ListWriterInterface!Graphic writer) {
        writer.write(_graphics);
    }

    public string getKeyByIndex(immutable int index) {
        return _graphics[index].key;
    }

    public string getKeyByGroupIndex(string group, immutable int index) {
        return _graphicByGroup[group][index].key;
    }

}
