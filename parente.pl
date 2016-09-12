pere(georges, louis).
pere(georges, isabelle).
pere(georges,charles).
pere(luc, catherine).
pere(luc, louise).
pere(lucien, georges).
pere(lucien, luc).
pere(bob, luc).


mere(claire, isabelle).
mere(claire, louis).
mere(claire, charles).

homme(louis). homme(charles).
homme(georges). homme(luc).
homme(lucien).

femme(claire). femme(louise).
femme(isabelle).

enfant(E,P):- (pere(P,E);mere(P,E)).

parent(P,E):- (pere(P,E); mere(P,E)).

grandparent(X,Z) :- parent(X, Y), parent(Y,Z).

fils(E,P):- homme(E), parent(P,E).
fille(E,P):- femme(E), parent(P,E).

longueur([],0).
longueur([_|Xs], N):- longueur(Xs,N1), N is N1+1.

ajoute([], Ys,Ys).
ajoute([X|Xs], Ys, [X|Zs]) :- ajoute(Xs,Ys,Zs).


:- dynamic([a/2,a/3]).
a(1,2).
a(2,3).

a(1,2,3).

add:- assert(a(3,4)).
remove:- retract(a(3,4)).


etat([1,2,3,4]).

etat([1,2,3,5]).
etat([1,2,3,6]).
etat([1,2,3,7]).

