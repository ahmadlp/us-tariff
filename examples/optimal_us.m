script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(repo_root);

spec = ustariff.scenario.optimal_us();
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off', ...
    'save_map', true);

disp(results.csv_file);
disp(results.runs{1}.tariff_rate);
