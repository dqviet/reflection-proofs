module Proofs.TautologyProver where

open import Relation.Binary.PropositionalEquality renaming ([_] to by ; subst to substpe)
open import Data.String
-- open import Data.Maybe hiding (Eq)
open import Data.Nat
open import Relation.Nullary hiding (¬_)
-- open import Data.Product hiding (map)
-- open import Data.Vec.Properties
-- open import Data.Nat.Properties
-- open import Relation.Binary hiding (_⇒_)
open import Reflection
-- 
-- open import Data.Vec.N-ary
open import Data.Bool renaming (not to ¬_ )
-- open import Data.Nat
open import Data.Fin hiding (_+_; pred)
open import Data.Vec renaming (reverse to vreverse ; map to vmap; foldr to vfoldr; _++_ to _v++_)
open import Data.Unit hiding (_≤?_)
open import Data.Empty
-- open import Data.Sum hiding (map)
open import Data.Product hiding (map)
open import Data.List hiding (_∷ʳ_)

infixr 4 _⇒_
_⇒_ : Bool → Bool → Bool
true  ⇒ true  = true
true  ⇒ false = false
false ⇒ true  = true
false ⇒ false = true

data Error (a : String) : Set where

So : String → Bool → Set
So _ true  = ⊤
So s false = Error s

P : Bool → Set
P = So "Expression doesn't evaluate to true in this branch."

bOrNotb : (b : Bool) → b ∨ ¬ b ≡ true
bOrNotb true  = refl
bOrNotb false = refl

bImpb : (b : Bool) → P(b ⇒ b)
bImpb true  = tt
bImpb false = tt

-- wouldn't it be nice if we could automate this?

-- eventually we'd like to prove these kinds of tautologies:
myfavouritetheorem : Set
myfavouritetheorem = (p1 q1 p2 q2 : Bool) → P(  (p1 ∨ q1) ∧ (p2 ∨ q2)
                                              ⇒ (q1 ∨ p1) ∧ (q2 ∨ p2)
                                              )

-- we'll make some DSL into which we're going to translate theorems
-- (which are actually types of functions), and then use reflection
-- in some unmagical way... see below.

{-
The point of having SET is to have a place to put stuff subst gives us.
i.e., if we want to go from BoolExpr → Set, we need a way to reattach a
variable in the Pi type to some term inside our boolean expression.
-}
data BoolIntermediate : Set where
  Truth     :                                       BoolIntermediate
  Falsehood :                                       BoolIntermediate
  And       : BoolIntermediate → BoolIntermediate → BoolIntermediate
  Or        : BoolIntermediate → BoolIntermediate → BoolIntermediate
  Not       : BoolIntermediate                    → BoolIntermediate
  Imp       : BoolIntermediate → BoolIntermediate → BoolIntermediate
  Atomic    : ℕ                                   → BoolIntermediate

data BoolExpr : ℕ → Set where
  Truth     : {n : ℕ}                           → BoolExpr n
  Falsehood : {n : ℕ}                           → BoolExpr n
  And       : {n : ℕ} → BoolExpr n → BoolExpr n → BoolExpr n
  Or        : {n : ℕ} → BoolExpr n → BoolExpr n → BoolExpr n
  Not       : {n : ℕ} → BoolExpr n              → BoolExpr n
  Imp       : {n : ℕ} → BoolExpr n → BoolExpr n → BoolExpr n
  Atomic    : {n : ℕ} → Fin n                   → BoolExpr n

-- ...and some way to interpret our representation
-- of the formula at hand:
-- this is compile : S → D

-- the environment
Env : ℕ → Set
Env = Vec Bool
-- lijst van lengte n met daarin een Set / Bool

-- S = BoolExpr (the syntactic realm)
-- D = the domain of our Props

