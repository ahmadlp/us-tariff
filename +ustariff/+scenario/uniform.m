function spec = uniform(rate)
%USTARIFF.SCENARIO.UNIFORM  Uniform U.S. tariff scenario.
%
%   spec = ustariff.scenario.uniform(0.10)
%
%   Returns a scenario struct for a uniform U.S. tariff at the given rate
%   on all trading partners and sectors.
%
%   See also: ustariff.scenario.build_tariff_cube

    validateattributes(rate, {'numeric'}, {'scalar', 'real', '>=', 0, '<=', 1}, ...
        mfilename, 'rate');

    spec.name   = 'uniform';
    spec.type   = 'uniform';
    spec.label  = sprintf('Uniform %d%%', round(rate * 100));
    spec.rate   = rate;
    spec.target = 'all';
end
