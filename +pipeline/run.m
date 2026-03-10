function results = run(scenarios, datasets, years, elasticities, varargin)
%USTARIFF.PIPELINE.RUN  Run U.S. tariff scenario analysis.
%
%   ustariff.pipeline.run(scenarios, 'icio', 2022, 'IS')
%   ustariff.pipeline.run(scenarios, {'wiod','icio'}, 2000:2022, {'IS','U4'})
%
%   Positional args:
%     scenarios    - cell array of scenario structs from ustariff.scenario.*
%     datasets     - string or cell ('wiod', 'icio', 'itpd')
%     years        - numeric vector (e.g. 2014 or 2000:2022)
%     elasticities - abbreviation or cell ('IS','U4','CP','BSY','GYY','Shap','FGO','LL')
%
%   Name-value options:
%     'output_file'  - CSV path (default: +ustariff/results/results.csv)
%
%   Year coverage (from prebuilt .mat files):
%     WIOD:  2000-2014  (44 countries, 16 sectors)
%     ICIO:  2011-2022  (81 countries, 28 sectors)
%     ITPD:  2000-2019  (135 countries, 154 sectors)
%   Years without a .mat file are silently skipped.
%
%   See also: ustariff.main, ustariff.scenario.build_tariff_cube

    % Normalize inputs
    if ischar(datasets), datasets = {datasets}; end
    if ischar(elasticities), elasticities = {elasticities}; end

    % Load defaults
    cfg = ustariff.defaults();
    pkg_root = cfg.pkg_root;
    output_file = fullfile(pkg_root, 'results', 'results.csv');
    for i = 1:2:numel(varargin)
        switch varargin{i}
            case 'output_file', output_file = varargin{i+1};
        end
    end

    % Resolve elasticity abbreviations
    reg = tariffwar.elasticity.registry();
    elas = resolve_elasticities(elasticities, reg);

    % Load GDP data for dollar value conversion
    try
        gdp_map = tariffwar.io.load_gdp();
    catch
        fprintf('Warning: GDP data not available. Dollar values will be NaN.\n');
        gdp_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    end

    % Open CSV
    out_dir = fileparts(output_file);
    if ~isempty(out_dir) && ~isfolder(out_dir), mkdir(out_dir); end
    fid = fopen(output_file, 'w');
    fprintf(fid, 'Country,Year,Dataset,Elasticity,Scenario,Tariff_Rate,Target,Retaliation,Percent_Change,Dollar_Change,Real_GDP\n');

    % Retaliation regimes
    retaliations = {'none', 'reciprocal'};

    % === Main loop ===
    all_results = {};
    for di = 1:numel(datasets)
      ds = datasets{di};
      for yi = 1:numel(years)
        yr = years(yi);

        % Skip years without a .mat file
        mat_file = fullfile(cfg.mat_dir, sprintf('%s%d.mat', upper(ds), yr));
        if ~isfile(mat_file)
            fprintf('Skipping %s %d (no data file)\n', upper(ds), yr);
            continue;
        end

        fprintf('\n=== Loading %s %d ===\n', upper(ds), yr);
        d = tariffwar.io.load_data(ds, yr, 'mat_dir', cfg.mat_dir);
        N = d.N;  S = d.S;

        for ei = 1:numel(elas)
            fprintf('\n--- Elasticity: %s ---\n', elas(ei).abbrev);

            % Sigma cube from prebuilt data
            sigma_S   = d.sigma.(elas(ei).abbrev).sigma_S;
            sigma_k3D = repmat(reshape(sigma_S, 1, 1, S), [N, N, 1]);

            % Diagonal scaling for sparse datasets
            Xjik_raw = d.Xjik_3D;
            if strcmp(ds, 'icio'), Xjik_raw = Xjik_raw + repmat(eye(N), [1, 1, S]); end

            % Step 1: Balance trade (shared across all scenarios)
            Xjik_3D = tariffwar.data.balance_trade(Xjik_raw, sigma_k3D, d.tjik_3D, N, S, cfg);
            % Step 2: Compute derived cubes
            [lam, Yi3D, Ri3D, e_ik3D] = tariffwar.data.compute_derived_cubes(Xjik_3D, d.tjik_3D, N, S);

            % Find U.S. index
            us_idx = find_us(d.countries);

            % --- Loop over scenarios ---
            for si = 1:numel(scenarios)
                spec = scenarios{si};

                for ri = 1:numel(retaliations)
                    retal = retaliations{ri};

                    % --- Solve ---
                    if strcmp(spec.type, 'optimal_us')
                        % Optimal U.S. tariff: solve 2N+1 system first
                        [X_opt, ef, out, t_us_opt] = ustariff.solver.optimal_us_tariff( ...
                            N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, us_idx, cfg);

                        % Build tariff cube with computed rate
                        spec_solved = spec;
                        spec_solved.computed_rate = t_us_opt;
                        [~, tjik_h3D] = ustariff.scenario.build_tariff_cube(spec_solved, retal, d);

                        % Welfare from the 2N+1 solution
                        pct = ustariff.welfare.welfare_gains(X_opt, N, S, e_ik3D, sigma_k3D, lam, tjik_h3D);
                        tariff_rate = 100 * t_us_opt;

                        if strcmp(retal, 'reciprocal')
                            % Re-solve 2N system with retaliation cube
                            [X_sol, ef, out] = ustariff.solver.counterfactual( ...
                                N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, tjik_h3D, cfg);
                            pct = ustariff.welfare.welfare_gains(X_sol, N, S, e_ik3D, sigma_k3D, lam, tjik_h3D);
                        end
                    else
                        % Exogenous tariff scenario: build cube, solve 2N
                        [~, tjik_h3D] = ustariff.scenario.build_tariff_cube(spec, retal, d);

                        [X_sol, ef, out] = ustariff.solver.counterfactual( ...
                            N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, tjik_h3D, cfg);
                        pct = ustariff.welfare.welfare_gains(X_sol, N, S, e_ik3D, sigma_k3D, lam, tjik_h3D);

                        if isfield(spec, 'rate')
                            tariff_rate = 100 * spec.rate;
                        else
                            tariff_rate = NaN;  % Liberation Day has multiple rates
                        end
                    end

                    % --- Dollar values ---
                    [dollar_change, country_gdp] = compute_dollar_values( ...
                        pct, d.countries, yr, N, gdp_map);
                    total_cost = sum(dollar_change(~isnan(dollar_change)));

                    fprintf('  %s [%s] ef=%d iter=%d US=%.3f%% mean=%.3f%% total=$%.1fB\n', ...
                        spec.label, retal, ef, out.iterations, ...
                        pct(us_idx), mean(pct), total_cost/1e9);

                    % --- Write CSV rows ---
                    for ci = 1:N
                        c = d.countries{ci};
                        if iscell(c), c = c{1}; end
                        if isnan(country_gdp(ci))
                            fprintf(fid, '%s,%d,%s,%s,%s,%.1f,%s,%s,%.6f,,\n', ...
                                c, yr, ds, elas(ei).name, spec.name, tariff_rate, ...
                                spec.target, retal, pct(ci));
                        else
                            fprintf(fid, '%s,%d,%s,%s,%s,%.1f,%s,%s,%.6f,%.2f,%.2f\n', ...
                                c, yr, ds, elas(ei).name, spec.name, tariff_rate, ...
                                spec.target, retal, pct(ci), dollar_change(ci), country_gdp(ci));
                        end
                    end

                    all_results{end+1} = struct('dataset', ds, 'year', yr, ...
                        'elasticity', elas(ei).name, 'scenario', spec.name, ...
                        'tariff_rate', tariff_rate, 'target', spec.target, ...
                        'retaliation', retal, 'pct_change', pct, ...
                        'dollar_change', dollar_change, 'country_gdp', country_gdp, ...
                        'exitflag', ef, 'countries', {d.countries}); %#ok<AGROW>
                end
            end
        end
      end
    end

    fclose(fid);
    fprintf('\nDone. Output: %s\n', output_file);

    % Return
    results.csv_file = output_file;
    results.runs     = all_results;
