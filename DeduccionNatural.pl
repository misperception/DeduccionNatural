%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                          Copyright (C)2023 Joaquín Arias (URJC)
%  Name: DeduccionNatural.pl
%  Author: Joaquín Arias
%  Date: 24 October 2023
%  Purpose: Execute Natural Deduction Proofs
%  LICENSE: Apache License 2.0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% Operator precedence
:- op(200, fy, !).
:- op(400, xfy,[and, or]).
:- op(600, xfy,[-->, <->]).

% Auxiliary precedence for !
% Used to define the inference rules
:- op(400, xfy, !).

%% Bug found by students of the cybersecurity degree of the URJC in
%% the academic year 23/24. Solved in 24 October 2023 
bug :-
    main([s --> c],
        c,
        [ 
            'Premisa'(1),
            'Supuesto'(s),
            'E' --> (1,2),
            'I' --> (2,3),
            'I' or a(3,sa),
            'E' --> (5,2)
        ]).


%% Examples
ejemplo1 :-
    main([ s and p or q, p --> ! r, q --> ! r ],
         s and ! r,
         [ 'Premisa'(1),
           'E' and b(1),
           'Premisa'(2),
           'Premisa'(3),
           'E' or (2, 3, 4),
           'E' and a(1),
           'I' and (6, 5)
         ]).

ejemplo2 :-
    main([ !p --> q and !q ],
         p,
         [ 'Premisa'(1),
           'I' ! (1),
           'E' ! (2)
         ]).

ejemplo3 :-
    main([ p --> !r, !r-->q, p ],
         q,
         [ 'Premisa'(1),
           'Premisa'(3),
           'E' --> (1, 2),
           'Premisa'(2),
           'E' --> (4, 3)
         ]).

ejemplo4 :-
    main([ p --> q, q-->r],
         p --> r,
         [ 'Premisa'(1),
           'Premisa'(2),
           'Supuesto'(p),
           'E' --> (1, 3),
           'E' --> (2, 4),
           'I' --> (3, 5)
         ]).

ejemploMT :-
    main([ r --> (q and s), !(q and s) ],
         !r,
         [ 'Premisa'(1),
           'Premisa'(2),
           'MT'(1, 2)
         ]).

%% This example fails becuase the assumption is not closed
ejemploSupuesto :- 
    main( [ s and p or q, p --> ! r, q --> ! r ],
          s and ! r,
          [ 'Premisa'(1),
            'E' and b(1),
            'Premisa'(2),
            'Premisa'(3),
            'Supuesto'(p1),
            'Supuesto'(p2),
            'Supuesto'(p3),
%            'I' --> (6,5),
            'I' --> (7,5),
            'Supuesto'(p4),
            'Supuesto'(s and !r)
          ]).
ejemploMorganAnd :-
    main( [ !(s and q)],
          !s or !q,
          [ 'Premisa'(1),
            'Morgan And a'(1)
          ]).
ejemploMorganAndB :-
    main( [ !s and !q],
          !(s or q),
          [ 'Premisa'(1),
            'Morgan And b'(1)
          ]).

ejemploMorganOr :-
    main( [ !(s or q)],
          !s and !q,
          [ 'Premisa'(1),
            'Morgan Or a'(1)
          ]).

ejemploMorganOrB :-
    main( [ !s or !q],
          !(s and q),
          [ 'Premisa'(1),
            'Morgan Or b'(1)
          ]).
ejemploCorteA :-
    main([p or q, !p],
          q,
          [ 'Premisa'(1),
            'Premisa'(2),
            'Corte a'(1, 2)
          ]).
ejemploCorteB :-
    main([p or q, !q],
          p,
          [ 'Premisa'(1),
            'Premisa'(2),
            'Corte b'(1, 2)
          ]).
ejemploTransitividad :-
    main([p --> q, q --> r],
          p --> r,
          [ 'Premisa'(1),
            'Premisa'(2),
            'Transitividad'(1, 2)
          ]).

:- data counter/1, formula/2, tabular/1, closed/1, opened/1, check/1.
main(Hypotheses, Deduction, Proof) :-
    retractall(counter(_)), retractall(formula(_,_)), retractall(tabular(_)),retractall(closed(_)),retractall(opened(_)),retractall(check(_)),
    assert(counter(0)), assert(tabular(0)),
    format(" T~p  |-  ~p\n\n",[Hypotheses, Deduction]),
    eval(Hypotheses, Deduction, Proof),
    check_pending.

check_pending :-
    setof(Name, check(Name), Pending), !,
    check_pending_(Pending).
check_pending.

check_pending_([]).
check_pending_([Name|Ns]) :-
    retractall(counter(_)),retractall(formula(_,_)), retractall(tabular(_)),retractall(closed(_)),retractall(opened(_)),
    assert(counter(0)), assert(tabular(0)),
    rule(Name, Hypotheses, Deduction, Proof), !,
    numbervars([Hypotheses, Deduction, Proof], 0, _),
    format("\n\n Demostración de la regla auxiliar ~p:  T~p  |-  ~p\n\n",[Name,Hypotheses,Deduction]),
    eval(Hypotheses, Deduction, Proof), !,
    check_pending_(Ns).

