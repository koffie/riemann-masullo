module

public import Mathlib.Analysis.Normed.Field.ProperSpace
public import Mathlib.LinearAlgebra.Dimension.RankNullity
public import Mathlib.NumberTheory.NumberField.CanonicalEmbedding.NormLeOne
public import Mathlib.NumberTheory.NumberField.ClassNumber
public import Mathlib.RingTheory.ClassGroup.ExtendedHom
public import Mathlib.RingTheory.DedekindDomain.SelmerGroup
public import Mathlib.Topology.Algebra.Group.Units
public import Mathlib.Topology.Algebra.IsOpenUnits
public import Mathlib.Topology.Algebra.Valued.LocallyCompact
public import RiemannMasullo.ForMathlib.NumberTheory.NumberField.Completion.FinitePlace
public import RiemannMasullo.ForMathlib.RingTheory.PicardGroup

/-! Private imports of `RiemannMasullo.AppA_AlgebraicNT.Sec1`, each as `public import`.

Only `Sec1` imports this file, with a plain `import`, so a line added here rebuilds
only `Sec1`, not every module above it (#6263).
Put a new import of the section here. -/
