module Ast where
import Data.Map as Map
import Data.List as List
import Data.Maybe as Maybe
import Data.Word as Word
import Text.Parsec.Pos (SourcePos, initialPos)

class HasPos a where
  getPos :: a -> SourcePos

data Lit = 
    IntLit Integer
  | Char Char
  | StrLit String
  | Word8 Word8
  deriving Eq

instance Show Lit where
  show (IntLit i) = 
    if i >= 0 then
      show i
    else
      '~' : show (-i)
  show (Char c) = "#\"" ++ show c ++ "\""  -- TODO Cake-ify
  show (StrLit s) = "\"" ++ show s ++ "\"" -- TODO Cakeify
  show (Word8 w) = show w  -- TODO Cakeify

data Opn = Plus | Minus | Times | Divide | Modulo
  deriving Eq

data Opb = Lt | Gt | Leq | Geq

data ModN = ModN String SourcePos

instance HasPos ModN where
  getPos (ModN _ p) = p

instance Eq ModN where
  (==) (ModN x _) (ModN y _) = x == y

instance Ord ModN where
  compare (ModN x _) (ModN y _) = compare x y

instance Show ModN where
  show (ModN x _) = x

data Id a = Short a
          | Long ModN a
  deriving (Eq, Ord)

instance HasPos a => HasPos (Id a) where
  getPos (Long m a) = getPos a
  getPos (Short a) = getPos a

instance Show a => Show (Id a) where
  show (Short x) = show x
  show (Long x y) = show x ++ "." ++ show y

data VarN = VarN String SourcePos

instance HasPos VarN where
  getPos (VarN _ p) = p

instance Eq VarN where
  (==) (VarN x _) (VarN y _) = x == y

instance Ord VarN where
  compare (VarN x _) (VarN y _) = compare x y

instance Show VarN where
  show (VarN x _) = x

data ConN = ConN String SourcePos

instance HasPos ConN where
  getPos (ConN _ p) = p

instance Eq ConN where
  (==) (ConN x _) (ConN y _) = x == y

instance Ord ConN where
  compare (ConN x _) (ConN y _) = compare x y

instance Show ConN where
  show (ConN x _) = x

data TypeN = TypeN String SourcePos

instance Eq TypeN where
  (==) (TypeN x _) (TypeN y _) = x == y

instance Ord TypeN where
  compare (TypeN x _) (TypeN y _) = compare x y

instance Show TypeN where
  show (TypeN x _) = x

instance HasPos TypeN where
  getPos (TypeN _ p) = p

data TvarN = TvarN String SourcePos

instance HasPos TvarN where
  getPos (TvarN _ p) = p

instance Eq TvarN where
  (==) (TvarN x _) (TvarN y _) = x == y

instance Ord TvarN where
  compare (TvarN x _) (TvarN y _) = compare x y

instance Show TvarN where
  show (TvarN x _) = x

mk_id :: Maybe ModN -> a -> Id a
mk_id Nothing n = Short n
mk_id (Just mn) n = Long mn n

id_to_n :: Id a -> a
id_to_n (Short n) = n
id_to_n (Long _ n) = n

data Op = 
  -- Operations on integers
    Opn Opn
  | Opb Opb
  -- Polymorphic =
  | Equality
  -- Application
  | Opapp
  -- Reference operations
  | Opassign
  | Opref
  | Opderef
  -- Word8Array operations
  | Aw8alloc
  | Aw8sub
  | Aw8length
  | Aw8update
  -- Char operations
  | Ord
  | Chr
  | Chopb Opb
  -- String operations
  | Explode
  | Implode
  | Strlen
  -- Vector operations
  | VfromList
  | Vsub
  | Vlength
  -- Array operations
  | Aalloc
  | Asub
  | Alength
  | Aupdate
  -- Call a given foreign function
  | FFI Integer

data Lop = And SourcePos | Or SourcePos

