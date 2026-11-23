module

public import Mathlib.GroupTheory.ArchimedeanDensely
public import Mathlib.RingTheory.Ideal.Norm.RelNorm
public import Mathlib.Topology.Algebra.Group.OpenMapping
public import Mathlib.Topology.Algebra.Group.Units
public import Mathlib.Topology.Baire.LocallyCompactRegular
public import Mathlib.Topology.Instances.Discrete
public import Mathlib.Topology.Instances.Matrix
public import RiemannMasullo.ForMathlib.NumberTheory.NumberField.Completion.FinitePlace

/-! Private imports of `RiemannMasullo.AppA_AlgebraicNT.Sec2`, each as `public import`.

Only `Sec2` imports this file, with a plain `import`, so a line added here rebuilds
only `Sec2`, not every module above it (#6263).
Put a new import of the section here. -/
