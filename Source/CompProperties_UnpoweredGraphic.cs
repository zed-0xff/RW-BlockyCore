using Verse;
using RimWorld;

namespace Blocky.Props;

public class CompProperties_UnpoweredGraphic : CompProperties {
    public GraphicData graphicData;

	public CompProperties_UnpoweredGraphic() {
		compClass = typeof(CompUnpoweredGraphic);
	}
}
