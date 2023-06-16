using RimWorld;
using System.Linq;
using Verse;

namespace Blocky.Core;

public static class Debug {

    const int edgeWidth = 2; // GenGrid.NoBuildEdgeWidth = 10

    static void clearRow(int z){
        GenDebug.ClearArea(new CellRect(edgeWidth, z, Find.CurrentMap.Size.x - edgeWidth*2, 1), Find.CurrentMap);
    }

    static void spawnAll(){
        var map = Find.CurrentMap;
        var allDefs = DefDatabase<ThingDef>.AllDefsListForReading
            .FindAll(d => d.modContentPack == ModConfig.Settings.Mod.Content && d is BuildableDef )
            .OrderBy(d => isReleased(d) ? 0 : 1 )
            .ThenBy( d => d.designatorDropdown?.defName )
            .ThenBy( d => d.uiOrder )
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
                z -= 1;
                clearRow(z);

                if( prevReleased != released ){
                    z -= 1;
                    clearRow(z);
                }

                prevCategory = def.designatorDropdown;
                prevReleased = released;
            }

            GenSpawn.Spawn(def, new IntVec3(x,0,z), map, WipeMode.Vanish);
            x++;
        }
    }

    static void spawnAllStuffable(){
        var map = Find.CurrentMap;
        var allDefs = DefDatabase<ThingDef>.AllDefsListForReading
            .FindAll(d => d is BuildableDef && d.MadeFromStuff && (
                        d.modContentPack == ModConfig.Settings.Mod.Content
                        || d.defName.StartsWith("Blocky")
                        || d is ThingDef td && (td.graphicData?.texPath?.StartsWith("Blocky") ?? false)
                        ))
            .OrderBy(d => d.modContentPack == ModConfig.Settings.Mod.Content ? 0 : 1 )
            .ThenBy( d => d.modContentPack.PackageId )
            .ThenBy( d => d.designatorDropdown?.defName )
            .ThenBy( d => d.uiOrder )
            .ThenBy( d => d.defName )
            .ToList();

        int z = map.Size.z - edgeWidth - 1;
        int x = edgeWidth;

        var stuffs = DefDatabase<ThingDef>.AllDefs.Where((ThingDef st) => st.IsStuff && st.stuffProps.CanMake(ThingDefOf.Wall));

        void wallRow(){
            x = edgeWidth;
            z -= 1;
            clearRow(z);
            foreach( var stuff in stuffs ){
                GenSpawn.Spawn(ThingMaker.MakeThing(ThingDefOf.Wall, stuff), new IntVec3(x,0,z), map, WipeMode.Vanish);
                x++;
            }
        }

        ModContentPack prevContentPack = null;
        foreach( ThingDef def in allDefs ){
            if( def.IsBlueprint || def.IsFrame )
                continue;

            clearRow(z);

            if( prevContentPack != def.modContentPack ){
                prevContentPack = def.modContentPack;
                wallRow();
                z -= 1;
                clearRow(z);
            }

            x = edgeWidth;
            foreach( var stuff in stuffs ){
                GenSpawn.Spawn(ThingMaker.MakeThing(def, stuff), new IntVec3(x,0,z), map, WipeMode.Vanish);
                x++;
            }
            z -= 1;
        }
        wallRow();
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

    [DebugAction("Blocky.Core", "Spawn all stuffable", false, false, allowedGameStates = AllowedGameStates.PlayingOnMap)]
    private static void SpawnAllStuffable(){
        var map = Find.CurrentMap;
        int dx = 16;
        int dy = 10;

        spawnAllStuffable();
        CameraJumper.TryJump(new IntVec3(edgeWidth + dx, 0, map.Size.z - edgeWidth - dy), map);
    }
}
