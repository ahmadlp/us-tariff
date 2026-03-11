function [ceq] = balanced_trade_equations(X, N ,S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_app)
%USTARIFF.SOLVER.BALANCED_TRADE_EQUATIONS  System of equations for balanced trade (D=0).
%
%   Defines the nonlinear system for the zero-deficit counterfactual.
%   Solves for wages and incomes that clear markets when every country
%   runs zero trade deficit.  Uses only Equations 6 and 7 from
%   Lashkaripour (2021, AER) -- no tariff optimization.
%
%   The system has 2N unknowns packed into vector X:
%     X(1:N)     - wi_h:  wage changes (hat algebra)
%     X(N+1:2N)  - Yi_h:  income changes (hat algebra)
%
%   Returns ceq (1 x 2N): equation residuals [ERR1, ERR2].
%
% ------------------------------------------------------------------
%        Description of Inputs
% ------------------------------------------------------------------
%   N: number of countries;  S: number of industries
%   Yi3D: factual income (GDP) in country i (N x N x S, replicated)
%   Ri3D: national wage revenues (N x N x S, replicated)
%   e_ik3D: industry-level expenditure share (Cobb-Douglas weight)
%   lambda_jik3D: within-industry trade share (j's share of k's spending)
%   sigma_k3D: industry-level CES parameter (sigma-1 = trade elasticity)
%   tjik_3D_app: applied tariff rates -- held fixed (not optimized)
% ------------------------------------------------------------------
%
%   See also: ustariff.data.balance_trade

% Extract unknowns from solution vector X
% abs(.) prevents complex numbers during fsolve line search
wi_h=abs(X(1:N));       % N x 1 wage changes
Yi_h=abs(X(N+1:N+N));   % N x 1 income changes
tjik_3D = tjik_3D_app;  % tariffs held at factual levels (no optimization)


% Construct 3D cubes from 1D vectors (replicate across trading partners and sectors)
wi_h3D=repmat(wi_h,[1 N S]);    % exporter wage cube
Yi_h3D=repmat(Yi_h,[1 N S]);    % importer income cube
Yj_h3D=permute(Yi_h3D,[2 1 3]); % swap importer/exporter dimensions
Yj3D=permute(Yi3D,[2 1 3]);     % factual income with swapped dimensions

% ------------------------------------------------------------------
%       Equation 6: Wage income = Total sales net of tariffs
% ------------------------------------------------------------------
% AUX0: updated trade cost term: initial share * (wage_hat)^(1 - sigma)
% Note: no tariff_hat term here because tariffs are held fixed (tjik_h = 1)
AUX0 = lambda_jik3D.*( wi_h3D.^(1-sigma_k3D));
% AUX1: CES price index denominator (sum over exporters)
AUX1 = repmat(sum(AUX0,1),[N 1 1]);
% AUX2: updated bilateral trade shares
AUX2 = AUX0./max(AUX1, eps);
% AUX3: export revenue net of tariffs
AUX3 = AUX2.*e_ik3D.*(Yj_h3D.*Yj3D)./((1+tjik_3D));
% ERR1: wage equation residual -- total export revenue minus wage bill
ERR1 = sum(sum(AUX3,3),2) - wi_h.*Ri3D(:,1,1);
% Normalization: replace last equation with world wage anchor
ERR1(N,1) = sum(Ri3D(:,1,1).*(wi_h-1));

% ------------------------------------------------------------------
%       Equation 7: National income = wage income + tariff revenue
% ------------------------------------------------------------------
% AUX5: tariff revenue collected by importer k
AUX5 = AUX2.*e_ik3D.*(tjik_3D./(1+tjik_3D)).*Yj_h3D.*Yj3D;
% ERR2: income equation residual -- tariff revenue + wage income - total income
ERR2 = sum(sum(AUX5,3),1)' + (wi_h.*Ri3D(:,1,1)) - Yi_h.*Yi3D(:,1,1);

% ------------------------------------------------------------------

ceq= [ERR1' ERR2'];

end
