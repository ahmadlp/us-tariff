function root = repo_root()
%USTARIFF.REPO_ROOT  Absolute path to the repository root.

    persistent cached_root

    if isempty(cached_root)
        here = fileparts(mfilename('fullpath'));
        cached_root = fileparts(here);
    end

    root = cached_root;
end
