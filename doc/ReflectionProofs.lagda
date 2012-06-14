\documentclass[a4paper]{article}

%include polycode.fmt
%include codecolour.fmt
%include agda.fmt

\usepackage{amsmath}

\newcommand{\ignore}[1]{}

\author{Paul van der Walt \and Wouter Swierstra}
\date{\today}
\title{Proof by reflection by reflection}

\begin{document}

\maketitle


\begin{abstract}
Hi, this is a test.
\end{abstract}


\section{Everything}

Proof by reflection is a technique bla.

\section{Proof by reflection}

The idea behind proof by reflection is that one needn't produce a large proof tree
for each proof instance one wants to have, but rather proves the soundness of
a decision function, in effect giving a ``proof recipe'' which can be instantiated
when necessary.




\ignore{
\begin{code}
module ReflectionProofs where

open import Relation.Binary.PropositionalEquality
open import Data.Bool
open import Data.Nat
\end{code}
}


\subsection{Simple example}

Take for example the property of evenness on natural numbers. One has two
rules (TODO insert rules), namely the rule that says that zero is even, and the
rule that says that if $n$ is even, then $n+2$ is also even.

When translated into an Agda data type, the property of evenness can be expressed
as follows.


\begin{code}
data Even      : ℕ → Set where
  isEvenZ      :                          Even 0
  isEvenSS     : {n : ℕ} → Even n     →   Even (2 + n)
\end{code}

If one has to use these rules to produce the proof tree each time a
proof of evenness is required for some $N$, this would be tedious.
One would need to unfold the number using |isEvenSS| half the size
of the number. For example, to prove that 6 is even, one would require
the following proof.

\begin{code}
isEven6 : Even 6
isEven6 = isEvenSS (isEvenSS (isEvenSS isEvenZ))
\end{code}

Obviously, this proof tree grows as the natural one would like to show evenness
for becomes larger.

A solution here is to use proof by reflection. The basic technique is as follows.
Define a decision function, called |even?| here, which produces some binary
value (in our case a |Bool|) depending on if the input is true or not.
This function is rather simple in our case.

\begin{code}
even? : ℕ → Bool
even? zero              = true
even? (suc zero)        = false
even? (suc (suc n))     = even? n
\end{code}

Now one can ask whether some value is even or not. Next we need to show that
our decision function actually tells the truth. We need to prove that
|even?| returns |true| iff a proof |Even n| can be produced. This is done in
the function |soundnessEven|. What is actually happening here is that we are
giving a recipe for proof trees such as the one we manually defined for |isEven6|.

\begin{code}
soundnessEven : {n : ℕ} → even? n ≡ true → Even n
soundnessEven {0}              refl        = isEvenZ
soundnessEven {1}              ()
soundnessEven {suc (suc n)}    s           = isEvenSS (soundnessEven s)
\end{code}

Now that this has been done, if we need a proof that some arbitrary $n$ is even,
we only need to instantiate |soundnessEven|. Note that the value of $n$ is a hidden
and automatically inferred argument to |soundnessEven|, and that we also pass
a proof that |even? n| returns |true| for that particular $n$. Since in a
dependently typed setting $\beta$-reduction (evaluation) happens in the type system, |refl| is a valid proof. 

\begin{code}
isEven28        : Even 28
isEven28        = soundnessEven refl

isEven8772      : Even 8772
isEven8772      = soundnessEven refl
\end{code}

Now we can easily get a proof that arbitrarily large numbers are even,
without having to explicitly write down a large proof tree. Note that
it's not possible to write something with type |Even 27|, or any other uneven
number, since the parameter |even? n ≡ true| cannot be instantiated, thus
|refl| won't be accepted where it is in the |Even 28| example. This will
produce a |true !≡ false| type error at compile-time.

\subsection{Abstract proof by reflection}

Talk about S and D and interpretation function \&c. here. 


\subsection{Boolean tautologies example}

Another example of an application of the proof by reflection technique is
boolean expressions which are a tautology. We will follow the same recipe
as for even naturals.

Take as an example the boolean formula in equation \ref{eqn:tauto-example}.

\begin{align}\label{eqn:tauto-example}
(p_1 \vee q_1) \wedge (p_2 \vee q_2) \Rightarrow (q_1 \vee p_1) \wedge (q_2 \vee p_2)
\end{align}

It is trivial to see that this is a tautology, but proving this fact using basic
equivalence rules for booleans would be rather tedious. It's even worse if we want
to check if the formula always holds by trying all possible variable assignments,
since this will give $2^n$ cases, where $n$ is the number of variables.

To try to automate this process, we'll follow a similar approach to the one given
above for proving evenness of arbitrary (even) naturals.

We start off by defining boolean expressions with $n$ free variables,
using de Bruijn indices.  There isn't anything surprising about this
definition; we use the type |Fin n| to ensure that variables
(represented by |Atomic|) are always in scope.

Our language supports boolean and, or, not, implication and arbitrary unknown
boolean formulae represented by the constructor |Atomic|. 

Now we can define our decision function, which decides if a given
boolean expression is a tautology. It does this by evaluating (interpreting)
the formula's AST. For example, |And| is converted to the boolean function |_∧_|,
and it's two arguments in turn are recursively interpreted.

Note that the interpretation function also requires an environment to be
provided, which gives maps the free variables to actual boolean values.



\begin{code}





\end{code}



\section{Conclusion}


Lorem ipsum dolor sit amet.



\end{document}