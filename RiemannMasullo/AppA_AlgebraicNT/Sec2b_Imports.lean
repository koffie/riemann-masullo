module

public import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv
public import Mathlib.Analysis.InnerProductSpace.Calculus
public import Mathlib.NumberTheory.NumberField.CanonicalEmbedding.PolarCoord
public import Mathlib.NumberTheory.Padics.HeightOneSpectrum
public import Mathlib.Topology.Algebra.Group.Units
public import Mathlib.Topology.Baire.LocallyCompactRegular
public import Mathlib.Topology.MetricSpace.ProperSpace.Lemmas
public import RiemannMasullo.ForMathlib.Analysis.SpecialFunctions.Pow.Complex
public import RiemannMasullo.ForMathlib.NumberTheory.NumberField.Completion.FinitePlace

/-! Private imports of `RiemannMasullo.AppA_AlgebraicNT.Sec2b`, each as `public import`.

Only `Sec2b` imports this file, with a plain `import`, so a line added here rebuilds
only `Sec2b`, not every module above it (#6263).
Put a new import of the section here. -/
