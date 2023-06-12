using HarmonyLib;
using RimWorld;
using Verse;

namespace Blocky.Core;

[HarmonyPatch(typeof(GenSpawn), nameof(GenSpawn.SpawningWipes))]
static class Patch_GenSpawn {
    static void Postfix(ref bool __result, BuildableDef newEntDef, BuildableDef oldEntDef) {
        if( __result ) return;

        var ext = newEntDef.GetModExtension<ExtSpawningWipes>();
        var extBP = (newEntDef as ThingDef)?.entityDefToBuild?.GetModExtension<ExtSpawningWipes>();

        if( ext != null && ext.defs.Contains(oldEntDef) ){
            __result = true;
            return;
        }

        // new blueprint wipes old blueprint
        if( extBP != null && oldEntDef is ThingDef td && td.entityDefToBuild != null && extBP.defs.Contains(td.entityDefToBuild) ){
            __result = true;
            return;
        }
    }
}

