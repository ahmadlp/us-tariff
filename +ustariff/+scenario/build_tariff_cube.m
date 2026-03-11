function [tjik_3D_cf, tjik_h3D] = build_tariff_cube(spec, retaliation, data)
%USTARIFF.SCENARIO.BUILD_TARIFF_CUBE  Construct counterfactual tariff cube.
%
%   [tjik_3D_cf, tjik_h3D] = ustariff.scenario.build_tariff_cube(spec, retaliation, data)
%
%   Builds the counterfactual tariff cube for a given scenario.  Replaces
%   U.S. import tariffs with the scenario rates.  For reciprocal
%   retaliation, foreign countries mirror the tariff on U.S. exports.
%
%   Cube convention:  tjik_3D(j, i, k)
%     j = exporter,  i = importer,  k = sector
%     Row j, column i => tariff that importer i charges on exporter j
%     U.S. tariff on CHN imports:  tjik_3D(chn, us, k)
%     CHN tariff on U.S. imports:  tjik_3D(us, chn, k)
%
%   Inputs:
%     spec         - scenario struct from ustariff.scenario.*
%     retaliation  - 'none' or 'reciprocal'
%     data         - struct from ustariff.io.load_data (needs .countries,
%                    .tjik_3D, .N, .S)
%
%   Returns:
%     tjik_3D_cf   - N x N x S counterfactual tariff levels
%     tjik_h3D     - N x N x S tariff hat (= (1+cf)/(1+factual))
%
%   See also: ustariff.scenario.liberation_day, ustariff.scenario.uniform

    N = data.N;
    S = data.S;
    countries = data.countries;
    tjik_3D_factual = data.tjik_3D;

    % Find U.S. index in this dataset
    us_idx = find_country(countries, 'USA');
    if isempty(us_idx)
        error('ustariff:noUSA', 'USA not found in dataset countries.');
    end

    % Start from factual tariffs
    tjik_3D_cf = tjik_3D_factual;

    % --- Build scenario-specific U.S. tariff rates ---
    switch spec.type
        case 'uniform'
            % Uniform rate on all partners, all sectors
            for j = 1:N
                if j == us_idx, continue; end
                tjik_3D_cf(j, us_idx, :) = spec.rate;
            end

        case 'targeted'
            % Tariff on specific partner(s) only
            partner_idxs = resolve_partner(spec.partner, countries);
            for pi = 1:numel(partner_idxs)
                j = partner_idxs(pi);
                tjik_3D_cf(j, us_idx, :) = spec.rate;
            end

        case 'country_specific'
            % Liberation Day: country-specific rates from spec.rates map
            for j = 1:N
                if j == us_idx, continue; end
                c = countries{j};
                if iscell(c), c = c{1}; end
                if strcmp(c, 'ROW')
                    % Trade-weighted average for ROW countries
                    rate = compute_row_tariff(spec, countries);
                    tjik_3D_cf(j, us_idx, :) = rate;
                elseif spec.rates.isKey(c)
                    tjik_3D_cf(j, us_idx, :) = spec.rates(c);
                end
                % Countries not in the 195-country list keep factual tariffs
            end

        case 'optimal_us'
            % Tariff cube is built AFTER solving for the optimal rate.
            % At this stage, spec should have .computed_rate set by the solver.
            if ~isfield(spec, 'computed_rate')
                error('ustariff:noRate', ...
                    'optimal_us spec must have .computed_rate set before building tariff cube.');
            end
            for j = 1:N
                if j == us_idx, continue; end
                tjik_3D_cf(j, us_idx, :) = spec.computed_rate;
            end

        otherwise
            error('ustariff:unknownType', 'Unknown scenario type: %s', spec.type);
    end

    % --- Reciprocal retaliation ---
    if strcmp(retaliation, 'reciprocal')
        switch spec.type
            case 'uniform'
                % All partners mirror: impose spec.rate on U.S. exports
                for i = 1:N
                    if i == us_idx, continue; end
                    tjik_3D_cf(us_idx, i, :) = spec.rate;
                end

            case 'targeted'
                % Only targeted partners retaliate
                partner_idxs = resolve_partner(spec.partner, countries);
                for pi = 1:numel(partner_idxs)
                    i = partner_idxs(pi);
                    tjik_3D_cf(us_idx, i, :) = spec.rate;
                end

            case 'country_specific'
                % Each country retaliates with the rate the U.S. imposed on them
                for i = 1:N
                    if i == us_idx, continue; end
                    c = countries{i};
                    if iscell(c), c = c{1}; end
                    if strcmp(c, 'ROW')
                        % ROW retaliates with trade-weighted average of
                        % U.S. tariffs on ROW constituents, weighted by
                        % U.S. exports to each ROW country
                        rate = compute_row_retaliation(spec, countries);
                        tjik_3D_cf(us_idx, i, :) = rate;
                    elseif spec.rates.isKey(c)
                        tjik_3D_cf(us_idx, i, :) = spec.rates(c);
                    end
                end

            case 'optimal_us'
                % All partners mirror the optimal rate
                for i = 1:N
                    if i == us_idx, continue; end
                    tjik_3D_cf(us_idx, i, :) = spec.computed_rate;
                end
        end
    end

    % --- Tariff hat ---
    tjik_h3D = (1 + tjik_3D_cf) ./ (1 + tjik_3D_factual);
