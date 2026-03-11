function data = load_world_polygons()
%USTARIFF.VIZ.LOAD_WORLD_POLYGONS  Load projected world polygons for map export.
%
%   data = ustariff.viz.load_world_polygons()

    persistent cached_data

    if isempty(cached_data)
        asset_file = fullfile(ustariff.repo_root(), '+ustariff', '+viz', ...
            'assets', 'world_polygons.json');
        if ~isfile(asset_file)
            error('ustariff:viz:missingAsset', ...
                'World polygon asset not found: %s', asset_file);
        end
        cached_data = jsondecode(fileread(asset_file));
        cached_data.features = enrich_missing_iso3(cached_data.features);
    end

    data = cached_data;
end


function features = enrich_missing_iso3(features)
    lookup = numeric_code_lookup();

    for i = 1:numel(features)
        if isfield(features(i), 'iso3') && ~isempty(features(i).iso3)
            continue;
        end

        code = '';
        if isfield(features(i), 'numeric') && ~isempty(features(i).numeric)
            code = char(string(features(i).numeric));
        end

        if isempty(code) || ~isKey(lookup, code)
            continue;
        end

        meta = lookup(code);
        features(i).iso3 = meta.iso3;
        if (~isfield(features(i), 'name') || isempty(features(i).name)) && ~isempty(meta.name)
            features(i).name = meta.name;
        end
    end
end


function lookup = numeric_code_lookup()
    persistent cached_lookup

    if isempty(cached_lookup)
        rows = {
            '010', 'ATA', 'Antarctica'
            '016', 'ASM', 'American Samoa'
            '020', 'AND', 'Andorra'
            '028', 'ATG', 'Antigua and Barbuda'
            '064', 'BTN', 'Bhutan'
            '084', 'BLZ', 'Belize'
            '086', 'IOT', 'British Indian Ocean Territory'
            '090', 'SLB', 'Solomon Islands'
            '092', 'VGB', 'British Virgin Islands'
            '108', 'BDI', 'Burundi'
            '132', 'CPV', 'Cabo Verde'
            '136', 'CYM', 'Cayman Islands'
            '140', 'CAF', 'Central African Republic'
            '148', 'TCD', 'Chad'
            '174', 'COM', 'Comoros'
            '184', 'COK', 'Cook Islands'
            '192', 'CUB', 'Cuba'
            '204', 'BEN', 'Benin'
            '212', 'DMA', 'Dominica'
            '226', 'GNQ', 'Equatorial Guinea'
            '232', 'ERI', 'Eritrea'
            '234', 'FRO', 'Faroe Islands'
            '238', 'FLK', 'Falkland Islands'
            '239', 'SGS', 'South Georgia and the South Sandwich Islands'
            '248', 'ALA', 'Aland Islands'
            '258', 'PYF', 'French Polynesia'
            '260', 'ATF', 'French Southern Territories'
            '270', 'GMB', 'Gambia'
            '296', 'KIR', 'Kiribati'
            '304', 'GRL', 'Greenland'
            '308', 'GRD', 'Grenada'
            '316', 'GUM', 'Guam'
            '324', 'GIN', 'Guinea'
            '328', 'GUY', 'Guyana'
            '334', 'HMD', 'Heard Island and McDonald Islands'
            '336', 'VAT', 'Vatican City'
            '388', 'JAM', 'Jamaica'
            '430', 'LBR', 'Liberia'
            '438', 'LIE', 'Liechtenstein'
            '450', 'MDG', 'Madagascar'
            '462', 'MDV', 'Maldives'
            '466', 'MLI', 'Mali'
            '478', 'MRT', 'Mauritania'
            '492', 'MCO', 'Monaco'
            '499', 'MNE', 'Montenegro'
            '500', 'MSR', 'Montserrat'
            '520', 'NRU', 'Nauru'
            '531', 'CUW', 'Curacao'
            '534', 'SXM', 'Sint Maarten'
            '540', 'NCL', 'New Caledonia'
            '548', 'VUT', 'Vanuatu'
            '558', 'NIC', 'Nicaragua'
            '570', 'NIU', 'Niue'
            '574', 'NFK', 'Norfolk Island'
            '580', 'MNP', 'Northern Mariana Islands'
            '583', 'FSM', 'Micronesia'
            '584', 'MHL', 'Marshall Islands'
            '585', 'PLW', 'Palau'
            '612', 'PCN', 'Pitcairn Islands'
            '624', 'GNB', 'Guinea-Bissau'
            '626', 'TLS', 'Timor-Leste'
            '630', 'PRI', 'Puerto Rico'
            '646', 'RWA', 'Rwanda'
            '652', 'BLM', 'Saint Barthelemy'
            '654', 'SHN', 'Saint Helena'
            '659', 'KNA', 'Saint Kitts and Nevis'
            '660', 'AIA', 'Anguilla'
            '662', 'LCA', 'Saint Lucia'
            '663', 'MAF', 'Saint Martin'
            '666', 'SPM', 'Saint Pierre and Miquelon'
            '670', 'VCT', 'Saint Vincent and the Grenadines'
            '674', 'SMR', 'San Marino'
            '690', 'SYC', 'Seychelles'
            '694', 'SLE', 'Sierra Leone'
            '728', 'SSD', 'South Sudan'
            '732', 'ESH', 'Western Sahara'
            '740', 'SUR', 'Suriname'
            '748', 'SWZ', 'Eswatini'
            '768', 'TGO', 'Togo'
            '776', 'TON', 'Tonga'
            '796', 'TCA', 'Turks and Caicos Islands'
            '831', 'GGY', 'Guernsey'
            '832', 'JEY', 'Jersey'
            '833', 'IMN', 'Isle of Man'
            '850', 'VIR', 'U.S. Virgin Islands'
            '876', 'WLF', 'Wallis and Futuna'
            '882', 'WSM', 'Samoa'
        };

        cached_lookup = containers.Map('KeyType', 'char', 'ValueType', 'any');
        for i = 1:size(rows, 1)
            cached_lookup(rows{i, 1}) = struct( ...
                'iso3', rows{i, 2}, ...
                'name', rows{i, 3});
        end
    end

    lookup = cached_lookup;
end
