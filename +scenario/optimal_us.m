function spec = optimal_us()
%USTARIFF.SCENARIO.OPTIMAL_US  Optimal unilateral U.S. tariff scenario.
%
%   spec = ustariff.scenario.optimal_us()
%
%   Returns a scenario struct for the optimal unilateral U.S. tariff,
%   computed using Equation 14 from Lashkaripour (2021) applied only to
%   the U.S. (not a full Nash equilibrium).
%
%   See also: ustariff.solver.optimal_us_tariff

    spec.name   = 'optimal_us';
    spec.type   = 'optimal_us';
    spec.label  = 'Optimal Unilateral U.S. Tariff';
    spec.target = 'all';
end
