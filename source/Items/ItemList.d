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
