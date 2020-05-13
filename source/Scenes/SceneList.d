/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Scenes.SceneList;

import List.ListInterface;
import List.ListReaderInterface;
import List.ListWriterInterface;

import Scenes.Scene;

public class SceneList : ListInterface!Scene {

    private Scene[] _scenes;

    public void readWith(ListReaderInterface!Scene reader) {
        _scenes = reader.read();
    }

    public void writeWith(ListWriterInterface!Scene writer) {
        writer.write(_scenes);
    }

    public string getKeyByIndex(immutable int index) {
        return _scenes[index].key;
    }

    public Scene getByIndex(immutable int index) {
        return _scenes[index];
    }

    public void setByIndex(immutable int index, Scene scene) {
        _scenes[index] = scene;
    }

    @property public size_t length() {
        return _scenes.length;
    }

}
