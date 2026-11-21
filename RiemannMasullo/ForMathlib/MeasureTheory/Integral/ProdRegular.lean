module

public import Mathlib.MeasureTheory.Integral.Prod
public import Mathlib.Topology.Compactness.SigmaCompact
public import Mathlib.MeasureTheory.Measure.Regular

@[expose] public section

open Filter MeasureTheory Set Topology
open scoped ENNReal NNReal Pointwise

namespace RiemannMasullo

/-- A finite regular measure is carried by a countable union of compact sets. -/
theorem exists_isSigmaCompact_ae_mem
    {X : Type*} [TopologicalSpace X] [T2Space X] [MeasurableSpace X] [BorelSpace X]
    (ν : Measure X) [IsFiniteMeasure ν] [ν.Regular] :
    ∃ S : Set X, IsSigmaCompact S ∧ ∀ᵐ x ∂ν, x ∈ S := by
  obtain ⟨ε, -, hε, hlim⟩ := exists_seq_strictAnti_tendsto' (zero_lt_one : (0 : ℝ≥0∞) < 1)
  choose K _ hK hSmall using fun n ↦ MeasurableSet.univ.exists_isCompact_sdiff_lt
    (μ := ν) (measure_ne_top ν univ) (hε n).1.ne'
  let S := ⋃ n, K n
  refine ⟨S, ⟨K, hK, rfl⟩, ?_⟩
  rw [ae_iff]
  change ν Sᶜ = 0
  by_contra h
  have ht : ∀ᶠ n in atTop, ε n < ν Sᶜ := hlim (Iio_mem_nhds (pos_iff_ne_zero.mpr h))
  obtain ⟨n, hn⟩ := ht.exists
  have hs : ν Sᶜ ≤ ν (univ \ K n) := measure_mono <|
    fun x hx ↦ ⟨mem_univ x, fun hk ↦ hx (mem_iUnion.mpr ⟨n, hk⟩)⟩
  exact (hs.trans_lt (hSmall n)).not_gt hn

