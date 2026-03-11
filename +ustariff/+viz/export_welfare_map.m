function output_file = export_welfare_map(countries, pct_change, varargin)
%USTARIFF.VIZ.EXPORT_WELFARE_MAP  Export a static welfare choropleth.
%
%   ustariff.viz.export_welfare_map(countries, pct_change, ...
%       'output_file', 'results/maps/welfare_map_uniform_all_10pct_none_icio_2022_IS.png')

    p = inputParser;
    addRequired(p, 'countries', @(x) iscell(x) || isstring(x));
    addRequired(p, 'pct_change', @isnumeric);
    addParameter(p, 'output_file', '', @is_text_scalar);
    addParameter(p, 'dataset', '', @is_text_scalar);
    addParameter(p, 'year', NaN, @isnumeric);
    addParameter(p, 'elasticity', '', @is_text_scalar);
    addParameter(p, 'scenario_label', '', @is_text_scalar);
    addParameter(p, 'retaliation', '', @is_text_scalar);
    addParameter(p, 'rate_label', '', @is_text_scalar);
    parse(p, countries, pct_change, varargin{:});

    output_file = char(string(p.Results.output_file));
    if isempty(strtrim(output_file))
        error('ustariff:viz:missingOutputFile', ...
            'An output file path is required.');
    end

    countries = normalize_codes(countries);
    pct_change = pct_change(:);
    if numel(countries) ~= numel(pct_change)
        error('ustariff:viz:sizeMismatch', ...
            'countries and pct_change must have the same length.');
    end

    world = ustariff.viz.load_world_polygons();
    out_dir = fileparts(output_file);
    if ~isempty(out_dir) && ~isfolder(out_dir)
        mkdir(out_dir);
    end

    [value_map, omitted_codes] = build_value_map(countries, pct_change, world.features);
    if ~isempty(omitted_codes)
        fprintf('Warning: Omitting codes from map values: %s\n', ...
            strjoin(omitted_codes, ', '));
    end

    fig = figure( ...
        'Visible', 'off', ...
        'Color', 'w', ...
        'Units', 'pixels', ...
        'Position', [100, 100, 1100, 700], ...
        'PaperPositionMode', 'auto');

    cleanup = onCleanup(@() close(fig));

    ax = axes('Parent', fig, 'Position', [0.03, 0.11, 0.94, 0.76]);
    hold(ax, 'on');
    axis(ax, 'equal');
    axis(ax, 'off');
    xlim(ax, [0, world.width]);
    ylim(ax, [0, world.height]);
    set(ax, 'YDir', 'reverse');

    rectangle(ax, ...
        'Position', [1, 1, world.width - 2, world.height - 2], ...
        'FaceColor', rgb('#fafafa'), ...
        'EdgeColor', rgb('#d8d8d8'), ...
        'LineWidth', 1.0);

    no_data_color = rgb('#c8c8c8');
    no_data_edge = rgb('#a8a8a8');
    data_edge = [1, 1, 1];

    for i = 1:numel(world.features)
        feature = world.features(i);
        [face_color, has_data] = feature_color(feature.iso3, value_map, no_data_color);
        edge_color = no_data_edge;
        if has_data
            edge_color = data_edge;
        end

        polygons = normalize_polygons(feature.polygons);
        for j = 1:numel(polygons)
            ring = polygons{j};
            patch(ax, ring(:, 1), ring(:, 2), face_color, ...
                'EdgeColor', edge_color, 'LineWidth', 0.45);
        end
    end

    annotation(fig, 'textbox', [0.05, 0.92, 0.9, 0.05], ...
        'String', 'Welfare Impact by Country', ...
        'EdgeColor', 'none', ...
        'FontName', 'Helvetica', ...
        'FontSize', 19, ...
        'FontWeight', 'bold', ...
        'Color', [0.07, 0.07, 0.07], ...
        'HorizontalAlignment', 'left');

    annotation(fig, 'textbox', [0.05, 0.885, 0.9, 0.04], ...
        'String', 'Percentage change in welfare under the selected U.S. tariff scenario.', ...
        'EdgeColor', 'none', ...
        'FontName', 'Helvetica', ...
        'FontSize', 11, ...
        'Color', [0.2, 0.2, 0.2], ...
        'HorizontalAlignment', 'left');

    run_label = build_run_label( ...
        p.Results.scenario_label, ...
        p.Results.retaliation, ...
        p.Results.rate_label, ...
        p.Results.dataset, ...
        p.Results.year, ...
        p.Results.elasticity);
    if ~isempty(run_label)
        annotation(fig, 'textbox', [0.05, 0.855, 0.9, 0.03], ...
            'String', run_label, ...
            'EdgeColor', 'none', ...
            'FontName', 'Helvetica', ...
            'FontSize', 10, ...
            'Color', [0.35, 0.35, 0.35], ...
            'HorizontalAlignment', 'left');
    end

    draw_legend(ax, world.width, world.height);

    print(fig, output_file, '-dpng', '-r180');
    clear cleanup
