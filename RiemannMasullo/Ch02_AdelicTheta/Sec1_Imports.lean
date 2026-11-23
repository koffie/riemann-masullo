module

public import Mathlib.LinearAlgebra.PiTensorProduct.Generators
public import Mathlib.Algebra.BigOperators.Fin
public import Mathlib.Algebra.Group.Pointwise.Set.Scalar
public import Mathlib.Analysis.InnerProductSpace.l2Space
public import RiemannMasullo.External.GaussianField.HermiteFunctions
public import Mathlib.Analysis.Complex.RealDeriv
public import Mathlib.Data.Nat.Pairing
public import Mathlib.MeasureTheory.Integral.Pi
public import Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace
public import Mathlib.Analysis.PSeries
public import Mathlib.Data.List.FinRange
public import Mathlib.Data.List.OfFn
public import Mathlib.Data.Set.FiniteExhaustion
public import RiemannMasullo.ForMathlib.Analysis.Calculus.FDeriv.Symmetric
public import RiemannMasullo.ForMathlib.Analysis.Distribution.SchwartzSpace.Complete
public import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
public import Mathlib.Analysis.Distribution.SchwartzSpace.Deriv
public import Mathlib.Topology.Instances.RealVectorSpace
public import RiemannMasullo.ForMathlib.Topology.Algebra.PontryaginDual.Real
public import Mathlib.Analysis.LocallyConvex.WeakDual
public import Mathlib.Analysis.LocallyConvex.AbsConvex
public import Mathlib.Analysis.LocallyConvex.Polar
public import Mathlib.Analysis.LocallyConvex.Separation
public import Mathlib.Analysis.LocallyConvex.StrongTopology
public import Mathlib.Analysis.RCLike.Lemmas
public import Mathlib.Analysis.SpecificLimits.Basic
public import Mathlib.Topology.Algebra.InfiniteSum.NatInt
public import Mathlib.Topology.Algebra.Module.Spaces.WeakDual
public import RiemannMasullo.ForMathlib.Analysis.Distribution.SchwartzSpace.Montel
public import RiemannMasullo.ForMathlib.Analysis.LocallyConvex.StrongBidual
public import RiemannMasullo.ForMathlib.Analysis.LocallyConvex.HahnBanach
public import RiemannMasullo.ForMathlib.Analysis.Normed.Module.Seminorm.DirectSum
public import RiemannMasullo.ForMathlib.Analysis.InnerProductSpace.PiL2
public import RiemannMasullo.ForMathlib.NumberTheory.NumberField.Completion.FinitePlace
public import Mathlib.Analysis.Fourier.FiniteAbelian.PontryaginDuality
public import Mathlib.Analysis.Normed.Group.Ultra
public import Mathlib.Topology.Algebra.Nonarchimedean.TotallyDisconnected
public import Mathlib.Topology.Connected.LocallyConnected
public import Mathlib.Topology.Compactness.Bases
public import Mathlib.Topology.LocallyConstant.Algebra
public import RiemannMasullo.ForMathlib.Topology.LocallyConstant.CompactSupport

/-! Private imports of `RiemannMasullo.Ch02_AdelicTheta.Sec1`, each as `public import`.

Only `Sec1` imports this file, with a plain `import`, so a line added here rebuilds
only `Sec1`, not every module above it (#6263).
Put a new import of the section here. -/
