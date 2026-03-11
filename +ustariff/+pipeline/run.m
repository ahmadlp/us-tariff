function results = run(scenarios, datasets, years, elasticities, varargin)
%USTARIFF.PIPELINE.RUN  Run U.S. tariff scenario analysis.
%
%   ustariff.pipeline.run({ustariff.scenario.uniform(0.10)}, 'icio', 2022, 'IS')
%   ustariff.pipeline.run(ustariff.scenario.standard_suite(), 'wiod', 2014, {'IS','U4'})
%
%   Name-value options:
%     'output_file'        - CSV path (default: results/results.csv)
%     'mat_dir'            - local archive of prebuilt .mat files
%     'auto_download_data' - download missing .mat files into repo-root mat/ (default: true)
%     'save_map'           - export a PNG welfare map for each run (default: false)
%     'map_output_dir'     - directory for PNG maps (default: results/maps)
%     'retaliations'       - 'none', 'reciprocal', or both (default: both)
%     'Display'            - solver display: 'off' or 'iter' (default: 'iter')
%
%   See also: ustariff.main, ustariff.scenario.standard_suite

    scenarios = normalize_scenarios(scenarios);
    datasets = normalize_text_list(datasets);
    elasticities = normalize_text_list(elasticities);
    years = years(:).';

    cfg = ustariff.defaults();
    opts = parse_options(cfg, varargin{:});
    cfg.verbose = ~strcmpi(opts.Display, 'off');
    cfg.solver.Display = opts.Display;
    cfg.optimal.Display = opts.Display;
    cfg.balance_trade.Display = opts.Display;

    reg = ustariff.elasticity.registry();
    elas = resolve_elasticities(elasticities, reg);
    retaliations = normalize_retaliations(opts.retaliations);
    single_request = numel(scenarios) == 1 && numel(datasets) == 1 && ...
        numel(years) == 1 && numel(elas) == 1;
    requested_runs = numel(scenarios) * numel(datasets) * numel(years) * ...
        numel(elas) * numel(retaliations);
    detailed_reporting = requested_runs <= 6;

    try
        gdp_map = ustariff.io.load_gdp();
    catch err
        fprintf('Warning: GDP data unavailable (%s). Dollar values will be NaN.\n', err.message);
        gdp_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    end

    out_dir = fileparts(opts.output_file);
    if ~isempty(out_dir) && ~isfolder(out_dir)
        mkdir(out_dir);
    end
    if opts.save_map && ~isfolder(opts.map_output_dir)
        mkdir(opts.map_output_dir);
    end

    fid = fopen(opts.output_file, 'w');
    if fid < 0
        error('ustariff:pipeline:outputOpenFailed', ...
            'Could not open output file: %s', opts.output_file);
    end
    cleaner = onCleanup(@() fclose(fid));

    fprintf(fid, 'Country,Year,Dataset,Elasticity,Scenario,Tariff_Rate,Target,Retaliation,Percent_Change,Dollar_Change,Real_GDP\n');

    all_results = {};
    map_files = {};
    skipped_data = struct('dataset', {}, 'year', {}, 'reason', {});

    for di = 1:numel(datasets)
        ds = datasets{di};
        for yi = 1:numel(years)
            yr = years(yi);
            [mat_dir, skip_reason] = resolve_mat_dir(ds, yr, opts.mat_dir, cfg.mat_dir, opts.auto_download_data);
            if isempty(mat_dir)
                skipped_data(end + 1) = struct('dataset', ds, 'year', yr, 'reason', skip_reason); %#ok<AGROW>
                if single_request
                    error('ustariff:pipeline:dataUnavailable', ...
                        'No data available for %s %d: %s', upper(ds), yr, skip_reason);
                end
                fprintf('Skipping %s %d: %s\n', upper(ds), yr, skip_reason);
                continue;
            end

            if cfg.verbose
                fprintf('\n=== Loading %s %d ===\n', upper(ds), yr);
            end
            d = ustariff.io.load_data(ds, yr, 'mat_dir', mat_dir);
            N = d.N;
            S = d.S;
            us_idx = find_us(d.countries);

            for ei = 1:numel(elas)
                if cfg.verbose
                    fprintf('\n--- Elasticity: %s ---\n', elas(ei).abbrev);
                end

                sigma_S = d.sigma.(elas(ei).abbrev).sigma_S;
                sigma_k3D = repmat(reshape(sigma_S, 1, 1, S), [N, N, 1]);

                Xjik_raw = d.Xjik_3D;
                if strcmp(ds, 'icio')
                    Xjik_raw = Xjik_raw + repmat(eye(N), [1, 1, S]);
                end

                Xjik_3D = ustariff.data.balance_trade(Xjik_raw, sigma_k3D, d.tjik_3D, N, S, cfg);
                [lam, Yi3D, Ri3D, e_ik3D] = ustariff.data.compute_derived_cubes(Xjik_3D, d.tjik_3D, N, S);

                for si = 1:numel(scenarios)
                    spec = scenarios{si};
                    for ri = 1:numel(retaliations)
                        retal = retaliations{ri};

                        [pct, tariff_rate, exitflag, output, solved_spec] = run_single_scenario( ...
                            spec, retal, d, N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, us_idx, cfg);

                        [dollar_change, country_gdp] = compute_dollar_values( ...
                            pct, d.countries, yr, N, gdp_map);
                        total_cost = compute_total_cost(dollar_change);

                        map_file = '';
                        if opts.save_map
                            map_file = fullfile(opts.map_output_dir, build_map_filename( ...
                                solved_spec, retal, ds, yr, elas(ei).abbrev));
                            ustariff.viz.export_welfare_map(d.countries, pct, ...
                                'output_file', map_file, ...
                                'dataset', ds, ...
                                'year', yr, ...
                                'elasticity', elas(ei).abbrev, ...
                                'scenario_label', solved_spec.label, ...
                                'retaliation', retal, ...
                                'rate_label', rate_label_for_spec(solved_spec, tariff_rate));
                            map_files{end + 1} = map_file; %#ok<AGROW>
                        end

                        print_run_report( ...
                            solved_spec, retal, ds, yr, elas(ei).abbrev, ...
                            tariff_rate, pct(us_idx), mean(pct), total_cost, ...
                            exitflag, output.iterations, map_file, detailed_reporting);

                        write_rows(fid, d.countries, yr, ds, elas(ei).name, solved_spec, ...
                            retal, pct, tariff_rate, dollar_change, country_gdp);

                        all_results{end + 1} = struct( ... %#ok<AGROW>
                            'dataset', ds, ...
                            'year', yr, ...
                            'elasticity', elas(ei).name, ...
                            'elasticity_abbrev', elas(ei).abbrev, ...
                            'scenario', solved_spec.name, ...
                            'scenario_label', solved_spec.label, ...
                            'tariff_rate', tariff_rate, ...
                            'target', solved_spec.target, ...
                            'retaliation', retal, ...
                            'pct_change', pct, ...
                            'dollar_change', dollar_change, ...
                            'country_gdp', country_gdp, ...
                            'exitflag', exitflag, ...
                            'iterations', output.iterations, ...
                            'countries', {d.countries}, ...
                            'map_file', map_file);
                    end
                end
            end
        end
    end

    clear cleaner
    print_pipeline_footer(opts.output_file, numel(all_results), numel(map_files), skipped_data);

    results.csv_file = opts.output_file;
    results.map_files = map_files;
    results.runs = all_results;
    results.skipped_data = skipped_data;
    if numel(all_results) == 1
        results.pct_change = all_results{1}.pct_change;
        results.dollar_change = all_results{1}.dollar_change;
        results.exitflag = all_results{1}.exitflag;
        results.countries = all_results{1}.countries;
        results.map_file = all_results{1}.map_file;
    elseif single_request
        results.map_file = '';
    end
