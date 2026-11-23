module

public import Mathlib.MeasureTheory.Constructions.Polish.Basic
public import Mathlib.Topology.Baire.BaireMeasurable
public import Mathlib.Topology.Baire.LocallyCompactRegular

/-! # Automatic continuity of orbits on Polish spaces -/

public section

open Filter Function Set TopologicalSpace Topology

namespace RiemannMasullo

/-- A Borel map to a second-countable space becomes continuous on restriction to a residual set. -/
theorem exists_residual_continuousOn_of_measurable
    {X Y : Type*} [TopologicalSpace X] [MeasurableSpace X] [BorelSpace X]
    [TopologicalSpace Y] [SecondCountableTopology Y] [MeasurableSpace Y] [OpensMeasurableSpace Y]
    {f : X → Y} (hf : Measurable f) : ∃ s ∈ residual X, ContinuousOn f s := by
  classical
  choose U hU hEq using fun V : countableBasis Y ↦
    (hf (isOpen_of_mem_countableBasis V.2).measurableSet).residualEq_isOpen
  let s := {x : X | ∀ V : countableBasis Y, f x ∈ V.1 ↔ x ∈ U V}
  have hs : s ∈ residual X := eventually_countable_forall.2 fun V ↦ (hEq V).mem_iff
  refine ⟨s, hs, (isBasis_countableBasis Y).continuousOn_iff.2 ?_⟩
  intro V hV
  refine ⟨U ⟨V, hV⟩, hU _, ?_⟩
  ext x
  exact and_congr_left fun hx ↦ hx ⟨V, hV⟩

/-- An equivariant map from a sequential Baire group which is continuous on a residual set
is continuous everywhere. Only continuity of each fixed group element on the target is needed. -/
theorem continuous_equivariant_of_residual_continuousOn
    {H E : Type*} [Group H] [TopologicalSpace H] [IsTopologicalGroup H]
    [SequentialSpace H] [BaireSpace H] [TopologicalSpace E]
    (u : H → E) (T : H → E → E) (hT : ∀ b, Continuous (T b))
    (hu : ∀ b h, T b (u h) = u (b * h)) {s : Set H} (hs : s ∈ residual H)
    (hus : ContinuousOn u s) : Continuous u := by
  apply SeqContinuous.continuous
  intro g h hg
  have hright (k : H) : ∀ᶠ b in residual H, b * k ∈ s :=
    tendsto_residual_of_isOpenMap (continuous_mul_const k) (isOpenMap_mul_right k) hs
  have hseq : ∀ᶠ b in residual H, ∀ n, b * g n ∈ s :=
    eventually_countable_forall.2 fun n ↦ hright (g n)
  obtain ⟨b, hb, hbg⟩ := (dense_of_mem_residual ((hright h).and hseq)).nonempty
  have hlim : Tendsto (fun n ↦ b * g n) atTop (𝓝[s] (b * h)) :=
    tendsto_nhdsWithin_iff.2 ⟨hg.const_mul b, Eventually.of_forall hbg⟩
  have htranslate := ((hT b⁻¹).continuousAt (x := u (b * h))).tendsto.comp
    ((hus _ hb).tendsto.comp hlim)
  simpa only [Function.comp_def, hu, inv_mul_cancel_left] using htranslate

/-- Continuous injective observations into a Hausdorff space detect continuity of an equivariant
map to a Polish space. Lusin–Souslin gives measurability, not a topological embedding. -/
theorem continuous_equivariant_of_continuous_injective_comp
    {H E Y : Type*} [Group H] [TopologicalSpace H] [IsTopologicalGroup H]
    [SequentialSpace H] [BaireSpace H] [TopologicalSpace E] [PolishSpace E]
    [TopologicalSpace Y] [T2Space Y]
    (u : H → E) (T : H → E → E) (hT : ∀ b, Continuous (T b))
    (hu : ∀ b h, T b (u h) = u (b * h))
    (j : E → Y) (hj : Continuous j) (hinj : Injective j) (hc : Continuous (j ∘ u)) :
    Continuous u := by
  borelize H E Y
  have hm : Measurable u := (hj.measurableEmbedding hinj).measurable_comp_iff.mp hc.measurable
  obtain ⟨s, hs, hus⟩ := exists_residual_continuousOn_of_measurable hm
  exact continuous_equivariant_of_residual_continuousOn u T hT hu hs hus

end RiemannMasullo
