script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
addpath(repo_root);

spec = ustariff.scenario.targeted('CHN', 0.20);
results = ustariff.pipeline.run({spec}, 'icio', 2022, 'IS', ...
    'retaliations', {'none', 'reciprocal'}, ...
    'Display', 'off');

disp(results.csv_file);
disp({results.runs{1}.retaliation, results.runs{2}.retaliation});
