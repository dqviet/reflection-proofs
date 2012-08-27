open import Equal

module Datatypes (U : Set) (equal? : (x : U) → (y : U) → Equal? x y) (Uel : U → Set) where

open import Data.List
open import Data.Nat hiding (_≟_)
open import Data.Unit hiding (_≟_)
open import Data.Empty
open import Data.Fin using (Fin ;  zero ; suc)


infixl 30 _⟨_⟩ 
infixr 20 _=>_

-- type signatures. Either a base type or a function. and then continuations.
data U' : Set where
  O    : U → U'
  _=>_ : U' → U' → U'
  Cont : U' → U'

el' : U' -> Set
el' (O x) = Uel x
el' (u => u₁) = el' u → el' u₁
el' (Cont t) = ⊥ -- arbitrary, as `el' (Cont _)` is never called.

_=?=_ : (σ τ : U') → Equal? σ τ
O x          =?= O  y       with (equal? x y)
O .y         =?= O y  | yes = yes
O x          =?= O y  | no  = no
-- O          =?= O        = yes
O x          =?= (_ => _)   = no
(σ => τ)     =?= O  y       = no
(σ₁ => τ₁)   =?= (σ₂ => τ₂) with σ₁ =?= σ₂ | τ₁ =?= τ₂
(.σ₂ => .τ₂) =?= (σ₂ => τ₂) | yes | yes = yes
(.σ₂ => τ₁)  =?= (σ₂ => τ₂) | yes | no  = no
(σ₁ => .τ₂)  =?= (σ₂ => τ₂) | no  | yes = no
(σ₁ => τ₁)   =?= (σ₂ => τ₂) | no  | no  = no
O x          =?= Cont b     = no
(a => a₁)    =?= Cont b     = no
Cont a       =?= O y        = no
Cont a       =?= (b => b₁)  = no
Cont a       =?= Cont b     with a =?= b
Cont .b      =?= Cont b     | yes = yes
Cont a       =?= Cont b     | no  = no

-- we don't know anything about Raws, except
-- that they're lambdas.
data Raw : Set where
  Var  : ℕ              → Raw
  App  : Raw   → Raw    → Raw
  Lam  : U'    → Raw    → Raw
  Lit  : (x : U)   →  Uel x → Raw

open import Data.Stream using (Stream ; _∷_)
open import Coinduction

-----------------------------------------------------------------------------
-- Well-scoped, well-typed lambda terms
-----------------------------------------------------------------------------

-- this will probably become a Vec later.
Ctx : Set
Ctx = List U'

infix 3 _∈_

data _∈_ {A : Set} (x : A) : List A → Set where
  here    : {xs : List A} → x ∈ x ∷ xs
  there   : {xs : List A} {y : A} → x ∈ xs → x ∈ y ∷ xs
  
data WT : (Γ : Ctx) → U' -> Set where
  Var   : forall {Γ} {τ}   → τ ∈ Γ → WT Γ τ
  _⟨_⟩  : forall {Γ} {σ τ} → WT Γ (σ => τ) → WT Γ σ → WT Γ τ
  Lam   : forall {Γ} σ {τ} → WT (σ ∷ Γ) τ → WT Γ (σ => τ)
  Lit   : forall {Γ} {x} → Uel x → WT Γ (O x) -- a constant

FreshVariables : Set
FreshVariables = Stream ℕ

fv : FreshVariables
fv = startAt 0
  where startAt : ℕ → FreshVariables
        startAt n = n ∷ ♯ startAt (suc n)
  
-- todo: replace with finindex?
index : {A : Set} {x : A} {xs : List A} → x ∈ xs → ℕ
index   here    = zero
index (there h) = suc (index h)

finindex : {A : Set} {x : A} {xs : List A} → x ∈ xs → Fin (length xs)
finindex   here     = zero
finindex (there h)  = suc (finindex h)

data Lookup {A : Set} (xs : List A) : ℕ → Set where
  inside   : (x : A) (p : x ∈ xs) → Lookup xs (index p)
  outside  : (m : ℕ) → Lookup xs (length xs + m)
  

_!_ : {A : Set} (xs : List A) (n : ℕ) → Lookup xs n
[]        ! n      = outside n
(x ∷ x₁)  ! zero   = inside x here
(x ∷ x₁)  ! suc n with x₁ ! n
(x₂ ∷ x₁) ! suc .(index p)       | inside x p  = inside x (there p)
(x ∷ x₁)  ! suc .(length x₁ + m) | outside  m  = outside m

-- a way to get untyped terms back

erase : forall {Γ τ} → WT Γ τ → Raw
erase (Var inpf)      = Var (index inpf)
erase (t ⟨ t₁ ⟩)      = App (erase t) (erase t₁)
erase (Lam σ t)       = Lam σ (erase t)
erase (Lit {_}{σ} x)  = Lit σ x

data Infer (Γ : Ctx) : Raw → Set where
  ok    : (τ : U') (t : WT Γ τ)  → Infer Γ (erase t)
  bad   : {e : Raw}              → Infer Γ e
