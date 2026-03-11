function spec = targeted(partner, rate)
%USTARIFF.SCENARIO.TARGETED  Targeted U.S. tariff on a specific partner.
%
%   spec = ustariff.scenario.targeted('CHN', 0.10)
%   spec = ustariff.scenario.targeted('EU', 0.20)
%
%   Returns a scenario struct for a U.S. tariff at the given rate on a
%   specific trading partner.  For 'EU', the tariff is applied to all
%   EU-27 member states present in the dataset.
%
%   See also: ustariff.scenario.build_tariff_cube

    validateattributes(rate, {'numeric'}, {'scalar', 'real', '>=', 0, '<=', 1}, ...
        mfilename, 'rate');
    if ~(ischar(partner) || (isstring(partner) && isscalar(partner)))
        error('ustariff:scenario:invalidPartner', ...
            'partner must be a text scalar such as ''CHN'' or ''EU''.');
    end
    partner = upper(char(string(partner)));

    spec.name    = 'targeted';
    spec.type    = 'targeted';
    spec.label   = sprintf('Targeted %s at %d%%', partner, round(rate * 100));
    spec.partner = partner;
    spec.rate    = rate;
    spec.target  = partner;
end
