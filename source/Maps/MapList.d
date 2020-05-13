module Maps.MapList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Maps.Map;

public class MapList : ListInterface!Map {

    private Map[] _maps;

    public void readWith(ListReaderInterface!Map reader) {
        _maps = reader.read();
    }

    public void writeWith(ListWriterInterface!Map writer) {
        writer.write(_maps);
    }

    public string getKeyByIndex(immutable int index) {
        return _maps[index].key;
    }

}
