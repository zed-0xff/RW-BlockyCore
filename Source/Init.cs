using HarmonyLib;
using RimWorld;
using Verse;

namespace Blocky.Props;

[StaticConstructorOnStartup]
public class Init
{
    static Init()
    {
        Harmony harmony = new Harmony("Blocky.Props");
        harmony.PatchAll();
    }
}
