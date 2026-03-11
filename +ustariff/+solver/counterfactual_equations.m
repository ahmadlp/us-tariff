function [ceq] = counterfactual_equations(X, N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_factual, tjik_h3D)
%USTARIFF.SOLVER.COUNTERFACTUAL_EQUATIONS  2N system for exogenous tariff scenarios.
%
%   Implements Equations 6 and 7 from Lashkaripour (2021, JIE) with an
%   exogenous tariff hat.  Unlike nash_equations.m (3N system), tariffs
%   are NOT solved for -- they are given as inputs via tjik_h3D.
%
%   The system has 2N unknowns packed into vector X:
%     X(1:N)     - wi_h:  wage changes (hat algebra)
%     X(N+1:2N)  - Yi_h:  income changes (hat algebra)
%
%   Key difference from balanced_trade_equations.m:
%     balanced: AUX0 = lambda .* (wi_h3D .^ (1-sigma))         % no tariff change
%     here:     AUX0 = lambda .* ((tjik_h3D .* wi_h3D) .^ (1-sigma))  % tariff hat
%
%   Key difference from nash_equations.m:
%     nash: 3N unknowns (wages, incomes, tariffs) -- tariffs endogenous
%     here: 2N unknowns (wages, incomes) -- tariffs exogenous via tjik_h3D
%
%   Inputs:
%     X               - 2N x 1 solution vector
%     N, S            - scalars
%     Yi3D, Ri3D      - N x N x S replicated income/revenue cubes
%     e_ik3D          - N x N x S expenditure shares
%     sigma_k3D       - N x N x S CES parameters
%     lambda_jik3D    - N x N x S initial trade shares
%     tjik_3D_factual - N x N x S factual tariff levels
%     tjik_h3D        - N x N x S tariff hat (= (1+cf)/(1+factual))
%
%   Returns ceq (1 x 2N): equation residuals [ERR1, ERR2].
%
%   See also: ustariff.solver.counterfactual

% Extract unknowns from solution vector X
% abs(.) prevents complex numbers during fsolve line search
wi_h = abs(X(1:N));        % N x 1 wage changes
Yi_h = abs(X(N+1:N+N));    % N x 1 income changes

% Construct 3D cubes from 1D vectors (replicate across trading partners and sectors)
wi_h3D = repmat(wi_h, [1 N S]);     % exporter wage cube
Yi_h3D = repmat(Yi_h, [1 N S]);     % importer income cube
Yj_h3D = permute(Yi_h3D, [2 1 3]);  % swap importer/exporter dimensions
Yj3D   = permute(Yi3D, [2 1 3]);    % factual income with swapped dimensions

% Counterfactual tariff levels
tjik_3D_cf = tjik_h3D .* (1 + tjik_3D_factual) - 1;

% ------------------------------------------------------------------
%       Equation 6: Wage income = Total sales net of tariffs
% ------------------------------------------------------------------
% AUX0: updated trade cost term with exogenous tariff hat
AUX0 = lambda_jik3D .* ((tjik_h3D .* wi_h3D) .^ (1 - sigma_k3D));
% AUX1: CES price index denominator
AUX1 = repmat(sum(AUX0, 1), [N 1 1]);
% AUX2: updated bilateral trade shares
AUX2 = AUX0 ./ max(AUX1, eps);
% AUX3: export revenue net of tariffs
AUX3 = AUX2 .* e_ik3D .* (Yj_h3D .* Yj3D) ./ (1 + tjik_3D_cf);
% ERR1: wage equation residual
ERR1 = sum(sum(AUX3, 3), 2) - wi_h .* Ri3D(:,1,1);
% Normalization: world wage anchor (weighted average wage = 1)
ERR1(N,1) = sum(Ri3D(:,1,1) .* (wi_h - 1));

% ------------------------------------------------------------------
%       Equation 7: National income = wage income + tariff revenue
% ------------------------------------------------------------------
% AUX5: tariff revenue
AUX5 = AUX2 .* e_ik3D .* (tjik_3D_cf ./ (1 + tjik_3D_cf)) .* Yj_h3D .* Yj3D;
% ERR2: income equation residual
ERR2 = sum(sum(AUX5, 3), 1)' + (wi_h .* Ri3D(:,1,1)) - Yi_h .* Yi3D(:,1,1);

ceq = [ERR1' ERR2'];

end
