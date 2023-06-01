using RimWorld;
using System.Linq;
using Verse;

namespace Blocky.Core;

public static class Debug {

    const int edgeWidth = 1; // GenGrid.NoBuildEdgeWidth = 10

    static void spawnAll(){
        var map = Find.CurrentMap;
        var allDefs = DefDatabase<ThingDef>.AllDefsListForReading
            .FindAll(d => d.modContentPack == ModConfig.Settings.Mod.Content && d is BuildableDef )
            .OrderBy(d => d.designatorDropdown?.defName )
            .ThenBy( d => d.defName )
            .ToList();

        int z = map.Size.z - edgeWidth;
        int x = edgeWidth;

        var prevCategory = allDefs[0].designatorDropdown;
        foreach( ThingDef def in allDefs ){
            if( def.IsBlueprint || def.IsFrame )
                continue;

            if( def.designatorDropdown != prevCategory || x >= map.Size.x - edgeWidth ){
                // start new row
                prevCategory = def.designatorDropdown;
                x = edgeWidth;
                z -= 1;
            }

            GenSpawn.Spawn(def, new IntVec3(x,0,z), map, WipeMode.Vanish);
            x++;
        }
    }

    [DebugAction("Blocky.Core", "Spawn all!", false, false, allowedGameStates = AllowedGameStates.PlayingOnMap)]
    private static void SpawnAll(){
        var map = Find.CurrentMap;
        int dx = 16;
        int dy = 10;

        spawnAll();
        CameraJumper.TryJump(new IntVec3(edgeWidth + dx, 0, map.Size.z - edgeWidth - dy), map);
    }
}