instance HasPos Lop where
  getPos (And p) = p
  getPos (Or p) = p

data Tc = 
    TC_name (Id TypeN)
  | TC_int
  | TC_char
  | TC_string
  | TC_ref
  | TC_word8
  | TC_word8array
  | TC_fn
  | TC_tup
  | TC_exn
  | TC_vector
  | TC_array
  deriving Eq

instance Show Tc where
  show (TC_name n) = show n
  show TC_int = "int"
  show TC_char = "char"
  show TC_string = "string"
  show TC_ref = "ref"
  show TC_word8 = "Word8.t"
  show TC_word8array = "Word8Array.t"
  show TC_fn = "->"
  show TC_tup = "*"
  show TC_exn = "exn"
  show TC_vector = "Vector.t"
  show TC_array = "Array.t"

data T = 
    Tvar TvarN
  | Tvar_db Integer
  | Tapp [T] Tc
  deriving Eq

tint = Tapp [] TC_int
tchar = Tapp [] TC_char
tstring = Tapp [] TC_string
tref t = Tapp [t] TC_ref
tword8 = Tapp [] TC_word8
tword8array = Tapp [] TC_word8array
tfn t1 t2 = Tapp [t1,t2] TC_fn
texn = Tapp [] TC_exn

data Pat = 
    Pvar VarN
  | Plit Lit SourcePos
  | Pcon (Maybe (Id ConN)) [Pat] SourcePos
  | Pref Pat SourcePos

data Exp = 
    Raise Exp
  | Handle Exp [(Pat,Exp)]
  | Lit Lit SourcePos
  | Con (Maybe (Id ConN)) [Exp] SourcePos
  | Var (Id VarN)
  | Fun VarN Exp SourcePos
  | App Op [Exp]
  | Log Lop Exp Exp
  | If Exp Exp Exp
  | Mat Exp [(Pat,Exp)]
  | Let (Maybe VarN) Exp Exp
  | Letrec [(VarN,VarN,Exp)] Exp

type Type_def = [([TvarN], TypeN, [(ConN, [T])])]

data Dec = 
    Dlet Pat Exp SourcePos
  | Dletrec [(VarN, VarN, Exp)]
  | Dtype Type_def
  | Dtabbrev [TvarN] TypeN T
  | Dexn ConN [T]

type Decs = [Dec]

data Spec = 
    Sval VarN T
  | Stype Type_def
  | Stabbrev [TvarN] TypeN T
  | Stype_opq [TvarN] TypeN
  | Sexn ConN [T]

type Specs = [Spec]

data Top = 
    Tmod ModN (Maybe Specs) Decs
  | Tdec Dec

type Prog = [Top]

pat_bindings :: Pat -> [VarN] -> [VarN]
pat_bindings (Pvar n) already_bound = n:already_bound
pat_bindings (Plit l _) already_bound = already_bound
pat_bindings (Pcon _ ps _) already_bound = pats_bindings ps already_bound
pat_bindings (Pref p _) already_bound = pat_bindings p already_bound
pats_bindings [] already_bound = already_bound
pats_bindings (p:ps) already_bound = pats_bindings ps (pat_bindings p already_bound)