end


function opts = parse_options(cfg, varargin)
    p = inputParser;
    addParameter(p, 'output_file', fullfile(cfg.results_dir, 'results.csv'), @is_text_scalar);
    addParameter(p, 'mat_dir', '', @is_text_scalar);
    addParameter(p, 'auto_download_data', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'save_map', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'map_output_dir', fullfile(cfg.results_dir, 'maps'), @is_text_scalar);
    addParameter(p, 'retaliations', {'none', 'reciprocal'});
    addParameter(p, 'Display', cfg.solver.Display, @is_text_scalar);
    parse(p, varargin{:});
    opts = p.Results;
    opts.output_file = char(string(opts.output_file));
    opts.mat_dir = char(string(opts.mat_dir));
    opts.map_output_dir = char(string(opts.map_output_dir));
    opts.Display = char(string(opts.Display));
    opts.auto_download_data = logical(opts.auto_download_data);
    opts.save_map = logical(opts.save_map);
end


function scenarios = normalize_scenarios(scenarios)
    if isstruct(scenarios)
        scenarios = num2cell(scenarios(:));
    end
    if ~iscell(scenarios)
        error('ustariff:pipeline:invalidScenarios', ...
            'scenarios must be a struct, struct array, or cell array.');
    end
    scenarios = scenarios(:);
