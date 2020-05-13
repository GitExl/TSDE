import std.stdio;
import std.json;

import Game;

import BinaryFile;
import JSONTools;

int main(string[] argv) {
    writeln("Time Switch Data Extractor version 1.0");
    writeln();

    if (argv.length != 4) {
        writeln("Invalid number of arguments.");
        writeln("Usage: tsde [data file] [configuration file] [output directory]");
        writeln();
        return 1;
    }

    BinaryFile data = new BinaryFile(argv[1]);
    JSONValue config = loadJSON(argv[2]);
    
    Game game = new Game();  
    game.readFromROM(data, config);
    game.write(argv[3]);

    writeln("Done!");
    
    return 0;
}
