module

public import Mathlib.Analysis.InnerProductSpace.GramSchmidtOrtho
public import Mathlib.Analysis.LocallyConvex.StrongTopology
public import Mathlib.Analysis.PSeries
public import Mathlib.Analysis.InnerProductSpace.Dual
public import Mathlib.Topology.Baire.LocallyCompactRegular
public import RiemannMasullo.ForMathlib.Analysis.LocallyConvex.SeparatingDual
public import RiemannMasullo.ForMathlib.Analysis.Normed.Module.WeakDual
public import RiemannMasullo.ForMathlib.Topology.Algebra.InfiniteSum.NatInt

/-! Private imports of `RiemannMasullo.Ch04_PeriodicSchauderBases.Sec1`, each as `public import`.

Only `Sec1` imports this file, with a plain `import`, so a line added here rebuilds
only `Sec1`, not every module above it (#6263).
Put a new import of the section here. -/