/-- A continuous kernel on a product, set to zero outside a product of σ-compact sets, is
measurable for the product σ-algebra. -/
theorem measurable_indicator_prod_of_isSigmaCompact
    {X Y E : Type*} [TopologicalSpace X] [T2Space X] [MeasurableSpace X] [BorelSpace X]
    [TopologicalSpace Y] [T2Space Y] [MeasurableSpace Y] [BorelSpace Y]
    [TopologicalSpace E] [TopologicalSpace.PseudoMetrizableSpace E] [Zero E] [MeasurableSpace E] [BorelSpace E]
    {k : X × Y → E} (hk : Continuous k) {S : Set X} {T : Set Y}
    (hS : IsSigmaCompact S) (hT : IsSigmaCompact T) :
    Measurable ((S ×ˢ T).indicator k) := by
  classical
  obtain ⟨K, hK, rfl⟩ := hS
  obtain ⟨L, hL, rfl⟩ := hT
  have hRect (n m : ℕ) (U : Set E) (hU : MeasurableSet U) :
      MeasurableSet ((K n ×ˢ L m) ∩ k ⁻¹' U) := by
    let e : K n × L m → X × Y := Prod.map Subtype.val Subtype.val
    have he : MeasurableEmbedding e :=
      (MeasurableEmbedding.subtype_coe (hK n).isClosed.measurableSet).prodMap
        (MeasurableEmbedding.subtype_coe (hL m).isClosed.measurableSet)
    let : CompactSpace (K n) := isCompact_iff_compactSpace.mp (hK n)
    let : CompactSpace (L m) := isCompact_iff_compactSpace.mp (hL m)
    have hc : Continuous (k ∘ e) :=
      hk.comp ((continuous_subtype_val.comp continuous_fst).prodMk
        (continuous_subtype_val.comp continuous_snd))
    have hm : Measurable (k ∘ e) := (HasCompactSupport.of_compactSpace _).measurable_of_prod hc
    have hr : range e = K n ×ˢ L m := by
      ext ⟨x, y⟩
      constructor
      · rintro ⟨⟨a, b⟩, heq⟩
        rw [← heq]
        exact ⟨a.property, b.property⟩
      · intro h
        exact ⟨(⟨x, h.1⟩, ⟨y, h.2⟩), rfl⟩
    have heq : e '' ((k ∘ e) ⁻¹' U) = (K n ×ˢ L m) ∩ k ⁻¹' U := by
      rw [preimage_comp, image_preimage_eq_inter_range, hr, inter_comm]
    rw [← heq]
    exact he.measurableSet_image' (hm hU)
  let R := (⋃ n, K n) ×ˢ (⋃ m, L m)
  have hR : MeasurableSet R := (MeasurableSet.iUnion fun n ↦ (hK n).isClosed.measurableSet).prod
    (MeasurableSet.iUnion fun m ↦ (hL m).isClosed.measurableSet)
  intro U hU
  have hOn : MeasurableSet (R ∩ k ⁻¹' U) := by
    have heq : R ∩ k ⁻¹' U = ⋃ n, ⋃ m, ((K n ×ˢ L m) ∩ k ⁻¹' U) := by
      simp only [R, ← iUnion_prod, iUnion_inter, iUnion_prod']
    rw [heq]
    exact MeasurableSet.iUnion fun n ↦ MeasurableSet.iUnion fun m ↦ hRect n m U hU
  by_cases h : (0 : E) ∈ U
  · convert hOn.union hR.compl using 1
    ext p
    by_cases hp : p ∈ R <;> change ((R.indicator k p ∈ U) ↔ _)
    all_goals simp [hp, h]
  · convert hOn using 1
    ext p
    by_cases hp : p ∈ R <;> change ((R.indicator k p ∈ U) ↔ _)
    all_goals simp [hp, h]

/-- Haar averaging of a translated nonnegative weight can be computed by integrating
over Haar first. A σ-compact carrier for the weight suffices for Tonelli. -/
theorem lintegral_lintegral_mul_translate
    {H : Type*} [CommGroup H] [TopologicalSpace H] [IsTopologicalGroup H] [T2Space H]
    [LocallyCompactSpace H] [MeasurableSpace H] [BorelSpace H]
    (η τ : Measure H) [η.IsHaarMeasure] [IsFiniteMeasure τ] [τ.Regular]
    {w v : H → ℝ≥0} (hw : Continuous w) (hv : Continuous v)
    {U : Set H} (hU : IsSigmaCompact U) (hW : Function.support w ⊆ U) :
    (∫⁻ a, ∫⁻ b, (w (a * b) : ℝ≥0∞) * (v b : ℝ≥0∞) ∂τ ∂η) =
      (∫⁻ a, (w a : ℝ≥0∞) ∂η) * (∫⁻ b, (v b : ℝ≥0∞) ∂τ) := by
  obtain ⟨S, hS, hτ⟩ := exists_isSigmaCompact_ae_mem τ
  obtain ⟨K, hK, rfl⟩ := hU
  obtain ⟨L, hL, rfl⟩ := hS
  let T : Set H := ⋃ p : ℕ × ℕ, K p.1 * (L p.2)⁻¹
  have hC (p : ℕ × ℕ) : IsCompact (K p.1 * (L p.2)⁻¹) := (hK p.1).mul (hL p.2).inv
  have hTm : MeasurableSet T := MeasurableSet.iUnion fun p ↦ (hC p).isClosed.measurableSet
  obtain ⟨B, hB, hBT⟩ := isSigmaCompact_iUnion_of_isCompact _ hC
  let : SigmaFinite (η.restrict T) := by
    refine ⟨⟨⟨fun n ↦ B n ∪ Tᶜ, fun _ ↦ trivial, fun n ↦ ?_, ?_⟩⟩⟩
    · rw [Measure.restrict_apply ((hB n).isClosed.measurableSet.union hTm.compl),
        union_inter_distrib_right, compl_inter_self, union_empty]
      exact (measure_mono inter_subset_left).trans_lt (hB n).measure_lt_top
    · rw [← iUnion_union, hBT]
      exact union_compl_self T
  have hzero (a b : H) (ha : a ∉ T) (hb : b ∈ ⋃ n, L n) : w (a * b) = 0 := by
    by_contra hne
    obtain ⟨n, hn⟩ := mem_iUnion.mp (hW hne)
    obtain ⟨m, hm⟩ := mem_iUnion.mp hb
    exact ha (mem_iUnion.mpr ⟨(n, m), a * b, hn, b⁻¹, by simpa, mul_inv_cancel_right a b⟩)
  let k (p : H × H) : ℝ≥0∞ := ((w (p.1 * p.2) * v p.2 : ℝ≥0) : ℝ≥0∞)
  have hk : Continuous k := ENNReal.continuous_coe.comp
    ((hw.comp (continuous_fst.mul continuous_snd)).mul (hv.comp continuous_snd))
  let q := (T ×ˢ (⋃ n, L n)).indicator k
  have hq : Measurable q :=
    measurable_indicator_prod_of_isSigmaCompact hk ⟨B, hB, hBT⟩ ⟨L, hL, rfl⟩
  have hrow (a : H) (ha : a ∈ T) :
      (∫⁻ b, q (a, b) ∂τ) = ∫⁻ b, (w (a * b) : ℝ≥0∞) * (v b : ℝ≥0∞) ∂τ := by
    apply lintegral_congr_ae
    filter_upwards [hτ] with b hb
    simpa only [q, k, ENNReal.coe_mul] using
      (indicator_of_mem (s := T ×ˢ (⋃ n, L n)) (a := (a, b)) ⟨ha, hb⟩ k)
  have hcol (b : H) (hb : b ∈ ⋃ n, L n) :
      (∫⁻ a in T, q (a, b) ∂η) = ∫⁻ a, (w (a * b) : ℝ≥0∞) * (v b : ℝ≥0∞) ∂η := by
    rw [← setLIntegral_eq_of_support_subset (s := T)
      (f := fun a ↦ (w (a * b) : ℝ≥0∞) * (v b : ℝ≥0∞)) (fun a ha ↦ by
        by_contra h
        exact ha (by simp [hzero a b h hb]))]
    apply setLIntegral_congr_fun hTm
    intro a ha
    simpa only [q, k, ENNReal.coe_mul] using
      (indicator_of_mem (s := T ×ˢ (⋃ n, L n)) (a := (a, b)) ⟨ha, hb⟩ k)
  calc
    _ = ∫⁻ a in T, ∫⁻ b, (w (a * b) : ℝ≥0∞) * (v b : ℝ≥0∞) ∂τ ∂η := by
      symm
      apply setLIntegral_eq_of_support_subset
      intro a ha
      by_contra h
      exact ha ((lintegral_congr_ae (hτ.mono fun b hb ↦ by simp [hzero a b h hb])).trans
        (lintegral_zero))
    _ = ∫⁻ a in T, ∫⁻ b, q (a, b) ∂τ ∂η :=
      setLIntegral_congr_fun hTm fun a ha ↦ (hrow a ha).symm
    _ = ∫⁻ b, ∫⁻ a in T, q (a, b) ∂η ∂τ :=
      lintegral_lintegral_swap hq.aemeasurable
    _ = ∫⁻ b, ∫⁻ a, (w (a * b) : ℝ≥0∞) * (v b : ℝ≥0∞) ∂η ∂τ :=
      lintegral_congr_ae (hτ.mono hcol)
    _ = _ := by
      have hm : Measurable (fun a : H ↦ (w a : ℝ≥0∞)) :=
        (ENNReal.continuous_coe.comp hw).measurable
      have hinner (b : H) : (∫⁻ a, (w (a * b) : ℝ≥0∞) * (v b : ℝ≥0∞) ∂η) =
          (∫⁻ a, (w a : ℝ≥0∞) ∂η) * (v b : ℝ≥0∞) := by
        have hmb : Measurable (fun a : H ↦ (w (a * b) : ℝ≥0∞)) :=
          hm.comp (continuous_id.mul continuous_const).measurable
        rw [lintegral_mul_const _ hmb]
        rw [lintegral_mul_right_eq_self (fun a ↦ (w a : ℝ≥0∞)) b]
      simp_rw [hinner]
      exact lintegral_const_mul _ (ENNReal.continuous_coe.comp hv).measurable

end RiemannMasullo
