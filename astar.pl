
ensure_loaded(roumanie).



%expand(Cost, Location, Location, PQ, PQ).

expand([Location,_, CurrentCost,Path],  PQ, NewPQ):-
	s(Location, Dest),
	prioritize(CurrentCost, Location,Path, Dest,PQ, NewPQ).

prioritize(_,_,_,[],PQ,PQ).

prioritize(CurrentCost, CurrentLocation,Path,[D|Destinations],PQ, PQOut):-
	d(CurrentLocation,D, Distance), h(D, Heuristic),
	NewCost is  CurrentCost+ Distance + Heuristic,
	TravelCost is CurrentCost + Distance,
	append(Path,[CurrentLocation], NPath),
	insert_pq([D, NewCost, TravelCost, NPath], PQ, PQNew ),
	prioritize(CurrentCost, CurrentLocation, Path, Destinations, PQNew,PQOut).


findGoal([Goal,_,_,Path], Goal,_, Path):-writeln("Shwaddup"),!.
findGoal(InitNode, Goal, PQ, Out):-
	expand(InitNode, PQ, [Node|NextPQ]),
	findGoal(Node, Goal, NextPQ, Out).


