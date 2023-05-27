using UnityEngine;
using RimWorld;
using Verse;

namespace Blocky.Props;

[StaticConstructorOnStartup]
public class CompMWFireOverlay : CompFireOverlayBase
{
    protected CompRefuelable refuelableComp;

    public new CompProperties_MWFireOverlay Props => (CompProperties_MWFireOverlay)props;

    Graphic fireGraphic;
    Graphic FireGraphic
    {
        get
        {
            if (fireGraphic == null)
            {
                fireGraphic = GraphicDatabase.Get<Graphic_Fire>(Props.texPath, ShaderDatabase.TransparentPostLight, Vector2.one, Color.white);
            }
            return fireGraphic;
        }
    }

    public override void PostDraw()
    {
        base.PostDraw();
        if (refuelableComp == null || refuelableComp.HasFuel)
        {
            Vector3 drawPos = parent.DrawPos;
            drawPos.y += 3f / 74f;
            FireGraphic.Draw(drawPos, Rot4.North, parent);
        }
    }

    public override void PostSpawnSetup(bool respawningAfterLoad)
    {
        base.PostSpawnSetup(respawningAfterLoad);
        refuelableComp = parent.GetComp<CompRefuelable>();
    }

    public override void CompTick()
    {
        if ((refuelableComp == null || refuelableComp.HasFuel) && startedGrowingAtTick < 0)
        {
            startedGrowingAtTick = GenTicks.TicksAbs;
        }
    }
}
