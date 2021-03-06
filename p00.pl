%-----------------------------------------------------------------------------
% Auteur: Charles-Antoine Brunet
% Version: 3.0
% Date: 2015-07-29
%-----------------------------------------------------------------------------
% Le nom du fichier, le nom du module, le prï¿½fixe des prï¿½dicats et le nom
% du mutex ont tous la mï¿½me valeur. Dans ce cas ci, c'est p00. Changez TOUTES
% les occurrences de p00 dans ce fichier pour le prï¿½fixe qui vous est assignï¿½.
%-----------------------------------------------------------------------------

% Un JI doit ï¿½tre un module afin d'ï¿½viter les conflits de noms entre les JI.
:- module(p03,[p03_nom/1,p03_auteurs/1,p03_reset/0,p03_plan/1,p03_action/2]).

%-----------------------------------------------------------------------------
% Prï¿½dicats de jeu.
%-----------------------------------------------------------------------------

% Nom du JI: p00_nom(-Nom)
p03_nom('Lad').

% Auteurs du JI: p00_auteurs(-Auteurs)
p03_auteurs('Etienne et Max').

% Remise ï¿½ zero du JI: p00_reset
p03_reset :-
    planInitial(P),
    setPlan(P).

% Plan courant du JI: p00_plan(-PlanCourant)
p03_plan(Plan) :-
    getPlan(Plan).

% Prochaine action du JI: p00_action(+Etat, -Action)
p03_action(Etat, Action) :-
    trouveAction(Etat, Action).

%-----------------------------------------------------------------------------
% Prï¿½dicats internes de plans.
%-----------------------------------------------------------------------------
% La consultation d'un plan et la modification d'un plan sont protï¿½gï¿½es par
% mutex afin d'ï¿½viter les conflits possibles d'appels en parallï¿½le.
%
% Le prï¿½dicat planRestant est dï¿½clarï¿½ dynamique, car sa valeur change au cours
% de l'exï¿½cution.
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
% Prï¿½dicats internes d'action
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

playerHasBetterBlock([_,_,_,_,Joueurs,_], [_,_,_,_,V], X,Y):-
	member_set([_,_,X,Y,PV], Joueurs),
	PV>V.

validateMove(State,Direction):- getJoueur(State,Joueur), position(Joueur, Direction, X,Y), clear(State,X,Y).
validateTake(State,Direction):- getJoueur(State,Joueur), position(Joueur, Direction, X,Y), block(State,X,Y).
validateDrop(State, Direction):- getJoueur(State,Joueur), position(Joueur, Direction, X,Y), hasBlock(Joueur), clear(State,X,Y).
validateAttack(State, Direction):-getJoueur(State,Joueur), position(Joueur, Direction, X,Y), playerOn(State, X,Y), playerHasBetterBlock(State, Joueur, X,Y).

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

dropBlock(Blocks,0,_,_,Blocks):-!.
dropBlock(Blocks, Value, X, Y, ResultingBlocks):-
	add_in_set([Value,X,Y], Blocks, ResultingBlocks).

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
	RetVal is floor(sqrt( abs((PosX-GX)*10)^2 + abs((PosY- GY)*10)^2)).



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
	getBestFleeAction(State,[], Actions,_,[BestNode|_] ),
	[_, _, _,ProchaineAction] = BestNode.


hasBestBlock([_,NBlocks,_,_,Joueurs,_]):-
	getJoueurFrom(Joueurs,[_,_,_,_,Value]),
	NBlocks = Value.

% -------------------
% Main call
% -------------------
trouveAction(State, ProchaineAction,Plan) :-
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

state_attack([4,3,4,4,
[[2,'Lad',0,2,0],[3,'Zouf',1,0,0],[1,'Ares',3,0,3],
[4,'Buddy',2,2,0]],[[1,1,3],[2,0,1]]]).

state3([2,6,5,5,[[1,'Lad',0,0,0],[2,'Unknown2',1,0,0]],[[1,1,2],[2,3,0],[3,4,0],[4,2,2],[5,1,1],[6,2,1]]]).



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

prioritize(_,_,_,[],PQ,PQ).  % end condition

