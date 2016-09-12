%------------------------------------------------------------------------------
% Structure de donn�es de set (collection),
%   Le set est sans dupliqu�s et les valeurs ne sont pas ordonn�es
%
% Auteur: Charles-Antoine Brunet
%------------------------------------------------------------------------------
% Version 1.0: Version initiale
% Date: 2005/04/11
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% +: param�tre en entr�e
% -: param�tre en sortie
% ?: param�tre en entr�e ou sortie
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% Tester si un set est vide ou cr�er un set
% empty_set(?Set)
%------------------------------------------------------------------------------
empty_set([]).

%------------------------------------------------------------------------------
% V�rifier si un �l�ment est membre d'un set
% Utilise la fonction member de la librairie standard de liste
% member_set(+Item, +Set)
%------------------------------------------------------------------------------
member_set(E, S) :- member(E, S).

%------------------------------------------------------------------------------
% Enlever un �l�ment du set, s'il est pr�sent
% delete_in_set(+Item, +Set, -NewSet)
% Item=item � enlever, Set = ancien set, NewSet = nouveau set
%------------------------------------------------------------------------------
delete_in_set(_, [], []) :- !.
delete_in_set(E, [E|T], T) :- !.
delete_in_set(E, [H|T], [H|Tnew]) :- delete_in_set(E,T,Tnew).

%------------------------------------------------------------------------------
% Ajouter un �l�ment au set, s'il n'est pas pr�sent
% add_in_set(+Item, +Set, -NewSet)
% Item=item � ajouter, Set = ancien set, NewSet = nouveau set
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
% V�rifier si un set est un sous-ensemble d'un autre
% sub_set(+Set1, +Set2) est vrai si Set1 est un sous-ensemble de Set2.
%------------------------------------------------------------------------------
sub_set([],_).
sub_set([H|T], S) :- member_set(H,S), sub_set(T,S).

%------------------------------------------------------------------------------
% Trouver les �l�ments communs � 2 sets
% set_intersection(+Set1, +Set2, -Intersection)
% Intersection contient les items communs � Set1 et Set2.
%------------------------------------------------------------------------------
set_intersection([], _, []).
set_intersection([H|T],S,[H|Snew]) :-
    member_set(H,S), set_intersection(T,S,Snew), !.
set_intersection([_|T],S,Snew) :- set_intersection(T, S, Snew).

%------------------------------------------------------------------------------
% Calculer la diff�rence entre 2 sets.
% set_difference(+Set1,+Set2,-Difference)
% Diff�rence contient les �l�ments qui sont dans Set1 mais pas dans Set2
%------------------------------------------------------------------------------
set_difference([], _, []).
set_difference([H|T], S, Tnew) :-
    member_set(H,S), set_difference(T, S, Tnew), !.
set_difference([H|T], S, [H|Tnew]) :- set_difference(T,S,Tnew).

%------------------------------------------------------------------------------
% V�rifier si 2 sets sont �quivalents
% equal_set(+S1, +S2)
% Vrai si tous membres de Set1 sont dans Set2 et ceux de Set2 dans Set1
%------------------------------------------------------------------------------
equal_set(S1, S2) :- sub_set(S1, S2), sub_set(S2, S1).

%------------------------------------------------------------------------------
% Imprimer un set
%------------------------------------------------------------------------------
print_set([]).
print_set([H|Q]) :- write(H), nl, print_set(Q).