eval(Hypotheses, Deduction, [ Rule | Proof ]) :-
    eval_rule(Rule, Hypotheses),
    eval(Hypotheses, Deduction, Proof).
eval(_, Deduction, []) :-
    check_deduccion(Deduction).

eval_rule(R, P):-
    (   exec(R, P) ->
        output(R)
    ;
        format("\nFALLO: No se puede aplicar la regla \t\t~p\n\n", [R]), !, fail
    ).

exec('Premisa'(C), Hypotheses) :- !,
    'Premisa'(C, Hypotheses).
exec(Rule,_) :-
    Rule =.. [Name|Args],
    rule(Name,Hypotheses, Deduction, _Proof), !,
    assert(check(Name)),
    exec_rule(Args, Hypotheses, Deduction).
exec(Rule,_) :-
    catch(call(Rule),_,fail).

'Premisa'(1,[P | _Hypotheses]) :- !,
    add_formula(P).
'Premisa'(A,[_ | Hypotheses]) :-
    A1 is A - 1,
    'Premisa'(A1, Hypotheses).

exec_rule(Args, Hypotheses, Deduction) :-
    see_formulas(Args, Formulas),
    Hypotheses = Formulas,
    add_formula(Deduction).
see_formulas([],[]).
see_formulas([A|As], [FA|FAs]) :-
    formula(A, FA),
    see_formulas(As, FAs).

check_deduccion(Deduction) :-
    retract(counter(C)),
    formula(C, Formula),
    (   opened(_) ->
        findall(A, opened(A), LA),
        format("\nFALLO: Supuesto(s) '~w' no está(n) cerrado(s)\n\n",[LA]),!,fail
    ;
        (   Formula = Deduction ->
            format("~50|ok",[])
        ;
            format("\nFALLO: Se demuestra '~w' en lugar de '~w'\n\n",[Formula,Deduction]),!,fail
        )
    ).

add_formula(Formula) :-
    next_couonter(C),
    asserta(formula(C, Formula)).

next_couonter(C1) :-
    retract(counter(C)),
    C1 is C + 1,
    asserta(counter(C1)).
    

output(Rule) :-
    tabular(T),
    counter(C),
    formula(C, Formula),
    format("  ~p~5|",[C]),
    format_tabular(T),
    format("~p",[Formula]),
    format("~50|~p\n",[Rule]).    

increase_tab :-
    retract(tabular(Tab)),
    Tab1 is Tab + 1,
    assert(tabular(Tab1)).
decrease_tab :-
    retract(tabular(Tab)),
    Tab1 is Tab - 1,
    assert(tabular(Tab1)).

format_tabular(0) :- !.
format_tabular(T) :-
    T1 is T - 1,
    format("     ",[]),
    format_tabular(T1).


%% Inference Rules
% Conjunction
'I' and (A, B) :-
    formula(A, FA), is_valid(A),
    formula(B, FB), is_valid(B),
    add_formula(FA and FB).

'E' and a(A) :-
    formula(A, FA and _FB), is_valid(A),
    add_formula(FA).
'E' and b(A) :-
    formula(A, _FA and FB), is_valid(A),
    add_formula(FB).
% Disjuncion
'E' or (A, B, C) :-
    formula(A, FB or FC), is_valid(A),
    formula(B, FB --> F), is_valid(B),
    formula(C, FC --> F), is_valid(C),
    add_formula(F).

'I' or a(A, Formula) :-
    formula(A, FA), is_valid(A),
    add_formula(FA or Formula).
'I' or b(Formula, B) :-
    formula(B, FB), is_valid(B),
    add_formula(Formula or FB).
% Negation
'I' ! (A) :-
    formula(A, FA --> B and ! B), is_valid(A),
    add_formula(! FA).

'E' ! (A) :-
    formula(A, ! ! FA), is_valid(A),
    add_formula(FA).
% Implication
'E' --> (A, B) :-
    formula(A, FB --> FC), is_valid(A),
    formula(B, FB), is_valid(B),
    add_formula(FC).
'I' --> (A, B) :-
    formula(A, FA), is_valid(A),
    last_opened(A),
    formula(B, FB), is_valid(B),
    close_assumption(A),
    add_formula(FA --> FB).
'Supuesto'(FA) :-
    increase_tab,
    add_formula(FA),
    counter(C),
    asserta(opened(C)).
% Bi-Implication
'I' <-> (A, B) :-
    formula(A, FA --> FB), is_valid(A),
    formula(B, FB --> FA), is_valid(B),
    add_formula(FA <-> FB).
'E' <-> a(A) :-
        formula(A, FA <-> FB), is_valid(A),
        add_formula(FA --> FB).
'E' <-> b(A) :-
        formula(A, FA <-> FB), is_valid(A),
        add_formula(FB --> FA).


