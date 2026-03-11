script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);
parent_dir = fileparts(repo_root);
addpath(repo_root);

candidate_dirs = {
    fullfile(parent_dir, 'tariffwar', 'mat')
    fullfile(parent_dir, '+tariffwar', 'mat')
};
mat_dir = '';
for i = 1:numel(candidate_dirs)
    if isfolder(candidate_dirs{i})
        mat_dir = candidate_dirs{i};
        break;
    end
end

if isempty(mat_dir)
    error('ustariff:example:noExternalArchive', ...
        ['No external mat archive found. Set mat_dir to a tariffwar mat/ directory ' ...
         'before running the full suite example.']);
end

results = ustariff.pipeline.run(ustariff.scenario.standard_suite(), 'wiod', 2014, 'IS', ...
    'mat_dir', mat_dir, ...
    'auto_download_data', false, ...
    'Display', 'off');

disp(results.csv_file);
