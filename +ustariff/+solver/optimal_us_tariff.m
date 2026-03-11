function [X_sol, exitflag, output, t_us_opt] = optimal_us_tariff(N, S, Yi3D, Ri3D, e_ik3D, ...
    sigma_k3D, lambda_jik3D, tjik_3D, us_idx, cfg)
%USTARIFF.SOLVER.OPTIMAL_US_TARIFF  Solve for the optimal unilateral U.S. tariff.
%
%   [X_sol, exitflag, output, t_us_opt] = ustariff.solver.optimal_us_tariff(...)
%
%   Solves the 2N+1 system: N wages + N incomes + 1 U.S. tariff.
%   Only the U.S. optimizes its tariff (Equation 14 for U.S. row only).
%   All other countries keep factual tariffs (no retaliation).
%
%   Returns the full solution vector X_sol and the scalar optimal
%   U.S. tariff rate t_us_opt.
%
%   See also: ustariff.solver.optimal_us_equations

    % Build initial guess (2N+1: wages + incomes + U.S. tariff)
    T0 = [cfg.optimal.T0_scale.wi   * ones(N, 1); ...
          cfg.optimal.T0_scale.Yi   * ones(N, 1); ...
          cfg.optimal.T0_scale.t_us];

    % Cache function handle
    target = @(X) ustariff.solver.optimal_us_equations(X, N, S, Yi3D, Ri3D, ...
        e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D, us_idx);

    % Stall monitor
    [monitor_fcn, monitor_reset] = ustariff.solver.stall_monitor( ...
        cfg.optimal.stall_window, cfg.optimal.min_progress);

    % Initial-guess ranges for retries
    rng_wi   = cfg.optimal.T0_range.wi;
    rng_Yi   = cfg.optimal.T0_range.Yi;
    rng_t_us = cfg.optimal.T0_range.t_us;

    % Track best across all attempts
    max_attempts = 1 + cfg.optimal.max_retries;
    X_sol    = T0;
    exitflag = -99;
    output   = struct('iterations', 0, 'max_residual', Inf);

    for attempt = 1:max_attempts
        monitor_reset();

        if attempt == 1
            T0_cur = T0;
            lbl = 'default T0';
        else
            a = rng_wi(1)   + diff(rng_wi)   * rand;
            b = rng_Yi(1)   + diff(rng_Yi)   * rand;
            c = rng_t_us(1) + diff(rng_t_us) * rand;
            T0_cur = [a * ones(N,1); b * ones(N,1); c];
            lbl = sprintf('random T0 [%.2f, %.2f, %.2f]', a, b, c);
        end

        if attempt > 1 && cfg.verbose
            fprintf('[optimal_us] Attempt %d/%d: %s\n', attempt, max_attempts, lbl);
        end

        % Build solver options using optimal config
        cfg_opt = cfg;
        cfg_opt.solver = cfg.optimal;
        if attempt < max_attempts
            opts = ustariff.solver.solver_options(cfg_opt, monitor_fcn);
        else
            opts = ustariff.solver.solver_options(cfg_opt);
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

    % Extract optimal tariff
    t_us_opt = abs(X_sol(2*N+1));

    if exitflag <= 0 && cfg.verbose
        warning('ustariff:solver:noConvergence', ...
            'fsolve did not converge (exitflag = %d, max_resid = %.2e).', ...
            exitflag, output.max_residual);
    end

    if cfg.verbose
        fprintf('Optimal U.S. tariff = %.2f%%\n', 100 * t_us_opt);
    end
end