-- decision procedure:
-- return whether the given proposition is true
-- this is like our isEvenQ
⟦_⊢_⟧ : ∀ {n : ℕ} (e : Env n) → BoolExpr n → Bool
⟦ env ⊢ Truth      ⟧ = true
⟦ env ⊢ Falsehood  ⟧ = false
⟦ env ⊢ And be be₁ ⟧ = ⟦ env ⊢ be ⟧ ∧ ⟦ env ⊢ be₁ ⟧
⟦ env ⊢ Or be be₁  ⟧ = ⟦ env ⊢ be ⟧ ∨ ⟦ env ⊢ be₁ ⟧
⟦ env ⊢ Not be     ⟧ = ¬ ⟦ env ⊢ be ⟧
⟦ env ⊢ Imp be be₁ ⟧ = ⟦ env ⊢ be ⟧ ⇒ ⟦ env ⊢ be₁ ⟧
⟦ env ⊢ Atomic n   ⟧ = lookup n env

-- returns the number of the outermost pi quantified variables.

freeVars : Term → ℕ
freeVars (pi (arg visible relevant (el (lit _) (def Bool []))) (el s t)) = suc (freeVars t)
freeVars (pi a b)     = 0
freeVars (var x args) = 0
freeVars (con c args) = 0
freeVars (def f args) = 0
freeVars (lam v σ t)  = 0
freeVars (sort x)     = 0
freeVars unknown      = 0

-- peels off all the outermost Pi constructors,
-- returning a term with freeVars free variables.

stripPi : Term → Term
stripPi (pi (arg visible relevant (el (lit _) (def Bool []))) (el s t)) = stripPi t
-- identity otherwise
stripPi (pi args t)  = pi   args t
stripPi (var x args) = var  x    args
stripPi (con c args) = con  c    args
stripPi (def f args) = def  f    args
stripPi (lam v σ t)  = lam  v  σ  t
stripPi (sort x)     = sort x
stripPi unknown      = unknown

isSoExprQ : (t : Term) → Set
isSoExprQ (var x args) = ⊥
isSoExprQ (con c args) = ⊥
isSoExprQ (def f args) with Data.Nat._≟_ (length args) 2
isSoExprQ (def f args) | yes p with tt
isSoExprQ (def f [])                   | yes () | tt
isSoExprQ (def f (x ∷ []))             | yes () | tt
isSoExprQ (def f (a ∷ arg v r x ∷ [])) | yes p  | tt with f ≟-Name quote So
isSoExprQ (def f (a ∷ arg v r x ∷ [])) | yes p₁ | tt | yes p = ⊤
isSoExprQ (def f (a ∷ arg v r x ∷ [])) | yes p  | tt | no ¬p = ⊥
isSoExprQ (def f (x ∷ x₃ ∷ x₄ ∷ args)) | yes () | tt
isSoExprQ (def f args)                 | no ¬p with tt
isSoExprQ (def f [])                   | no ¬p | tt = ⊥
isSoExprQ (def f (x ∷ xs))             | no ¬p | tt = ⊥
isSoExprQ (lam v σ t)                  = ⊥
isSoExprQ (pi t₁ t₂)                   = ⊥
isSoExprQ (sort x)                     = ⊥
isSoExprQ unknown                      = ⊥


stripSo : (t : Term) → isSoExprQ t → Term
stripSo (var x args)                 ()
stripSo (con c args)                 ()
stripSo (def f args)                 pf with Data.Nat._≟_ (length args) 2
stripSo (def f args)                 pf | yes p with tt
stripSo (def f [])                   pf | yes () | tt
stripSo (def f (x ∷ []))             pf | yes () | tt
stripSo (def f (a ∷ arg v r x ∷ [])) pf | yes p  | tt with f ≟-Name quote So
stripSo (def f (a ∷ arg v r x ∷ [])) pf | yes p₁ | tt | yes p = x
stripSo (def f (a ∷ arg v r x ∷ [])) () | yes p  | tt | no ¬p
stripSo (def f (x ∷ x₃ ∷ x₄ ∷ args)) pf | yes () | tt
stripSo (def f args)                 pf | no ¬p with tt
stripSo (def f [])                   () | no ¬p | tt
stripSo (def f (x ∷ xs))             () | no ¬p | tt
stripSo (lam v σ t)                  ()
stripSo (pi t₁ t₂)                   ()
stripSo (sort x)                     ()
stripSo unknown                      ()



