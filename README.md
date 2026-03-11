# ustariff

`ustariff` is a MATLAB package for computing the welfare effects of predetermined U.S. tariff scenarios in the multi-country, multi-sector CES trade model of Lashkaripour (2021). Tariffs are treated as policy inputs, and the package solves for the resulting equilibrium wages, incomes, and welfare changes.

The repository includes:

- MATLAB package code under `+ustariff/`
- bundled quickstart data in `mat/ICIO2022.mat`
- a bundled GDP lookup in `support/gdp/`
- example scripts in `examples/`

You can run the package from a new clone without rebuilding raw data.

## Install Or Download

Clone the repository or download the ZIP, then open the repository root in MATLAB. The folder name does not matter.

```bash
git clone <repo-url> ustariff
cd ustariff
```

Add the repository root to the MATLAB path:

```matlab
addpath(pwd)
```

## One-Minute Quickstart

This example uses the bundled `mat/ICIO2022.mat` file.

```matlab
addpath(pwd)
spec = ustariff.scenario.uniform(0.10);
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off');
```

Or run the checked-in example:

```matlab
run(fullfile('examples', 'quickstart_uniform.m'))
```

## Scenario Cookbook

### Uniform tariff

```matlab
addpath(pwd)
spec = ustariff.scenario.uniform(0.10);
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off');
```

### Compare retaliation vs no retaliation

```matlab
addpath(pwd)
spec = ustariff.scenario.targeted('CHN', 0.20);
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', {'none', 'reciprocal'}, ...
    'Display', 'off');
```

Checked-in example:

```matlab
run(fullfile('examples', 'targeted_china_compare_retaliation.m'))
```

### Liberation Day schedule

```matlab
addpath(pwd)
spec = ustariff.scenario.liberation_day();
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off');
```

### Target a specific partner

```matlab
addpath(pwd)
spec = ustariff.scenario.targeted('EU', 0.15);
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'reciprocal', ...
    'Display', 'off');
```

### Optimal unilateral U.S. tariff

```matlab
addpath(pwd)
spec = ustariff.scenario.optimal_us();
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off');
```

Checked-in example:

```matlab
run(fullfile('examples', 'optimal_us.m'))
```

### Broad suite

`ustariff.scenario.broad_suite()` returns the six headline policy specifications:

- Liberation Day
- Uniform 5%
- Uniform 10%
- Uniform 15%
- Uniform 20%
- Optimal U.S.

With the default two retaliation modes, that becomes 12 outcomes.

```matlab
addpath(pwd)
results = ustariff.pipeline.run(ustariff.scenario.broad_suite(), 'icio', 2022, 'IS', ...
    'Display', 'off');
```

### Full 68-scenario suite

`ustariff.scenario.standard_suite()` returns 34 scenario specifications:

- The six broad scenarios above
- Targeted tariffs on `MEX`, `CAN`, `EU`, `CHN`, `IND`, `BRA`, and `JPN`
- Four rates for each partner: 5%, 10%, 15%, and 20%

With the default two retaliation modes, that expands to 68 outcomes.

```matlab
addpath(pwd)
results = ustariff.pipeline.run(ustariff.scenario.standard_suite(), 'icio', 2022, 'IS', ...
    'Display', 'off');
```

If you want an example that points to an external archive explicitly:

```matlab
run(fullfile('examples', 'full_suite_external_data.m'))
```

## Expected Output

The runner writes `results/results.csv` by default. The CSV schema is:

```text
Country,Year,Dataset,Elasticity,Scenario,Tariff_Rate,Target,Retaliation,Percent_Change,Dollar_Change,Real_GDP
```

Returned fields:

- `results.csv_file`
- `results.runs`
- `results.map_files`
- `results.map_file` for single-run calls
- `results.skipped_data` for dataset-year requests that could not be satisfied

The `Elasticity` column stores the full registry name rather than only the abbreviation.

## Optional Map Export

Add `'save_map', true` to export a dashboard-style world welfare map alongside the CSV.

