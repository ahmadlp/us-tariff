function spec = liberation_day()
%USTARIFF.SCENARIO.LIBERATION_DAY  Liberation Day reciprocal tariff scenario.
%
%   spec = ustariff.scenario.liberation_day()
%
%   Reads the reciprocal tariff schedule from the data files:
%     +ustariff/data/reciprocal_tariffs/country_labels.csv
%     +ustariff/data/reciprocal_tariffs/tariffs.csv
%     +ustariff/data/reciprocal_tariffs/trade_cepii.csv
%
%   Builds an ISO3 -> tariff rate mapping and stores trade data for
%   computing ROW trade-weighted averages.
%
%   See also: ustariff.scenario.build_tariff_cube

    pkg_root = fileparts(fileparts(mfilename('fullpath')));
    data_dir = fullfile(pkg_root, 'data', 'reciprocal_tariffs');

    % Read country labels
    labels = readtable(fullfile(data_dir, 'country_labels.csv'), 'TextType', 'string');

    % Read tariff rates
    tariffs = readtable(fullfile(data_dir, 'tariffs.csv'));

    % Build ISO3 -> rate mapping
    rates = containers.Map('KeyType', 'char', 'ValueType', 'double');
    iso3_list     = cell(height(labels), 1);
    iso_code_list = zeros(height(labels), 1);
    rate_list     = zeros(height(labels), 1);
    for i = 1:height(labels)
        iso3 = char(labels.iso3(i));
        iso3_list{i}     = iso3;
        iso_code_list(i) = labels.iso_code(i);
        rate_list(i)     = tariffs.applied_tariff(i);
        rates(iso3) = tariffs.applied_tariff(i);
    end

    % Read trade data for ROW weighting
    trade = readtable(fullfile(data_dir, 'trade_cepii.csv'));
    trade_matrix = table2array(trade);  % 195 x 194

    spec.name         = 'liberation_day';
    spec.type         = 'country_specific';
    spec.label        = 'Liberation Day Reciprocal Tariffs';
    spec.target       = 'all';
    spec.rates        = rates;
    spec.iso3_list     = iso3_list;
    spec.iso_code_list = iso_code_list;
    spec.rate_list     = rate_list;
    spec.trade_matrix = trade_matrix;
    spec.us_iso_code  = 185;  % USA iso_code in the 195-country list
end
