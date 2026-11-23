module

public import Mathlib.Analysis.LocallyConvex.WithSeminorms
public import Mathlib.Topology.Maps.Proper.CompactlyGenerated
public import Mathlib.Topology.MetricSpace.Polish

/-! # Separability of metrizable Montel spaces -/

public section

open Set Filter TopologicalSpace Bornology

namespace RiemannMasullo


/-- A proper map pulls back Lindelöf sets to Lindelöf sets. -/
theorem isLindelof_preimage_of_isProperMap {X Y : Type*} [TopologicalSpace X]
    [TopologicalSpace Y] {f : X → Y} (hf : IsProperMap f) {s : Set Y} (hs : IsLindelof s) :
    IsLindelof (f ⁻¹' s) := by
  intro l _ _ hl
  have hm : l.map f ≤ 𝓟 s := by rwa [map_le_iff_le_comap, comap_principal]
  obtain ⟨y, hy, hc⟩ := hs hm
  obtain ⟨x, rfl, hx⟩ := hf.clusterPt_of_mapClusterPt hc
  exact ⟨x, hy, hx⟩

/-- A pseudometrizable space with a countable generating family of seminorms and the
Heine–Borel property for von Neumann bounded sets is separable. Indeed the map that
records all the seminorms is proper with Lindelöf target. -/
theorem separableSpace_of_withSeminorms_of_compact_bounded
    {𝕜 E ι : Type*} [NontriviallyNormedField 𝕜] [AddCommGroup E] [Module 𝕜 E]
    [TopologicalSpace E] [PseudoMetrizableSpace E] [Countable ι]
    {p : SeminormFamily 𝕜 E ι} (hp : WithSeminorms p)
    (h : ∀ {s : Set E}, IsClosed s → IsVonNBounded 𝕜 s → IsCompact s) : SeparableSpace E := by
  let F (x : E) := fun i ↦ p i x
  have hF : Continuous F := continuous_pi hp.continuous_seminorm
  have hP : IsProperMap F := by
    refine isProperMap_iff_isCompact_preimage.mpr ⟨hF, fun {K} hK ↦ h (hK.isClosed.preimage hF) ?_⟩
    apply hp.isVonNBounded_iff_seminorm_bddAbove.mpr
    intro i
    refine (hK.bddAbove_image (continuous_apply i).continuousOn).mono ?_
    rintro _ ⟨x, hx, rfl⟩
    exact ⟨F x, hx, rfl⟩
  have : LindelofSpace E := ⟨isLindelof_preimage_of_isProperMap hP isLindelof_univ⟩
  infer_instance

end RiemannMasullo
