/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module List.ListInterface;

import List.ListReaderInterface;
import List.ListWriterInterface;

public interface ListInterface(T) {
    public void readWith(ListReaderInterface!T reader);
    public void writeWith(ListWriterInterface!T writer);
    public string getKeyByIndex(immutable int index);
}
