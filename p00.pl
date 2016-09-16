%-----------------------------------------------------------------------------
% Auteur: Charles-Antoine Brunet
% Version: 3.0
% Date: 2015-07-29
%-----------------------------------------------------------------------------
% Le nom du fichier, le nom du module, le pr�fixe des pr�dicats et le nom
% du mutex ont tous la m�me valeur. Dans ce cas ci, c'est p00. Changez TOUTES
% les occurrences de p00 dans ce fichier pour le pr�fixe qui vous est assign�.
%-----------------------------------------------------------------------------

% Un JI doit �tre un module afin d'�viter les conflits de noms entre les JI.
:- module(p00,[p00_nom/1,p00_auteurs/1,p00_reset/0,p00_plan/1,p00_action/2]).

%-----------------------------------------------------------------------------
% Pr�dicats de jeu.
%-----------------------------------------------------------------------------

% Nom du JI: p00_nom(-Nom)
p00_nom('Lad').

% Auteurs du JI: p00_auteurs(-Auteurs)
p00_auteurs('Etienne et Max').

% Remise � zero du JI: p00_reset
p00_reset :-
    planInitial(P),
    setPlan(P).

% Plan courant du JI: p00_plan(-PlanCourant)
p00_plan(Plan) :-
    getPlan(Plan).

% Prochaine action du JI: p00_action(+Etat, -Action)
p00_action(Etat, Action) :-
    trouveAction(Etat, Action).

%-----------------------------------------------------------------------------
% Pr�dicats internes de plans.
%-----------------------------------------------------------------------------
% La consultation d'un plan et la modification d'un plan sont prot�g�es par
% mutex afin d'�viter les conflits possibles d'appels en parall�le.
%
% Le pr�dicat planRestant est d�clar� dynamique, car sa valeur change au cours
% de l'ex�cution.
%-----------------------------------------------------------------------------

:- dynamic([planRestant/1]).

planInitial([move(1),move(2),move(3),move(4)]).

planRestant([move(1),move(2),move(3),move(4)]).

getPlan(Plan) :-
    with_mutex(p00,planRestant(Plan)).

setPlan(Plan) :-
    with_mutex(p00,changePlan(Plan)).

changePlan(Plan) :-
    retractall(planRestant(_)),
    assert(planRestant(Plan)).

%-----------------------------------------------------------------------------
% Pr�dicats internes d'action
%-----------------------------------------------------------------------------
%-----------------------------------------------------------------------------
% +Direction
move(_).
% +Direction
take(_).
% +Direction
drop(_).
% +Direction
attack(_).
% None
none().

getJoueur([_,_,_,_,Joueurs|_], Joueur) :-  getJoueurFrom(Joueurs, Joueur).
getJoueurFrom(Joueurs, Joueur) :- p00_nom(Nom),  member_set([N,Nom,X,Y,Z], Joueurs), append([],[N,Nom,X,Y,Z], Joueur).
getJoueurFromPosition(Joueurs, X, Y, Joueur):- member_set([N,Nom,X,Y,Z], Joueurs), append([],[N,Nom,X,Y,Z], Joueur).

clear([_, _, NCols, NRows,Joueurs, Blocs], X,Y) :-
	\+member_set([_,_,X,Y,_], Joueurs),
	\+member_set([_,X,Y], Blocs),
	X<NCols,
	Y<NRows,
	X>=0,
	Y>=0.

block([_, _,NCols,NRows,_, Blocs], X,Y) :-
	member_set([_,X,Y], Blocs),
	X<NCols,
	Y<NRows,
	X>=0,
	Y>=0.
hasBlock([_,_,_,_,Block]):- Block >0.

playerOn([_, _,_,_,Joueurs, _], X,Y) :-
	member_set([_,_,X,Y,_], Joueurs).


validateMove(State,Direction):- getJoueur(State,Joueur), position(Joueur, Direction, X,Y), clear(State,X,Y).
validateTake(State,Direction):- getJoueur(State,Joueur), position(Joueur, Direction, X,Y), block(State,X,Y).
validateDrop(State, Direction):- getJoueur(State,Joueur), position(Joueur, Direction, X,Y), hasBlock(Joueur), clear(State,X,Y).
validateAttack(State, Direction):-getJoueur(State,Joueur), position(Joueur, Direction, X,Y), playerOn(State, X,Y).

action(State, move(Direction)) :- validateMove(State,Direction).
action(State, take(Direction)) :- validateTake(State,Direction).
action(State, drop(Direction)) :- validateDrop(State,Direction).
action(State, attack(Direction)) :- validateAttack(State,Direction).
action(_, none()).

