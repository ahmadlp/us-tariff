function Xijs_new3D = balance_trade(Xijs3D, sigma_k3D, tjik_3D, N, S, cfg)
%USTARIFF.DATA.BALANCE_TRADE  Solve for trade-balanced flows (D=0).
%
%   Xijs_new3D = ustariff.data.balance_trade(Xijs3D, sigma_k3D, tjik_3D, N, S, cfg)
%
%   Solves the DEK balanced trade exercise that removes trade deficits.
%   Uses fsolve with 2*N unknowns (wages + incomes) to find new equilibrium
%   flows under zero deficits.  Options are read from cfg.balance_trade.
%
%   Convergence strategy:
%     Attempt 1: fsolve + default algorithm, default X0
%     Attempt 2: fsolve + fallback algorithm, random scalar X0
%       wi_h in [T0_range.wi(1), T0_range.wi(2)] * ones(N,1)
%       Yi_h in [T0_range.Yi(1), T0_range.Yi(2)] * ones(N,1)
%     Stall monitor kills early if ||F|| stops decreasing.
%     Best solution (by exitflag, then residual) is returned.
%
%   See also: ustariff.solver.balanced_trade_equations

    % Build derived cubes from Xijs3D
    Xjik_3D = Xijs3D;
    [lambda_jik3D, Yi3D, Ri3D, e_ik3D] = ...
        ustariff.data.compute_derived_cubes(Xjik_3D, tjik_3D, N, S);

    % Solve balanced trade
    X0 = [ones(N, 1); ones(N, 1)];
    bt_fn = @ustariff.solver.balanced_trade_equations;
    syst = @(X) bt_fn(X, N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D);

    bt = cfg.balance_trade;

    % Stall monitor
    [monitor_fcn, monitor_reset] = ustariff.solver.stall_monitor( ...
        bt.stall_window, bt.min_progress);

    algo1 = bt.algorithm;
    algo2 = bt.algorithm_fallback;

    % Initial-guess ranges for retry
    rng_wi = bt.T0_range.wi;
    rng_Yi = bt.T0_range.Yi;

    % Track best across both attempts
    x_best    = X0;
    ef_best   = -99;
    fval_best = Inf(2*N, 1);

    for attempt = 1:2
        monitor_reset();

        if attempt == 1
            X0_cur = X0;
            algo = algo1;
            lbl = algo1;
        else
            % Fallback algo + random scalar initial guess
            a = rng_wi(1) + diff(rng_wi) * rand;
            b = rng_Yi(1) + diff(rng_Yi) * rand;
            X0_cur = [a * ones(N,1); b * ones(N,1)];
            algo = algo2;
            lbl = sprintf('%s + random X0 [%.2f, %.2f]', algo2, a, b);
        end

        if attempt > 1 && cfg.verbose
            fprintf('[balance_trade] Attempt %d/2: %s\n', attempt, lbl);
        end

        opts = optimoptions('fsolve', ...
            'Algorithm',              algo, ...
            'Display',                bt.Display, ...
            'MaxFunctionEvaluations', bt.MaxFunEvals, ...
            'MaxIterations',          bt.MaxIter, ...
            'FunctionTolerance',      bt.TolFun, ...
            'StepTolerance',          bt.TolX);
        % Last attempt: no stall monitor — let it run to MaxIter
        if attempt < 2
            opts = optimoptions(opts, 'OutputFcn', monitor_fcn);
        end
        [x_try, fval_try, ef] = fsolve(syst, X0_cur, opts);

        if ef > ef_best || (ef == ef_best && max(abs(fval_try)) < max(abs(fval_best)))
            x_best    = x_try;
            ef_best   = ef;
            fval_best = fval_try;
        end

        if ef > 0, break; end
    end

    max_resid = max(abs(fval_best));
    if cfg.verbose
        fprintf('[ustariff.data] Balance trade max residual: %.2e\n', max_resid);
    end

    % Extract solution
    wi_h = abs(x_best(1:N));
    Yi_h = abs(x_best(N+1:2*N));

    % Construct 3D cubes from solution
    wi_h3D = repmat(wi_h, [1 N S]);
    Yi_h3D = repmat(Yi_h, [1 N S]);
    Yj_h3D = permute(Yi_h3D, [2 1 3]);
    Yj3D   = permute(Yi3D, [2 1 3]);

    % Compute new trade flows under balanced trade
    AUX0 = lambda_jik3D .* (wi_h3D .^ (1 - sigma_k3D));
    AUX1 = repmat(sum(AUX0, 1), [N 1 1]);
    AUX2 = AUX0 ./ max(AUX1, eps);
    Xijs_new3D = AUX2 .* e_ik3D .* (Yj_h3D .* Yj3D);
end
