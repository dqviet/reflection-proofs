%\documentclass[a4paper]{report}
\documentclass[a4paper]{llncs}

\usepackage{color}
\usepackage[usenames,dvipsnames,svgnames,table]{xcolor}

%include polycode.fmt
%if style == newcode
%else
%include agda.fmt
%include generated-colour.fmt
%include codecolour.fmt
%endif


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TODO: stuff only for DRAFT versions {{
%%%%% microtype with settings.
\usepackage[activate={true,nocompatibility},final,tracking=true,kerning=true,spacing=true,factor=1100,stretch=10,shrink=10]{microtype}
\microtypecontext{spacing=nonfrench}
%\newcommand{\microtypesetup}[1]{\fbox{NO MICROTYPE!\phantom{\rule{0.1\textwidth}{0.1\textwidth}}}}
%\usepackage{todonotes}

\usepackage{draftwatermark}
\SetWatermarkLightness{0.95}
%% end DRAFT-version stuff. }}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{subfigure}
\usepackage{xspace}
\usepackage{textcomp} % text-mode <> characters


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Font definitions.
\usepackage{tgpagella}                  %% looks a little like palatino -- thanks Zapf!
\usepackage[T1]{fontenc}
\renewcommand{\ttdefault}{lmtt}         %% Latin Modern for teletype
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\ignore}[1]{}

