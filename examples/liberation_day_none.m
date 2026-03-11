script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(repo_root);

spec = ustariff.scenario.liberation_day();
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off');

disp(results.csv_file);
