using HarmonyLib;
using RimWorld;
using System.Collections.Generic;
using System.Reflection;
using Verse;

namespace Blocky.Core;

// show/hide "Blocky.Core" tab
static class Patch_MainTabWindow_Architect {

    private static readonly MethodInfo m_CacheDesPanels = AccessTools.Method(typeof(MainTabWindow_Architect), "CacheDesPanels");
    private static readonly FastInvokeHandler _CacheDesPanels = MethodInvoker.GetHandler(m_CacheDesPanels);

    private static readonly MethodInfo m_ResetAndUnfocusQuickSearch = AccessTools.Method(typeof(MainTabWindow_Architect), "ResetAndUnfocusQuickSearch");
    private static readonly FastInvokeHandler _ResetAndUnfocusQuickSearch = MethodInvoker.GetHandler(m_ResetAndUnfocusQuickSearch);

    static bool prevMode = true; // as unpatched
    public static bool needClear = false;

    static bool WantToShow(){
        switch( ModConfig.Settings.tabShowMode ){
            case TabShowMode.DevModeOnly:
                return Prefs.DevMode;
            case TabShowMode.GodModeOnly:
                return DebugSettings.godMode;
            case TabShowMode.Always:
                return true;
            case TabShowMode.Never:
                return false;
        }
        return true;
    }

    static void check(MainTabWindow_Architect __instance){
        bool curMode = WantToShow();
        if( prevMode != curMode || needClear ){
            prevMode = curMode;
            needClear = false;
            _CacheDesPanels(__instance);
            _ResetAndUnfocusQuickSearch(__instance); // or panels will have gray color text
        }
    }

    // clear cache if needed
    [HarmonyPatch(typeof(MainTabWindow_Architect), nameof(MainTabWindow_Architect.DoWindowContents))]
    static class Patch_DoWindowContents {
        static void Prefix( MainTabWindow_Architect __instance ){
            check(__instance);
        }
    }

    // clear cache if needed, or window size will glitch
    [HarmonyPatch(typeof(MainTabWindow_Architect), "get_WinHeight")]
    static class Patch_getWinHeight {
        static void Prefix( MainTabWindow_Architect __instance ){
            check(__instance);
        }
    }

    // hide panel if needed
    [HarmonyPatch(typeof(MainTabWindow_Architect), "CacheDesPanels")]
    static class Patch_CacheDesPanels {
        static void Postfix( List<ArchitectCategoryTab> ___desPanelsCached ){
            if( WantToShow() )
                return; // show

            // hide
            foreach( var x in ___desPanelsCached ){
                if( x.def == VDefOf.Blocky_Props ){
                    ___desPanelsCached.Remove(x);
                    break;
                }
            }
        }
    }
}