getPosition(1, X,Y, X1,Y1):- X1 is X , Y1 is Y+1.
getPosition(2, X,Y, X1,Y1):- X1 is X+1 , Y1 is Y.
getPosition(3, X,Y, X1,Y1):- X1 is X , Y1 is Y-1.
getPosition(4, X,Y, X1,Y1):- X1 is X-1 , Y1 is Y.
getPosition(5, X,Y, X1,Y1):- X1 is X+1, Y1 is Y+1.
getPosition(6, X,Y, X1,Y1):- X1 is X +1, Y1 is Y-1.
getPosition(7, X,Y, X1,Y1):- X1 is X-1, Y1 is Y-1.
getPosition(8, X,Y, X1,Y1):- X1 is X-1, Y1 is Y+1.

position([_,_,X1,Y1,_], Direction, X,Y):- getPosition(Direction, X1,Y1, X,Y).


getAvailableActions(State, Actions):- findall(Action, action(State, Action), Actions).


movePlayer(Players, [N,Name,_,_,Block],X,Y,ResultingPlayers):-
	add_in_set([N,Name,X,Y,Block], Players, ResultingPlayers).


dropBlock(Blocks, Value, X, Y, ResultingBlocks):-
	add_in_set([Value,X,Y], Blocks, ResultingBlocks).
dropBlock(Blocks,0,_,_,Blocks).

acquireBlock(Players, Blocks, [N,Name,X,Y,PlayerBlock], BlockX,BlockY, ResultingPlayers, ResultingBlocks):-
	member_set([Value,BlockX,BlockY],Blocks),
	delete_in_set([_,BlockX,BlockY],Blocks,TBlocks),
	add_in_set([N,Name,X,Y,Value],Players,ResultingPlayers),
	dropBlock(TBlocks, PlayerBlock, BlockX, BlockY, ResultingBlocks).

stealBlock(Players, [PN, PName, PX, PY, PB], [VN, VName, VX, VY, VB], ResultingPlayers):-
	add_in_set([PN,PName,PX,PY,VB], Players, T1),
	add_in_set([VN,VName,VX,VY,PB], T1, ResultingPlayers).

applyAction([A,B,C,D,Players,E], move(Dir), [A,B,C,D,ResultingPlayers,E]):-
	getJoueurFrom(Players,Player),
	delete_in_set(Player,Players,T1),
	position(Player,Dir,X,Y),
	movePlayer(T1,Player,X,Y,ResultingPlayers).

applyAction([A,B,C,D,Players,Blocks], take(Dir), [A,B,C,D,ResultingPlayers,ResultingBlocks]):-
	getJoueurFrom(Players,Player),
	delete_in_set(Player,Players,T1),
	position(Player,Dir,X,Y),
	acquireBlock(T1,Blocks, Player, X, Y, ResultingPlayers,ResultingBlocks).

applyAction([A,B,C,D,Players,Blocks], drop(Dir), [A,B,C,D,ResultingPlayers,ResultingBlocks]):-
	getJoueurFrom(Players,Player),
	delete_in_set(Player,Players,T1),
	position(Player,Dir,X,Y),
	[PN,PName,PX,PY,V] = Player,
	dropBlock(Blocks,V, X,Y, ResultingBlocks),
        add_in_set([PN,PName,PX,PY,0], T1, ResultingPlayers).

applyAction([A,B,C,D,Players,E], attack(Dir), [A,B,C,D,ResultingPlayers,E]):-
	getJoueurFrom(Players,Player),
	delete_in_set(Player,Players,T1),
	position(Player,Dir,X,Y),
	getJoueurFromPosition(Players, X, Y, Victim),
	delete_in_set(Victim, T1, T2),
	stealBlock(T2, Player, Victim, ResultingPlayers).

applyAction(State, none(), State).

% -----------------------------
% Utils
% -----------------------------

getBestFreeBlock([],_, Block,Block).

getBestFreeBlock([[Value, PosX, PosY]|T],BestVal, TBlock, Block) :-
	(Value >= BestVal, NextVal is Value,
	getBestFreeBlock(T, NextVal, [Value, PosX, PosY], Block) ;
	Value < BestVal,
	getBestFreeBlock(T,BestVal,TBlock,Block)) .

getBestPlayerBlock([], _, Player, Player).

getBestPlayerBlock([[PNumber, PName, PosX, PosY, BlockVal]|T], BestVal, TPlayer,Player):-
	(p00_nom(Name),
	 Name == PName,
	 getBestPlayerBlock(T, BestVal, TPlayer, Player);
	 BlockVal >= BestVal, NextVal is BlockVal,
	 getBestPlayerBlock(T, NextVal,[PNumber, PName, PosX, PosY, BlockVal], Player);
	 BlockVal < BestVal,
	 getBestPlayerBlock(T, BestVal, TPlayer, Player)).

getBestBlockValue([_,NBlocks|_], NBlocks).

% ---------------------------------------
% Heuristics things
% --------------------------------------
%
%
getRunningHeuristic(_, _, [], Sum, Sum).
getRunningHeuristic(PosX, PosY, [Player|NextPlayers], Sum, RetVal):-
	[_,_, PX, PY, PV] = Player,
        TempRet is Sum + floor(sqrt( abs(PosX-PX)^2 + abs(PosY- PY)^2))*PV,
	getRunningHeuristic(PosX, PosY, NextPlayers, TempRet, RetVal).