```matlab
addpath(pwd)
spec = ustariff.scenario.uniform(0.10);
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off', ...
    'save_map', true);
```

Or run:

```matlab
run(fullfile('examples', 'quickstart_uniform_with_map.m'))
```

This writes:

- `results/results.csv`
- `results/maps/welfare_map_uniform_all_10pct_none_icio_2022_IS.png`

The map exporter uses a local world-geometry asset, so it does not need Mapping Toolbox or an internet connection at runtime. Countries outside the simulated value layer, including non-observed `ROW` geography, render in gray rather than disappearing into the background.

## On-Demand Download Of Missing `.mat` Files

Only `ICIO2022.mat` is bundled. If a requested dataset-year file is not present locally, `ustariff.pipeline.run` will, by default, try to download a version-pinned prebuilt `.mat` file into repo-root `mat/`.

Example:

```matlab
addpath(pwd)
spec = ustariff.scenario.uniform(0.10);
results = ustariff.pipeline.run({spec}, 'wiod', 2014, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off');
```

Behavior:

- First it checks an explicit `'mat_dir'`, if provided.
- Then it checks repo-root `mat/`.
- Then, if `'auto_download_data'` is `true`, it downloads the missing file into repo-root `mat/`.
- If the file still cannot be found, single-run calls error with setup instructions and larger batch calls record the request in `results.skipped_data`.

To disable downloads:

```matlab
results = ustariff.pipeline.run({spec}, 'wiod', 2014, 'IS', ...
    'auto_download_data', false);
```

## Use A Local Archive Via `mat_dir`

If you already have a directory of prebuilt files, point `ustariff` at it directly.

```matlab
addpath(pwd)
spec = ustariff.scenario.uniform(0.10);
results = ustariff.pipeline.run({spec}, 'wiod', 2014, 'IS', ...
    'mat_dir', '/path/to/tariffwar/mat', ...
    'auto_download_data', false, ...
    'retaliations', 'none', ...
    'Display', 'off');
```

This is the fastest option when you already maintain a full `tariffwar` data archive locally.

## Data Sources

The bundled and downloaded `.mat` files are built from the underlying `tariffwar` data pipeline. You do not need that pipeline to run `ustariff`, but the underlying data sources should still be cited when results are reported.

| Source | Coverage used here | Citation |
| --- | --- | --- |
| WIOD 2016 Release | 44 countries, 16 sectors, 2000-2014 | Timmer et al. (2015) |
| OECD ICIO Extended 2023 | 81 countries, 28 sectors, 2011-2022 | OECD (2023) |
| USITC ITPD-S R1.1 | 135 countries, 154 sectors, 2000-2019 | Borchert et al. (2022) |
| Teti Global Tariff Database | Bilateral tariffs in the prebuilt archive | Teti (2024) |
| World Bank WDI | GDP in constant 2015 US$ | World Bank (2024) |

Scenario-specific bundled data:

- `data/reciprocal_tariffs/tariffs.csv` stores the Liberation Day country schedule used by `ustariff.scenario.liberation_day()`.
- `data/reciprocal_tariffs/trade_cepii.csv` provides the bilateral trade matrix used to compute `ROW` trade-weighted tariff averages in that scenario.

## Trade Elasticity Sources

`ustariff` supports the same eight elasticity specifications as `tariffwar`.

| Abbrev | Source | Citation |
| --- | --- | --- |
| `IS` | In-sample, dataset-specific | WIOD: Lashkaripour (2021); ICIO/ITPD: Caliendo-Parro triple difference estimator implemented in-package |
| `U4` | Uniform elasticity of 4 | Simonovska and Waugh (2014) |
| `CP` | Caliendo-Parro | Caliendo and Parro (2015) |
| `BSY` | Bagwell-Staiger-Yurukoglu | Bagwell, Staiger, and Yurukoglu (2021) |
| `GYY` | Giri-Yi-Yilmazkuday | Giri, Yi, and Yilmazkuday (2021) |
| `Shap` | Shapiro | Shapiro (2016) |
| `FGO` | Fontagne-Guimbard-Orefice | Fontagne, Guimbard, and Orefice (2022) |
| `LL` | Lashkaripour-Lugovskyy | Lashkaripour and Lugovskyy (2023) |