end


function values = normalize_text_list(values)
    if ischar(values) || (isstring(values) && isscalar(values))
        values = {char(string(values))};
        return;
    end
    if isnumeric(values)
        error('ustariff:pipeline:invalidTextList', 'Expected a text list.');
    end
    values = cellstr(string(values(:)));
end


function retaliations = normalize_retaliations(retaliations)
    if ischar(retaliations) || (isstring(retaliations) && isscalar(retaliations))
        retaliations = {char(string(retaliations))};
    else
        retaliations = cellstr(string(retaliations(:)));
    end
    retaliations = lower(retaliations);
    allowed = {'none', 'reciprocal'};
    for i = 1:numel(retaliations)
        if ~ismember(retaliations{i}, allowed)
            error('ustariff:pipeline:invalidRetaliation', ...
                'Unknown retaliation mode: %s', retaliations{i});
        end
    end
    retaliations = unique(retaliations, 'stable');
end


function [mat_dir, reason] = resolve_mat_dir(dataset, year, explicit_mat_dir, repo_mat_dir, auto_download_data)
    filename = sprintf('%s%d.mat', upper(dataset), year);
    candidate_dirs = {};
    if ~isempty(strtrim(explicit_mat_dir))
        candidate_dirs{end + 1} = explicit_mat_dir; %#ok<AGROW>
    end
    candidate_dirs{end + 1} = repo_mat_dir; %#ok<AGROW>

    mat_dir = '';
    reason = '';
    for i = 1:numel(candidate_dirs)
        candidate = candidate_dirs{i};
        if isempty(candidate)
            continue;
        end
        if isfile(fullfile(candidate, filename))
            mat_dir = candidate;
            return;
        end
    end

    if auto_download_data
        entry = ustariff.io.mat_asset_manifest(dataset, year);
        if ~isempty(entry)
            try
                ustariff.io.download_mat_asset(dataset, year, repo_mat_dir);
                mat_dir = repo_mat_dir;
                return;
            catch err
                reason = err.message;
                return;
            end
        end
    end

    reason = sprintf(['No local file matched %s. Checked ''mat_dir'' and repo-root mat/. ' ...
        'Enable auto download or point ''mat_dir'' to a local tariffwar mat archive.'], filename);
end