getDistanceHeuristic(PosX, PosY, GX,  GY, RetVal):-
	RetVal is floor(sqrt( abs(PosX-GX)^2 + abs(PosY- GY)^2)).



calculateHeuristic([_,_,PosX,PosY, MyBlock], [BlockVal, BlockX, BlockY], [_,_,PlayerX, PlayerY, PBlock],Joueurs, RetVal):-
	%Already have best block
	(MyBlock >PBlock, MyBlock > BlockVal,
	 % getRunningHeuristic(PosX,PosY, Joueurs,0, Val),
	RetVal is 1;

	%Best block on
	(MyBlock < BlockVal, PBlock<BlockVal,
	getDistanceHeuristic(PosX, PosY, BlockX,BlockY, RetVal));

	%Best block on player
	(MyBlock <PBlock, PBlock>BlockVal,
	getDistanceHeuristic(PosX, PosY, PlayerX,PlayerY, RetVal))).

evaluateState([_,_,_,_, Joueurs, Blocks ], RetVal) :-
	getJoueurFrom(Joueurs, Joueur),
	getBestFreeBlock(Blocks,0,_,Block),
	getBestPlayerBlock(Joueurs,0,_,Player),
	calculateHeuristic(Joueur, Block, Player, Joueurs, RetVal).

planEscape(State, ProchaineAction):-
	getAvailableActions(State, Actions ),
	prioritize(0, State, [], Actions, _,[BestNode|_]),
	[_, _, _,ProchaineAction] = BestNode.


hasBestBlock([_,NBlocks,_,_,Joueurs,_]):-
	getJoueurFrom(Joueurs,[_,_,_,_,Value]),
	NBlocks = Value.

% -------------------
% Main call
% -------------------
trouveAction(State, ProchaineAction, Plan) :-
	( hasBestBlock(State),
	  planEscape(State, ProchaineAction);

	  \+hasBestBlock(State),
	  p00_nom(Name), getBestBlockValue(State,BestBlock),
	  astar(State,[_,Name,_,_,BestBlock],Plan),
	  changePlan(Plan),
	  getPlan([ProchaineAction|PlanRestant]),
	  setPlan(PlanRestant)
	),!.

% -------------------------------------------
% Test states
% ----------------------------------------------

state([4,3,4,4,
[[2,'Lad',0,2,3],[3,'Zouf',1,3,0],[1,'Ares',3,0,0],
[4,'Buddy',2,2,0]],[[1,1,3],[2,0,1]]]).

state2([4,3,4,4,
[[2,'Lad',0,2,0],[3,'Zouf',1,0,0],[1,'Ares',3,0,0],
[4,'Buddy',2,2,0]],[[1,1,3],[3,3,2],[2,0,1]]]).


joueurs([[2,'Lad',0,2,0],[3,'Zouf',1,0,0],[1,'Ares',3,0,0],
[4,'Buddy',2,2,0]]).

blocs([[1,1,3],[3,3,2],[2,0,1]]).


% -------------------------------------------
% A star
% ------------------------------------------
%
% Expand the selected node.
% +Node, +PriorityQueue, -UpdatedPriorityQueue
expand([State, _, CurrentCost, Path],  PQ, NewPQ):-
	getAvailableActions(State, Actions),
	prioritize(CurrentCost, State, Path, Actions,PQ, NewPQ).

% Internal logic of "expand".
% +CurrentCost, +CurrentState, +Path, +PossibleActions,
% +RemaningQueue, -OutQueue
prioritize(_,_,_,[],PQ,PQ).  % end condition
prioritize(CurrentCost, CurrentState, Path, [Action|RemainingActions], PQ, PQOut):-
	computeG(CurrentState, Action, ActionCost),
	applyAction(CurrentState, Action, ResultingState),
	computeH(ResultingState, Heuristic),
	NewEstimatedCost is CurrentCost+ ActionCost + Heuristic,
	TravelCost is CurrentCost + ActionCost,
	append(Path,[Action], NPath),
	insert_pq([ResultingState, NewEstimatedCost, TravelCost, NPath], PQ, PQNew ),
	prioritize(CurrentCost, CurrentState, Path, RemainingActions, PQNew,PQOut).

% +InitialNode, +Goal, +CurrentPQ, -Path
findGoal([[_,_,_,_,Players,_],_,_,Path], Goal,_, Path):- member_set(Goal,Players), !.

findGoal(InitNode, Goal, PQ, Out):-
	expand(InitNode, PQ, [Node|NextPQ]),
	findGoal(Node, Goal, NextPQ, Out).


% ------------------------
% Case specific code
computeH(State,H):-
	evaluateState(State,H).

% +State, +Action, -Cost
computeG(_, _, G):- G is 1.

astar(InitialState, GoalState, R):-findGoal([InitialState, 0, 0, []], GoalState, _, R).



