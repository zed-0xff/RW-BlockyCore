namespace Blocky.Core;

public static class Utils {
    public static void ArchitectMenu_ClearCache() {
        Patch_MainTabWindow_Architect.needClear = true;
    }
}
