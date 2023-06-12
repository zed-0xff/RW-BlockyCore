using System.Collections;
using System.Collections.Generic;

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

