module

public import Mathlib.MeasureTheory.Measure.Regular
public import Mathlib.MeasureTheory.Measure.WithDensity
public import Mathlib.Topology.Compactness.SigmaCompact
public import Mathlib.Topology.ContinuousMap.CompactlySupported
import Mathlib.Topology.UrysohnsLemma

@[expose] public section

open MeasureTheory Set
open scoped ENNReal

namespace RiemannMasullo

/-- A measure dominated by a finite regular measure on a Hausdorff Borel space is regular. -/
theorem regular_of_le_finite_regular {X : Type*} [TopologicalSpace X] [T2Space X]
    [MeasurableSpace X] [BorelSpace X] (μ ν : Measure X) [IsFiniteMeasure ν]
    [ν.Regular] (h : μ ≤ ν) : μ.Regular := by
  have : IsFiniteMeasure μ := isFiniteMeasure_of_le ν h
  have : μ.InnerRegularCompactLTTop := by
    constructor
    intro A hA r hr
    have he : μ A - r ≠ 0 := ne_of_gt (tsub_pos_of_lt hr)
    obtain ⟨K, hKA, hK, hsmall⟩ :=
      hA.1.exists_isCompact_sdiff_lt (μ := ν) (measure_ne_top ν A) he
    refine ⟨K, hKA, hK, ?_⟩
    have hd : μ (A \ K) < μ A - r := lt_of_le_of_lt (h (A \ K)) hsmall
    have hsum : μ A = μ K + μ (A \ K) := by
      simpa [union_eq_right.mpr hKA] using
        (measure_add_sdiff (μ := μ) hK.measurableSet.nullMeasurableSet A).symm
    rw [lt_tsub_iff_right] at hd
    rw [hsum] at hd
    exact (ENNReal.add_lt_add_iff_right (measure_ne_top μ (A \ K))).mp
      (by simpa [add_comm] using hd)
  infer_instance


section CompactTests

open scoped CompactlySupported ENNReal NNReal

variable {X : Type*} [TopologicalSpace X] [T2Space X] [LocallyCompactSpace X]
  [MeasurableSpace X] [BorelSpace X]

/-- A bounded density with a σ-compact carrier over a regular measure is inner regular. -/
theorem innerRegular_withDensity_of_le_of_isSigmaCompact
    (η : Measure X) [η.Regular] {w : X → ℝ≥0∞} {C : ℝ≥0}
    (hBound : ∀ x, w x ≤ C) {S : Set X} (hS : IsSigmaCompact S)
    (hW : Function.support w ⊆ S) : (η.withDensity w).InnerRegular := by
  let ν := η.withDensity w
  obtain ⟨K, hK, rfl⟩ := hS
  let L := accumulate K
  have hL (n : ℕ) : IsCompact (L n) := isCompact_accumulate hK n
  have hLm (n : ℕ) : MeasurableSet (L n) := (hL n).isClosed.measurableSet
  have hUnion : (⋃ n, L n) = ⋃ n, K n := iUnion_accumulate
  have hSm : MeasurableSet (⋃ n, L n) := MeasurableSet.iUnion hLm
  have hSupp : ∀ᵐ x ∂ν, x ∈ ⋃ n, L n := by
    rw [ae_iff]
    change ν (⋃ n, L n)ᶜ = 0
    rw [withDensity_apply _ hSm.compl]
    refine (lintegral_congr_ae ?_).trans lintegral_zero
    filter_upwards [ae_restrict_mem hSm.compl] with x hx
    by_contra hn
    exact hx (hUnion ▸ hW hn)
  have hRestr (n : ℕ) : (ν.restrict (L n)).InnerRegular := by
    let : Fact (η (L n) < ∞) := ⟨(hL n).measure_lt_top⟩
    let : (η.restrict (L n)).Regular :=
      Measure.Regular.restrict_of_measure_ne_top (hL n).measure_lt_top.ne
    let Cη := C • η.restrict (L n)
    let : Cη.Regular := inferInstanceAs (C • η.restrict (L n)).Regular
    have hDom : ν.restrict (L n) ≤ Cη := by
      rw [show ν = η.withDensity w from rfl, restrict_withDensity (hLm n),
        show Cη = (C : ℝ≥0∞) • η.restrict (L n) from rfl, ← withDensity_const]
      exact withDensity_mono (.of_forall hBound)
    let : IsFiniteMeasure (ν.restrict (L n)) := isFiniteMeasure_of_le Cη hDom
    let := regular_of_le_finite_regular _ Cη hDom
    infer_instance
  constructor
  intro s hs r hr
  have hEq : ν s = ⨆ n, ν (s ∩ L n) := by
    conv_lhs => rw [← Measure.restrict_eq_self_of_ae_mem hSupp, Measure.restrict_apply hs]
    rw [inter_iUnion, (monotone_const.inter monotone_accumulate).measure_iUnion]
  rw [hEq] at hr
  obtain ⟨n, hn⟩ := lt_iSup_iff.mp hr
  let := hRestr n
  rw [← Measure.restrict_apply hs] at hn
  obtain ⟨A, hA, hAc, hAn⟩ := hs.exists_lt_isCompact hn
  exact ⟨A, hA, hAc, hAn.trans_le (Measure.restrict_apply_le _ _)⟩

