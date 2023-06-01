using RimWorld;
using UnityEngine;
using Verse;

namespace Blocky.Core;

// same as Graphic_Flicker, but without jumping
public class Graphic_Fire : Graphic_Collection
{
	private const int BaseTicksPerFrameChange = 15;

	public override Material MatSingle => subGraphics[Rand.Range(0, subGraphics.Length)].MatSingle;

	public override void DrawWorker(Vector3 loc, Rot4 rot, ThingDef thingDef, Thing thing, float extraRotation)
	{
		if (thingDef == null)
		{
			Log.ErrorOnce("Fire DrawWorker with null thingDef: " + loc, 3427325);
			return;
		}
		if (subGraphics == null)
		{
			Log.ErrorOnce("Graphic_Fire has no subgraphics " + thingDef, 358773633);
			return;
		}
		int num = Find.TickManager.TicksGame;
		if (thing != null)
		{
			num += Mathf.Abs(thing.thingIDNumber ^ 0x80FD52);
		}
		int num2 = num / BaseTicksPerFrameChange;
		int num3 = Mathf.Abs(num2 ^ ((thing?.thingIDNumber ?? 0) * 391)) % subGraphics.Length;
		float fireSize = 1f;
		CompFireOverlayBase compFireOverlayBase = null;
		if (thing is Fire fire)
		{
			fireSize = fire.fireSize;
		}
		else if (thing != null)
		{
			compFireOverlayBase = thing.TryGetComp<CompFireOverlayBase>();
			if (compFireOverlayBase != null)
			{
				fireSize = compFireOverlayBase.FireSize;
			}
			else
			{
				compFireOverlayBase = thing.TryGetComp<CompDarklightOverlay>();
				if (compFireOverlayBase != null)
				{
					fireSize = compFireOverlayBase.FireSize;
				}
			}
		}
		if (num3 < 0 || num3 >= subGraphics.Length)
		{
			Log.ErrorOnce("Fire drawing out of range: " + num3, 7453436);
			num3 = 0;
		}
		Graphic graphic = subGraphics[num3];
		float num5 = ((compFireOverlayBase == null) ? Mathf.Min(fireSize / 1.2f, 1.2f) : fireSize);
		Vector3 pos = loc;
		if (compFireOverlayBase != null)
		{
			pos += compFireOverlayBase.Props.offset;
		}
		Vector3 s = new Vector3(num5, 1f, num5);
		Matrix4x4 matrix = default(Matrix4x4);
		matrix.SetTRS(pos, Quaternion.identity, s);
		Graphics.DrawMesh(MeshPool.plane10, matrix, graphic.MatSingle, 0);
	}

	public override string ToString()
	{
		return "Flicker(subGraphic[0]=" + subGraphics[0].ToString() + ", count=" + subGraphics.Length + ")";
	}
}