end


function [value_map, omitted_codes] = build_value_map(countries, pct_change, features)
    value_map = containers.Map('KeyType', 'char', 'ValueType', 'double');

    iso_codes = cell(numel(features), 1);
    for i = 1:numel(features)
        iso_codes{i} = char(string(features(i).iso3));
    end
    iso_codes = unique(iso_codes(~cellfun(@isempty, iso_codes)));

    omitted_codes = {};
    ignored_codes = {'ROW', 'WLD', 'CHI'};
    for i = 1:numel(countries)
        code = char(string(countries{i}));
        if isempty(code)
            continue;
        end
        if ismember(code, ignored_codes)
            omitted_codes{end + 1} = code; %#ok<AGROW>
            continue;
        end
        if ~ismember(code, iso_codes)
            omitted_codes{end + 1} = code; %#ok<AGROW>
            continue;
        end
        value_map(code) = pct_change(i);
    end

    omitted_codes = unique(omitted_codes, 'stable');
end


function countries = normalize_codes(countries)
    countries = countries(:);
    out = cell(numel(countries), 1);
    for i = 1:numel(countries)
        code = countries{i};
        if iscell(code)
            code = code{1};
        end
        out{i} = char(string(code));
    end
    countries = out;
end


function polygons = normalize_polygons(polygons)
    if isempty(polygons)
        polygons = {};
        return;
    end

    if isnumeric(polygons)
        if isempty(polygons)
            polygons = {};
            return;
        end

        dims = size(polygons);
        if ismatrix(polygons)
            polygons = {coerce_ring(polygons)};
            return;
        end

        if ndims(polygons) == 3 && dims(3) == 2
            out = cell(dims(1), 1);
            for i = 1:dims(1)
                out{i} = coerce_ring(squeeze(polygons(i, :, :)));
            end
            polygons = out;
            return;
        end

        if dims(end) ~= 2
            error('ustariff:viz:invalidPolygonShape', ...
                'Expected polygon coordinates with two columns, got %s.', ...
                mat2str(size(polygons)));
        end

        polygons = {coerce_ring(reshape(polygons, [], 2))};
        return;
    end

    if iscell(polygons)
        flat = {};
        for i = 1:numel(polygons)
            nested = normalize_polygons(polygons{i});
            if ~isempty(nested)
                flat = [flat; nested(:)]; %#ok<AGROW>
            end
        end
        polygons = flat;
        return;
    end

    error('ustariff:viz:unsupportedPolygonType', ...
        'Unsupported polygon container type: %s', class(polygons));
end


function ring = coerce_ring(ring)
    ring = squeeze(ring);
    if isempty(ring)
        ring = zeros(0, 2);
        return;
    end
    if isvector(ring)
        ring = reshape(ring, [], 2);
    end
    if size(ring, 2) ~= 2 && size(ring, 1) == 2
        ring = ring.';
    end
    if size(ring, 2) ~= 2
        error('ustariff:viz:invalidRingShape', ...
            'Expected ring coordinates with two columns, got %s.', ...
            mat2str(size(ring)));
    end
end


