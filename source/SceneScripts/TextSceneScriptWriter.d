/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module SceneScripts.TextSceneScriptWriter;

import std.stdio;
import std.string;
import std.file;

import List.ListWriterInterface;

import SceneScripts.SceneScript;

public class TextSceneScriptWriter : ListWriterInterface!SceneScript {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(SceneScript[] scripts) {
        mkdirRecurse(_outputPath);
        foreach (SceneScript script; scripts) {
            File file = File(format("%s/%s.txt", _outputPath, script.key), "w");
            foreach (SceneObject object; script.objects) {
                object.root.output(file, script.labels, 0);
            }
            file.close();    
        }
    }
}