/-- Nonnegative compactly supported continuous tests determine inner regular measures
when one of the two measures is locally finite. -/
theorem measure_eq_of_lintegral_eq_on_compactlySupported_nnreal
    (μ ν : Measure X) [μ.InnerRegular] [ν.InnerRegular] [IsLocallyFiniteMeasure ν]
    (h : ∀ f : C_c(X, ℝ≥0), (∫⁻ x, (f x : ℝ≥0∞) ∂μ) = ∫⁻ x, (f x : ℝ≥0∞) ∂ν) :
    μ = ν := by
  have hle (m n : Measure X) [n.InnerRegular] [IsLocallyFiniteMeasure n]
      (h' : ∀ f : C_c(X, ℝ≥0), (∫⁻ x, (f x : ℝ≥0∞) ∂m) ≤
        ∫⁻ x, (f x : ℝ≥0∞) ∂n)
      {K : Set X} (hK : IsCompact K) : m K ≤ n K := by
    by_contra! hLt
    obtain ⟨V, hKV, hV, hVn⟩ := hK.exists_isOpen_lt_of_lt (μ := n) (m K) hLt
    obtain ⟨f, hf, hfc, hfs, h01⟩ :=
      exists_continuousMap_one_of_isCompact_subset_isOpen hK hV hKV
    let u := (⟨f, hfc⟩ : C_c(X, ℝ)).nnrealPart
    have huK (x : X) (hx : x ∈ K) : (u x : ℝ≥0∞) = 1 := by
      change ENNReal.ofReal (f x) = 1
      exact ENNReal.ofReal_eq_one.mpr (hf hx)
    have huV (x : X) : (u x : ℝ≥0∞) ≤ V.indicator (fun _ ↦ (1 : ℝ≥0∞)) x := by
      by_cases hx : x ∈ V
      · rw [indicator_of_mem hx]
        change ENNReal.ofReal (f x) ≤ 1
        exact ENNReal.ofReal_le_one.mpr (h01 x).2
      · have hz := image_eq_zero_of_notMem_tsupport (fun hx' ↦ hx (hfs hx'))
        rw [indicator_of_notMem hx]
        change ENNReal.ofReal (f x) ≤ 0
        simp [hz]
    have hLow : m K ≤ ∫⁻ x, (u x : ℝ≥0∞) ∂m := by
      rw [← setLIntegral_one]
      refine (setLIntegral_congr_fun hK.isClosed.measurableSet
        (fun x hx ↦ (huK x hx).symm)).le.trans (setLIntegral_le_lintegral _ _)
    have hHigh : (∫⁻ x, (u x : ℝ≥0∞) ∂n) ≤ n V :=
      (lintegral_mono huV).trans_eq (by simpa using lintegral_indicator_const (μ := n) hV.measurableSet 1)
    exact hVn.not_ge (hLow.trans ((h' u).trans hHigh))
  have hμν {K : Set X} (hK : IsCompact K) : μ K ≤ ν K := hle μ ν (fun f ↦ (h f).le) hK
  let : IsFiniteMeasureOnCompacts μ :=
    ⟨fun K hK ↦ (hμν hK).trans_lt hK.measure_lt_top⟩
  have hνμ {K : Set X} (hK : IsCompact K) : ν K ≤ μ K := hle ν μ (fun f ↦ (h f).ge) hK
  ext1 s hs
  rw [hs.measure_eq_iSup_isCompact μ, hs.measure_eq_iSup_isCompact ν]
  exact iSup_congr fun K ↦ iSup_congr fun _ ↦ iSup_congr fun hK ↦
    le_antisymm (hμν hK) (hνμ hK)

end CompactTests

end RiemannMasullo
