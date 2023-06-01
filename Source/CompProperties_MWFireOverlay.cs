using UnityEngine;
using RimWorld;
using Verse;

namespace Blocky.Core;

public class CompProperties_MWFireOverlay : CompProperties_FireOverlay {
    public string texPath;

    public CompProperties_MWFireOverlay() {
        compClass = typeof(CompMWFireOverlay);
    }
}
