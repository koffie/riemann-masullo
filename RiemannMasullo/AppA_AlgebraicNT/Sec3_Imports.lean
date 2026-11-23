module

public import RiemannMasullo.AppA_AlgebraicNT.Sec2  -- for the diagonal adelic basis
public import RiemannMasullo.AppD_SchwartzBruhat.Sec1b  -- for duality of a quotient and its annihilator
public import Mathlib.Analysis.SpecialFunctions.Complex.Circle
public import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
public import Mathlib.Analysis.SpecialFunctions.Gaussian.FourierTransform
public import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
public import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
public import Mathlib.LinearAlgebra.Countable
public import Mathlib.LinearAlgebra.TensorProduct.Basis
public import Mathlib.MeasureTheory.Integral.Pi
public import Mathlib.MeasureTheory.Measure.Haar.DistribChar
public import Mathlib.MeasureTheory.Measure.Haar.Extension
public import Mathlib.MeasureTheory.Measure.Haar.Quotient
public import Mathlib.MeasureTheory.Measure.Haar.Unique
public import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
public import Mathlib.NumberTheory.NumberField.Discriminant.Basic
public import Mathlib.NumberTheory.NumberField.Discriminant.Different
public import Mathlib.NumberTheory.Padics.ProperSpace
public import Mathlib.Topology.Algebra.Group.OpenMapping
public import Mathlib.Topology.Algebra.IsOpenUnits
public import Mathlib.Topology.Baire.LocallyCompactRegular
public import Mathlib.Topology.Maps.Proper.CompactlyGenerated
public import RiemannMasullo.ForMathlib.Analysis.Fourier.LpSpace
public import RiemannMasullo.ForMathlib.MeasureTheory.Group.Arithmetic
public import RiemannMasullo.ForMathlib.MeasureTheory.Measure.Haar.Extension
public import RiemannMasullo.ForMathlib.MeasureTheory.Measure.Haar.Unique
public import RiemannMasullo.ForMathlib.MeasureTheory.Measure.Haar.Units
public import RiemannMasullo.ForMathlib.NumberTheory.NumberField.Completion.FinitePlace
public import RiemannMasullo.ForMathlib.RingTheory.Trace.Defs
public import RiemannMasullo.ForMathlib.Topology.Algebra.PontryaginDual.Real

/-! Private imports of `RiemannMasullo.AppA_AlgebraicNT.Sec3`, each as `public import`.

Only `Sec3` imports this file, with a plain `import`, so a line added here rebuilds
only `Sec3`, not every module above it (#6263).
Put a new import of the section here. -/
