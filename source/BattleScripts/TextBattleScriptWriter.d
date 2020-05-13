module BattleScripts.TextBattleScriptWriter;

import std.string;
import std.stdio;
import std.conv;
import std.file;

import List.ListWriterInterface;

import BattleScripts.BattleScript;
import BattleScripts.Parameter;

import ArrayTools;

public class TextBattleScriptWriter : ListWriterInterface!BattleScript {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(BattleScript[] scripts) {
        mkdirRecurse(_outputPath);
        foreach (BattleScript script; scripts) {
            File file = File(format("%s/%s.txt", _outputPath, script.key), "w");
            serialize(script, file);
            file.close();    
        }
    }

    public void serialize(BattleScript script, File file) {
        file.writeln("idle {");
        foreach (Trigger trigger; script.triggers) {
            serializeTrigger(trigger, file);
        }
        file.writeln("}");
        
        file.writeln();

        file.writeln("attacked {");
        foreach (Trigger trigger; script.attackTriggers) {
            serializeTrigger(trigger, file);
        }
        file.writeln("}");
    }
    
    public void serializeTrigger(Trigger trigger, File file) {
        file.writeln("  when {");
        foreach (Condition condition; trigger.conditions) {
            serializeCondition(condition, file);
        }
        file.writeln("  }");

        file.writeln("  do {");
        foreach (Action action; trigger.actions) {
            serializeAction(action, file);
        }
        file.writeln("  }");
        file.writeln();
    }

    public void serializeAction(Action action, File file) {
        string[] parts;
        string[] comments;

        foreach (Parameter param; action.params) {
            if (param.comment) {
                comments ~= param.comment;
            }
            parts ~= param.value;
        }

        if (comments.length) {
            file.writeln(format("    %s(%s);    // %s", action.name, join(parts, ", "), join(comments, ", ")));
        } else {
            file.writeln(format("    %s(%s);", action.name, join(parts, ", ")));
        }
    }

    public void serializeCondition(Condition condition, File file) {
        string[] funcParts;
        string[] parts;
        string[] comments;

        foreach (Parameter param; condition.funcParams) {
            funcParts ~= param.value;
        }
        
        foreach (Parameter param; condition.params) {
            if (param.comment) {
                comments ~= param.comment;
            }
            parts ~= param.value;
        }

        string func;
        if (parts.length) {
            func = format("    %s(%s) %s;", condition.name, funcParts.join(", "), join(parts, " "));
        } else {
            func = format("    %s(%s);", condition.name, funcParts.join(", "));
        }

        if (comments.length) {
            file.writeln(format("%s    // %s", func, join(comments, ", ")));
        } else {
            file.writeln(func);
        }
    }
}
