function [ceq] = optimal_us_equations(X, N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_factual, us_idx)
%USTARIFF.SOLVER.OPTIMAL_US_EQUATIONS  2N+1 system for optimal unilateral U.S. tariff.
%
%   Implements Equations 6, 7, and 14 from Lashkaripour (2021, JIE).
%   Equation 14 applies ONLY to the U.S. row (unilateral optimization).
%   All other countries keep their factual tariffs.
%
%   The system has 2N+1 unknowns packed into vector X:
%     X(1:N)     - wi_h:  wage changes (hat algebra)
%     X(N+1:2N)  - Yi_h:  income changes (hat algebra)
%     X(2N+1)    - t_us:  optimal U.S. uniform tariff rate (scalar)
%
%   Unlike nash_equations.m where ALL N countries optimize tariffs,
%   here only the U.S. optimizes.  The tariff cube is constructed with
%   t_us applied to all U.S. imports and factual tariffs elsewhere.
%
%   Inputs:
%     X               - (2N+1) x 1 solution vector
%     N, S            - scalars
%     Yi3D, Ri3D      - N x N x S replicated income/revenue cubes
%     e_ik3D          - N x N x S expenditure shares
%     sigma_k3D       - N x N x S CES parameters
%     lambda_jik3D    - N x N x S initial trade shares
%     tjik_3D_factual - N x N x S factual tariff levels
%     us_idx          - scalar index of USA in the country list
%
%   Returns ceq (1 x (2N+1)): equation residuals [ERR1, ERR2, ERR3].
%
%   See also: ustariff.solver.optimal_us_tariff

% Extract unknowns
wi_h = abs(X(1:N));
Yi_h = abs(X(N+1:N+N));
t_us = abs(X(2*N+1));  % scalar optimal U.S. tariff rate

% Construct tariff cube: U.S. imports at t_us, everything else factual
tjik_3D = tjik_3D_factual;
for j = 1:N
    if j == us_idx, continue; end
    tjik_3D(j, us_idx, :) = t_us;
end
tjik_h3D = (1 + tjik_3D) ./ (1 + tjik_3D_factual);

% Construct 3D cubes from 1D vectors
wi_h3D = repmat(wi_h, [1 N S]);
Yi_h3D = repmat(Yi_h, [1 N S]);
Yj_h3D = permute(Yi_h3D, [2 1 3]);
Yj3D   = permute(Yi3D, [2 1 3]);

% ------------------------------------------------------------------
%       Equation 6: Wage income = Total sales net of tariffs
% ------------------------------------------------------------------
AUX0 = lambda_jik3D .* ((tjik_h3D .* wi_h3D) .^ (1 - sigma_k3D));
AUX1 = repmat(sum(AUX0, 1), [N 1 1]);
AUX2 = AUX0 ./ max(AUX1, eps);
AUX3 = AUX2 .* e_ik3D .* (Yj_h3D .* Yj3D) ./ (1 + tjik_3D);
ERR1 = sum(sum(AUX3, 3), 2) - wi_h .* Ri3D(:,1,1);
ERR1(N,1) = sum(Ri3D(:,1,1) .* (wi_h - 1));

% ------------------------------------------------------------------
%       Equation 7: National income = wage income + tariff revenue
% ------------------------------------------------------------------
AUX5 = AUX2 .* e_ik3D .* (tjik_3D ./ (1 + tjik_3D)) .* Yj_h3D .* Yj3D;
ERR2 = sum(sum(AUX5, 3), 1)' + (wi_h .* Ri3D(:,1,1)) - Yi_h .* Yi3D(:,1,1);

% ------------------------------------------------------------------
%       Equation 14: Optimal tariff FOC (U.S. only)
% ------------------------------------------------------------------
% AUX6: foreign sales only (zero out domestic diagonal)
AUX6 = AUX3 .* repmat(1 - eye(N), [1 1 S]);
% AUX7: inverse export supply elasticity
AUX7 = sum(AUX6 .* (1 - AUX2), 2) ./ max(repmat(sum(sum(AUX6, 2), 3), [1 1 S]), eps);
% AUX8: trade-weighted average inverse supply elasticity
AUX8 = sum((sigma_k3D(:,1,:) - 1) .* AUX7, 3);
% ERR3: optimal tariff residual (scalar, U.S. row only)
% t_us is a tariff RATE (not level).  From Eq 14:  t_level = 1 + 1/AUX8,
% so t_rate = t_level - 1 = 1/AUX8.
% Floor AUX8 at 1 to cap the optimal rate at 100%.
ERR3 = t_us - 1 ./ max(AUX8(us_idx), 1);

ceq = [ERR1' ERR2' ERR3];

end
