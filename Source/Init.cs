using HarmonyLib;
using RimWorld;
using Verse;

namespace Blocky.Core;

[StaticConstructorOnStartup]
public class Init
{
    static Init()
    {
        Harmony harmony = new Harmony("Blocky.Core");
        harmony.PatchAll();
    }
}