%% Derived Rules
rule( 'MT',
      [ FA --> FB, !FB ],
      !FA,
      [ 'Premisa'(1),
        'Premisa'(2),
        'Supuesto'(FA),
        'E' --> (1, 3),
        'I' and (4, 2),
        'I' --> (3, 5),    
        'I' ! (6)
      ]).

rule( 'Morgan And a',
      [ !(FA and FB) ],
      !FA or !FB,
      [ 'Premisa'(1),
        'Supuesto'(!(!FA or !FB)),
        'Supuesto'(!FA),
        'I' or a(3, !FB),
        'I' --> (3, 4),
        'MT'(5, 2),
        'E' ! (6),
        'Supuesto'(!FB),
        'I' or b(!FA, 8),
        'I' --> (8, 9),
        'MT'(10, 2),
        'E' ! (11),
        'I' and (7, 12),
        'I' --> (2, 13),
        'MT'(14, 1),
        'E' ! (15)
      ]).

rule( 'Morgan And b',
        [!FA and !FB],
        !(FA or FB),
        [ 'Premisa'(1),
          'E' and a(1),
          'E' and b(1),
          'Supuesto'(FA or FB),
          'Supuesto'(FA),
          'I' and (5, 2),
          'Supuesto'(!(c and !c)),
          'I' --> (7, 6),
          'I' ! (8),
          'E' ! (9),
          'I' --> (5, 10),
          'Supuesto'(FB),
          'I' and (12, 3),
          'Supuesto'(!(c and !c)),
          'I' --> (14, 13),
          'I' ! (15),
          'E' ! (16),
          'I' --> (12, 17),
          'E' or (4, 11, 18),
          'I' --> (4, 19),
          'I' ! (20)
        ]).

rule( 'Morgan Or a',
      [ !(FA or FB) ],
      !FA and !FB,
      [ 'Premisa'(1),
        'Supuesto'(FA),
        'I' or a(2, FB),
        'I' --> (2, 3),
        'Supuesto'(FA),
        'I' or a(5, FB),
        'I' and (6, 1),
        'I' --> (5,7),
        'I' ! (8),
        'Supuesto'(FB),
        'I' or b(FA, 10),
        'I' --> (10, 11),
        'Supuesto'(FB),
        'I' or b(FA, 13),
        'I' and (14, 1),
        'I' --> (13,15),
        'I' ! (16),
        'I' and (9,17)
      ]).

rule( 'Morgan Or b',
      [ !FA or !FB ],
      !(FA and FB),
      [ 'Premisa'(1),
        'Supuesto'(FA and FB),
        'E' and a(2),
        'E' and b(2),
        'Supuesto'(!FA),
        'I' and (3, 5),
        'Supuesto'(!(c and !c)),
        'I' --> (7, 6),
        'I' ! (8),
        'E' ! (9),
        'I' --> (5, 10),
        'Supuesto'(!FB),
        'I' and (4, 12),
        'Supuesto'(!(c and !c)),
        'I' --> (14, 13),
        'I' ! (15),
        'E' ! (16),
        'I' --> (12, 17),
        'E' or (1, 11, 18),
        'I' --> (2, 19),
        'I' ! (20)
      ]).

rule( 'Corte a',
      [ FA or FB, !FA],
      FB,
      [ 'Premisa'(1),
        'Premisa'(2),
        'Supuesto'(FA),
        'I' and (3, 2),
        'Supuesto'(!FB),
        'I' --> (5, 4),
        'I' ! (6),
        'E' ! (7),
        'I' --> (3, 8),
        'Supuesto'(FB),
        'I' --> (10, 10),
        'E' or (1, 9, 11)
      ]).
rule( 'Corte b',
      [FA or FB, !FB],
      FA,
      [ 'Premisa'(1),
        'Premisa'(2),
        'Supuesto'(FA),
        'I' --> (3, 3),
        'Supuesto'(FB),
        'I' and (5, 2),
        'Supuesto'(!FA),
        'I' --> (7, 6),
        'I' ! (8),
        'E' ! (9),
        'I' --> (5, 10),
        'E' or (1, 4, 11)
      ]).
rule( 'Transitividad',
      [A --> B, B --> C],
      A --> C,
      [ 'Premisa'(1),
        'Premisa'(2),
        'Supuesto'(A),
        'E' --> (1, 3),
        'E' --> (2, 4),
        'I' --> (3, 5)
      ]).
% Auxiliary predicates
last_opened(A) :-
    retract(opened(L)),
    (   L = A ->
        true
    ;
        format("\nFALLO: Cerrar antes el supuesto '~w'", [L]), !, fail
    ).
is_valid(A) :-
    (   valid(A) ->
        true
    ;
        format("\nFALLO: La fórmula '~p' está en un supuesto cerrado", [A]), !, fail
    ).
valid(B) :-
    \+ closed(B).
close_assumption(A) :-
    counter(C),
    between(A, C, C1),
    assert(closed(C1)),
    fail.
close_assumption(_A) :-
    decrease_tab.


