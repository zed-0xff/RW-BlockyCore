using System;
using System.IO;
using System.Collections.Generic;
using System.Reflection;
using Verse;
using UnityEngine;

namespace Blocky.Props;

public enum TabShowMode{ DevModeOnly, GodModeOnly, Always, Never };

public class Settings : ModSettings {
    public TabShowMode tabShowMode = TabShowMode.DevModeOnly;

    public override void ExposeData() {
        Scribe_Values.Look(ref tabShowMode, "tabShowMode", TabShowMode.DevModeOnly);
        base.ExposeData();
    }
}

class PropsTab : SettingsTabBase {
    public override string Title => "Props";

    public override void Draw(Listing_Standard l){
        l.LabelDouble("Show 'Blocky.Props' architect menu tab", "");
        foreach (TabShowMode x in Enum.GetValues(typeof(TabShowMode))) {
            if( l.RadioButton(GenText.SplitCamelCase(x.ToString()), ModConfig.Settings.tabShowMode == x, 20) ){
                ModConfig.Settings.tabShowMode = x;
            }
        }
    }

    public override void Write(){
        ModConfig.Settings.Write();
    }
}

public class ModConfig : Mod
{
    public override string SettingsCategory() => "Blocky";

    public static Settings Settings { get; private set; }

    static List<SettingsTabBase> Tabs;

    public ModConfig(ModContentPack content) : base(content) {
        Settings = GetSettings<Settings>();

        Tabs = new List<SettingsTabBase>();
        foreach( Type t in typeof(SettingsTabBase).AllSubclassesNonAbstract()){
            Tabs.Add( (SettingsTabBase)Activator.CreateInstance(t, null) );
        }
    }

    int PageIndex = 0;

    public override void DoSettingsWindowContents(Rect inRect) {
        var tabRect = new Rect(inRect) {
            y = inRect.y + 40f
        };
        var mainRect = new Rect(inRect) {
            height = inRect.height - 40f,
            y = inRect.y + 40f
        };

        Widgets.DrawMenuSection(mainRect);

        var tabs = new List<TabRecord>();
        for( int i=0; i<Tabs.Count; i++ ){
            var t = Tabs[i];
            var li = i; // lambda's local i
            tabs.Add( new TabRecord(t.Title, () => { PageIndex = li; }, PageIndex == i));
        }
        TabDrawer.DrawTabs(tabRect, tabs);

        Listing_Standard l = new Listing_Standard();
        l.Begin(mainRect.ContractedBy(15f));
        Tabs[PageIndex].Draw(l);
        l.End();
    }

    public override void WriteSettings(){
        base.WriteSettings();
        foreach( SettingsTabBase tab in Tabs ){
            tab.Write();
        }
    }
}
