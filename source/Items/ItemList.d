/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Items.ItemList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Items.Item;

public class ItemList : ListInterface!Item {

    private Item[] _items;

    public void readWith(ListReaderInterface!Item reader) {
        _items = reader.read();
    }

    public void writeWith(ListWriterInterface!Item writer) {
        writer.write(_items);
    }

    public Item getByIndex(immutable int index) {
        return _items[index];
    }

    public string getKeyByIndex(immutable int index) {
        return _items[index].key;
    }

}
