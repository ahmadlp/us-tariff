function main(varargin)
%USTARIFF.MAIN  Run all U.S. tariff scenario analyses with one click.
%
%   ustariff.main
%   ustariff.main('mat_dir', '/path/to/archive', 'save_map', true)
%
%   Runs the standard 68-scenario suite across all datasets, years, and
%   elasticities.  This is the full-suite batch runner, not the public
%   quickstart entry point.
%
%   Output: results/results.csv
%
%   Scenarios (68 total):
%     Liberation Day (2 retaliation variants)
%     Uniform 5/10/15/20% (8 variants)
%     Optimal U.S. (2 variants)
%     Targeted: MEX, CAN, EU, CHN, IND, BRA, JPN x 4 rates x 2 retaliation (56 variants)
%
%   Year coverage (from prebuilt .mat files):
%     WIOD:  2000-2014  (44 countries, 16 sectors)
%     ICIO:  2011-2022  (81 countries, 28 sectors)
%     ITPD:  2000-2019  (135 countries, 154 sectors)
%
%   See also: ustariff.pipeline.run, ustariff.defaults

    scenarios = ustariff.scenario.standard_suite();
    fprintf('Built %d scenario specs.\n', numel(scenarios));

    % ===================== Run pipeline =====================
    datasets     = {'wiod', 'icio', 'itpd'};
    years        = 2000:2022;
    elasticities = {'IS', 'U4', 'CP', 'BSY', 'GYY', 'Shap', 'FGO', 'LL'};

    ustariff.pipeline.run(scenarios, datasets, years, elasticities, varargin{:});
end
