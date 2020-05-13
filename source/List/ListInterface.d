module List.ListInterface;

import List.ListReaderInterface;
import List.ListWriterInterface;

public interface ListInterface(T) {
    public void readWith(ListReaderInterface!T reader);
    public void writeWith(ListWriterInterface!T writer);
    public string getKeyByIndex(immutable int index);
}
