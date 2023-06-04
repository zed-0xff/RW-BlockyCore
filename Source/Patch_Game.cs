using HarmonyLib;
using Verse;

namespace Blocky.Core;

// clear caches on game load / new game
static class Patch_Game {
    [HarmonyPatch(typeof(Game), nameof(Game.InitNewGame))]
    static class ClearCaches_Init {
        static void Prefix(){
            CacheBase.ClearAll();
        }
    }

    [HarmonyPatch(typeof(Game), nameof(Game.LoadGame))]
    static class ClearCaches_Load {
        static void Prefix(){
            CacheBase.ClearAll();
        }
    }
}
