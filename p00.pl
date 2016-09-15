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
% Calcul de la prochaine action du JI. Ce JI ne fera jamais rien de bon...
%-----------------------------------------------------------------------------
trouveAction(EtatJeu, ProchaineAction) :-
    getPlan([ProchaineAction]), !, planInitial(P), setPlan(P).


trouveAction(EtatJeu, ProchaineAction) :-    getPlan([ProchaineAction|PlanRestant]), setPlan(PlanRestant).


move(Direction).
take(Direction).
drop(Direction).
attack(Direction).
none().

getJoueur([_,_,_,_,Joueurs|_], Joueur) :- p00_nom(Nom),  member_set([N,Nom,X,Y,Z], Joueurs), append([],[N,Nom,X,Y,Z], Joueur).

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


validateMove(State,Direction):- getJoueur(State,Joueur), position(State, Joueur, Direction, X,Y), clear(State,X,Y).
validateTake(State,Direction):- getJoueur(State,Joueur), position(State, Joueur, Direction, X,Y), block(State,X,Y).
validateDrop(State, Direction):- getJoueur(State,Joueur), position(State, Joueur, Direction, X,Y), hasBlock(Joueur), clear(State,X,Y).
validateAttack(State, Direction):-getJoueur(State,Joueur), position(State, Joueur, Direction, X,Y), playerOn(State, X,Y).

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

%position_valid(State, X, Y, Valid):-member_set

position(State,[_,_,X1,Y1,_], Direction, X,Y):- getPosition(Direction, X1,Y1, X,Y).

%clear(Direction) :-

%move(Direction)_:-  member_set()
%
getAvailableActions(State, Actions):- findall(Action, action(State, Action), Actions).



state([4,3,4,4,
[[2,'Lad',0,2,3],[3,'Zouf',1,3,2],[1,'Ares',3,0,0],
[4,'Buddy',2,2,0]],[[1,1,3],[2,0,1]]]).

state2([4,3,4,4,
[[2,'Lad',0,2,3],[3,'Zouf',1,0,0],[1,'Ares',3,0,0],
[4,'Buddy',2,2,0]],[[1,1,3],[3,3,2],[2,0,1]]]).


joueurs([[2,'Lad',0,2,0],[3,'Zouf',1,0,0],[1,'Ares',3,0,0],
[4,'Buddy',2,2,0]]).


%joueur(X) :- joueurs(X,_,__)