function [face_color, has_data] = feature_color(iso3, value_map, no_data_color)
    has_data = false;
    if isempty(iso3)
        face_color = no_data_color;
        return;
    end

    code = char(string(iso3));
    if ~isKey(value_map, code)
        face_color = no_data_color;
        return;
    end

    has_data = true;
    value = value_map(code);
    if isnan(value)
        face_color = no_data_color;
        has_data = false;
        return;
    end
    if value >= 0
        face_color = rgb('#5782a5');
        return;
    end

    abs_value = abs(value);
    bins = [1, 3, 5, 10, 20];
    ramp = {
        rgb('#fae6e6')
        rgb('#f5d0d0')
        rgb('#e29e9e')
        rgb('#cf6b6b')
        rgb('#bc3939')
        rgb('#7a1f1f')
    };

    idx = find(abs_value < bins, 1);
    if isempty(idx)
        idx = numel(ramp);
    end
    face_color = ramp{idx};
end


function draw_legend(ax, width, height)
    items = {
        rgb('#7a1f1f'), '20%+'
        rgb('#bc3939'), '10-20%'
        rgb('#cf6b6b'), '5-10%'
        rgb('#e29e9e'), '3-5%'
        rgb('#f5d0d0'), '1-3%'
        rgb('#fae6e6'), '0-1%'
        rgb('#5782a5'), 'Gain'
        rgb('#c8c8c8'), 'No data'
    };

    box_width = 165;
    box_height = 186;
    box_x = width - box_width - 18;
    box_y = height - box_height - 16;
    row_height = 18;
    swatch_w = 18;
    swatch_h = 11;

    rectangle(ax, ...
        'Position', [box_x, box_y, box_width, box_height], ...
        'FaceColor', [1, 1, 1], ...
        'EdgeColor', rgb('#d0d0d0'), ...
        'LineWidth', 1.0);

    text(ax, box_x + 10, box_y + 16, 'Welfare Loss (%)', ...
        'FontName', 'Helvetica', ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'Color', [0.2, 0.2, 0.2], ...
        'VerticalAlignment', 'middle');

    for i = 1:size(items, 1)
        row_y = box_y + 34 + (i - 1) * row_height;
        rectangle(ax, ...
            'Position', [box_x + 10, row_y, swatch_w, swatch_h], ...
            'FaceColor', items{i, 1}, ...
            'EdgeColor', [0, 0, 0], ...
            'LineWidth', 0.25);
        text(ax, box_x + 36, row_y + swatch_h / 2, items{i, 2}, ...
            'FontName', 'Helvetica', ...
            'FontSize', 9, ...
            'Color', [0.2, 0.2, 0.2], ...
            'VerticalAlignment', 'middle');
    end
end


function label = build_run_label(scenario_label, retaliation, rate_label, dataset, year, elasticity)
    parts = {};
    if is_text_scalar(scenario_label) && strlength(string(scenario_label)) > 0
        parts{end + 1} = char(string(scenario_label)); %#ok<AGROW>
    end
    if is_text_scalar(retaliation) && strlength(string(retaliation)) > 0
        parts{end + 1} = sprintf('Retaliation: %s', char(string(retaliation))); %#ok<AGROW>
    end
    if is_text_scalar(rate_label) && strlength(string(rate_label)) > 0 && ...
            ~strcmp(char(string(rate_label)), 'na')
        parts{end + 1} = sprintf('Rate: %s', char(string(rate_label))); %#ok<AGROW>
    end
    if is_text_scalar(dataset) && strlength(string(dataset)) > 0
        parts{end + 1} = sprintf('Dataset: %s', upper(char(string(dataset)))); %#ok<AGROW>
    end
    if isnumeric(year) && isfinite(year)
        parts{end + 1} = sprintf('Year: %d', year); %#ok<AGROW>
    end
    if is_text_scalar(elasticity) && strlength(string(elasticity)) > 0
        parts{end + 1} = sprintf('Elasticity: %s', char(string(elasticity))); %#ok<AGROW>
    end
    label = strjoin(parts, '   |   ');
end


function out = rgb(hex)
    hex = char(string(hex));
    hex = strrep(hex, '#', '');
    out = [ ...
        hex2dec(hex(1:2)), ...
        hex2dec(hex(3:4)), ...
        hex2dec(hex(5:6))] / 255;
end


function tf = is_text_scalar(x)
    tf = ischar(x) || (isstring(x) && isscalar(x));
end