{- Old stuff 

newtype Env k v = Env (Map k v)

lookup :: Ord k => k -> Env k v -> Maybe v
lookup k (Env m) = Map.lookup k m

emp :: Env k v
emp = Env Map.empty

merge :: Ord k => Env k v -> Env k v -> Env k v
merge (Env m1) (Env m2) = Env (Map.union m1 m2)

bind :: Ord k => k -> v -> Env k v -> Env k v
bind k v (Env m) = Env (Map.insert k v m)

getDup :: (Eq a, Ord a) => [a] -> Maybe a
getDup ls = check (sort ls)
  where check [] = Nothing
        check [x] = Nothing
        check (x:y:zs) = if x == y then Just x else check (y:zs)

listToEnv :: Ord k => [(k,v)] -> Env k v
listToEnv l = Env (Map.fromList l)

envToList :: Env k v -> [(k,v)]
envToList (Env m) = Map.assocs m

envAll :: (k -> v -> Bool) -> Env k v -> Bool
envAll f (Env m) = List.all (\(x,y) -> f x y) (Map.assocs m)

envElem :: Ord k => k -> Env k v -> Bool
envElem k (Env m) = Map.member k m

show_pair (x,y) = "val " ++ show x ++ " = " ++ show y ++ ";"

instance (Show k, Show v) => Show (Env k v) where
  show (Env e) = List.intercalate "\n" (List.map show_pair (Map.assocs e))

opn_lookup :: Opn -> Integer -> Integer -> Integer
opn_lookup Plus = (+)
opn_lookup Minus = (-)
opn_lookup Times = ( * )
opn_lookup Divide = (div)
opn_lookup Modulo = (mod)

opb_lookup :: Opb -> Integer -> Integer -> Bool
opb_lookup Lt = (<)
opb_lookup Gt = (>)
opb_lookup Leq = (<=)
opb_lookup Geq = (>=)


data Tid_or_exn = 
    TypeId (Id TypeN)
  | TypeExn

instance Eq Tid_or_exn where
  (==) TypeExn TypeExn = True
  (==) (TypeId tid1) (TypeId tid2) = tid1 == tid2
  (==) _ _ = False

data Ast_pat = 
    Ast_Pvar VarN
  | Ast_Plit Lit SourcePos
  | Ast_Pcon (Maybe (Id ConN)) [Ast_pat] SourcePos
  | Ast_Pref Ast_pat SourcePos

data Ast_exp =
    Ast_Raise Ast_exp
  | Ast_Handle Ast_exp [(Ast_pat, Ast_exp)]
  | Ast_Lit Lit SourcePos
  | Ast_Var (Id VarN)
  | Ast_Con (Maybe (Id ConN)) [Ast_exp] SourcePos
  | Ast_Fun VarN Ast_exp SourcePos
  | Ast_App Ast_exp Ast_exp
  | Ast_Log Lop Ast_exp Ast_exp
  | Ast_If Ast_exp Ast_exp Ast_exp
  | Ast_Mat Ast_exp [(Ast_pat, Ast_exp)]
  | Ast_Let VarN Ast_exp Ast_exp
  | Ast_Letrec [(VarN, VarN, Ast_exp)] Ast_exp

data Ast_t =
    Ast_Tvar TvarN
  | Ast_Tapp [Ast_t] (Maybe (Id TypeN))
  | Ast_Tfn Ast_t Ast_t

type Ast_type_def = [([TvarN], TypeN, [(ConN, [Ast_t])])]

data Ast_dec =
    Ast_Dlet Ast_pat Ast_exp SourcePos
  | Ast_Dletrec [(VarN, VarN, Ast_exp)]
  | Ast_Dtype Ast_type_def
  | Ast_Dexn ConN [Ast_t]

type Ast_decs = [Ast_dec]

data Ast_spec =
    Ast_Sval VarN Ast_t
  | Ast_Stype Ast_type_def
  | Ast_Stype_opq [TvarN] TypeN

type Ast_specs = [Ast_spec]

data Ast_top =
    Ast_Tmod ModN (Maybe Ast_specs) Ast_decs
  | Ast_Tdec Ast_dec

type Ast_prog = [Ast_top]

type Ctor_env = Env ConN (Id ConN)

elab_p :: Ctor_env -> Ast_pat -> Pat
elab_p ctors (Ast_Pvar n) = Pvar n
elab_p ctors (Ast_Plit l pos) = Plit l pos
elab_p ctors (Ast_Pcon (Just (Short cn)) ps pos) =
  case Ast.lookup cn ctors of
     Just cid -> Pcon (Just cid) (elab_ps ctors ps) pos
     Nothing -> Pcon (Just (Short cn)) (elab_ps ctors ps) pos
elab_p ctors (Ast_Pcon cn ps pos) =
  Pcon cn (elab_ps ctors ps) pos
elab_p ctors (Ast_Pref p pos) = Pref (elab_p ctors p) pos
elab_ps ctors [] = []
elab_ps ctors (p:ps) = elab_p ctors p : elab_ps ctors ps

type Tdef_env = Env TypeN Tc

elab_t :: Tdef_env -> Ast_t -> T
elab_e :: Ctor_env -> Ast_exp -> Exp
elab_funs :: Ctor_env -> [(VarN, VarN, Ast_exp)] -> [(VarN, VarN, Exp)]
elab_dec :: Maybe ModN -> Tdef_env -> Ctor_env -> Ast_dec -> (Tdef_env, Ctor_env, Dec)
elab_decs :: Maybe ModN -> Tdef_env -> Ctor_env -> [Ast_dec] -> (Tdef_env, Ctor_env, [Dec])
elab_spec :: Maybe ModN -> Tdef_env -> [Ast_spec] -> [Spec]
elab_top :: Tdef_env -> Ctor_env -> Ast_top -> (Tdef_env, Ctor_env, Top)
elab_prog :: Tdef_env -> Ctor_env -> [Ast_top] -> (Tdef_env, Ctor_env, Prog)

elab_e ctors (Ast_Raise e) = Raise (elab_e ctors e)
elab_e ctors (Ast_Handle e pes) =
  Handle (elab_e ctors e) 
         (List.map (\(p,e) -> (elab_p ctors p, elab_e ctors e)) pes)
elab_e ctors (Ast_Lit l pos) =
  Lit l pos
elab_e ctors (Ast_Var id) =
  Var id
elab_e ctors (Ast_Con (Just (Short cn)) es pos) =
  case Ast.lookup cn ctors of
    Just cid -> Con (Just cid) (List.map (elab_e ctors) es) pos
    Nothing -> Con (Just (Short cn)) (List.map (elab_e ctors) es) pos
elab_e ctors (Ast_Con cn es pos) =
  Con cn (List.map (elab_e ctors) es) pos
elab_e ctors (Ast_Fun n e pos) =
  Fun n (elab_e ctors e) pos
elab_e ctors (Ast_App e1 e2) =
  App Opapp (elab_e ctors e1) (elab_e ctors e2)
elab_e ctors (Ast_Log lop e1 e2) =
  Log lop (elab_e ctors e1) (elab_e ctors e2)
elab_e ctors (Ast_If e1 e2 e3) =
  If (elab_e ctors e1) (elab_e ctors e2) (elab_e ctors e3)
elab_e ctors (Ast_Mat e pes) =
  Mat (elab_e ctors e) 
      (List.map (\(p,e) -> (elab_p ctors p, elab_e ctors e)) pes)
elab_e ctors (Ast_Let x e1 e2) =
  Let x (elab_e ctors e1) (elab_e ctors e2)
elab_e ctors (Ast_Letrec funs e) =
  Letrec (elab_funs ctors funs) 
         (elab_e ctors e)
elab_funs ctors [] =
  []
elab_funs ctors ((n1,n2,e):funs) =
  (n1,n2,elab_e ctors e) : elab_funs ctors funs

elab_t type_bound (Ast_Tvar n) = Tvar n
elab_t type_bound (Ast_Tfn t1 t2) =
  tfn (elab_t type_bound t1) (elab_t type_bound t2)
elab_t type_bound (Ast_Tapp ts Nothing) =
  let ts' = List.map (elab_t type_bound) ts in
    Tapp ts' TC_tup
elab_t type_bound (Ast_Tapp ts (Just (Long m tn))) =
  let ts' = List.map (elab_t type_bound) ts in
    Tapp ts' (TC_name (Long m tn))
elab_t type_bound (Ast_Tapp ts (Just (Short tn))) =
  let ts' = List.map (elab_t type_bound) ts in
    case Ast.lookup tn type_bound of
      Nothing -> Tapp ts' (TC_name (Short tn))
      Just tc -> Tapp ts' tc

get_ctors_bindings mn t =
  List.concat (List.map (\(tvs,tn,ctors) -> List.map (\(cn,t) -> (cn, mk_id mn cn)) ctors) t)
   
elab_td type_bound (tvs,tn,ctors) =
  (tvs, tn, List.map (\(cn,t) -> (cn, List.map (elab_t type_bound) t)) ctors)

elab_dec mn type_bound ctors (Ast_Dlet p e pos) =
  let p' = elab_p ctors p in
    (emp, emp, Dlet p' (elab_e ctors e) pos)
elab_dec mn type_bound ctors (Ast_Dletrec funs) =
  (emp, emp, Dletrec (elab_funs ctors funs))
elab_dec mn type_bound ctors (Ast_Dtype t) = 
  let type_bound' = listToEnv (List.map (\(tvs,tn,ctors) -> (tn, TC_name (mk_id mn tn))) t) in
    (type_bound',
     listToEnv (get_ctors_bindings mn t),
     Dtype (List.map (elab_td (merge type_bound' type_bound)) t))
elab_dec mn type_bound ctors (Ast_Dexn cn ts) =
  (emp,
   bind cn (mk_id mn cn) emp,
   Dexn cn (List.map (elab_t type_bound) ts)) 

elab_decs mn type_bound ctors [] = (emp,emp,[])
elab_decs mn type_bound ctors (d:ds) = 
  let (type_bound', ctors', d') = elab_dec mn type_bound ctors d in
  let (type_bound'',ctors'',ds') = elab_decs mn (merge type_bound' type_bound) (merge ctors' ctors) ds in
    (merge type_bound'' type_bound', merge ctors'' ctors', d':ds')

elab_spec mn type_bound [] = []
elab_spec mn type_bound (Ast_Sval x t:spec) =
  Sval x (elab_t type_bound t) : elab_spec mn type_bound spec
elab_spec mn type_bound (Ast_Stype td : spec) =
  let type_bound' = listToEnv (List.map (\(tvs,tn,ctors) -> (tn, TC_name (mk_id mn tn))) td) in
    Stype (List.map (elab_td (merge type_bound' type_bound)) td) : elab_spec mn (merge type_bound' type_bound) spec
elab_spec mn type_bound (Ast_Stype_opq tvs tn:spec) =
  Stype_opq tvs tn : elab_spec mn (bind tn (TC_name (mk_id mn tn)) type_bound) spec

elab_top type_bound ctors (Ast_Tdec d) =
  let (type_bound', ctors', d') = elab_dec Nothing type_bound ctors d in
      (type_bound', ctors', Tdec d')
elab_top type_bound ctors (Ast_Tmod mn spec ds) =
  let (type_bound',ctors',ds') = elab_decs (Just mn) type_bound ctors ds in
      (type_bound,ctors,Tmod mn (fmap (elab_spec (Just mn) type_bound) spec) ds')

elab_prog type_bound ctors [] = (emp,emp,[])
elab_prog type_bound ctors (top:prog) =
  let (type_bound',ctors',top') = elab_top type_bound ctors top in
  let (type_bound'',ctors'',prog') = elab_prog (merge type_bound' type_bound) (merge ctors' ctors) prog in
    (merge type_bound'' type_bound', merge ctors'' ctors', top':prog') 

dummy_pos = initialPos "initial_env"

init_elab_env =
  listToEnv
    (List.map (\(x,y) -> (TypeN x dummy_pos, y))
      [("int", TC_int),
       ("bool", TC_bool),
       ("ref", TC_ref),
       ("unit", TC_unit),
       ("exn", TC_exn),
       ("list", TC_name (Short (TypeN "list" dummy_pos)))])

-}
