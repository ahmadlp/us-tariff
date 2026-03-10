function main()
%USTARIFF.MAIN  Run all U.S. tariff scenario analyses with one click.
%
%   ustariff.main
%
%   Builds all 68 scenario specs and runs the pipeline across all
%   datasets, years, and elasticities.
%
%   Output: +ustariff/results/results.csv
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

    % ===================== Build scenarios =====================
    scenarios = {};

    % Liberation Day reciprocal tariffs
    scenarios{end+1} = ustariff.scenario.liberation_day();

    % Uniform tariffs: 5%, 10%, 15%, 20%
    for rate = [0.05, 0.10, 0.15, 0.20]
        scenarios{end+1} = ustariff.scenario.uniform(rate); %#ok<AGROW>
    end

    % Optimal unilateral U.S. tariff
    scenarios{end+1} = ustariff.scenario.optimal_us();

    % Targeted partner tariffs: 7 partners x 4 rates
    partners = {'MEX', 'CAN', 'EU', 'CHN', 'IND', 'BRA', 'JPN'};
    rates    = [0.05, 0.10, 0.15, 0.20];
    for pi = 1:numel(partners)
        for ri = 1:numel(rates)
            scenarios{end+1} = ustariff.scenario.targeted(partners{pi}, rates(ri)); %#ok<AGROW>
        end
    end

    fprintf('Built %d scenario specs.\n', numel(scenarios));

    % ===================== Run pipeline =====================
    datasets     = {'wiod', 'icio', 'itpd'};
    years        = 2000:2022;
    elasticities = {'IS', 'U4', 'CP', 'BSY', 'GYY', 'Shap', 'FGO', 'LL'};

    ustariff.pipeline.run(scenarios, datasets, years, elasticities);
end
