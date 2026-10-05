---
layout: page
title: Phase Diagrams
permalink: /phase-diagrams/
---

`eqMode = 'PD'` (and `MnMode`/`MniBMode = 'PD'`) sources major-elementequilibrium compositions from a pre-calculated phase-diagram look-up table instead of the 3-point polynomial fit - see [Configuration Options]({{ '/configuration-options/' | relative_url }}#major-element-equilibrium-source-eqmode).This page covers the table format MIDAS expects and how the shipped example table was generated.

## Required table format

A plain-text file, one row per $(T,P)$ point, arranged on a **square** grid ($N\times N$ points, any $N$) - `create_grid.m` infers $N$ from $\sqrt{\text{number of rows}}$. Required columns:

| Column | Contents |
|---|---|
| 1 | $T$ (K) |
| 2 | $P$ (bar) |
| 7 | MgO in phase A, wt% |
| 8 | MgO in phase B, wt% |
| 9 | MnO in phase A, wt% |
| 10 | MnO in phase B, wt% |

Columns 3-4 (phase volumes) and 5-6 (FeO in phases A/B) are read but not used by the current model; columns 11-12 (CaO in phases A/B), if present, are likewise unused. Any of these can be set to `NaN`/`0` if unavailable.The shipped example (`phasediagrams/Pelite_avg_1.dat`, used by `Example1_Baseline`/`Example3_ThermalBump`/`Example4_ManualPartitioning`/ `Example5_PlanarGeometry`/`Example6_CylindricalGeometry`) follows exactly this 12-column layout on a $120\times120$ grid. If your own table uses a different column arrangement, adapt `create_grid.m`'s `[PGPa,TK,MgOA,MgOB,MnOA,MnOB] = create_grid(PhaseDiagram)` accordingly rather than reshuffling your data to match.

<p align="center">
  <img src="{{ '/assets/figures/phase_diagram_example.png' | relative_url }}" width="100%" alt="Column 7 (MgO in phase A, wt%) of the shipped Pelite_avg_1.dat table, contoured across its full 1-10 GPa, 350-850C range.">
</p>

*Column 7 (MgO in phase A) of the shipped `Pelite_avg_1.dat`, contoured across the table's full range - this is what `create_grid.m`/`eqFun` interpolate into at every timestep. Note this is the table's full extent, not any one example's actual P-T path - compare to the much narrower Trange/Prange window ([Configuration Options]({{ '/configuration-options/' | relative_url }})) an individual run actually samples from within it.*

## Generating one with Perple_X {#generating-one-with-perplex}

The shipped example table was generated with [Perple_X](https://www.perplex.ethz.ch/) (Connolly, 2009) - a Gibbs free-energy minimization code that computes stable mineral assemblages and compositions from a bulk composition and thermodynamic dataset. (MAGEMin - Riel et al., 2022 - is a comparable alternative for the same purpose, not used here.) Any such phase-equilibrium software that can export MgO/MnO compositions of the two phases across a $T$-$P$ grid can produce a compatible table.

For the average-metapelite garnet/biotite example specifically:

- **Chemical system**: MnNCKFMASH (including MnO, Na$_2$O, CaO - these   oxides measurably shift mineral assemblages/compositions relative to a  simpler system for metapelites; Tinkham et al., 2003).
- **Thermodynamic dataset**: hp02ver (Holland & Powell, 1998; Connolly &  Kerrick, 2002).
- **Equation of state**: Stixrude & Bukowinski (1993) (Debye-Mie-Grüneisen).
- **Calculation range**: $10^{-4}$-1 GPa, 623-1123 K.
- **No saturated phase components.**

Solid-solution models used:

| Solid solution | Mineral | Reference |
|---|---|---|
| Bio(TCC) | Biotite | Tajčmanová et al. (2009) |
| Carp | Carpholite | ideal |
| Chl(HP) | Chlorite | Holland et al. (1998) |
| Ctd(HP) | Chloritoid | White et al. (2000) |
| feldspar | K-feldspar and plagioclase | Fuhrman & Lindsley (1988) |
| Gt(GCT) | Garnet | Ganguly et al. (1996) |
| hCrd | Cordierite | ideal |
| melt(HP) | Silicate melt | Holland & Powell (2001); White et al. (2001) |
| Mica(CHA) | White mica | Auzanneau et al. (2010); Coggon & Holland (2002) |
| O(HP) | Olivine | Holland & Powell (1998) |
| Opx(HP) | Orthopyroxene | Holland & Powell (1996) |
| Sp(HP) | Spinel | Holland & Powell (1998) |
| Stlp(M) | Stilpnomelane | Massonne (2008) |
| St(HP) | Staurolite | parameters from Thermo-Calc software |
| Sud | Sudoite | ideal |

MgO, FeO, and MnO look-up tables were extracted from the resulting phase diagram for the diffusion modelling. (The exact average-metapelite bulk composition used is in the project's own technical documentation, not reproduced here.)

## References

- Connolly, J. A. D.: The geodynamic equation of state: What and how, *Geochem. Geophys. Geosystems*, 10, [doi:10.1029/2009GC002540](https://doi.org/10.1029/2009GC002540), 2009.
- Connolly, J. A. D. and Kerrick, D. M.: Metamorphic controls on seismic velocity of subducted oceanic crust at 100-250 km depth, *Earth Planet. Sci. Lett.*, 204, 61-74, [doi:10.1016/S0012-821X(02)00957-3](https://doi.org/10.1016/S0012-821X(02)00957-3), 2002.
- Holland, T. J. B. and Powell, R.: An internally consistent thermodynamic data set for phases of petrological interest, *J. Metamorph. Geol.*, 16, 309-343, [doi:10.1111/j.1525-1314.1998.00140.x](https://doi.org/10.1111/j.1525-1314.1998.00140.x), 1998.
- Riel, N., Kaus, B. J. P., Green, E. C. R., and Berlie, N.: MAGEMin, an Efficient Gibbs Energy Minimizer: Application to Igneous Systems, *Geochem. Geophys. Geosystems*, 23, [doi:10.1029/2022GC010427](https://doi.org/10.1029/2022GC010427), 2022.
- Stixrude, L. and Bukowinski, M. S. T.: Thermodynamic Analysis of the System MgO-FeO-SiO2 at High Pressure and the Structure of the Lowermost Mantle, in: *Evolution of the Earth and Planets*, AGU, 131-141, [doi:10.1029/GM074p0131](https://doi.org/10.1029/GM074p0131), 1993.
- Tinkham, D. K., Zuluaga, C. A., and Stowell, H. H.: Metapelite phase equilibria modeling in MnNCKFMASH, *Am. Mineral.*, 88, 1174, 2003.

(Solid-solution model references are listed in the table above; full
citations for each are in the project's own technical documentation.)