function [pct, tariff_rate, exitflag, output, solved_spec] = run_single_scenario( ...
    spec, retal, d, N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, us_idx, cfg)

    solved_spec = spec;
    if strcmp(spec.type, 'optimal_us')
        [X_opt, exitflag, output, t_us_opt] = ustariff.solver.optimal_us_tariff( ...
            N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, us_idx, cfg);

        solved_spec.computed_rate = t_us_opt;
        solved_spec.label = sprintf('%s (%.1f%%)', spec.label, 100 * t_us_opt);
        [~, tjik_h3D] = ustariff.scenario.build_tariff_cube(solved_spec, retal, d);

        if strcmp(retal, 'reciprocal')
            [X_sol, exitflag, output] = ustariff.solver.counterfactual( ...
                N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, tjik_h3D, cfg);
            pct = ustariff.welfare.welfare_gains(X_sol, N, S, e_ik3D, sigma_k3D, lam, tjik_h3D);
        else
            pct = ustariff.welfare.welfare_gains(X_opt, N, S, e_ik3D, sigma_k3D, lam, tjik_h3D);
        end
        tariff_rate = 100 * t_us_opt;
    else
        [~, tjik_h3D] = ustariff.scenario.build_tariff_cube(spec, retal, d);
        [X_sol, exitflag, output] = ustariff.solver.counterfactual( ...
            N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, tjik_h3D, cfg);
        pct = ustariff.welfare.welfare_gains(X_sol, N, S, e_ik3D, sigma_k3D, lam, tjik_h3D);
        if isfield(spec, 'rate')
            tariff_rate = 100 * spec.rate;
        else
            tariff_rate = NaN;
        end
    end

    if ~isfield(output, 'iterations')
        output.iterations = NaN;
    end
end


function write_rows(fid, countries, year, dataset, elasticity, spec, retaliation, pct, tariff_rate, dollar_change, country_gdp)
    for ci = 1:numel(countries)
        c = countries{ci};
        if iscell(c)
            c = c{1};
        end
        if isnan(country_gdp(ci))
            fprintf(fid, '%s,%d,%s,%s,%s,%.6f,%s,%s,%.6f,,\n', ...
                c, year, dataset, elasticity, spec.name, tariff_rate, ...
                spec.target, retaliation, pct(ci));
        else
            fprintf(fid, '%s,%d,%s,%s,%s,%.6f,%s,%s,%.6f,%.2f,%.2f\n', ...
                c, year, dataset, elasticity, spec.name, tariff_rate, ...
                spec.target, retaliation, pct(ci), dollar_change(ci), country_gdp(ci));
        end
    end
end


function [dollar_change, country_gdp] = compute_dollar_values(pct, countries, yr, N, gdp_map)
    dollar_change = NaN(N, 1);
    country_gdp = NaN(N, 1);
    matched_gdp_sum = 0;
    row_idx = 0;
    for ci = 1:N
        c = countries{ci};
        if iscell(c)
            c = c{1};
        end
        if strcmp(c, 'ROW')
            row_idx = ci;
            continue;
        end
        key = sprintf('%s_%d', c, yr);
        if gdp_map.isKey(key)
            country_gdp(ci) = gdp_map(key);
            dollar_change(ci) = 0.01 * pct(ci) * country_gdp(ci);
            matched_gdp_sum = matched_gdp_sum + country_gdp(ci);
        end
    end
    if row_idx > 0
        wld_key = sprintf('WLD_%d', yr);
        if gdp_map.isKey(wld_key)
            country_gdp(row_idx) = gdp_map(wld_key) - matched_gdp_sum;
            dollar_change(row_idx) = 0.01 * pct(row_idx) * country_gdp(row_idx);
        end
    end
end


function total_cost = compute_total_cost(dollar_change)
    matched = dollar_change(~isnan(dollar_change));
    if isempty(matched)
        total_cost = NaN;
    else
        total_cost = sum(matched);
    end
end


function idx = find_us(countries)
    idx = [];
    for i = 1:numel(countries)
        c = countries{i};
        if iscell(c)
            c = c{1};
        end
        if strcmp(c, 'USA')
            idx = i;
            return;
        end
    end
    error('ustariff:noUSA', 'USA not found in dataset.');
end


