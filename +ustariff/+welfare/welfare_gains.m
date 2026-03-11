function [Gains] = welfare_gains(X, N, S, e_ik3D, sigma_k3D, lambda_jik3D, tjik_h3D)
%USTARIFF.WELFARE.WELFARE_GAINS  Compute welfare gains from exogenous tariff change.
%
%   Gains = ustariff.welfare.welfare_gains(X, N, S, e_ik3D, sigma_k3D, lambda_jik3D, tjik_h3D)
%
%   Given the counterfactual solution vector X and the exogenous tariff hat,
%   computes the percent change in real income (welfare) for each country.
%   Welfare_hat = E_hat / P_hat.
%
%   Unlike the Nash-equilibrium welfare routine in tariffwar, which reconstructs the tariff
%   cube from X(2N+1:3N), this version takes tjik_h3D directly as input.
%
%   Inputs:
%     X             - 2N x 1 solution vector [wi_h; Yi_h]
%     N, S          - number of countries, sectors
%     e_ik3D        - expenditure shares (Cobb-Douglas weights)
%     sigma_k3D     - CES elasticity parameters
%     lambda_jik3D  - initial bilateral trade shares
%     tjik_h3D      - tariff hat (exogenous, N x N x S)
%
%   Returns Gains (N x 1): percent welfare change per country.
%
%   See also: ustariff.solver.counterfactual

% Extract unknowns from the counterfactual solution vector
wi_h   = abs(X(1:N));           % N x 1 wage changes (hat)
wi_h3D = repmat(wi_h, [1 N S]); % replicate into exporter wage cube
Ei_h   = abs(X(N+1:N+N));      % N x 1 income/expenditure changes (hat)

% --- Price index change (CES aggregation across exporters) ---
% AUX0: bilateral trade cost change raised to (1 - sigma)
AUX0 = (tjik_h3D .* wi_h3D) .^ (1 - sigma_k3D);
% price_sum: CES price index numerator (sum over exporters, weighted by initial shares)
price_sum = max(sum(lambda_jik3D .* AUX0, 1), eps);
% Pjk_h: sectoral price index change for importer j in sector k
Pjk_h = price_sum .^ (1 ./ (1 - sigma_k3D(1,:,:)));
Pjk_h(isnan(Pjk_h) | isinf(Pjk_h)) = 1;

% --- Aggregate price index (Cobb-Douglas across sectors) ---
Pi_h = exp(sum(e_ik3D(1,:,:) .* log(max(Pjk_h, eps)), 3))';

% --- Welfare = real income change ---
Wi_h  = Ei_h ./ Pi_h;
Gains = 100 * (Wi_h - 1);

end