-- useful for things like Env n → Env m → Env n ⊕ m
_⊕_ : ℕ → ℕ → ℕ
zero  ⊕ m = m
suc n ⊕ m = n ⊕ suc m

data Diff : ℕ → ℕ → Set where
  Base : ∀ {n}   → Diff n n
  Step : ∀ {n m} → Diff (suc n) m → Diff n m


prependTelescope : (n m : ℕ) → Diff n m → BoolExpr m → Env n → Set
prependTelescope .m m (Base  ) b env = P ⟦ env ⊢ b ⟧ 
prependTelescope n m  (Step y) b env = (a : Bool) → prependTelescope (suc n) m y b (a ∷ env)

zeroId : (n : ℕ) → n ≡ n + 0
zeroId zero                           = refl
zeroId (suc  n) with n + 0 | zeroId n
zeroId (suc .w)    | w     | refl     = refl

succLemma : (n m : ℕ) → suc (n + m) ≡ n + suc m
succLemma zero m    = refl
succLemma (suc n) m = cong suc (succLemma n m)

coerceDiff : {n m k : ℕ} → n ≡ m → Diff k n → Diff k m
coerceDiff refl d = d

zero-least : (k n : ℕ) → Diff k (k + n)
zero-least k zero    = coerceDiff (zeroId k) Base
zero-least k (suc n) = Step (coerceDiff (succLemma k n) (zero-least (suc k) n))

forallBoolSo : (m : ℕ) → BoolExpr m → Set
forallBoolSo m b = prependTelescope zero m (zero-least 0 m) b []

{-
notice that u is automatically instantiated, since
there is only one option, namely tt,tt. this is special and
cool, the type system is doing work for us. Note that this is
because eta-reduction only is done in the type system for records
and not for general data types. possibly the reason is because this is
safe in records because recursion isn't allowed. question for agda-café?
-}
foo' : {u : ⊤ × ⊤} → ℕ
foo' = 5

baz : ℕ
baz = foo'

-- very much like ⊥-elim, but for Errors.
Error-elim : ∀ {Whatever : Set} {e : String} → Error e → Whatever
Error-elim ()

forallsAcc : {n m : ℕ} → (b : BoolExpr m) → Env n → Diff n m → Set
forallsAcc b' env (Base  ) = P ⟦ env ⊢ b' ⟧
forallsAcc b' env (Step y) = forallsAcc b' (true ∷ env) y × forallsAcc b' (false ∷ env) y

foralls : {n : ℕ} → (b : BoolExpr n) → Set
foralls {n} b = forallsAcc b [] (zero-least 0 n)

-- dependently typed if-statement
if : {P : Bool → Set} → (b : Bool) → P true → P false → P b
if true  t f = t
if false t f = f

soundnessAcc : {m : ℕ} →
                 (b : BoolExpr m) →
                 {n : ℕ} →
                 (env : Env n) →
                 (d : Diff n m) →
                 forallsAcc b env d →
                 prependTelescope n m d b env
soundnessAcc     bexp     env Base     H with ⟦ env ⊢ bexp ⟧
soundnessAcc     bexp     env Base     H | true  = H
soundnessAcc     bexp     env Base     H | false = Error-elim H
soundnessAcc {m} bexp {n} env (Step y) H =
  λ a → if {λ b → prependTelescope (suc n) m y bexp (b ∷ env)} a
    (soundnessAcc bexp (true  ∷ env) y (proj₁ H))
    (soundnessAcc bexp (false ∷ env) y (proj₂ H))

soundness : {n : ℕ} → (b : BoolExpr n) → {i : foralls b} → forallBoolSo n b
soundness {n} b {i} = soundnessAcc b [] (zero-least 0 n) i

open import Metaprogramming.Autoquote

boolTable : Table BoolIntermediate
boolTable = (Atomic ,
              2 # (quote _∧_  ) ↦ And
            ∷ 2 # (quote _∨_  ) ↦ Or
            ∷ 1 # (quote  ¬_  ) ↦ Not
            ∷ 0 # (quote true ) ↦ Truth
            ∷ 0 # (quote false) ↦ Falsehood
            ∷ 2 # (quote _⇒_  ) ↦ Imp
            ∷ [])

