function opts = solver_options(cfg, output_fcn)
%USTARIFF.SOLVER.SOLVER_OPTIONS  Build fsolve options from config.
%
%   opts = ustariff.solver.solver_options(cfg)
%   opts = ustariff.solver.solver_options(cfg, output_fcn)
%
%   Uses optimoptions (not legacy optimset) to properly set the algorithm.
%   Optionally attaches an OutputFcn (e.g. stall_monitor) when provided.

    opts = optimoptions('fsolve', ...
        'Display',              cfg.solver.Display, ...
        'MaxFunctionEvaluations', cfg.solver.MaxFunEvals, ...
        'MaxIterations',        cfg.solver.MaxIter, ...
        'FunctionTolerance',    cfg.solver.TolFun, ...
        'StepTolerance',        cfg.solver.TolX, ...
        'Algorithm',            cfg.solver.algorithm);

    if nargin >= 2 && ~isempty(output_fcn)
        opts = optimoptions(opts, 'OutputFcn', output_fcn);
    end
end
