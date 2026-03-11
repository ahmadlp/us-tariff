function file_path = download_mat_asset(dataset, year, target_dir)
%USTARIFF.IO.DOWNLOAD_MAT_ASSET  Download a version-pinned .mat file.
%
%   file_path = ustariff.io.download_mat_asset('wiod', 2014, './mat')

    entry = ustariff.io.mat_asset_manifest(dataset, year);
    if isempty(entry)
        error('ustariff:io:noManifestEntry', ...
            'No remote asset is registered for %s %d.', upper(char(string(dataset))), year);
    end

    if nargin < 3 || isempty(target_dir)
        target_dir = fullfile(ustariff.repo_root(), 'mat');
    end
    if ~isfolder(target_dir)
        mkdir(target_dir);
    end

    file_path = fullfile(target_dir, entry.filename);
    tmp_path = [file_path '.download'];
    if isfile(tmp_path)
        delete(tmp_path);
    end

    fprintf('Downloading %s %d from %s\n', upper(entry.dataset), entry.year, entry.url);
    try
        if exist('websave', 'file') == 2
            websave(tmp_path, entry.url);
        else
            urlwrite(entry.url, tmp_path); %#ok<URLWR>
        end
    catch err
        if isfile(tmp_path)
            delete(tmp_path);
        end
        error('ustariff:io:downloadFailed', ...
            'Failed to download %s: %s', entry.filename, err.message);
    end

    checksum = local_sha256(tmp_path);
    if ~strcmpi(checksum, entry.sha256)
        delete(tmp_path);
        error('ustariff:io:checksumMismatch', ...
            'Checksum mismatch for %s. Expected %s, got %s.', ...
            entry.filename, entry.sha256, checksum);
    end

    movefile(tmp_path, file_path, 'f');
end


function checksum = local_sha256(file_path)
    md = java.security.MessageDigest.getInstance('SHA-256');
    fis = java.io.FileInputStream(java.io.File(file_path));
    dis = java.security.DigestInputStream(fis, md);
    cleaner = onCleanup(@() close_streams(dis, fis));
    while dis.read() ~= -1
    end
    bytes = typecast(md.digest(), 'uint8');
    checksum = lower(reshape(dec2hex(bytes, 2).', 1, []));
    clear cleaner
end


function close_streams(dis, fis)
    try
        dis.close();
    catch
    end
    try
        fis.close();
    catch
    end
end
