ensure_loaded(roumanie).
ensure_loaded(queue).
% Node format : Location, Heuristic, CurrentCost, CurrentPath, ...

% Expand the selected node.
% +Node, +PriorityQueue, -UpdatedPriorityQueue
expand([Location, _, CurrentCost, Path],  PQ, NewPQ):-
	s(Location, Dest),
	prioritize(CurrentCost, Location, Path, Dest,PQ, NewPQ).

% Internal logic of "expand".
% +CurrentCost, +CurrentLocation, +Path, +Destinations, +RemaningQueue,
% -OutQueue
prioritize(_,_,_,[],PQ,PQ).  % end condition
prioritize(CurrentCost, CurrentLocation,Path, [EvaluatedDestination|Destinations], PQ, PQOut):-
	computeG(CurrentLocation, EvaluatedDestination, Distance),
	computeH(EvaluatedDestination, Heuristic),
	NewEstimatedCost is CurrentCost+ Distance + Heuristic,
	TravelCost is CurrentCost + Distance,
	append(Path,[CurrentLocation], NPath),
	insert_pq([EvaluatedDestination, NewEstimatedCost, TravelCost, NPath], PQ, PQNew ),
	prioritize(CurrentCost, CurrentLocation, Path, Destinations, PQNew,PQOut).

% +InitialNode, +Goal, +CurrentPQ, -Path
findGoal([Goal,_,_,Path], Goal,_, Path):-!.
findGoal(InitNode, Goal, PQ, Out):-
	expand(InitNode, PQ, [Node|NextPQ]),
	findGoal(Node, Goal, NextPQ, Out).


% ------------------------
% Case specific code
computeH(State, H):- h(State, H).
computeG(State, Dest, G):- d(State, Dest, G).

start(Origin, Destination, R):-findGoal([Origin, 0, 0, []], Destination, PQ, R).
