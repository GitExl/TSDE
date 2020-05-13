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
