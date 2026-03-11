function [fcn, reset_fcn] = stall_monitor(stall_window, min_progress)
%USTARIFF.SOLVER.STALL_MONITOR  OutputFcn for fsolve/lsqnonlin stall detection.
%
%   [fcn, reset_fcn] = ustariff.solver.stall_monitor(stall_window, min_progress)
%
%   Halts fsolve or lsqnonlin when it is clear the solver is going nowhere:
%     - After stall_window iterations, requires at least three orders of
%       magnitude drop from the initial residual.  If ||F|| is still
%       within 1000x of where it started, kill.
%     - After that, requires relative decrease > min_progress over
%       every sliding window of stall_window iterations.
%
%   Compatible with both fsolve (optimValues.fval) and lsqnonlin
%   (optimValues.residual).

    history = [];
    init_norm = [];

    fcn       = @check_stall;
    reset_fcn = @reset_history;

    function stop = check_stall(~, optimValues, state)
        stop = false;
        if strcmp(state, 'iter')
            % fsolve uses .fval; lsqnonlin uses .residual
            if isfield(optimValues, 'fval')
                res_norm = norm(optimValues.fval);
            else
                res_norm = norm(optimValues.residual);
            end
            history(end+1) = res_norm; %#ok<AGROW>

            % Record initial residual
            if isempty(init_norm)
                init_norm = res_norm;
            end

            k = numel(history);
            if k >= stall_window
                % Check 1: after stall_window iters, must have dropped
                % by at least one order of magnitude from start
                if k == stall_window && init_norm > 0 && res_norm > init_norm / 1000
                    stop = true;
                    fprintf('[stall_monitor] No 1000x drop after %d iters: ||F|| %.2e -> %.2e. Killing.\n', ...
                        stall_window, init_norm, res_norm);
                    return;
                end

                % Check 2: sliding window relative progress
                old_norm = history(k - stall_window + 1);
                if old_norm > 0
                    rel_decrease = (old_norm - res_norm) / old_norm;
                    if rel_decrease < min_progress
                        stop = true;
                        fprintf('[stall_monitor] Stalled at iter %d: ||F|| %.2e -> %.2e (%.1f%% over %d iters). Killing.\n', ...
                            optimValues.iteration, old_norm, res_norm, ...
                            rel_decrease*100, stall_window);
                    end
                end
            end
        end
    end

    function reset_history()
        history = [];
        init_norm = [];
    end
end