term2boolexpr' : (t : Term) → {pf : convertManages boolTable t} → BoolIntermediate
term2boolexpr' t {pf} = doConvert boolTable t {pf}

bool2finCheck : (n : ℕ) → (t : BoolIntermediate) → Set
bool2finCheck n Truth        = ⊤
bool2finCheck n Falsehood    = ⊤
bool2finCheck n (And t t₁)   = bool2finCheck n t × bool2finCheck n t₁
bool2finCheck n (Or t t₁)    = bool2finCheck n t × bool2finCheck n t₁
bool2finCheck n (Not t)      = bool2finCheck n t
bool2finCheck n (Imp t t₁)   = bool2finCheck n t × bool2finCheck n t₁
bool2finCheck n (Atomic x)   with suc x ≤? n
bool2finCheck n (Atomic x)   | yes p = ⊤
bool2finCheck n (Atomic x)   | no ¬p = ⊥

bool2fin : (n : ℕ) → (t : BoolIntermediate) → (bool2finCheck n t) → BoolExpr n
bool2fin n Truth       pf = Truth
bool2fin n Falsehood   pf = Falsehood
bool2fin n (And t t₁) (p₁ , p₂) = And (bool2fin n t p₁) (bool2fin n t₁ p₂)
bool2fin n (Or t t₁)  (p₁ , p₂) = Or (bool2fin n t p₁) (bool2fin n t₁ p₂)
bool2fin n (Not t)     p₁ = Not (bool2fin n t p₁)
bool2fin n (Imp t t₁) (p₁ , p₂) =  Imp (bool2fin n t p₁) (bool2fin n t₁ p₂)
bool2fin n (Atomic x)  p₁ with suc x ≤? n
bool2fin n (Atomic x)  p₁ | yes p = Atomic (fromℕ≤ {x} p)
bool2fin n (Atomic x)  () | no ¬p


concrete2abstract :
         (t : Term)
       → {pf : isSoExprQ (stripPi t)}
       → let t' = stripSo (stripPi t) pf in
            {pf2 : convertManages boolTable t'}
          → (bool2finCheck (freeVars t) (term2boolexpr' t' {pf2}))
          → BoolExpr (freeVars t)
concrete2abstract t {pf} {pf2} fin = bool2fin (freeVars t) (term2boolexpr' (stripSo (stripPi t) pf) {pf2}) fin

proveTautology : (t : Term) →
        {pf : isSoExprQ (stripPi t)} →
           let t' = stripSo (stripPi t) pf in
                {pf2 : convertManages boolTable t'} → 
                {fin : bool2finCheck (freeVars t) (term2boolexpr' t' {pf2})} → 
                let b = concrete2abstract t {pf} {pf2} fin in
                    {i : foralls b} →
                    forallBoolSo (freeVars t) b
proveTautology e {pf} {pf2} {fin} {i} = soundness {freeVars e} (concrete2abstract e fin) {i}

anotherTheorem : (a b : Bool) → P(a ∧ b ⇒ b ∧ a)
anotherTheorem = quoteGoal e in proveTautology e

goalbla2 : (b : Bool) → P(b ∨ true)
goalbla2 = quoteGoal e in proveTautology e

not : (b : Bool) → P(b ∨ ¬ b)
not = quoteGoal e in proveTautology e

peirce : (p q  : Bool) → P(((p ⇒ q) ⇒ p) ⇒ p)
peirce = quoteGoal e in proveTautology e

mft : myfavouritetheorem
mft = quoteGoal e in proveTautology e

foo : quoteTerm (\(x : Bool) -> x) ≡ lam visible (el _ (def (quote Bool) [])) (var 0 [])
foo = refl

-- -- acknowledge Ruud:
-- -- thing : {err : String} {a : Bool} → So err a → a ≡ true
-- -- thing ⊤ = {!!}
-- -- 
-- -- another : (a b : Bool) → a ∧ b ⇒ b ∧ a ≡ true
-- -- another a b with anotherTheorem a b
-- -- ...  | asdf = {!asdf!}