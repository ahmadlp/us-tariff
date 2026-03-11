function [lambda_jik3D, Yi3D, Ri3D, e_ik3D] = compute_derived_cubes(Xjik_3D, tjik_3D, N, S)
%USTARIFF.DATA.COMPUTE_DERIVED_CUBES  Build expenditure shares and income cubes.
%
%   [lambda, Yi, Ri, e] = ustariff.data.compute_derived_cubes(Xjik_3D, tjik_3D, N, S)
%
%   Computes:
%     lambda_jik3D - N x N x S trade share cube (sum over dim 1 = 1)
%     Yi3D         - N x N x S income cube (replicated)
%     Ri3D         - N x N x S revenue cube (replicated)
%     e_ik3D       - N x N x S expenditure share cube (sum over dim 3 = 1)
%
%   Uses max(..., eps) guards to prevent NaN from 0/0 in country-sectors
%   with zero trade.
%
%   See also: ustariff.pipeline.run, ustariff.data.balance_trade

    denom_lambda = repmat(sum(Xjik_3D, 1), [N 1 1]);
    lambda_jik3D = Xjik_3D ./ max(denom_lambda, eps);
    Yi3D = repmat(max(sum(sum(Xjik_3D, 1), 3)', eps), [1 N S]);
    Ri3D = repmat(max(sum(sum(Xjik_3D ./ (1 + tjik_3D), 2), 3), eps), [1 N S]);
    e_ik3D = repmat(sum(Xjik_3D, 1), [N 1 1]) ./ max(permute(Yi3D, [2 1 3]), eps);
end
