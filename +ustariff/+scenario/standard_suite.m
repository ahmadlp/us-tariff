function scenarios = standard_suite()
%USTARIFF.SCENARIO.STANDARD_SUITE  Full 68-outcome scenario list.
%
%   scenarios = ustariff.scenario.standard_suite()
%
%   Returns 34 scenario specifications. With the default two retaliation
%   regimes in ustariff.pipeline.run, this expands to 68 outcomes.

    scenarios = ustariff.scenario.broad_suite();
    partners = {'MEX', 'CAN', 'EU', 'CHN', 'IND', 'BRA', 'JPN'};
    rates = [0.05, 0.10, 0.15, 0.20];

    for i = 1:numel(partners)
        for j = 1:numel(rates)
            scenarios{end + 1, 1} = ustariff.scenario.targeted(partners{i}, rates(j)); %#ok<AGROW>
        end
    end
end
