/*
    our data
*/
processes([p1,p2,p3,p4]).

available_resources([[r1, 0], [r2, 0]]).

allocated(p1, [r2]):-!.
allocated(p2, [r1]):-!.
allocated(p3, [r1]):-!.
allocated(p4, [r2]):-!.
/*
 this predicate is here so that every process would have a list of resources even if doesn't
 allocate any , its list should be empty
*/

requested(p1, [r1]):-!.
requested(p3, [r2]):-!.

/*
    our rules
*/

allocated(X,[]):-!.
requested(X,[]):-!.

x(Res)
:-
    processes(Processes),
    available_resources(Avail),
    s(Processes,Avail,Res)
.

s([],_,[]):-!.
s(Processes,Avail,Res)
:-
    reallocateResourcesFromNonWaitingProcesses(Processes,Avail,NP,NR,EP),

    % check that the Executed processes isn't empty
    not(reallocateResourcesFromNonWaitingProcesses(Processes,Avail,NP2,NR2,[])),
    s(NP,NR,EP2),
    append(EP,EP2,Res)
.


/*
    this predicate takes a list of processes and a list of resources and executes the non-waiting
     processes and returns them in the ExecutedProcesses
*/
reallocateResourcesFromNonWaitingProcesses(Processes,Resources,NewProcesses,NewResources,ExecutedProcesses)
:-
    getNonWaitingProc(Processes,ExecutedProcesses,NewProcesses,Resources),
    executeNonWaitingProcesses(ExecutedProcesses,Resources,NewResources)
.

/*
a predicate to get the non-waiting and waiting processes
*/
getNonWaitingProc([],_,_,_):- !.

getNonWaitingProc([H|T],NonWaitingProc,WaitingProc,Resources)
:-
getNonWaitingProc(T,NonWaitingProc2,WaitingProc2,Resources),
((procCanExecute(H,Resources),append(NonWaitingProc2,[H],NonWaitingProc),append(WaitingProc2,[],WaitingProc));
(not(procCanExecute(H,Resources)),append(NonWaitingProc2,[],NonWaitingProc),append(WaitingProc2,[H],WaitingProc))),!
.

% a wrapper function for the procCanExecute
procCanExecute(Process,Resources)
:-
requested(Process,ItsRes),
procCanExecute(Resources,ItsRes,Resources)
.
procCanExecute(_,[],_):-!.
procCanExecute([H|OtherRes],[H2|ProcessRes],Resources)
:-
% if the two the current resource in the whole resources equals the current resources
% then reassign the whole resources to the initial resources
(checkIfEqual(H2,H),checkAvailable(H),procCanExecute(Resources,ProcessRes,Resources));
(not(checkIfEqual(H2,H)),procCanExecute(OtherRes,[H2|ProcessRes],Resources))
.

checkAvailable([_|Cnt]):- Cnt >= 1.
/*
this predicate iterates over all non-waiting processes to reallocate their resources
*/
executeNonWaitingProcesses([],R,R):-!.

executeNonWaitingProcesses([H|T],Res,Newresources)
:-
executeNonWaitingProcesses(T,Res,Newresources2),
allocated(H,ItsResources),
reallocateList(ItsResources,Newresources2,Newresources)
.

/*
this predicate will reallocate resources taken by some processes
*/
reallocateList([],Current,Current):-!.
reallocateList([H|T],CurrentResources,FinalResources)
:-
reallocateList(T,CurrentResources,FinalResources2),
reallocateResource(H,FinalResources2,FinalResources)
.

/*
this predicate will reallocate some resource from one list and puts the total resources in another
list
*/
reallocateResource(R,[],[]):-!.

reallocateResource(Resource,[H|TailOfCurrentRes],Res)
:-
reallocateResource(Resource,TailOfCurrentRes,Res2),
((checkIfEqual(Resource,H),addResource(H,NewRes),append([NewRes],Res2,Res));
(not(checkIfEqual(Resource,H)),append([H],Res2,Res)))
.

checkIfEqual(Resource,[Resource|_]).

addResource([Name,Cnt],[Name,Cnt2])
:-
Cnt2 is (Cnt+1)
.