end


% ========================================================================
%  Helper functions
% ========================================================================

function idx = find_us(countries)
    idx = [];
    for i = 1:numel(countries)
        c = countries{i};
        if iscell(c), c = c{1}; end
        if strcmp(c, 'USA')
            idx = i;
            return;
        end
    end
    if isempty(idx)
        error('ustariff:noUSA', 'USA not found in dataset.');
    end
end


function [dollar_change, country_gdp] = compute_dollar_values(pct, countries, yr, N, gdp_map)
    dollar_change   = NaN(N, 1);
    country_gdp     = NaN(N, 1);
    matched_gdp_sum = 0;
    row_idx         = 0;
    for ci = 1:N
        c = countries{ci};
        if iscell(c), c = c{1}; end
        if strcmp(c, 'ROW')
            row_idx = ci;
            continue;
        end
        key = sprintf('%s_%d', c, yr);
        if gdp_map.isKey(key)
            country_gdp(ci)   = gdp_map(key);
            dollar_change(ci) = 0.01 * pct(ci) * country_gdp(ci);
            matched_gdp_sum   = matched_gdp_sum + country_gdp(ci);
        end
    end
    if row_idx > 0
        wld_key = sprintf('WLD_%d', yr);
        if gdp_map.isKey(wld_key)
            country_gdp(row_idx)   = gdp_map(wld_key) - matched_gdp_sum;
            dollar_change(row_idx) = 0.01 * pct(row_idx) * country_gdp(row_idx);
        end
    end
end


function entries = resolve_elasticities(names, reg)
    entries = struct([]);
    for i = 1:numel(names)
        idx = find(strcmp({reg.abbrev}, names{i}), 1);
        if isempty(idx), idx = find(strcmp({reg.name}, names{i}), 1); end
        if isempty(idx), error('Unknown elasticity: %s', names{i}); end
        if isempty(entries), entries = reg(idx);
        else, entries(end+1) = reg(idx); end %#ok<AGROW>
    end
end