function print_run_report(spec, retaliation, dataset, year, elasticity, tariff_rate, ...
    us_welfare, world_mean, total_cost, exitflag, iterations, map_file, detailed_reporting)

    retaliation_label = format_retaliation(retaliation);
    cost_label = format_total_cost(total_cost);
    policy_lines = build_policy_lines(spec, retaliation_label, tariff_rate);

    if detailed_reporting
        print_rule('=');
        fprintf('Run Complete\n\n');

        fprintf('Scenario\n');
        fprintf('  %s\n\n', spec.label);

        fprintf('Context\n');
        fprintf('  Dataset: %s %d\n', upper(dataset), year);
        fprintf('  Elasticity: %s\n', elasticity);
        fprintf('  Retaliation: %s\n\n', retaliation_label);

        fprintf('Policy\n');
        for i = 1:numel(policy_lines)
            fprintf('  %s\n', policy_lines{i});
        end
        fprintf('\n');

        fprintf('Outcomes\n');
        fprintf('  U.S. welfare change %s: %.3f%%\n', retaliation_label, us_welfare);
        fprintf('  World average welfare change: %.3f%%\n', world_mean);
        fprintf('  Matched-GDP welfare change: %s\n\n', cost_label);

        fprintf('Solver\n');
        fprintf('  Exitflag: %d\n', exitflag);
        fprintf('  Iterations: %d\n', iterations);
        if ~isempty(map_file)
            fprintf('\nFiles\n');
            fprintf('  Map: %s\n', map_file);
        end
        print_rule('=');
        return;
    end

    line = sprintf(['Completed %s | %s %d | %s | %s | ' ...
        'U.S. welfare %.3f%% | world avg %.3f%%'], ...
        spec.label, upper(dataset), year, elasticity, retaliation_label, ...
        us_welfare, world_mean);
    compact_policy = compact_policy_label(spec, tariff_rate);
    if ~isempty(compact_policy)
        line = sprintf('%s | %s', line, compact_policy);
    end
    if ~isnan(total_cost)
        line = sprintf('%s | matched GDP %s', line, cost_label);
    end
    fprintf('%s\n', line);
end


function print_pipeline_footer(output_file, run_count, map_count, skipped_data)
    print_rule('-');
    fprintf('Pipeline Complete\n\n');

    fprintf('Output\n');
    fprintf('  CSV: %s\n', output_file);
    fprintf('  Runs completed: %d\n', run_count);
    if map_count > 0
        fprintf('  Maps saved: %d\n', map_count);
    end
    if ~isempty(skipped_data)
        fprintf('  Skipped dataset-years: %d\n', numel(skipped_data));
    end

    print_rule('-');
end


function print_rule(ch)
    fprintf('\n%s\n', repmat(ch, 1, 72));
end


function lines = build_policy_lines(spec, retaliation_label, tariff_rate)
    lines = {};
    switch spec.type
        case 'uniform'
            lines{end + 1} = 'U.S. tariff policy: uniform tariff on all imports'; %#ok<AGROW>
            lines{end + 1} = sprintf('Target coverage: %s', format_target(spec.target)); %#ok<AGROW>
            lines{end + 1} = sprintf('Applied rate %s: %.2f%%', retaliation_label, tariff_rate); %#ok<AGROW>
        case 'targeted'
            lines{end + 1} = sprintf('U.S. tariff policy: targeted tariff on %s', format_target(spec.target)); %#ok<AGROW>
            lines{end + 1} = sprintf('Applied rate %s: %.2f%%', retaliation_label, tariff_rate); %#ok<AGROW>
        case 'optimal_us'
            lines{end + 1} = 'U.S. tariff policy: computed unilateral optimum applied to all partners'; %#ok<AGROW>
            lines{end + 1} = sprintf('Target coverage: %s', format_target(spec.target)); %#ok<AGROW>
            lines{end + 1} = sprintf('Optimal U.S. tariff %s: %.2f%%', retaliation_label, tariff_rate); %#ok<AGROW>
        case 'country_specific'
            lines{end + 1} = 'U.S. tariff policy: country-specific Liberation Day schedule'; %#ok<AGROW>
            lines{end + 1} = 'Target coverage: scheduled partners; ROW aggregated with trade weights'; %#ok<AGROW>
            if isfield(spec, 'rate_list') && ~isempty(spec.rate_list)
                lines{end + 1} = sprintf('Schedule range: %.1f%% to %.1f%%', ...
                    100 * min(spec.rate_list), 100 * max(spec.rate_list)); %#ok<AGROW>
                lines{end + 1} = sprintf('Schedule simple average: %.1f%%', ...
                    100 * mean(spec.rate_list)); %#ok<AGROW>
            end
        otherwise
            if isfinite(tariff_rate)
                lines{end + 1} = sprintf('Applied tariff rate %s: %.2f%%', retaliation_label, tariff_rate); %#ok<AGROW>
            else
                lines{end + 1} = sprintf('Target coverage: %s', format_target(spec.target)); %#ok<AGROW>
            end
    end
