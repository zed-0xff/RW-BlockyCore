using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Verse;

namespace Blocky.Core;

public class CacheBase {
    private static HashSet<IDictionary> allDicts = new HashSet<IDictionary>();

    protected static void registerDict(IDictionary d){
        allDicts.Add(d);
    }

    public static void ClearAll(){
        foreach( var x in allDicts ){
            x.Clear();
        }
    }
}

public class Cache<T> : CacheBase where T : Thing {
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

    static public void Add(T t, Map map){
        if( t == null || map == null || t.Position == null ) return;

        registerDict(dict);
        dict[Hash(t.Position, map)] = t;
    }

    static public void Add(T t, int map_id){
        if( t == null || t.Position == null ) return;

        registerDict(dict);
        dict[Hash(t.Position, map_id)] = t;
    }

    static public T Get(IntVec3 pos, Map map){
        if( pos == null || map == null ) return null;

        if( dict.TryGetValue(Hash(pos, map), out T x) ){
            return x;
        }
        return null;
    }

    static public void Remove(T t, Map map){
        if( t == null || map == null || t.Position == null ) return;

        dict.Remove(Hash(t.Position, map));
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
