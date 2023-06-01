using Verse;

namespace Blocky.Core;

// XXX all child mods needs to be recompiled if changed!
public abstract class SettingsTabBase {
    public abstract string Title { get; }

    public abstract void Draw(Listing_Standard l);
    public abstract void Write();
}
