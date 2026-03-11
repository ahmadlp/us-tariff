function scenarios = broad_suite()
%USTARIFF.SCENARIO.BROAD_SUITE  Broad tariff scenarios used in the README.
%
%   scenarios = ustariff.scenario.broad_suite()

    scenarios = {
        ustariff.scenario.liberation_day()
        ustariff.scenario.uniform(0.05)
        ustariff.scenario.uniform(0.10)
        ustariff.scenario.uniform(0.15)
        ustariff.scenario.uniform(0.20)
        ustariff.scenario.optimal_us()
    };
end
