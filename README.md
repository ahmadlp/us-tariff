# U.S. Tariff Scenarios: Welfare Effects of Predetermined Tariff Policies

This MATLAB package computes the general equilibrium welfare effects of predetermined U.S. tariff scenarios using the multi-country, multi-sector CES trade model of [Lashkaripour (2021)](#references). Unlike the companion `+tariffwar` package -- which solves for Nash equilibrium tariffs where every country simultaneously optimizes -- this package takes tariff rates as exogenous policy inputs and solves only for the resulting equilibrium wages and incomes. Sixty-eight scenarios are implemented, covering broad tariff regimes (Liberation Day reciprocal tariffs, uniform tariffs, the optimal unilateral tariff) and bilateral tariff hikes on seven major U.S. trading partners, each under no-retaliation and reciprocal-retaliation assumptions. The package supports three international trade datasets covering 44 to 135 countries, 16 to 154 sectors, and years 2000--2022, with eight alternative sources of sectoral trade elasticities.

**Interactive dashboard:** An accompanying web dashboard is available at [tradewar.app](https://tradewar.app) for exploring the results without running any code.

---

## Quick Start

```matlab
addpath('..')                                           % add parent of +ustariff to MATLAB path
ustariff.main                                           % full grid: all datasets x years x elasticities

% Or run a single scenario
spec = ustariff.scenario.uniform(0.10);
ustariff.pipeline.run({spec}, 'icio', 2022, 'IS')      % single dataset-year-elasticity
```

**Output:** `results/results.csv` with country-level welfare changes (percent and dollars).

**Prerequisites:** MATLAB R2016b or later with the Optimization Toolbox. Prebuilt `.mat` files from `+tariffwar/mat/` are required; see [Prerequisites](#prerequisites).

---

## Methodology

The analysis implements the sufficient-statistics framework of **Proposition 2** in Lashkaripour (2021). In the original framework, all *N* countries simultaneously optimize tariffs, yielding a 3*N*-equation Nash equilibrium. This package adapts the framework for policy counterfactuals by fixing tariffs at exogenous values and solving for the resulting equilibrium.

### Counterfactual equations (2*N* system)

For all predetermined tariff scenarios, the solver finds the root of a system of 2*N* equations in 2*N* unknowns, stacked as *X* = [*w&#x302;*; *Y&#x302;*], where *w&#x302;* and *Y&#x302;* denote proportional changes in wages and incomes (hat algebra). Tariffs enter exogenously through the tariff hat *t&#x302;_jik* = (1 + *t*^cf_jik) / (1 + *t*^factual_jik).

**Equation 6 -- Market clearing (wage income).** Total export revenue of country *i*, net of tariffs collected by importers, equals its wage bill:

> *w&#x302;_i* &middot; *R_i* = &sum;_j &sum;_k &lambda;'_jik &middot; *e_ik* &middot; *Y&#x302;_j* &middot; *Y_j* / (1 + *t*^cf_jik)

where the updated bilateral trade share is:

> &lambda;'_jik = &lambda;_jik &middot; (*t&#x302;_jik* &middot; *w&#x302;_i*)^(1 - &sigma;_k) / &sum;_m &lambda;_mjk &middot; (*t&#x302;_mjk* &middot; *w&#x302;_m*)^(1 - &sigma;_k)

The last equation (*i* = *N*) is replaced by a world-wage normalization: &sum;_i *R_i* (*w&#x302;_i* - 1) = 0.

**Equation 7 -- Budget constraint (national income).** National income equals wage income plus tariff revenue:

> *Y&#x302;_i* &middot; *Y_i* = *w&#x302;_i* &middot; *R_i* + &sum;_j &sum;_k [*t*^cf_jik / (1 + *t*^cf_jik)] &middot; &lambda;'_jik &middot; *e_ik* &middot; *Y&#x302;_j* &middot; *Y_j*

This is identical to the balanced-trade system in `+tariffwar`, except that the tariff hat *t&#x302;_jik* enters the CES price index through AUX0, reflecting the exogenous tariff change:

```
AUX0 = lambda_jik3D .* ((tjik_h3D .* wi_h3D) .^ (1 - sigma_k3D))
```

### Optimal U.S. tariff (2*N* + 1 system)

For the optimal unilateral tariff scenario, the system adds a single equation -- **Equation 14** -- for the U.S. only. The system has 2*N* + 1 unknowns: *N* wages, *N* incomes, and 1 scalar U.S. tariff rate *t*_US.

**Equation 14 -- Optimal tariff (first-order condition).** The U.S. tariff equates the marginal benefit of terms-of-trade improvement to the marginal cost of trade distortion:

> *t*_US = 1 / &sum;_k (&sigma;_k - 1) &middot; &omega;_US,k

where &sigma;_k is the CES elasticity of substitution in sector *k* and &omega;_US,k is a trade-weighted inverse supply elasticity measuring how foreign exporters' trade shares respond to the U.S. tariff. The denominator is floored at 1 to cap the optimal rate at 100%.

All other countries keep their factual tariffs. Foreign countries do **not** optimize; this is a unilateral policy exercise.

### Welfare computation

Welfare changes are computed via hat algebra. The real-income change for country *i* is:

> *W&#x302;_i* = *Y&#x302;_i* / *P&#x302;_i*

where the aggregate price index *P&#x302;_i* is a Cobb-Douglas aggregate of sectoral CES price indices:

> *P&#x302;_i* = &prod;_k [&sum;_j &lambda;_jik &middot; (*t&#x302;_jik* &middot; *w&#x302;_j*)^(1 - &sigma;_k)]^(*e_ik* / (1 - &sigma;_k))

The welfare gain is reported as 100 &middot; (*W&#x302;_i* - 1) percent.

### Rest-of-World (ROW) tariff aggregation

Datasets aggregate some countries into a "Rest of World" composite. The U.S. tariff on ROW imports is a trade-weighted average over all 195 countries in the Liberation Day schedule that are not individually present in the dataset:

> *t*_ROW = &sum;_c *t*_c &middot; *X*_c,US / &sum;_c *X*_c,US

where *X*_c,US is country *c*'s bilateral exports to the United States, drawn from the 195 &times; 194 CEPII trade matrix.

---

## Scenarios

The package implements **68 scenarios** organized into broad and targeted categories.

### Broad U.S. tariff scenarios (12)

| Scenario | Rate | Description |
|----------|------|-------------|
| Liberation Day | Country-specific | Reciprocal tariff schedule (195 country-specific rates) |
| Uniform 5% | 5% | Uniform tariff on all U.S. imports |
| Uniform 10% | 10% | Uniform tariff on all U.S. imports |
| Uniform 15% | 15% | Uniform tariff on all U.S. imports |
| Uniform 20% | 20% | Uniform tariff on all U.S. imports |
| Optimal U.S. | Computed (Eq. 14) | Welfare-maximizing unilateral tariff |

Each runs under both no-retaliation and reciprocal-retaliation modes (2 &times; 6 = 12).

### Targeted partner scenarios (56)

| Partner | Rates | Retaliation modes |
|---------|-------|-------------------|
| MEX, CAN, EU, CHN, IND, BRA, JPN | 5%, 10%, 15%, 20% | none, reciprocal |

7 partners &times; 4 rates &times; 2 retaliation modes = 56 scenarios. EU is expanded to all EU-27 member states present in the dataset.

### Retaliation modes

- **No retaliation:** Foreign countries keep their factual tariffs. Only U.S. import tariffs change.
- **Reciprocal retaliation:** Each affected foreign country imposes the same rate on U.S. exports that the U.S. imposed on their goods. For Liberation Day, each country retaliates with its own country-specific rate.

---

## Code Structure

```
+ustariff/
|-- main.m                       One-click runner: build scenarios -> analyze
|-- defaults.m                   Solver defaults and paths
|-- results/                     Analysis output (generated by pipeline.run)
|
|-- +scenario/                   Scenario specification and tariff cube construction
|   |-- liberation_day.m         Liberation Day reciprocal tariff schedule (195 countries)
|   |-- uniform.m                Uniform tariff spec builder
|   |-- targeted.m               Targeted partner tariff spec builder
|   |-- optimal_us.m             Optimal unilateral U.S. tariff spec
|   |-- build_tariff_cube.m      N x N x S counterfactual tariff cube (ROW aggregation, EU expansion)
|
|-- +solver/                     Counterfactual and optimal tariff solvers
|   |-- counterfactual.m         fsolve wrapper for 2N system (retry logic, stall monitor)
|   |-- counterfactual_equations.m  Equations 6 and 7 with exogenous tariff hat
|   |-- optimal_us_tariff.m      fsolve wrapper for 2N+1 system (retry logic, stall monitor)
|   |-- optimal_us_equations.m   Equations 6, 7, and 14 (U.S. unilateral FOC)
|
|-- +welfare/                    Welfare computation
|   |-- welfare_gains.m          Hat-algebra welfare (percent changes) from 2N solution
|
|-- +pipeline/                   Analysis engine
|   |-- run.m                    Load -> balance -> solve -> welfare -> CSV
|
|-- data/                        Exogenous tariff schedules
|   |-- reciprocal_tariffs/
|       |-- tariffs.csv          195 country-specific tariff rates (decimal)
|       |-- country_labels.csv   ISO3 codes and country names
|       |-- trade_cepii.csv      195 x 194 bilateral export matrix (for ROW weighting)
```

### Key data structures

All core arrays are **N &times; N &times; S** cubes where dimension 1 = exporter *j*, dimension 2 = importer *i*, dimension 3 = sector *k*.

| Variable | Description |
|----------|-------------|
| `Xjik_3D` | Bilateral trade flow (*j* exports to *i* in sector *k*) |
| `tjik_3D` | Applied tariff rate (*i* charges on imports from *j* in sector *k*) |
| `tjik_h3D` | Tariff hat: (1 + *t*^cf) / (1 + *t*^factual). Equals 1 where tariffs are unchanged |
| `lambda_jik3D` | Trade share: *X_jik* / &sum;_j *X_jik*. Sums to 1 over *j* |
| `Yi3D` | Total expenditure of importer *i* (replicated to N &times; N &times; S) |
| `Ri3D` | Wage revenue of exporter *j* (replicated to N &times; N &times; S) |
| `e_ik3D` | Expenditure share of sector *k* in country *i*. Sums to 1 over *k* |
| `sigma_k3D` | CES elasticity of substitution (&sigma; = &epsilon; + 1) |

---

## Relationship to `+tariffwar`

This package reuses the data infrastructure, solver utilities, and trade elasticity sources of the `+tariffwar` package. It does **not** duplicate any shared code.

| Feature | `+tariffwar` | `+ustariff` |
|---------|-------------|-------------|
| **Tariff determination** | Endogenous (Nash equilibrium) | Exogenous (predetermined policy) |
| **Equation system** | 3*N* unknowns (Eq 6, 7, 14 for all countries) | 2*N* unknowns (Eq 6, 7 only) |
| **Optimal tariff** | All *N* countries optimize simultaneously | U.S. only (2*N*+1 system, Eq 14 for U.S. row) |
| **Retaliation** | Endogenous (part of Nash equilibrium) | Exogenous (mirror or none) |
| **Solver** | `fsolve` on 3*N* system | `fsolve` on 2*N* or 2*N*+1 system |
| **Scenario support** | Single Nash equilibrium | 68 policy counterfactuals |

### Shared dependencies

| Module | Function |
|--------|----------|
| `tariffwar.io.load_data` | Load prebuilt `.mat` files |
| `tariffwar.io.load_gdp` | Load World Bank GDP data for dollar conversion |
| `tariffwar.data.balance_trade` | Zero-deficit counterfactual (2*N* system) |
| `tariffwar.data.compute_derived_cubes` | Trade shares, income, revenue, expenditure shares |
| `tariffwar.elasticity.registry` | Master registry of 8 elasticity sources |
| `tariffwar.solver.solver_options` | Build `optimoptions` struct from config |
| `tariffwar.solver.stall_monitor` | `OutputFcn` for early termination on convergence stall |

---

## Prerequisites

### Analysis (using prebuilt data)

- MATLAB R2016b or later
- Optimization Toolbox (`fsolve`)
- `+tariffwar` package with prebuilt `.mat` files in `+tariffwar/mat/`

### Platform support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Fully supported | Primary development platform |
| Linux | Fully supported | All dependencies available via package manager |
| Windows | Supported | No platform-specific requirements beyond MATLAB |

---

## API Reference

### `ustariff.pipeline.run(scenarios, datasets, years, elasticities, ...)`

Main entry point. Runs all scenarios across all dataset-year-elasticity combinations. Years without a prebuilt `.mat` file are silently skipped.

```matlab
% Single scenario, single dataset
spec = ustariff.scenario.uniform(0.10);
ustariff.pipeline.run({spec}, 'icio', 2022, 'IS')

% Multiple scenarios, full grid
specs = {ustariff.scenario.liberation_day(), ustariff.scenario.uniform(0.20)};
ustariff.pipeline.run(specs, {'wiod','icio'}, 2000:2022, {'IS','U4','CP'})
```

**Year coverage** (prebuilt `.mat` files in `+tariffwar/mat/`):

| Dataset | Years | *N* | *S* |
|---------|-------|-----|-----|
| `wiod` | 2000--2014 | 44 | 16 |
| `icio` | 2011--2022 | 81 | 28 |
| `itpd` | 2000--2019 | 135 | 154 |

**Name-value options:**

| Option | Default | Description |
|--------|---------|-------------|
| `'output_file'` | `results/results.csv` | CSV output path |

### Scenario constructors

| Constructor | Arguments | Description |
|-------------|-----------|-------------|
| `ustariff.scenario.liberation_day()` | none | Liberation Day reciprocal tariff schedule |
| `ustariff.scenario.uniform(rate)` | `rate` in [0,1] | Uniform tariff on all imports (e.g., 0.10 = 10%) |
| `ustariff.scenario.targeted(partner, rate)` | ISO3 or `'EU'`, rate | Tariff on a specific partner |
| `ustariff.scenario.optimal_us()` | none | Optimal unilateral U.S. tariff (Eq. 14) |

### Output format

CSV file with one row per country per scenario:

| Column | Description |
|--------|-------------|
| `Country` | ISO3 country code |
| `Year` | Data year |
| `Dataset` | `wiod`, `icio`, or `itpd` |
| `Elasticity` | Elasticity source (full name from registry) |
| `Scenario` | `liberation_day`, `uniform`, `optimal_us`, `targeted` |
| `Tariff_Rate` | Tariff rate in percent (e.g., 10.0); `NaN` for Liberation Day |
| `Target` | `all`, `MEX`, `CAN`, `EU`, `CHN`, `IND`, `BRA`, `JPN` |
| `Retaliation` | `none` or `reciprocal` |
| `Percent_Change` | Welfare change (percent of real GDP) |
| `Dollar_Change` | Welfare change (constant 2015 USD) |
| `Real_GDP` | Baseline real GDP (constant 2015 USD, World Bank WDI) |

---

## Convergence Strategy

### Counterfactual solver (2*N* system)

The solver uses Levenberg-Marquardt with 1 + `max_retries` attempts. On failure, it retries with random scalar initial guesses:

| Attempt | Initial guess |
|---------|---------------|
| 1 | Default: *w&#x302;* = 0.95, *Y&#x302;* = 1.05 |
| 2--4 | Random: *w&#x302;* ~ U(0.8, 1.2), *Y&#x302;* ~ U(0.8, 1.2) |

### Optimal U.S. tariff solver (2*N* + 1 system)

| Attempt | Initial guess |
|---------|---------------|
| 1 | Default: *w&#x302;* = 0.95, *Y&#x302;* = 1.05, *t*_US = 0.25 |
| 2--4 | Random: *w&#x302;* ~ U(0.8, 1.2), *Y&#x302;* ~ U(0.8, 1.2), *t*_US ~ U(0.10, 0.50) |

Each scalar is drawn once and applied uniformly to all *N* countries. The attempt with the best exit flag (or smallest residual on ties) is returned.

### Balanced trade: algorithm-switch retry

Balanced-trade pre-processing uses the `+tariffwar` solver directly:

| Attempt | Algorithm | Initial guess |
|---------|-----------|---------------|
| 1 | `trust-region-dogleg` | Ones |
| 2 | `levenberg-marquardt` | Random scalar |

### Stall monitor

Both solvers use an `OutputFcn` (from `+tariffwar`) that kills the solver when progress stalls:

1. **Initial gate:** After `stall_window` (5) iterations, the residual must have dropped by at least 1000&times; from the initial value.
2. **Sliding window:** Each subsequent iteration must show at least 10% improvement relative to `stall_window` iterations ago.

---

## Trade Elasticity Sources

The package inherits all eight elasticity sources from `+tariffwar`, selectable by abbreviation or full name. When the source classification differs from the target dataset, concordance matrices in `+tariffwar/+concordance/` map elasticities to the appropriate sectors.

| Abbrev | Source | Sectors | Classification |
|--------|--------|---------|----------------|
| `IS` | In-sample (dataset-specific) | 16 | WIOD-16 |
| `U4` | Simonovska and Waugh (2014) | 1 (uniform &sigma; = 4) | -- |
| `CP` | Caliendo and Parro (2015) | 20 | ISIC Rev. 3 |
| `BSY` | Bagwell, Staiger, and Yurukoglu (2021) | 49 | SITC Rev. 2 |
| `GYY` | Giri, Yi, and Yilmazkuday (2021) | 19 | OECD |
| `Shap` | Shapiro (2016) | 13 | HS sections |
| `FGO` | Fontagn&eacute;, Guimbard, and Orefice (2022) | 19 | TiVA |
| `LL` | Lashkaripour and Lugovskyy (2023) | 14 | ISIC Rev. 4 |

---

## Data Sources

### Trade and tariff data

The package uses prebuilt `.mat` files from `+tariffwar`, which draws on five publicly available data sources:

| Dataset | Countries | Sectors | Years | Source |
|---------|-----------|---------|-------|--------|
| WIOD 2016 Release | 44 (43 + RoW) | 16 (15 goods + 1 services) | 2000--2014 | [Timmer et al. (2015)](#references) |
| OECD ICIO Extended 2023 | 81 | 28 (27 goods + 1 services) | 2011--2022 | [OECD (2023)](#references) |
| USITC ITPD-S R1.1 | 135 (filtered from 246) | 154 (153 goods + 1 services) | 2000--2019 | [Borchert et al. (2022)](#references) |
| Teti Global Tariff Database | bilateral | ISIC Rev. 3.3 | 1988--2021 | [Teti (2024)](#references) |
| World Bank WDI | 189+ | GDP (constant 2015 USD) | 1960--present | [World Bank (2024)](#references) |

### Liberation Day tariff data

The 195-country reciprocal tariff schedule is stored in `data/reciprocal_tariffs/`:

| File | Description |
|------|-------------|
| `tariffs.csv` | Applied tariff rates (decimal) for 195 countries |
| `country_labels.csv` | ISO3 codes, numeric codes, and country names |
| `trade_cepii.csv` | 195 &times; 194 bilateral export matrix for ROW trade-weighting |

---

## References

Bagwell, K., Staiger, R.W., and Yurukoglu, A. (2021). "Multilateral Trade Bargaining: A First Look at the GATT Bargaining Records." *Econometrica*, 89(4), 1723--1764.

Borchert, I., Larch, M., Shikher, S., and Yotov, Y.V. (2022). "The International Trade and Production Database for Estimation (ITPD-E)." *International Economics*, 170, 140--166.

Caliendo, L. and Parro, F. (2015). "Estimates of the Trade and Welfare Effects of NAFTA." *Review of Economic Studies*, 82(1), 1--44.

Fontagn&eacute;, L., Guimbard, H., and Orefice, G. (2022). "Tariff-Based Product-Level Trade Elasticities." *Journal of International Economics*, 137, 103593.

Giri, R., Yi, K.-M., and Yilmazkuday, H. (2021). "Gains from Trade: Does Sectoral Heterogeneity Matter?" *Journal of International Economics*, 129, 103429.

Lashkaripour, A. (2021). "The Cost of a Global Tariff War: A Sufficient-Statistics Approach." *Journal of International Economics*, 131, 103489.

Lashkaripour, A. and Lugovskyy, V. (2023). "Profits, Scale Economies, and the Gains from Trade and Industrial Policy." *American Economic Review*, 113(10), 2759--2808.

OECD (2023). Inter-Country Input-Output Tables, 2023 edition. [oecd.org/en/data/datasets/inter-country-input-output-tables.html](https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html).

Shapiro, J.S. (2016). "Trade Costs, CO2, and the Environment." *American Economic Journal: Economic Policy*, 8(4), 220--254.

Simonovska, I. and Waugh, M.E. (2014). "The Elasticity of Trade: Estimates and Evidence." *Journal of International Economics*, 92(1), 34--50.

Teti, F. (2024). "30+ Years of Trade Policy: Evidence from 160 Countries." ECARES Working Paper 2024-04.

Timmer, M.P., Dietzenbacher, E., Los, B., Stehrer, R., and de Vries, G.J. (2015). "An Illustrated User Guide to the World Input-Output Database: The Case of Global Automotive Production." *Review of International Economics*, 23(3), 575--605.

World Bank (2024). World Development Indicators. Indicator NY.GDP.MKTP.KD (GDP, constant 2015 US$). [data.worldbank.org](https://data.worldbank.org).
