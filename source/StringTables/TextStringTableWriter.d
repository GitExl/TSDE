module StringTables.TextStringTableWriter;

import std.stdio;
import std.file;
import std.string;

import List.ListWriterInterface;

import StringTables.StringTable;

public class TextStringTableWriter : ListWriterInterface!StringTable {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const StringTable[] tables) {
        mkdirRecurse(_outputPath);
        foreach (const StringTable table; tables) {
            File file = File(format("%s/%s.txt", _outputPath, table.key), "w");
            serialize(table, file);
            file.close();    
        }
    }

    public void serialize(const StringTable table, File file) {
        foreach (string str; table.strings) {
            file.writeln(str);
        }
    }

}
