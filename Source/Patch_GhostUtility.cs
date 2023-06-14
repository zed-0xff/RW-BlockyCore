using HarmonyLib;
using RimWorld;
using Verse;
using UnityEngine;

namespace Blocky.Core;

[HarmonyPatch(typeof(GhostUtility), nameof(GhostUtility.GhostGraphicFor))]
static class Patch_ExtUseBlueprintAsPreview {
    static void Postfix(ref Graphic __result, Graphic baseGraphic, ThingDef thingDef, Color ghostCol) {
        if (thingDef.GetModExtension<ExtUseBlueprintAsPreview>() != null ) {
            __result = GraphicDatabase.Get(
                    thingDef.building.blueprintGraphicData.graphicClass,
                    thingDef.building.blueprintGraphicData.texPath,
                    ShaderTypeDefOf.Cutout.Shader,
                    baseGraphic.drawSize,
                    new Color(1, 1, 1, 0.8f),
                    Color.white,
                    thingDef.building.blueprintGraphicData,
                    null);
        }
    }
}

