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
move(Direction).
take(Direction).
drop(Direction).
attack(Direction).
none().

getJoueur([_,_,_,_,Joueurs|_], Joueur) :-  getJoueurFrom(Joueurs, Joueur).
getJoueurFrom(Joueurs, Joueur) :- p00_nom(Nom),  member_set([N,Nom,X,Y,Z], Joueurs), append([],[N,Nom,X,Y,Z], Joueur).


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




% -----------------------------
% Utils
% -----------------------------

getBestFreeBlock([],_, Block,Block).

getBestFreeBlock([[Value, PosX, PosY]|T],BestVal, TBlock, Block) :-(Value >= BestVal, NextVal is Value, getBestBlock(T, NextVal, [Value, PosX, PosY], Block) ; Value < BestVal, getBestBlock(T,BestVal,TBlock,Block)) .

getBestPlayerBlock([], _, Player, Player).

getBestPlayerBlock([[PNumber, PName, PosX, PosY, BlockVal]|T], BestVal, TPlayer,Player):-
	p00_nom(Name),
	Name \= PName,
	( BlockVal >= BestVal, NextVal is BlockVal, getBestPlayerBlock(T, NextVal,[PNumber, PName, PosX, PosY, BlockVal], Player);
	 BlockVal < BestVal, getBestPlayerBlock(T, BestVal, TPlayer, Player)).

getBestBlockValue([_,NBlocks|_], NBlocks).

% ---------------------------------------
% Heuristics things
% --------------------------------------
getRunningHeuristic(PosX, PosY, Joueurs, 100).
getDistanceHeuristic().



calculateHeuristic([_,_,PosX,PosY, PBlock], [BlockVal, BlockX, BlockY], [_,_,PlayerX, PlayerY, PBlock],Joueurs, RetVal):-
	%Already have best block
	((MyBlock >PBlock, MyBlock > BlockVal,
	  getRunningHeuristic(PosX,PosY, Joueurs, RetVal)) ;

	%Best block on
	(MyBlock < BlockVal, PBlock<BlockVal,
	getDistanceHeuristic(PosX, PosY, BlockX,BlockY));

	%Best block on player
	(MyBlock <PBlock, PBlock>BlockVal,
	getDistanceHeuristic(PosX, PosY, PlayerX,PlayerY))).




evaluateState([NPlayers,NBlocs, NCols,NRows, Joueurs, Blocks ], ReturnVal) :-

	getJoueurFrom(Joueurs, Joueur),
	getBestFreeBlock(Blocks,0,_,Block),
	getBestPlayerBlock(Joueurs,0,_,Player),
	calculateHeuristic(Joueur, Block, Player, Joueurs, RetVal).


evaluateActions(State, [Action|T] , Steps).
	%resolveAction(State, Action, NextState),
	%evaluateState(NextState, Value),
	%Push to queue(Action, Value), evaluateActions(NextState, T,Steps).



planEscape(State, ProchaineAction):-
	getPossibleActions(State, Actions),
	evaluateActions(State, Actions, ProchaineAction, run).


hasBestBlock([_,NBlocks,_,_,Joueurs,_]):-
	getJoueur(State,[_,_,_,_,Value]),
	NBlocks = Value.

planAcquireBlock( State, _, Goal):- member_set(State,Goal).

planAcquireBlock( State, ProchaineAction, Goal):-
       getPossibleActions(State,Actions),
       hasBestBlock(State).



% -------------------
% Main call
% -------------------
trouveAction(EtatJeu, ProchaineAction) :-
    getPlan([ProchaineAction]), !, planInitial(P), setPlan(P).



trouveAction(EtatJeu, ProchaineAction) :-
	( hasBlock(EtatJeu),
	  planEscape(EtatJeu, ProchaineAction) ;
	  \+hasBlock(EtatJeu),
	  p00_nom(Name), getBestBlockValue(State,BestBlock),
	  astar(EtatJeu,[_,Name,_,_,BestBlock],Plan),
	  changePlan(plan),
	  getPlan([ProchaineAction|PlanRestant]),
	  setPlan(PlanRestant)
	).

% -------------------------------------------
% Test states
% ----------------------------------------------

state([4,3,4,4,
[[2,'Lad',0,2,3],[3,'Zouf',1,3,2],[1,'Ares',3,0,0],
[4,'Buddy',2,2,0]],[[1,1,3],[2,0,1]]]).

state2([4,3,4,4,
[[2,'Lad',0,2,3],[3,'Zouf',1,0,0],[1,'Ares',3,0,0],
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
	getPossibleActions(State, Actions),
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
	insert_pq([Action, NewEstimatedCost, TravelCost, NPath], PQ, PQNew ),
	prioritize(CurrentCost, CurrentState, Path, RemainingActions, PQNew,PQOut).

% +InitialNode, +Goal, +CurrentPQ, -Path
findGoal([State,_,_,Path], Goal,_, Path):- member_set(Goal,State).
findGoal(InitNode, Goal, PQ, Out):-
	expand(InitNode, PQ, [Node|NextPQ]),
	findGoal(Node, Goal, NextPQ, Out).


% ------------------------
% Case specific code
computeH(State,H):-
	evaluateState(ResultingState,H).

computeG(State, Dest, G):- G is 1.

astar(Origin, Destination, R):-findGoal([Origin, 0, 0, []], Destination, PQ, R).



