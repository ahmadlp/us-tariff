function [X_sol, exitflag, output] = counterfactual(N, S, Yi3D, Ri3D, e_ik3D, ...
    sigma_k3D, lambda_jik3D, tjik_3D_factual, tjik_h3D, cfg)
%USTARIFF.SOLVER.COUNTERFACTUAL  Solve for counterfactual equilibrium with exogenous tariffs.
%
%   [X_sol, exitflag, output] = ustariff.solver.counterfactual(N, S, ...)
%
%   Solves the 2N system (Equations 6 & 7) for an exogenous tariff change.
%   The tariff hat (tjik_h3D) is given as input -- not solved for.
%
%   The system has 2*N unknowns:
%     - N wage multipliers (wi_h)
%     - N income multipliers (Yi_h)
%
%   Convergence strategy:
%     Attempt 1: fsolve with default T0 from cfg.solver.T0_scale
%     Attempts 2..max_retries+1: random scalar initial guesses
%     Stall monitor kills early if ||F|| stops decreasing.
%     Best solution (by exitflag, then residual) is returned.
%
%   See also: ustariff.solver.counterfactual_equations

    % Build initial guess (2N: wages + incomes only)
    T0 = [cfg.solver.T0_scale.wi * ones(N, 1); ...
          cfg.solver.T0_scale.Yi * ones(N, 1)];

    % Cache function handle
    target = @(X) ustariff.solver.counterfactual_equations(X, N, S, Yi3D, Ri3D, ...
        e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_factual, tjik_h3D);

    % Stall monitor
    [monitor_fcn, monitor_reset] = ustariff.solver.stall_monitor( ...
        cfg.solver.stall_window, cfg.solver.min_progress);

    % Initial-guess ranges for retries
    rng_wi = cfg.solver.T0_range.wi;
    rng_Yi = cfg.solver.T0_range.Yi;

    % Track best across all attempts
    max_attempts = 1 + cfg.solver.max_retries;
    X_sol    = T0;
    exitflag = -99;
    output   = struct('iterations', 0, 'max_residual', Inf);

    for attempt = 1:max_attempts
        monitor_reset();

        if attempt == 1
            T0_cur = T0;
            lbl = 'default T0';
        else
            a = rng_wi(1) + diff(rng_wi) * rand;
            b = rng_Yi(1) + diff(rng_Yi) * rand;
            T0_cur = [a * ones(N,1); b * ones(N,1)];
            lbl = sprintf('random T0 [%.2f, %.2f]', a, b);
        end

        if attempt > 1 && cfg.verbose
            fprintf('[counterfactual] Attempt %d/%d: %s\n', attempt, max_attempts, lbl);
        end

        % Last attempt: no stall monitor
        if attempt < max_attempts
            opts = ustariff.solver.solver_options(cfg, monitor_fcn);
        else
            opts = ustariff.solver.solver_options(cfg);
        end
        [X_try, fval, ef, out] = fsolve(target, T0_cur, opts);
        out.max_residual = max(abs(fval));

        if ef > exitflag || (ef == exitflag && out.max_residual < output.max_residual)
            X_sol    = X_try;
            exitflag = ef;
            output   = out;
        end

        if ef > 0, break; end
    end

    if exitflag <= 0 && cfg.verbose
        warning('ustariff:solver:noConvergence', ...
            'fsolve did not converge (exitflag = %d, max_resid = %.2e).', ...
            exitflag, output.max_residual);
    end
end
