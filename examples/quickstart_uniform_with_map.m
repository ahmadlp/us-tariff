script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(repo_root);

spec = ustariff.scenario.uniform(0.10);
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', 'none', ...
    'Display', 'off', ...
    'save_map', true);

disp(results.csv_file);
disp(results.map_file);
