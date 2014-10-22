

-define(GV(P,L), proplists:get_value(P,L)).
-define(GV(P,L,D), proplists:get_value(P,L,D)).
-define(KS(K,V,L), lists:keystore(K, 1, L, {K, V})).
