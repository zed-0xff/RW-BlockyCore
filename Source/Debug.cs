using RimWorld;
using System.Linq;
using Verse;

namespace Blocky.Core;

public static class Debug {

    const int edgeWidth = 2; // GenGrid.NoBuildEdgeWidth = 10

    static void spawnAll(){
        var map = Find.CurrentMap;
        var allDefs = DefDatabase<ThingDef>.AllDefsListForReading
            .FindAll(d => d.modContentPack == ModConfig.Settings.Mod.Content && d is BuildableDef )
            .OrderBy(d => isReleased(d) ? 0 : 1 )
            .ThenBy( d => d.designatorDropdown?.defName )
            .ThenBy( d => d.defName )
            .ToList();

        int z = map.Size.z - edgeWidth;
        int x = edgeWidth;

        var prevCategory = allDefs[0].designatorDropdown;
        bool prevReleased = isReleased(allDefs[0]);
        foreach( ThingDef def in allDefs ){
            if( def.IsBlueprint || def.IsFrame )
                continue;

            bool released = isReleased(def);
            if( def.designatorDropdown != prevCategory || prevReleased != released || x >= map.Size.x - edgeWidth ){
                // start new row
                x = edgeWidth;
                z -= 1 + (prevReleased != released ? 1 : 0);

                prevCategory = def.designatorDropdown;
                prevReleased = released;
            }

            GenSpawn.Spawn(def, new IntVec3(x,0,z), map, WipeMode.Vanish);
            x++;
        }
    }

    static bool isReleased(ThingDef def){
        return !def.label.Contains("unreleased");
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