These sources matter substantively. The welfare numbers can move with the elasticity choice, so the README examples keep the elasticity argument explicit instead of hiding it behind a default.

## Methodology

`ustariff` implements the sufficient-statistics framework of Lashkaripour (2021), but it does not solve a full Nash tariff equilibrium. For exogenous tariff scenarios it solves the 2`N` system in wages and incomes, taking tariff changes as given. For the `optimal_us` case it solves a 2`N`+1 system that adds one unilateral U.S. tariff first-order condition while leaving the rest of the world non-optimizing.

That distinction is the main conceptual difference from `tariffwar`:

- `tariffwar` solves endogenous Nash tariffs for all countries.
- `ustariff` evaluates fixed policy scenarios chosen by the user.

## Troubleshooting

- `ustariff.pipeline.run` not found: make sure you called `addpath(pwd)` from the repository root, not from inside `+ustariff/`.
- Keep the repo in a normal folder name such as `ustariff/`, not `+ustariff/`. Only the inner MATLAB package directory should use the `+` prefix.
- The bundled-data example fails: confirm that `mat/ICIO2022.mat` exists and that the repository root is on the MATLAB path.
- A missing dataset-year is skipped: inspect `results.skipped_data`. Single-run calls error; larger batches continue.
- Auto-download fails: try again with a stable internet connection, or pass `'mat_dir'` to a local archive of prebuilt `.mat` files.
- Dollar values are `NaN`: the GDP lookup could not be found or matched for that country-year.
- The map shows gray countries: those countries have no welfare value for the selected run, which is expected for non-observed geography such as `ROW`.

## References

- Bagwell, K., Staiger, R.W., and Yurukoglu, A. (2021). "Multilateral Trade Bargaining: A First Look at the GATT Bargaining Records." *Econometrica*, 89(4), 1723-1764.
- Borchert, I., Larch, M., Shikher, S., and Yotov, Y.V. (2022). "The International Trade and Production Database for Estimation (ITPD-E)." *International Economics*, 170, 140-166.
- Caliendo, L. and Parro, F. (2015). "Estimates of the Trade and Welfare Effects of NAFTA." *Review of Economic Studies*, 82(1), 1-44.
- Fontagne, L., Guimbard, H., and Orefice, G. (2022). "Tariff-Based Product-Level Trade Elasticities." *Journal of International Economics*, 137, 103593.
- Giri, R., Yi, K.-M., and Yilmazkuday, H. (2021). "Gains from Trade: Does Sectoral Heterogeneity Matter?" *Journal of International Economics*, 129, 103429.
- Lashkaripour, A. (2021). "The Cost of a Global Tariff War: A Sufficient-Statistics Approach." *Journal of International Economics*, 131, 103489.
- Lashkaripour, A. and Lugovskyy, V. (2023). "Profits, Scale Economies, and the Gains from Trade and Industrial Policy." *American Economic Review*, 113(10), 2759-2808.
- OECD (2023). Inter-Country Input-Output Tables, 2023 edition. [oecd.org/en/data/datasets/inter-country-input-output-tables.html](https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html).
- Shapiro, J.S. (2016). "Trade Costs, CO2, and the Environment." *American Economic Journal: Economic Policy*, 8(4), 220-254.
- Simonovska, I. and Waugh, M.E. (2014). "The Elasticity of Trade: Estimates and Evidence." *Journal of International Economics*, 92(1), 34-50.
- Teti, F. (2024). "30+ Years of Trade Policy: Evidence from 160 Countries." ECARES Working Paper 2024-04.
- Timmer, M.P., Dietzenbacher, E., Los, B., Stehrer, R., and de Vries, G.J. (2015). "An Illustrated User Guide to the World Input-Output Database: The Case of Global Automotive Production." *Review of International Economics*, 23(3), 575-605.
- World Bank (2024). World Development Indicators. Indicator `NY.GDP.MKTP.KD`.
