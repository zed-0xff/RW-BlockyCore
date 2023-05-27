using UnityEngine;
using RimWorld;
using Verse;

namespace Blocky.Props;

public class CompUnpoweredGraphic : ThingComp
{
	private CompProperties_UnpoweredGraphic Props => (CompProperties_UnpoweredGraphic)props;

	public bool ParentIsPowered {
		get {
            if (!FlickUtility.WantsToBeOn(parent)) {
                return false;
            }

            CompPowerTrader compPowerTrader = parent.TryGetComp<CompPowerTrader>();
            if (compPowerTrader != null && !compPowerTrader.PowerOn) {
                return false;
            }

            CompRefuelable compRefuelable = parent.TryGetComp<CompRefuelable>();
            if (compRefuelable != null && !compRefuelable.HasFuel) {
                return false;
            }
            return true;
		}
	}

	public override void PostDraw()
	{
		base.PostDraw();
		if (!ParentIsPowered) {
			Mesh mesh = Props.graphicData.Graphic.MeshAt(parent.Rotation);
			Vector3 drawPos = parent.DrawPos;
			drawPos.y = AltitudeLayer.BuildingOnTop.AltitudeFor();
			Graphics.DrawMesh(mesh, drawPos + Props.graphicData.drawOffset.RotatedBy(parent.Rotation), Quaternion.identity, Props.graphicData.Graphic.MatAt(parent.Rotation), 0);
		}
	}
}
