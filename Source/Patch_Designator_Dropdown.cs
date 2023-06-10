using HarmonyLib;
using RimWorld;
using System;
using Verse;
using UnityEngine;

namespace Blocky.Core;

// allow stuffable buildings in dropdown menus
[HarmonyPatch(typeof(Designator_Dropdown), "GetDesignatorSelectAction")]
static class Patch_Designator_Dropdown {
    static void Postfix(ref Action __result, Designator_Dropdown __instance, Event ev, Designator des) {
        if( des is Designator_Build b && b.PlacingDef is ThingDef td && td.MadeFromStuff ){
            __result = delegate
            {
                b.ProcessInput(ev);
                __instance.SetActiveDesignator(des);
            };
        }
    }
}
