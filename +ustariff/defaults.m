function cfg = defaults()
%USTARIFF.DEFAULTS  Solver defaults and paths.
%
%   cfg = ustariff.defaults()
%
%   Returns repo-local defaults for public quickstart runs.

    cfg.pkg_root     = ustariff.repo_root();
    cfg.data_root    = fullfile(cfg.pkg_root, 'data');
    cfg.support_root = fullfile(cfg.pkg_root, 'support');
    cfg.results_dir  = fullfile(cfg.pkg_root, 'results');
    cfg.verbose      = true;

    % Bundled quickstart data lives in repo-root mat/
    cfg.mat_dir = fullfile(cfg.pkg_root, 'mat');

    % Counterfactual solver (2N system: wages + incomes, exogenous tariffs)
    cfg.solver.TolFun      = 1e-6;
    cfg.solver.TolX        = 1e-8;
    cfg.solver.MaxIter     = 50;
    cfg.solver.MaxFunEvals = Inf;
    cfg.solver.algorithm   = 'levenberg-marquardt';
    cfg.solver.Display     = 'iter';
    cfg.solver.T0_scale.wi = 0.95;
    cfg.solver.T0_scale.Yi = 1.05;

    % Retry: random scalar initial guesses
    cfg.solver.max_retries   = 3;
    cfg.solver.T0_range.wi   = [0.8, 1.2];
    cfg.solver.T0_range.Yi   = [0.8, 1.2];

    % Stall detection
    cfg.solver.stall_window  = 5;
    cfg.solver.min_progress  = 0.10;

    % Optimal U.S. tariff solver (2N+1 system)
    cfg.optimal.TolFun      = 1e-6;
    cfg.optimal.TolX        = 1e-8;
    cfg.optimal.MaxIter     = 50;
    cfg.optimal.MaxFunEvals = Inf;
    cfg.optimal.algorithm   = 'levenberg-marquardt';
    cfg.optimal.Display     = 'iter';
    cfg.optimal.T0_scale.wi   = 0.95;
    cfg.optimal.T0_scale.Yi   = 1.05;
    cfg.optimal.T0_scale.t_us = 0.25;   % tariff RATE (not level): 25% initial guess
    cfg.optimal.max_retries   = 3;
    cfg.optimal.T0_range.wi   = [0.8, 1.2];
    cfg.optimal.T0_range.Yi   = [0.8, 1.2];
    cfg.optimal.T0_range.t_us = [0.10, 0.50]; % retry range: 10-50% tariff rate
    cfg.optimal.stall_window  = 5;
    cfg.optimal.min_progress  = 0.10;

    % Balanced trade solver
    cfg.balance_trade.TolFun             = 1e-6;
    cfg.balance_trade.TolX               = 1e-8;
    cfg.balance_trade.MaxIter            = 200;
    cfg.balance_trade.MaxFunEvals        = Inf;
    cfg.balance_trade.Display            = 'iter';
    cfg.balance_trade.algorithm          = 'trust-region-dogleg';
    cfg.balance_trade.algorithm_fallback = 'levenberg-marquardt';
    cfg.balance_trade.stall_window       = 5;
    cfg.balance_trade.min_progress       = 0.10;
    cfg.balance_trade.T0_range.wi        = [0.8, 1.2];
    cfg.balance_trade.T0_range.Yi        = [0.8, 1.2];
end
