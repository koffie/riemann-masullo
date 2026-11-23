module

public import Mathlib.Algebra.Module.ZLattice.Summable
public import Mathlib.Analysis.Calculus.SmoothSeries
public import Mathlib.Analysis.Normed.Group.FunctionSeries
public import Mathlib.Topology.Algebra.Nonarchimedean.TotallyDisconnected
public import RiemannMasullo.ForMathlib.NumberTheory.NumberField.Completion.FinitePlace

/-! Private imports of `RiemannMasullo.Ch02_AdelicTheta.Sec3`, each as `public import`.

Only `Sec3` imports this file, with a plain `import`, so a line added here rebuilds
only `Sec3`, not every module above it (#6263).
Put a new import of the section here. -/
