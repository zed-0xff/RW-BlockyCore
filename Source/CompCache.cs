using System.Collections.Generic;
using Verse;

namespace Blocky.Core;

public class CompCache<T> : CacheBase where T : ThingComp {
    static Dictionary <int, T> dict = new Dictionary<int, T>();

    public static IEnumerable<T> All {
        get { return dict.Values; }
    }

    static int Hash(IntVec3 pos, Map map){
        return Gen.HashCombineInt(pos.GetHashCode(), map.uniqueID);
    }

    static int Hash(IntVec3 pos, int map_id){
        return Gen.HashCombineInt(pos.GetHashCode(), map_id);
    }

    static public void Add(T t){
        if( t == null || t.parent == null ) return;

        Add(t, t.parent.Map);
    }

    static public void Add(T t, Map map){
        if( t == null || map == null ) return;

        Add(t, map.uniqueID);
    }

    static public void Add(T t, int map_id){
        if( t == null ) return;

        var parent = t.parent;
        if( parent == null || parent.Position == null ) return;

        registerDict(dict);
        dict[Hash(parent.Position, map_id)] = t;
    }

    static public T Get(IntVec3 pos, Map map){
        if( pos == null || map == null ) return null;

        if( dict.TryGetValue(Hash(pos, map), out T x) ){
            return x;
        }
        return null;
    }

    static public void Remove(T t, Map map){
        if( t == null ) return;

        var parent = t.parent;
        if( parent == null || parent.Position == null || map == null ){
            Remove(t);
            return;
        }

        dict.Remove(Hash(parent.Position, map));
    }

    // slower
    static public void Remove(T t){
        if( t == null ) return;

        foreach( KeyValuePair<int, T> kv in dict ) {
            if( kv.Value == t ){
                dict.Remove(kv.Key);
                break;
            }
        }
    }

    static public void Clear(){
        dict.Clear();
    }

    // required for scribe dict loading
    static List<int> tmpKeys;
    static List<T> tmpValues;

    public static void ExposeData(){
        Scribe_Collections.Look(ref dict, "dict", LookMode.Value, LookMode.Reference, ref tmpKeys, ref tmpValues);
        if( dict == null ){
            dict = new Dictionary<int, T>();
        }
    }
}
