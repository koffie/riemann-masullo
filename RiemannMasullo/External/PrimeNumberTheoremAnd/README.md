# PrimeNumberTheoremAnd

- **Source**: https://github.com/AlexKontorovich/PrimeNumberTheoremAnd
- **Pinned commit**: [`a4fb6989b07e9c76b511807ae93e33e25b820e9b`](https://github.com/AlexKontorovich/PrimeNumberTheoremAnd/tree/a4fb6989b07e9c76b511807ae93e33e25b820e9b) (14 November 2026; upstream builds with Lean v4.35.0)
- **License**: Apache-2.0, [`LICENSE`](LICENSE) (unmodified copy)
- **Authors**: the PrimeNumberTheoremAnd contributors. By the upstream git history of
  `StrongPNT.lean`, the vendored part is due mainly to Preston Tranbarger, Preston Walker,
  Maksym Radziwill and Alex Kontorovich; upstream notes that the part from `cauchy_formula_deriv`
  on was upstreamed from <https://github.com/math-inc/strongpnt>.
- **Intended use**: Appendix B.6 (zero-free regions, bounds for logarithmic derivatives and for
  reciprocals of finite Hecke L-functions).

## Files taken

| Here | Upstream | What |
|---|---|---|
| [`StrongPNT.lean`](StrongPNT.lean) | `PrimeNumberTheoremAnd/StrongPNT.lean`, lines 34–1230 | the general complex analysis at the start of the file, before it turns to ζ |

Main declarations, all in namespace `RiemannMasullo.External.PrimeNumberTheoremAnd`:

- `borelCaratheodory'`, `DerivativeBound`, `BorelCaratheodoryDeriv`: Borel–Carathéodory for `f`
  and `f'` on discs centred at 0, with `f 0 = 0`.
- `LogOfAnalyticFunction`, `LogOfAnalyticFunction'`: an analytic logarithm of a nonvanishing
  analytic function on a disc.
- `SetOfZeros`, `ZeroFactor`, `ZeroFactorization`, `Cf`, `BlaschkeB` and their lemmas:
  dividing out the zeros in a disc by a Blaschke product.
- `ZerosBound`: Jensen-type bound, the number of zeros (with multiplicity) in the disc of radius
  `r` is at most `log B / log (R / r)` when `f 0 = 1` and `‖f‖ ≤ B` on the disc of radius `R`.
- `FinalBound` (Landau's lemma): `‖f'(z)/f(z) - ∑_{|ρ| ≤ r} m(ρ)/(z - ρ)‖ ≤ C · log B` for
  `|z| ≤ r'`, `z` away from the zeros, with `C` depending only on the radii.

Nothing that mentions ζ is taken. The rest of `StrongPNT.lean` (the zero-free region and
logarithmic-derivative bounds for ζ) is the template for Appendix B.6 but has to be adapted to
Hecke L-functions rather than vendored; see the plan in the pull request that brought this in.

See [`MODIFICATIONS.md`](MODIFICATIONS.md) for the changes and [`../README.md`](../README.md)
for the vendoring convention.
