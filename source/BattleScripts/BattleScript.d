/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BattleScripts.BattleScript;

import BattleScripts.Parameter;

public struct Action {
    string name;
    Parameter[] params;

    public this(immutable string name, Parameter[] params...) {
        this.name = name;
        this.params = params.dup;
    }

    public this(immutable string name) {
        this.name = name;
    }
}

public struct Condition {
    string name;
    Parameter[] funcParams;
    Parameter[] params;

    public this(immutable string name, Parameter[] funcParams, Parameter[] params...) {
        this.name = name;
        this.funcParams = funcParams;
        this.params = params.dup;
    }

    public this(immutable string name) {
        this.name = name;
    }
}

public struct Trigger {
    Condition[] conditions;
    Action[] actions;
}

public struct BattleScript {
    string key;

    Trigger[] triggers;
    Trigger[] attackTriggers;
}