end


% ========================================================================
%  Helper functions
% ========================================================================

function idx = find_country(countries, iso3)
%FIND_COUNTRY  Find index of an ISO3 country code in the dataset.
    idx = [];
    for i = 1:numel(countries)
        c = countries{i};
        if iscell(c), c = c{1}; end
        if strcmp(c, iso3)
            idx = i;
            return;
        end
    end
end


function idxs = resolve_partner(partner, countries)
%RESOLVE_PARTNER  Resolve partner name to dataset country indices.
%   For 'EU', expands to all EU-27 members present in the dataset.

    EU27 = {'AUT','BEL','BGR','CYP','CZE','DEU','DNK','ESP','EST', ...
            'FIN','FRA','GRC','HRV','HUN','IRL','ITA','LTU','LUX', ...
            'LVA','MLT','NLD','POL','PRT','ROU','SVK','SVN','SWE'};

    if strcmp(partner, 'EU')
        idxs = [];
        for ei = 1:numel(EU27)
            idx = find_country(countries, EU27{ei});
            if ~isempty(idx)
                idxs(end+1) = idx; %#ok<AGROW>
            end
        end
        if isempty(idxs)
            error('ustariff:noEU', 'No EU-27 members found in dataset.');
        end
    else
        idx = find_country(countries, partner);
        if isempty(idx)
            error('ustariff:partnerNotFound', ...
                'Partner %s not found in dataset countries.', partner);
        end
        idxs = idx;
    end
end


function rate = compute_row_tariff(spec, countries)
%COMPUTE_ROW_TARIFF  Trade-weighted average tariff for ROW countries.
%
%   rate = sum(tariff_c * exports_c_to_US) / sum(exports_c_to_US)
%
%   where the sum is over all 195 countries NOT individually present
%   in the dataset.

    % Countries individually present in the dataset (excluding ROW itself)
    dataset_iso3 = {};
    for i = 1:numel(countries)
        c = countries{i};
        if iscell(c), c = c{1}; end
        if ~strcmp(c, 'ROW')
            dataset_iso3{end+1} = c; %#ok<AGROW>
        end
    end

    % Column index for exports to USA in the trade matrix
    % trade_matrix is 195 x 194, columns = export_ij1..export_ij194
    us_col = spec.us_iso_code;  % 185

    num = 0;
    den = 0;
    for i = 1:numel(spec.iso3_list)
        c = spec.iso3_list{i};
        % Skip countries that are individually in the dataset
        if any(strcmp(c, dataset_iso3)), continue; end
        % Skip USA itself
        if strcmp(c, 'USA'), continue; end

        exports_to_us = spec.trade_matrix(i, us_col);
        tariff_c      = spec.rate_list(i);
        num = num + tariff_c * exports_to_us;
        den = den + exports_to_us;
    end

    if den > 0
        rate = num / den;
    else
        rate = 0.10;  % fallback: default 10%
    end
end


function rate = compute_row_retaliation(spec, countries)
%COMPUTE_ROW_RETALIATION  Trade-weighted retaliation rate for ROW.
%
%   ROW's retaliation rate = weighted average of each ROW constituent's
%   tariff on the U.S., weighted by U.S. exports to that country.
%   Under reciprocal retaliation, each country retaliates with the rate
%   the U.S. imposed on them, so:
%     rate = sum(tariff_c * exports_US_to_c) / sum(exports_US_to_c)
%
%   Uses iso_code_list to look up correct trade matrix columns.
%   trade_matrix(us_row, iso_code_c) = U.S. exports to country c.

    dataset_iso3 = {};
    for i = 1:numel(countries)
        c = countries{i};
        if iscell(c), c = c{1}; end
        if ~strcmp(c, 'ROW')
            dataset_iso3{end+1} = c; %#ok<AGROW>
        end
    end

    % Row for USA in the trade matrix (exports FROM USA)
    us_row = find(strcmp(spec.iso3_list, 'USA'));
    if isempty(us_row)
        rate = 0.10;
        return;
    end

    num = 0;
    den = 0;
    n_cols = size(spec.trade_matrix, 2);
    for i = 1:numel(spec.iso3_list)
        c = spec.iso3_list{i};
        if any(strcmp(c, dataset_iso3)), continue; end
        if strcmp(c, 'USA'), continue; end

        % Column for destination c = iso_code of country i
        col_c = spec.iso_code_list(i);
        if col_c < 1 || col_c > n_cols, continue; end

        exports_us_to_c = spec.trade_matrix(us_row, col_c);
        tariff_c = spec.rate_list(i);
        num = num + tariff_c * exports_us_to_c;
        den = den + exports_us_to_c;
    end

    if den > 0
        rate = num / den;
    else
        rate = 0.10;
    end
end