getBestFleeAction(_,_,[],PQ,PQ).
getBestFleeAction(CurrentState, Path, [Action|RemainingActions], PQ, PQOut):-
	computeG(CurrentState, Action, ActionCost),
	applyAction(CurrentState, Action, ResultingState),
	computeRunningH(ResultingState, Heuristic),
	NewEstimatedCost is ActionCost + Heuristic,
	TravelCost is ActionCost,
	append(Path,[Action], NPath),
	insert_pq([ResultingState, NewEstimatedCost, TravelCost, NPath], PQ, PQNew ),
	getBestFleeAction(CurrentState, Path, RemainingActions, PQNew,PQOut).

% +InitialNode, +Goal, +CurrentPQ, -Path
findGoal([[_,_,_,_,Players,_],_,_,Path], Goal,_, Path):- member_set(Goal,Players), !.

findGoal(InitNode, Goal, PQ, Out):-
	expand(InitNode, PQ, [Node|NextPQ]),
	findGoal(Node, Goal, NextPQ, Out).


% ------------------------
% Case specific code
computeH(State,H):-
	evaluateState(State,H).

computeRunningH(State,H):-
	getJoueur(State, Player),
	[_,_,X,Y,_] = Player,
	[_,_,_,_,Players,_] = State,
	 getRunningHeuristic(X,Y, Players,0, V),
        H is 1000-V.

% +State, +Action, -Cost
computeG(_, _, G):- G is 1.

astar(InitialState, GoalState, R):-findGoal([InitialState, 0, 0, []], GoalState, _, R).



%includes
%Queue

%------------------------------------------------------------------------------
% +: param�tre en entr�e
% -: param�tre en sortie
% ?: param�tre en entr�e ou sortie
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% Tester si une file est vide ou cr�er une file
% empty_queue(?Stack)
%------------------------------------------------------------------------------
empty_queue([]).

%------------------------------------------------------------------------------
% Ajouter un item dans la file
% enqueue(+Item, +Queue, -NewQueue)
% Item=item � ajouter, Y=ancienne file, Z=nouvelle file
%------------------------------------------------------------------------------
enqueue(E, [], [E]).
enqueue(E, [H|T], [H|Tnew]) :- enqueue(E, T, Tnew).

%------------------------------------------------------------------------------
% Elever un item de la file
% dequeue(-Item, +Queue, -NewQueue)
% Item= item enlev�, Queue=ancienne file, NewQueue=la nouvelle file
%------------------------------------------------------------------------------
dequeue(E, [E|T], T).

%------------------------------------------------------------------------------
% Consulte le premier item de la file
% peek_queue(-Item, +Queue), Item=premier item, Queue= file a consulter
%------------------------------------------------------------------------------
peek_queue(E, [E|_]).

%------------------------------------------------------------------------------
% V�rifier si un �lement est membre d'une file
% Utilise la fonction member de la librairie standard de liste
%------------------------------------------------------------------------------
member_queue(E, T) :- member(E, T).

%------------------------------------------------------------------------------
% Ajoute une liste d'�lements � une file
% add_list_to_queue(+List, +Queue, -NewQueue)
% List=liste � ajouter, Queue=ancienne file, NewQueue=nouvelle file
% Utilise la fonction append de la librairie standard de liste
%------------------------------------------------------------------------------
add_list_to_queue(List, T, NewT) :- append(T, List, NewT).
%------------------------------------------------------------------------------
% QUEUE AVEC PRIORIT�
%------------------------------------------------------------------------------
% Les op�rateurs empty_queue, member_queue, dequeue et peek sont les m�mes
%      que plus haut. Les 2 op�rateurs qui changent sont les suivants
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% Ajouter un item dans la file avec priorit�
% insert_pq(+Item, +Queue, -NewQueue)
% Item=item � ajouter, Y=ancienne file, Z=nouvelle file
%------------------------------------------------------------------------------
insert_pq(E, [], [E]) :- !.
insert_pq(E, [H|T], [E, H|T]) :- precedes(E,H), !.
insert_pq(E, [H|T], [H|Tnew]) :- insert_pq(E, T, Tnew).