\newcommand{\ghloc}{https://github.com/toothbrush/reflection-proofs}
\newcommand{\ghurl}{\url{\ghloc}}
\def\CC{{C\nolinebreak[4]\hspace{ -.05em}\raisebox{.2ex}{\small\bf ++}}}
\colorlet{hlite}{CornflowerBlue!15!white}

\newcommand{\hlitem}[1]{\item[\colorbox{hlite}{#1}]~\\}
\newcommand{\ch}{Curry--Howard isomorphism\xspace}
% This defines figures with backgrounds -- useful for code
\usepackage{adjustbox}
% \usepackage{float} % enable H position specifier
% \newenvironment{shadedfigure}{\begin{figure}}{\end{figure}}
% \newenvironment{shade}{}{}
\newenvironment{shadedfigure}[1][tbhp]{%
 % \vskip -5mm
    \begin{figure}[#1]
    \begin{adjustbox}{minipage=\linewidth-10pt,margin=5pt,bgcolor=hlite}
}{%
    \end{adjustbox}
    \end{figure}
 % \vskip -5mm
}
\newenvironment{shade}{

\vskip 0.2\baselineskip
\begin{adjustbox}{%
minipage=\linewidth,margin=0pt,padding=0pt,bgcolor=hlite%
}}{%
\end{adjustbox}
\vskip 0.2\baselineskip

}

\newcommand{\lagda}{\texttt{\--\--{}lagda}\xspace}
\ignore{
  
\begin{code}
module doc.ReflectionProofs where

open import Proofs.TautologyProver hiding (concrete2abstract;  soundness ;
        boolTable;  proofGoal ; ⟦_⊢_⟧ ; forallsAcc )
open import Data.Bool renaming (not to ¬_)
open import Relation.Binary.PropositionalEquality
open import Reflection
open import Data.List
open import Data.Nat
open import Data.Unit using (⊤ ; tt)
open import Data.Empty
open import Data.Product
open import Data.Maybe
open import Data.Vec
open import Relation.Nullary using (yes; no)
open import Data.String
open import Data.Fin hiding (_+_)
open import Proofs.Util.Types


\end{code}
}
\ignore{
\begin{code}
open import Proofs.Util.Lemmas renaming (zero-least to zeroleast)
open import Proofs.Util.Types using (Diff; Base; Step)
\end{code}
}

\usepackage{amsmath}

\usepackage{hyperref}
\usepackage{url}

%% Give citations etc a nicer look
\hypersetup{
  colorlinks,
  citecolor=DarkBlue,
  linkcolor=black,
  urlcolor=DarkBlue}
  
\date{\today}
\newcommand{\HRule}{\noindent\rule{\linewidth}{1.5pt}}
\title{Engineering Proof by Reflection in Agda}
\author{Paul van der Walt \and Wouter Swierstra}
\institute{
\href{mailto:paul@@denknerd.org}{\nolinkurl{paul@@denknerd.org}}, \href{mailto:W.S.Swierstra@@uu.nl}{\nolinkurl{W.S.Swierstra@@uu.nl}}\\
Department of Computer Science, Utrecht University
}



\begin{document}

\maketitle

\begin{abstract}
  This paper explores the recent addition to Agda enabling
\emph{reflection}, in the style of Lisp~\cite{Smith:1984:RSL:800017.800513}, MetaML~\cite{metaml}, and Template Haskell~\cite{template-haskell}.
It gives a brief introduction to using reflection, and details the intricacies
of using reflection to automate certain proofs using \emph{proof by
  reflection}. 
It presents a library that
can be used for automatically quoting a class of concrete Agda terms
to a simple, user-defined
inductive data type, alleviating the burden a programmer usually faces
when using reflection in a practical setting. 
\end{abstract}



\newcommand{\researchquestion}{%
\begin{quote}
  ``What practical issues do we run into when trying to engineer
  automatic proofs in a dependently typed language with reflection?
  Are Agda's reflective capabilities sufficient and practically
  usable, and if not, which improvements might make life easier?''
\end{quote}
}

\section{Introduction}\label{chap:introduction}

The dependently typed programming language
Agda~\cite{norell:thesis,Norell:2009:DTP:1481861.1481862} has recently been
extended with a \emph{reflection mechanism} for compile time metaprogramming in the style of Lisp~\cite{lisp-macros},
MetaML~\cite{metaml}, Template Haskell~\cite{template-haskell}, and
\CC\ templates~\cite{cplusplus}. Agda's reflection mechanisms make it
possible to convert a program fragment into its corresponding abstract
syntax tree (AST) and vice versa. In tandem with Agda's dependent types,
this has promising new programming potential.


This paper addresses the following central questions:

\researchquestion

\paragraph{Contributions} 
This paper reports on the experience of using Agda's reflection mechanism to automate certain 
categories of proofs.
This is a case study,
exemplative of the kind of problems that can be solved using
reflection. More specifically this work makes the following contributions:

\begin{itemize}
  \item We give a brief overview of Agda's reflection mechanism (Sec.~\ref{sec:crash}). Previously, these features were only documented in release notes and comments in Agda's source files.
\item We present |Autoquote|, an Agda library that 
alleviates much
  of a programmer's burden when quoting a given abstract syntax tree 
(Sec.~\ref{sec:autoquote}).
\item We show how to use Agda's reflection mechanism to
  automate certain categories of proofs (Sec.~\ref{sec:proof-by-reflection}).
 The idea of \emph{proof by
    reflection} is certainly not new, but still worth examining in the
  context of this new technology.
\end{itemize}

The code presented in this paper compiles using the
latest version of Agda (currently 2.3.2). Supporting code, including this
paper, is available on
GitHub\footnote{\ghurl}.
This paper is also a Literate Agda file, which means the code snippets can be extracted, compiled, and adapted.



\subsection{Introducing Agda}\label{sec:reflection}

Agda is an implementation
of Martin-L\"of's type theory~\cite{Martin-Lof:1985:CMC:3721.3731},
extended with records and modules. It is developed at the Chalmers
University of Technology~\cite{norell:thesis}; in accordance with \ch,
it can be viewed as
both a 
functional programming language
and a proof assistant for intuitionistic logic. It is comparable to
Coq, which is based on
Coquand's calculus of constructions~\cite{DBLP:journals/iandc/CoquandH88}. 
For an excellent tutorial on dependently typed programming using Agda,
the reader is referred to Norell's work~\cite{Norell:2009:DTP:1481861.1481862}.

Since version 2.2.8, Agda includes a reflection API~\cite{agda-relnotes-228}, which allows the conversion of
parts of a program's code into an abstract syntax tree, a data structure
in Agda itself, that can be inspected or modified like any other data structure.
The idea of reflection is old: in the 1980s % no apostrophe!
 Lisp included a similar
feature, then already called \emph{quoting} and \emph{unquoting},
which allowed run time modification of a program's code, for example by
the program itself. This has given rise to powerful techniques for code reuse and
abstraction.

This paper explores how such a reflection mechanism can be used in a
\emph{dependently typed} language such as Agda.

\section{Using Reflection}\label{sec:crash}

Before going into too much detail about how reflection can make our
life easier and what new programming techniques are possible, we look 
at Agda's reflection API in some detail. It should be a good
starting point for someone familiar with Agda, or at the very least
dependently typed programming in general. 



\paragraph{The Keywords} There are several new keywords that can be used to quote and unquote
|Term| values: |quote|, |quoteTerm|, |quoteGoal|, and |unquote|. The
|quote| keyword allows the user to access the internal representation of
any identifier. This internal representation can be used to query the
type or definition of the identifier. We refer to the release
% Kurt Vonnegut zegt over de semi-colon: Here is a lesson in creative
% writing. First rule: Do not use semicolons. They are transvestite
% hermaphrodites representing absolutely nothing. All they do is show
% you've been to college. -- gebruik ze niet te vaak :)
notes~\cite{agda-relnotes-228} for a listing of the data structures
involved; the most important one is the type |Term : Set| which
represents concrete Agda terms.

The easiest example of quotation uses the |quoteTerm| keyword to turn
a fragment of concrete syntax into a |Term| value. Note that the
|quoteTerm| keyword reduces like any other function in Agda. As an
example, the following unit test type checks:

\begin{shade}
\begin{code}
example₀   : quoteTerm (\ (x : Bool) -> x)       ≡ lam visible (var 0 [])
example₀   = refl
\end{code}
\end{shade}

Dissecting
this, we introduced a lambda abstraction, so we expect the |lam|
constructor. Its one argument is visible (as opposed to hidden), and
the body of the lambda abstraction is just a reference to the
nearest-bound variable, thus |var 0|, applied to an empty list of
arguments. Variables are referred to by their De Bruijn indices.

Furthermore, |quoteTerm| type checks and normalises its term before
returning the |Term|, as the following example demonstrates:
\begin{shade}
\begin{code}
example₁   : quoteTerm ((\ x → x) 0) ≡ con (quote ℕ.zero) []
example₁   = refl
\end{code}
\end{shade}

See how the identity function is applied to zero, resulting in only the value zero.
The quoted representation of a natural zero is |con (quote zero) []|, where |con| means that we
are introducing a constructor. The constructor |zero| takes no arguments, hence the empty list.

The |quoteGoal| keyword is slightly different. It is best explained using an
example:

\begin{shade}
\begin{spec}
example₂ : ℕ
example₂ = quoteGoal e in (HOLE 0)
\end{spec}
\end{shade}

The |quoteGoal| keyword binds the variable |e| to the |Term|
representing the type of the current goal. In this example, the value
of |e| in the hole will be |def ℕ []|, i.e., the |Term| representing
the type |ℕ|.


The |unquote| keyword converts a |Term| data type back to concrete
syntax. Just as |quoteTerm| and |quoteGoal|, it type checks and
normalises the |Term| before it is spliced into the program text.


Unfortunately, we cannot pattern match on constructor names without
further ado.
This is why we have decidable equality on the following types: |Visibility|, |Relevance|, |List Arg|s, |Arg Type|s, |Arg Term|s,  |Name|s,  |Term|s, |Sort|s  and |Type|s. 
Typically, this is useful for deciding which constructor is present in
some expression, by comparing to known |Name|s (obtained using |quote|). Such a comparison is
illustrated in the function |convert|, below. 

\begin{shade}
\begin{spec}
convert : Term → Something
convert (con c args) with c ≟-Name quote foo
...                   | yes p     = (HOLE 0) -- |foo| applied to arguments
...                   | no ¬p     = (HOLE 1) -- a function other than |foo|
\end{spec}
\end{shade}

This short introduction should already be enough to start developing
simple programs using reflection.  For a more detailed description of the
reflection API in Agda, including many examples, the inquisitive
reader is referred to the chapter in van der Walt's thesis covering this topic~\cite{vdWalt:Thesis:2012}.
This thesis goes into more detail 
regarding the data structures involved in Agda's reflection API, and later, 
gives a detailed account of some real-world applications.



\section{Automatic Quoting}\label{sec:autoquote}
\ignore{
\begin{shade}
\begin{code}
open import Metaprogramming.Autoquote renaming (_#_↦_ to _\#_↦_)
\end{code}
\end{shade}
}

In the previous section, we saw how we can get hold of values of type
|Term|, representing concrete Agda terms. This is a great start, but
we rarely want to directly manipulate |Term|s: often it
is much more useful to use our own AST for computations. It sounds
like a minor task to write a quick function to convert a |Term|
into something more useful. However, it turns out this often becomes a mess.

In a language like Haskell, which has pattern matching, converting
elements of one AST to another is usually a simple, if boring,
task. Unfortunately for us, though, Agda functions are required to be
total, which means they must have a case branch for each possible pattern. Since  |Term|
 covers all quotable terms, it has many alternatives.  Furthermore, we cannot pattern match on the
names of the constructors, so we must resort to using decidable
equality. This is why
 such a
 conversion function  is often
verbose, as can be seen in the code snippet of
Fig.~\ref{fig:concrete2abstract}, an excerpt of an actual 
conversion function, used before a better solution was developed.

\begin{shadedfigure}
\begin{spec}
term2boolexpr n (con tf []) pf with tf ≟-Name quote true
term2boolexpr n (con tf []) pf | yes p = Truth
...
term2boolexpr n (def f []) ()
term2boolexpr n (def f (arg v r x ∷ [])) pf with f ≟-Name quote ¬_
... | yes p = Not (term2boolexpr n x pf)
... | no ¬p with f ≟-Name quote _∧_
...
\end{spec}
\caption{The gist of  the conversion of a |Term| into some more specific data
  type.}\label{fig:concrete2abstract}
\end{shadedfigure}

The (partial) solution to this problem~-- something which at least mitigates 
the agony~-- is presented in this section, in the form of the
|Autoquote| library.

\paragraph{The |Autoquote| library}
We will examine a toy AST, called |Expr|, shown in Fig.~\ref{fig:exprdata}.
It is a rather simple inductive data structure representing terms which can contain Peano-style natural
numbers, variables (represented by an Agda natural) and additions.


\begin{shadedfigure}
\begin{code}
data Expr : Set where
  Var           : ℕ               →     Expr
  Plus          : Expr → Expr     →     Expr
  S             : Expr            →     Expr
  Z             :                       Expr
\end{code}
\caption{The toy expression language |Expr|. We would like support for automatically quoting such terms.}\label{fig:exprdata}
\end{shadedfigure}

We might want to convert an expression, such as $5 + x$, to this
AST using reflection. In an ideal world, we would  just
 provide a mapping from concrete constructs such as the |_+_| function
 to elements like |Plus| of our
AST, and get a conversion function for free.
The |Autoquote| library does just this, exposing
an interface which, when provided with such a mapping, automatically quotes expressions
that fit. Here, \emph{fitting} is defined as only having names that are listed
in the mapping, or variables. Other terms are rejected.
The user provides an elegant mapping, such as in
Fig.~\ref{fig:exprTable}, and |Autoquote| automatically converts
Agda terms to elements of the AST.

\begin{shadedfigure}
\begin{code}
exprTable : Table Expr
exprTable = (Var ,
             2   \# (quote _+_)      ↦ Plus   ∷
             0   \# (quote ℕ.zero)   ↦ Z      ∷ 
             1   \# (quote ℕ.suc)    ↦ S      ∷ [])
\end{code}
\caption{The mapping table for converting to the imaginary |Expr| AST. }\label{fig:exprTable}
\end{shadedfigure}

This should be interpreted as follows: any variables encountered should be stored as |Var|s, and
the |_+_| operator should be mapped to a |Plus| constructor. In each case we are required to manually specify the
arity of the constructor, or    how many arguments it expects.
A |zero|, from the |Data.Nat| standard library, should be treated as our |Z| constructor, and
a |suc| translates to |S|. These constructors expect 0 and 1 argument, respectively.

We will not say much about the implementation of this library, since
it is not groundbreaking.
For more details, we again refer to van der Walt's thesis~\cite{vdWalt:Thesis:2012}. 
Using the library is simple; it exposes a function called
|doConvert| which takes the conversion table, a (hidden)  proof that
the conversion is possible, and a |Term| to convert,
and produces an inhabitant of the desired data type.

The use of |doConvert| is illustrated in Fig.~\ref{fig:test-autoquote}. 
The hidden assumption that the conversion is possible causes
a 
compile time failure if an incompatible term is given.
To convince yourself of the utility of the |Autoquote| library,
compare this relatively elegant code  to the verbose
|term2boolexpr| function in Fig.~\ref{fig:concrete2abstract}.


\begin{shadedfigure}
\begin{code}
something : {x : ℕ}      → doConvert    exprTable      (    quoteTerm (x + 1))
                         ≡                                  Plus (Var 0) (S Z)
something = refl
\end{code}
\caption{An example of |Autoquote| in use. See Fig.~\ref{fig:exprTable} for the definition of |exprTable|, a typical |Name|-to-constructor mapping.}\label{fig:test-autoquote}
\end{shadedfigure}


In most cases, the result from |doConvert| will require some
post-processing, as we will see later in the Boolean tautologies
example (Sec.~\ref{sec:Boolean-tautologies}), but for now it suffices to say that |Autoquote| removes a lot
of the burden of converting |Term|s into other ASTs.

\section{Proof by Reflection}\label{sec:proof-by-reflection}

The idea behind proof by reflection is simple: given that type theory
is both a programming language and a proof system, it is possible to
define functions that compute proofs. Reflection is an overloaded word
in this context, since in programming language technology reflection
is the capability of converting some piece of concrete code
into an abstract syntax tree that can be manipulated in the same
system. Reflection in the proof technical sense is the method of
mechanically constructing a proof of a theorem by inspecting its
shape. The proof by reflection technique we describe here is not new --
see for example the chapter in Coq'Art~\cite{L:BC04} -- but
instead
combines a number of existing methods into a usable package. 
Here we will see two case studies illustrating proof by
reflection and how Agda's reflection mechanism can make the technique
more convenient.


\subsection{Simple Example: Evenness}\label{sec:evenness}

To illustrate the concept of proof by reflection, we will follow
Chlipala's example of even naturals~\cite{chlipala2011certified}.
 We start by defining the
property |Even| below. There are two constructors: the first
constructor says that zero is even; the second constructor states that
if $n$ is even, then so is $2 + n$.

\begin{shade}
\begin{code}
data Even      : ℕ → Set where
  isEven0      :                          Even 0
  isEven+2     : {n : ℕ} → Even n     →   Even (2 + n)
\end{code}
\end{shade}

Using these rules to produce the proof that some large number $n$ is
even is tedious: the proof that $2 \times n$ is even requires $n$
applications of the |isEven+2| constructor. For example, here is the
proof that 6 is even:

\begin{shade}
\begin{code}
isEven6 : Even 6
isEven6 = isEven+2 (isEven+2 (isEven+2 isEven0))
\end{code}
\end{shade}

To automate this, we will show how to \emph{compute} the proof
required. We start by defining a predicate |even?| that
returns the unit type (top) when its input is even and the empty type (bottom) otherwise.
In this context, |⊤| and |⊥| can be seen as the analogues of |true|
and |false|, since
 there exists
a proof that some number is even, if it is $0$ or $2 + n$, for even $n$. Otherwise, no proof exists. 
The idea
of ``there exists'' is perfectly modelled by the unit and empty types,
since the unit type has one inhabitant, the empty type none.

\begin{shade}
\begin{code}
even? : ℕ → Set
even? 0                 = ⊤
even? 1                 = ⊥
even? (suc (suc n))     = even? n
\end{code}
\end{shade}

Next we need to show that the |even?| function is \emph{sound}.
 To do so, we prove that when |even? n| returns |⊤|,
the type |Even n| is
inhabited. Since we are working in a constructive logic, the only
way to show this is to give some witness. This is done in the function |soundnessEven|. What
we are 
actually doing here is giving a recipe for
constructing proof trees, such as the one we manually defined for
|isEven6|.

\begin{shade}
\begin{code}
soundnessEven : {n : ℕ} → even? n → Even n
soundnessEven {0}              tt        = isEven0
soundnessEven {1}              ()
soundnessEven {suc (suc n)}    s         = isEven+2 (soundnessEven s)
\end{code}
\end{shade}

Note that in the case branch for 1, we do not need to provide a
right-hand side of the function definition. The assumption, |even?
1|, is uninhabited, and we discharge this branch using Agda's
absurd pattern, \texttt{()}.

If we need a proof that some arbitrary
|n| is even, we only need to call |soundnessEven|. Note that
the value of |n| is inferred. The only
argument we must to provide to |soundnessEven| is a proof
that |even? n| is inhabited. For any closed term, such as the numbers |28|
or |8772|, this proof obligation reduces to 
|⊤|, which is proven by its single constructor, |tt|.

\begin{shade}
\begin{code}
isEven8772      : Even 8772
isEven8772      = soundnessEven tt
\end{code}
\end{shade}

Now we can easily get a proof that arbitrarily large numbers are even,
without having to explicitly write down a large proof tree. Note that
it is not possible to write something with type |Even 27|, or any other uneven
number, since the parameter |even? n|  is equal to |⊥|,
 thus
|tt| would not be accepted where it is in the |Even 28| example. This will
produce a type error stating that the types |⊤| and |⊥| cannot be unified.

Since the type |⊤| is a simple record type, Agda can infer the |tt|
argument. This means we can turn the assumption |even? n| into an
implicit argument, so a user could get away with writing just
|soundnessEven| as the proof, letting Agda fill in the missing proof. 
To achieve this, we modify the |soundnessEven|
function slightly, making all its arguments implicit.  This trick works
because Agda supports eta expansion for record types. More specifically, Agda will automatically fill in implicit arguments of the unit type. Here,
 the type system is doing work for us which is not done for general
 data types; for records eta expansion is safe, since recursion is not allowed.
This trick is
implemented in the code on GitHub, and will be
used from here on to make our proofs easier to use.



Note that it is possible to generate a user-friendly ``error'' of
sorts, by replacing the |⊥| with
an empty type having a descriptive name:

\begin{shade}
\begin{spec}
data IsOdd : ℕ -> Set where
\end{spec}  
\end{shade}


This makes the soundness proof a little less straightforward, but in return the
type error generated if an odd number is used becomes more
informative. When a user tries to use the |soundnessEven| lemma to generate a proof
of the statement |Even 7|, Agda will complain about a missing implicit
argument of type |IsOdd 7|. An unsolved implicit argument is marked
yellow in Agda, which looks less scary than a type error in a visible argument, but rest assured that
no spurious proofs are being generated.
This concludes the example of proving that certain naturals are even using proof by reflection.
The next step will be to use the same approach for a more involved and
realistic problem.

\subsection{Second Example: Boolean Tautologies}\label{sec:Boolean-tautologies}

We will now apply the same technique as above to a more interesting problem, making
the relationship to the previous example clear at each step.
The next example of proof by reflection will be a decision procedure 
that checks if a Boolean expression is a tautology. We will follow the same
recipe as for even naturals, with one further addition. In the
previous example, the input of our decision procedure |even?| and the
problem domain were both natural numbers. As we shall see, this need
not always be the case: more complex structures and properties may be used.
Take as an example the following Boolean formula.
\begin{align}\label{eqn:tauto-example}
(p_1 \vee q_1) \wedge (p_2 \vee q_2) \Rightarrow (q_1 \vee p_1) \wedge (q_2 \vee p_2)
\end{align}

It is trivial to see that this is a tautology, but directly proving this 
in Agda can be rather tedious. It
is even worse if we want to check if the formula always holds by
trying all possible variable assignments, since this requires $2^n$
cases, where $n$ is the number of variables.

To automate this process, we will follow a similar approach to
the one given in the previous section. We start by defining an
inductive data type to represent Boolean expressions with at most $n$ free
variables in Fig.~\ref{fig:boolexprn}.

\begin{shadedfigure}
\begin{spec}
data BoolExpr (n : ℕ) : Set where
  Truth Falsehood  :                                  BoolExpr n
  And   Or  Imp    : BoolExpr n → BoolExpr n      →   BoolExpr n
  Not              : BoolExpr n                   →   BoolExpr n
  Atomic           : Fin n                        →   BoolExpr n
\end{spec}
\caption{Inductive definition of Boolean expressions with $n$ free variables.}\label{fig:boolexprn}
\end{shadedfigure}



There is nothing
surprising about this definition; we use the type |Fin n| to ensure
that variables (represented by |Atomic|) are always in scope. If we want to
evaluate the expression, however, we will need some way to map variables to values.
Enter |Env n|: a vector of $n$ Boolean values. It has fixed size |n| since a |BoolExpr n| has at most $n$ free variables.

% ...lijkt me dat mensen dit wel begrijpen. Ik probeer hier ruimte te
% besparen. --Paul
% \begin{shade}
% \begin{spec}
% Env   : ℕ → Set
% Env   = Vec Bool
% \end{spec}
% \end{shade}

Now we can define an evaluation function, which tells us if a given
Boolean expression is true or not, under some assignment of variables. It does this by evaluating
the formula's % the apostrophe is bonafide.
 AST, filling in for |Atomic| values the concrete values which are
looked up in the environment. For example, |And| is evaluated to
the Boolean function |_∧_|, and its two arguments in turn are
recursively interpreted.

\ignore{
\begin{code}
open import Proofs.Util.Handy
\end{code}
}

\begin{shade}
\begin{code}
⟦_⊢_⟧ : ∀ {n : ℕ} (e : Env n) → BoolExpr n → Bool
⟦ env     ⊢ Truth           ⟧ = true
⟦ env     ⊢ Falsehood       ⟧ = false
⟦ env     ⊢ And   be   be₁  ⟧ =     ⟦ env ⊢ be ⟧     ∧      ⟦ env ⊢ be₁ ⟧
⟦ env     ⊢ Or    be   be₁  ⟧ =     ⟦ env ⊢ be ⟧     ∨      ⟦ env ⊢ be₁ ⟧
⟦ env     ⊢ Not   be        ⟧ = ¬   ⟦ env ⊢ be ⟧
⟦ env     ⊢ Imp   be   be₁  ⟧ =     ⟦ env ⊢ be ⟧     ⇒      ⟦ env ⊢ be₁ ⟧
⟦ env     ⊢ Atomic n        ⟧ = lookup n env
\end{code}
\end{shade}

Recall our decision function |even?| in the previous section. It returned
|⊤| if the proposition was valid, |⊥| otherwise. Looking at |⟦_⊢_⟧|, we see that
we should just translate |true| to the unit type and false to the empty type, to get
the analogue of the |even?| function. We therefore define a function
|P| in Fig.~\ref{fig:error}, mapping Booleans to types. To give more useful error messages, we decorate the empty type with a string.

\begin{shadedfigure}
\begin{spec}
data Error (e : String) : Set where

P    : Bool → Set
P  true    =     ⊤
P  false   =     Error "Argument expression does not evaluate to true."
\end{spec}
\caption{Helper type |Error|, enabling clearer type errors.}\label{fig:error}
\end{shadedfigure}


Now that we have these helper functions, it is easy to define what it
means to be a tautology. We quantify over a few Boolean variables, and
wrap the formula in the function |P|. If the resulting type is
inhabited, the argument to |P| is a tautology, i.e., for each
assignment of the free variables the entire equation still evaluates
to |true|. An example encoding of such a theorem is Fig.~\ref{fig:exampletheorem}~-- notice
how similar it looks to the version expressed in mathematical notation, in equation~\ref{eqn:tauto-example}.

\begin{shadedfigure}
\begin{code}
exampletheorem : Set
exampletheorem = (p₁ q₁ p₂ q₂ : Bool)   →
                 P  (         (p₁ ∨ q₁) ∧ (p₂ ∨ q₂) ⇒ (q₁ ∨ p₁) ∧ (q₂ ∨ p₂))
\end{code}
\caption{Encoding of an example tautology.}\label{fig:exampletheorem}
\end{shadedfigure}

Here a complication arises, though. We are quantifying over a list of Boolean values \emph{outside}
of the function |P|, so proving |P| to be sound will not suffice. We just defined an evaluation function |⟦_⊢_⟧|
to take an environment, an expression, and return a Boolean. In Fig.~\ref{fig:exampletheorem}, though,
we effectively quantified over all possible environments. We are going to need a way
to lift the function |P| over arbitrary environments.

% Ik zou uitkijken met het gebruik van 'decision function' -- hier
% wordt meestal mee bedoeld een functie van het type:
% decideP : (x : A) -> Either (P x) (P x -> Empty)

The function |forallsAcc|, in Fig.~\ref{fig:forallsacc}, performs this lifting. This function represents the real analogue
of |even?| in this situation: it returns a type which is only inhabited if the argument Boolean
expression is true under all variable assignments. This is done by generating a full binary tree
of |⊤| or |⊥| types, depending on the result of |⟦_⊢_⟧| under each assignment.
This corresponds precisely to the expression being a tautology if and
only if the tree is inhabited. The function |foralls| simply bootstraps
|forallsAcc| with an empty environment -- it is omitted for brevity.

The |Diff| argument is unfortunately needed for bookkeeping, to prove that |forallsAcc| will eventually produce a
tree with depth equal to the number of free variables in an expression, and can be ignored.


\begin{shadedfigure}
\begin{code}
forallsAcc : {n m : ℕ} → BoolExpr m → Env n → Diff n m → Set
forallsAcc b acc    (Base     ) = P ⟦ acc ⊢ b ⟧
forallsAcc b acc    (Step y   ) =
  forallsAcc b (true ∷ acc) y × forallsAcc b (false ∷ acc) y
\end{code}
\caption{The function |forallsAcc|, which decides if a proposition is a tautology. Compare to the |even?| function in Sec.~\ref{sec:evenness}.}\label{fig:forallsacc}
\end{shadedfigure}

\paragraph{Soundness} Since we now finally know our real decision function |foralls|, we can set about proving its
soundness. Following the |soundnessEven| example, we want a function something like this.

\begin{shade}
\begin{spec}
soundness : {n : ℕ} → (b : BoolExpr n) → foralls b → ...
\end{spec}
\end{shade}

But what should the return type of the |soundness| lemma be? We would like to
prove that the argument |b| is a tautology, and hence, the |soundness|
function should return something of the form |(b₁ ... bn : Bool) -> P
B|, where |B| is an expression in the image of the interpretation
|⟦_⊢_⟧|. For instance, the statement |exampletheorem| is a proposition
of this form.

The function |proofGoal| takes a |BoolExpr n| as its argument and generates the statement
that it is a tautology. That is, it gives back the type  equal to the theorem  under scrutiny. It does this by
first introducing $n$ universally quantified Boolean
variables. These variables are accumulated in an environment. Finally, when $n$
binders have been introduced, the |BoolExpr| is evaluated under this
environment.


\begin{shade}
\begin{code}
proofGoal      : (n m : ℕ) → Diff n m → BoolExpr m → Env n → Set
proofGoal   .  m    m    (Base    ) b acc = P ⟦ acc ⊢ b ⟧ 
proofGoal      n    m    (Step y  ) b acc =
               (a : Bool) → proofGoal (1 + n) m y b (a ∷ acc)
\end{code}
\end{shade}


Now that we can interpret a |BoolExpr n| as a theorem using |proofGoal|, and we have a
way to decide if something is true for a given environment, we still
need to show the soundness of our decision function |foralls|. That is, we need
to be able to show that a formula is true if it holds for every
possible assignment of its variables to |true| or |false|. 

This is done in the function |soundness|, of which we only provide the
type signature. It takes the predicate |foralls| which is only
satisfied when a proposition is a tautology, and gives back a proof
which has the type computed by |proofGoal|. It uses the predicate to
safely extract the leaf from |foralls| corresponding to any given
environment resulting from the binders introduced by |proofGoal|.

\begin{shade}
\begin{code}
soundness       : {n : ℕ}    → (b : BoolExpr n) → {p : foralls b}
                             → proofGoal' 0 n (zeroleast 0 n) b []
\end{code}
\ignore{
\begin{code}
soundness {n} b {p}          = soundnessAcc b [] (zeroleast 0 n) p
\end{code}
}
\end{shade}

%If we look closely at the definition of |soundnessAcc|, we see that it
%builds up the environment by assigning some configuration of |true| and |false| to the variables. It eventually returns the
%leaf from |forallsAcc| which is the proof that the formula is a tautology
%in that specific case. 

Now, we can prove theorems by a call of the form |soundness b {p}|, where |b| is the
representation of the formula under consideration, and |p| is the evidence
that all branches of the proof tree are true. Agda is convinced
that the representation does in fact correspond to the concrete
formula, and also that |soundness| gives a valid proof. We do not
even give |p| explicitly since the only valid values are nested
pairs of |tt|, which can be
inferred automatically for closed terms if the type
is inhabited.  This once  again exploits the fact that  Agda supports eta
expansion for record types. 

If the module
passes the type checker, we know our formula is both a tautology and
that we have the corresponding proof object at our disposal
afterwards, as in |someTauto| (Fig.~\ref{fig:dup}).

\begin{shadedfigure}
\begin{code}
rep          : BoolExpr 2
rep          = Imp    (And (Atomic (suc zero)) (Atomic zero)) 
                      (Atomic zero)

someTauto    : (p q : Bool)         → P( p ∧ q ⇒ q )
someTauto    = soundness rep
\end{code}
\caption{An example Boolean formula, along with the transliteration to a proposition and the corresponding proof.}\label{fig:dup}
\end{shadedfigure}

If one were to give as input a formula which is not a tautology, Agda would not be able to infer the proof |foralls|, since
it would be an uninhabited type. This would result in an unsolved meta-variable, which
might seem a triviality if you do not read the compiler's output carefully. Luckily Agda disallows
importing modules with unsolved meta-variables, which means such a spurious proof would not be usable elsewhere
in a real-life development. 

The only part we still have to do manually is to convert the concrete
Agda representation of the formula (|p ∧ q ⇒ q|, in this case) into our abstract
syntax (|rep|, in this example). This is unfortunate, as we end up typing out the
formula twice. We also have to count the number of variables
ourselves and convert them to De Bruijn indices. This is
error-prone given how cluttered the abstract representation can get
for formulae containing many variables. 

It would be desirable for this representation
process to be automated. Luckily we have the |Autoquote| library
for precisely this purpose.


\subsection{Adding Reflection}\label{sec:addrefl}

It might come as a surprise that in a paper focusing on reflection --
in the programming language technology sense -- we have not yet
presented a convincing use for reflection. This is about to change. 
We can get rid of the duplication seen in Fig.~\ref{fig:dup} using Agda's reflection API. 
There we see the same Boolean formula twice: once in the type signature as an Agda
proposition and once expressed as a  |BoolExpr|. Using
the |quoteGoal| keyword to inspect the
current goal, and passing that goal to |Autoquote|, 
 we can
convert it to its corresponding |BoolExpr| automatically.


The conversion between a |Term| and |BoolExpr| is achieved in two phases.
Since |Autoquote| only supports simple inductive data types, the first issue we encounter is that
|BoolExpr n| has an argument of type |Fin n| to its constructor |Atomic| (see Fig.~\ref{fig:boolexprn}).
To work around this, we introduce a simpler, intermediary data structure, to which we will convert
from |Term|. This type, called |BoolInter|, is not shown here, but the only difference with |BoolExpr n| is that its
variables are represented by naturals instead of |Fin|s.


The |Autoquote| library needs a lookup table, mentioning which constructor represents
variables and what the arity of the constructors is. This way
only |Term|s containing variables or the usual operators 
are accepted. Using the mapping presented in Fig.~\ref{fig:booltable}, we can
construct a function that, for suitable |Term|s,
gives us a value in |BoolInter|. 

\begin{shadedfigure}
\begin{code}
boolTable : Table BoolInter
boolTable = (Atomic ,
                  2 \# (quote _∧_      ) ↦ And                 ∷     2 \# (quote _∨_      ) ↦ Or
            ∷     1 \# (quote  ¬_      ) ↦ Not                 ∷     0 \# (quote true     ) ↦ Truth
            ∷     0 \# (quote false    ) ↦ Falsehood           ∷     2 \# (quote _⇒_      ) ↦ Imp           ∷ [])
\end{code}
\caption{The mapping table for quoting |BoolInter|.}\label{fig:booltable}
\end{shadedfigure}

Once we have a |BoolInter| expression, we just need to check that its
variables are all in scope (this means that $\forall$ |Atomic| $x  :     x < n$, if we
want to convert to a |BoolExpr n|), and replace all the |ℕ| values with their |Fin n| counterparts.
We can now write a function called |proveTautology|, which uses the automatic quoter and calls |soundness| on the resulting term.

That is all we need to automatically prove that
formulae are tautologies.  The following snippet illustrates the use of
the |proveTautology| function; we can omit all arguments except |e|, since they
  can  be inferred.

\begin{shade}
\begin{code}
peirce     : (p q : Bool) → P(((p ⇒ q) ⇒ p) ⇒ p)
peirce     = quoteGoal e in proveTautology e

fave       : exampletheorem -- defined in Fig.~\ref{fig:exampletheorem}
fave       = quoteGoal e in proveTautology e
\end{code}
\end{shade}

With that, we have automatically converted propositions in the Agda world to our
own AST, generated a proof of their soundness, and converted that back into a real proof that Agda
trusts. 

\section{Discussion}\label{sec:discussion}

 
\paragraph{Related work} 
 
Our main innovations are novel combinations of existing
techniques; as a result, quite a number of subjects are relevant to mention
here.
 
As far as reflection in general goes, Demers and Malenfant~\cite{demers1995reflection} wrote an informative historical overview on the topic.
What we are referring to as reflection dates back to work by Brian Smith~\cite{Smith:1984:RSL:800017.800513}
and was initially presented in the Lisp family of languages in the 80s. Since then,
many developments in the functional, logic as well as object-oriented programming worlds have 
been inspired~-- systems with varying power and scope.
 
Reflection is becoming more common, to
various extents, in industry-standard languages such as Java, Objective-C, as well as theoretically more interesting
languages, such as Haskell~\cite{DBLP:journals/lisp/Stump09}. Smalltalk, an early
object-oriented programming language with advanced reflective
features~\cite{Goldberg:1983:SLI:273}, is the predecessor of
Objective-C.
The disadvantage of Smalltalk, however, is that reflection
is extremely unsafe: one can call non-existent functions, to name just
one pitfall.
Nevertheless, it
is surprising that industry programming does not use more of these advanced reflective features which have already  been around for a 
long time. 

These systems would seem to be the inspiration for the current reflection mechanism recently introduced
in Agda, although it is lacking in a number of fundamental
capabilities, most notably type awareness of |unquote|, and type erasure
when using |quoteTerm|.

\paragraph{Evaluation}
If we look at the taxonomy of reflective systems in programming language technology written up 
by Sheard~\cite{sheard-staged-programming},
we see that we can make a few rough judgements about the metaprogramming facilities Agda currently 
supports\footnote{Of course, having been implemented during a single
Agda Implementors' Meeting~\cite{thorsten-communication}, the current
implementation is more a proof-of-concept, and is still far from
being considered finished, so it would be unfair to judge the current implementation all too harshly. In
fact, we hope that this work might motivate the Agda developers to include some more features, to
make the system truly useful. }.
 
\begin{itemize}
\item Agda's current reflection API leans more towards analysis than generation,
\item it supports encoding of terms in an algebraic data type (as opposed to a string, for example),
\item it involves manual staging annotations (by using keywords such as |quote| and |unquote|),
\item it is homogeneous, because the object language is the
  metalanguage. The object language's representation is a native
  data type.
\item It is only two-stage: we cannot as yet produce an object program which is itself a metaprogram. This is
  because we rely on built in keywords such as |quote|, which cannot themselves be represented.
\end{itemize}
 
 
As far as the proof techniques used in the section on proof by reflection (Sec.~\ref{sec:proof-by-reflection}) are concerned,  
Chlipala's work~\cite{chlipala2011certified} proved an invaluable resource. One motivating example
for doing this in Agda was Wojciech Jedynak's ring solver~\cite{ringsolver}, which is the first example of Agda's reflection
API in use that came to our attention. Compared to Jedynak's work, the proof generator presented here is more refined in terms of the interface
presented to the user. The expectation is that approaches like these will become more commonplace for proving mundane lemmas in 
large proofs. The comparison to tactics in a language like Coq is a tempting one, and we see both advantages and disadvantages of each style. Of course, 
the tactic language in Coq is much more specialised and sophisticated when it comes to generating proofs, but it is a pity that there are
two separate languages. This paper explores an alternative, where metaprograms are written directly in the object language. Also, the 
fact that proof generation in Agda is explicit may be something some
people appreciate. 

There are performance issues with the current reflection API in
Agda. This should not come as a surprise. The extensive usage of proof
by reflection in Coq and SSReflect~\cite{gonthier:inria-00515548} has
motivated a lot of recent work on improving Coq's compile time
evaluation. We hope that Agda can be extended with similar technology.

 
\paragraph{Conclusions}
Returning to our research question,  repeated here to jog the memory,  a summary of findings is made.

\researchquestion


This paper has presented two simple applications of proof by
reflection, the latter using Agda's reflection API. 
We 
have managed to automate generation of a certain class of mundane
proofs. 
 This shows that the reflection capabilities recently added to Agda are quite useful for
 automating tedious tasks.  For example, we now need not encode expressions
 manually:
 using |quoteTerm| and |Autoquote|, the AST conversion can be done
 automatically. 
Furthermore, by using the proof by reflection technique, we have shown
how to automatically generate proofs, without loss
 of general applicability. Constraining ourselves to
(pairs of) unit types as predicates, we can let Agda infer them, and by tagging
an empty type with a string, we can achieve more helpful errors if
these predicates are invalid. These simple tools were sufficient to
engineer relatively powerful and -- more importantly -- easily usable
proof tools.

It seems conceivable to imagine that in the future, using techniques such as those presented
here, a framework for tactics might be within reach. Eventually we might be able to define an
embedded language in Agda, in the style of Coq's tactic language, to
inspect the shape of the proof that is needed using reflection, and look at a database
of predefined proof recipes to see if one of them might discharge the obligation. An advantage of 
this approach versus the tactic language in Coq, would be that the language of the propositions and
tactics is the same.

 

\bibliography{refs}{}
%\bibliographystyle{plain}
% for LNCS bibliography:
\bibliographystyle{splncs}%this one doesn't sort automatically. :(
% Voor IFL paper:
% Beperk je tot de essentie
% Geef voorbeelden
\end{document}

%%% Local Variables:
%%% mode: latex
%%% TeX-parse-self: t
%%% TeX-master: t
%%% TeX-command-default: "lagda2pdf"
%%% End: 