end


function label = compact_policy_label(spec, tariff_rate)
    switch spec.type
        case 'uniform'
            label = sprintf('uniform tariff %.2f%%', tariff_rate);
        case 'targeted'
            label = sprintf('target %s at %.2f%%', format_target(spec.target), tariff_rate);
        case 'optimal_us'
            label = sprintf('optimal U.S. tariff %.2f%%', tariff_rate);
        case 'country_specific'
            label = 'Liberation Day schedule';
        otherwise
            if isfinite(tariff_rate)
                label = sprintf('tariff %.2f%%', tariff_rate);
            else
                label = '';
            end
    end
end


function label = format_target(target)
    label = char(string(target));
    if strcmpi(label, 'all')
        label = 'all partners';
    elseif strcmpi(label, 'EU')
        label = 'EU partners';
    end
end


function label = format_retaliation(retaliation)
    switch lower(retaliation)
        case 'none'
            label = 'without retaliation';
        case 'reciprocal'
            label = 'with reciprocal retaliation';
        otherwise
            label = retaliation;
    end
end


function label = format_total_cost(total_cost)
    if isnan(total_cost)
        label = 'not available';
        return;
    end

    abs_cost = abs(total_cost);
    if abs_cost >= 1e12
        label = sprintf('$%.2fT', total_cost / 1e12);
    else
        label = sprintf('$%.1fB', total_cost / 1e9);
    end
end


function filename = build_map_filename(spec, retaliation, dataset, year, elasticity)
    filename = sprintf('welfare_map_%s_%s_%s_%s_%s_%d_%s.png', ...
        sanitize_token(spec.name), ...
        sanitize_token(spec.target), ...
        sanitize_token(rate_label_for_spec(spec, NaN)), ...
        sanitize_token(retaliation), ...
        sanitize_token(dataset), ...
        year, ...
        sanitize_token_case(elasticity));
end


function label = rate_label_for_spec(spec, tariff_rate)
    if strcmp(spec.type, 'country_specific')
        label = 'schedule';
        return;
    end
    if strcmp(spec.type, 'optimal_us')
        label = 'computed';
        return;
    end
    if isfield(spec, 'rate')
        label = sprintf('%dpct', round(100 * spec.rate));
        return;
    end
    if nargin >= 2 && isfinite(tariff_rate)
        label = sprintf('%.1fpct', tariff_rate);
        return;
    end
    label = 'na';
end


function token = sanitize_token(value)
    token = lower(char(string(value)));
    token = regexprep(token, '[^a-z0-9]+', '_');
    token = regexprep(token, '^_+|_+$', '');
    if isempty(token)
        token = 'na';
    end
end


function token = sanitize_token_case(value)
    token = char(string(value));
    token = regexprep(token, '[^A-Za-z0-9]+', '_');
    token = regexprep(token, '^_+|_+$', '');
    if isempty(token)
        token = 'NA';
    end
end


function entries = resolve_elasticities(names, reg)
    entries = struct([]);
    for i = 1:numel(names)
        idx = find(strcmp({reg.abbrev}, names{i}), 1);
        if isempty(idx)
            idx = find(strcmp({reg.name}, names{i}), 1);
        end
        if isempty(idx)
            error('ustariff:pipeline:unknownElasticity', ...
                'Unknown elasticity: %s', names{i});
        end
        if isempty(entries)
            entries = reg(idx);
        else
            entries(end + 1) = reg(idx); %#ok<AGROW>
        end
    end
end


function tf = is_text_scalar(x)
    tf = ischar(x) || (isstring(x) && isscalar(x));
end