%------------------------------------------------------------------------------
% Ajouter une liste d'�l�ments (non ordonn�s) � une file avec priorit�
% insert_list_pq(+List, +Queue, -NewQueue)
% List=liste � ajouter, Queue=ancienne file, NewQueue=nouvelle file
%------------------------------------------------------------------------------
insert_list_pq([], L, L).
insert_list_pq([E|T], L, NewL) :-
    insert_pq(E, L, Tmp), insert_list_pq(T, Tmp, NewL).

%------------------------------------------------------------------------------
% IMPORTANT! Selon le type de donn�es, peut-�tre n�cessaire de changer la
%     d�finition du pr�dicat suivant.
%------------------------------------------------------------------------------
precedes([_,ValX,_,_],[_, ValY,_,_]) :- ValX < ValY.



%Set

%------------------------------------------------------------------------------
% +: paramètre en entrèe
% -: paramètre en sortie
% ?: paramètre en entrèe ou sortie
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% Tester si un set est vide ou créer un set
% empty_set(?Set)
%------------------------------------------------------------------------------
empty_set([]).

%------------------------------------------------------------------------------
% Vérifier si un élément est membre d'un set
% Utilise la fonction member de la librairie standard de liste
% member_set(+Item, +Set)
%------------------------------------------------------------------------------
member_set(E, S) :- member(E, S).

%------------------------------------------------------------------------------
% Enlever un élément du set, s'il est présent
% delete_in_set(+Item, +Set, -NewSet)
% Item=item à enlever, Set = ancien set, NewSet = nouveau set
%------------------------------------------------------------------------------
delete_in_set(_, [], []) :- !.
delete_in_set(E, [E|T], T) :- !.
delete_in_set(E, [H|T], [H|Tnew]) :- delete_in_set(E,T,Tnew).

%------------------------------------------------------------------------------
% Ajouter un élément au set, s'il n'est pas présent
% add_in_set(+Item, +Set, -NewSet)
% Item=item à ajouter, Set = ancien set, NewSet = nouveau set
%------------------------------------------------------------------------------
add_in_set(E, S, S) :- member(E,S), !.
add_in_set(E, S, [E|S]).

%------------------------------------------------------------------------------
% Fusionner 2 sets
% set_union(+Set1, +Set2, -Set3)
% Set3 contient les items de Set1 et de Set2
%------------------------------------------------------------------------------
set_union([], S, S).
set_union([H|T], S, Snew) :- set_union(T, S, Tmp), add_in_set(H, Tmp, Snew).

%------------------------------------------------------------------------------
% Vérifier si un set est un sous-ensemble d'un autre
% sub_set(+Set1, +Set2) est vrai si Set1 est un sous-ensemble de Set2.
%------------------------------------------------------------------------------
sub_set([],_).
sub_set([H|T], S) :- member_set(H,S), sub_set(T,S).

%------------------------------------------------------------------------------
% Trouver les éléments communs à 2 sets
% set_intersection(+Set1, +Set2, -Intersection)
% Intersection contient les items communs à Set1 et Set2.
%------------------------------------------------------------------------------
set_intersection([], _, []).
set_intersection([H|T],S,[H|Snew]) :-
    member_set(H,S), set_intersection(T,S,Snew), !.
set_intersection([_|T],S,Snew) :- set_intersection(T, S, Snew).

%------------------------------------------------------------------------------
% Calculer la différence entre 2 sets.
% set_difference(+Set1,+Set2,-Difference)
% Différence contient les éléments qui sont dans Set1 mais pas dans Set2
%------------------------------------------------------------------------------
set_difference([], _, []).
set_difference([H|T], S, Tnew) :-
    member_set(H,S), set_difference(T, S, Tnew), !.
set_difference([H|T], S, [H|Tnew]) :- set_difference(T,S,Tnew).

%------------------------------------------------------------------------------
% Vérifier si 2 sets sont équivalents
% equal_set(+S1, +S2)
% Vrai si tous membres de Set1 sont dans Set2 et ceux de Set2 dans Set1
%------------------------------------------------------------------------------
equal_set(S1, S2) :- sub_set(S1, S2), sub_set(S2, S1).

%------------------------------------------------------------------------------
% Imprimer un set
%------------------------------------------------------------------------------
print_set([]).
print_set([H|Q]) :- write(H), nl, print_set(Q).

