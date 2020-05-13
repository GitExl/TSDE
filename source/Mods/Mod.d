module Mods.Mod;

import Mods.ModEffectInterface;
import Mods.ModConditionInterface;

public struct Mod {
    string key;
    string name;

    ModConditionInterface[] conditions;
    ModEffectInterface[] effects;
}
