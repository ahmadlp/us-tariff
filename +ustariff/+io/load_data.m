function data = load_data(dataset, year, varargin)
%USTARIFF.IO.LOAD_DATA  Load a pre-built analysis file.
%
%   data = ustariff.io.load_data('icio', 2022)
%   data = ustariff.io.load_data('wiod', 2014, 'mat_dir', './mat')
%
%   Loads WIOD2014.mat, ICIO2022.mat, ITPD2005.mat, etc. from a local
%   directory of prebuilt analysis files.
%
%   Returns a struct with:
%     .Xjik_3D         N x N x S unbalanced trade flows
%     .tjik_3D          N x N x S applied tariff rates (decimal)
%     .sigma            struct with one field per elasticity source
%     .N, .S            scalars
%     .services_sector  scalar (= S)
%     .countries        N x 1 cell
%     .sectors          S x 1 cell
%     .dataset          string
%     .year             scalar
%
%   Each sigma field (e.g. data.sigma.IS) contains:
%     .epsilon_S        S x 1 trade elasticity vector
%     .sigma_S          S x 1 CES parameter (= epsilon + 1)
%     .source           string (full source name)
%
%   See also: ustariff.pipeline.run

    p = inputParser;
    addRequired(p, 'dataset', @ischar);
    addRequired(p, 'year', @isnumeric);
    addParameter(p, 'mat_dir', ...
        fullfile(ustariff.repo_root(), 'mat'), @ischar);
    parse(p, dataset, year, varargin{:});

    fname = fullfile(p.Results.mat_dir, ...
        sprintf('%s%d.mat', upper(dataset), year));

    if ~isfile(fname)
        error('ustariff:io:dataNotFound', ...
            ['Data file not found: %s\n' ...
             'Pass ''mat_dir'' to a local archive or enable auto download in ustariff.pipeline.run.'], ...
            fname);
    end

    loaded = load(fname, 'data');
    data = loaded.data;
end
