function entry = mat_asset_manifest(dataset, year)
%USTARIFF.IO.MAT_ASSET_MANIFEST  Version-pinned remote archive for .mat files.
%
%   entries = ustariff.io.mat_asset_manifest()
%   entry = ustariff.io.mat_asset_manifest('wiod', 2014)

    commit = '9d523b1beedcd1f9eda4d7ea9d47804133d7cc94';
    base_url = ['https://raw.githubusercontent.com/ahmadlp/tariffwar/' commit '/mat/'];

    rows = {
        'ICIO', 2011, '7f16c4e759bd39e01bd2296ebc83238278675b60bd3e36bc2c2cc525ab98e8fc'
        'ICIO', 2012, '1217a1f15ae37aba982b94cda723351f4645e514d415b849b6040ec61bd06d33'
        'ICIO', 2013, '7be686f1bc4f196cee5f1c64e5fdf645c3ab84478f68dd14436adcd68d124103'
        'ICIO', 2014, '125a616d375a21211868453178058b4b21ce01556e9f755228e89100edb95e34'
        'ICIO', 2015, '94360219a9094d4913b020be7da9b5bc3a61ac1937d73a4b689436ca0d72d295'
        'ICIO', 2016, '8647a65dfb37664755ea9df463088e25dfd44103b058a434114695d621483540'
        'ICIO', 2017, '8e628119359a2da5db06e4ca35eee101a9f102b424bf418e0c99d0da3111220a'
        'ICIO', 2018, '1fc1b674f7abc6e62c634b33fcbddaab4dffbfe811685971973a6e808b730ff1'
        'ICIO', 2019, 'ffab7cd0970e3617581109b98d88632fb6d29e0f10a57e30c656eca9c0f3fc11'
        'ICIO', 2020, '6a5f7ed0764339c10adb48319754da9d03343ab2887cc5a2c25bf79e43b2a7e8'
        'ICIO', 2021, 'e4d8144b00fd50092606b1ebbc914518850e8dd01318201a14f8f689076c2149'
        'ICIO', 2022, '2f14a0b2e19a39bf29135c399eae7418f9d9cd84ff914d0442a6092de9135c77'
        'ITPD', 2000, '09e4973d11c4691f7629f5ac7c8d8ba28ec3582e3e6bec62e81a0388f00fbb31'
        'ITPD', 2001, '35a04b3a8f682f1997d53d9a48e9383bc941842f385b7696dbdc4a8b2149e0c5'
        'ITPD', 2002, 'e5ae87b12828c72fd2a1a6ba89132dd785f0b80d135ae5228f333fb57cdc6651'
        'ITPD', 2003, '86006e8b1650ee326797625054db974dd4f2debb619b5976af84b65e18c84003'
        'ITPD', 2004, '6149095a2db1c0f39d655e3c44cbaf1958b47c97397b3788cb8b14335a21447c'
        'ITPD', 2005, 'c8c1782aaf2fd262b89c6196f7142e04ec49209a9ecbd6287dd90aac51e65afa'
        'ITPD', 2006, '81cff32835be2c6779e03d3483e4b38885a29874a92b9b80af55a42b1fba9fd4'
        'ITPD', 2007, 'def131531c8c28b6c7a74b1f3dd364003cec446d4f7100aef30c3b222a5d6941'
        'ITPD', 2008, 'b5e8e548c6ca7c8b24ea0484bffb433e1a60ff417f2a458a3951e603e129e410'
        'ITPD', 2009, 'f366f856f05fce7a8ea5b39957497dbf6618f6656e9b3b276449e46f629b3b45'
        'ITPD', 2010, '049fdbfd6450dfb2062c209958aef141a4ae2247bd4d9041efcf04c50e3fff4e'
        'ITPD', 2011, '54008d7d99095816b9130e45b4b41152c7f16bc8565cc3278baaf15bbbb8da26'
        'ITPD', 2012, 'c29341ecb72027ee6c54988f87d5535223d3a66d18dec81986a85cfb0bfeb85c'
        'ITPD', 2013, 'f4e7363f06a48796f8a66ac42cc49d8e7efa15a41f9a2f95948fa3942feef5be'
        'ITPD', 2014, '734460343efe339ef70f62d1cbaff2a733ea4fa8c9fe4025fdb604b7947f0674'
        'ITPD', 2015, 'eb3726d30c6f16a7622d47472af0be554011ac4ffdbac61e99ad291e9b02a4a8'
        'ITPD', 2016, '20e296c677a477d45848a847e1952d4a033e91541ef387664b3711d2b6ca2098'
        'ITPD', 2017, '28171f53e266360e34912ed02d6d52103e2dee6f31df2cf03b7238f44968dc5d'
        'ITPD', 2018, '24c5bf646c57adc9e7fa8339723f3b7fa92e0b46cc6753f7247f93c67d6041f5'
        'ITPD', 2019, '165ee5479a09929718d4813bf22e3cd6562c0b0d21acf7259d0557fc47308d54'
        'WIOD', 2000, '942c1cdab85b5609c39001c64350f1c35181034fac617889b7cbf71bc96d33e5'
        'WIOD', 2001, '521664f52712b9f5ec70f7ec9e05c2fc7a1c0cfb6c96d47939b6449f3222ff59'
        'WIOD', 2002, 'eeebb3a885192dd46f033e27b6d6f5aed33ff61e3a70151b29f27b5e0e12a47d'
        'WIOD', 2003, 'f56c8817cc0223b274a6c79f0db519eb46f69f6354b8f13a898cec7d7c5c3e15'
        'WIOD', 2004, 'c91a8eefd0941ef5d96c38de4b918e7ae6a32127c739066cdfcbdfe6d5bf9cd4'
        'WIOD', 2005, 'a17b38926ad719f3382a792afedf9f2d799522b829e6e3bb1484493471dc2616'
        'WIOD', 2006, '267c1ab274439acd9991db985e34bd3b91750ccc40f297a7636786c9303733c3'
        'WIOD', 2007, 'dcb5e0472a40f352ba11e6b82e93f90b8644dc7dfa840dd3ea690efa8b37af7c'
        'WIOD', 2008, 'a948fd12eedf382723ceb4d3a67493548a85cf8ac9ebbf154ee4f982b946180a'
        'WIOD', 2009, '0fec46afd58b90ce33bbc640dee82fa901e151b0eb81556b38a31c7717cfe4b5'
        'WIOD', 2010, '185c06ee8700644e9760ba5f62c9b0d60c65897209d54f3bbff812d4f742e32d'
        'WIOD', 2011, 'ba0dc7c5ca05c087cbab528a67e67be19e42790b9fdfbb5af6346bc75da12e0c'
        'WIOD', 2012, '2d2752b5251a7b434d6f3690ab94a62408a327a23db4744e32f7166718ec09d6'
        'WIOD', 2013, '6de6298fc14f43f25bcae42fc4010411bb6962872d583be88ea1ad3d46af3966'
        'WIOD', 2014, '62308f56a87c8cb223f2e93998d1a896dc4fddbc62be445f72d5b8f16c64fea3'
    };

    entries = repmat(struct( ...
        'dataset', '', ...
        'year', NaN, ...
        'filename', '', ...
        'sha256', '', ...
        'url', ''), size(rows, 1), 1);

    for i = 1:size(rows, 1)
        entries(i).dataset = lower(rows{i, 1});
        entries(i).year = rows{i, 2};
        entries(i).filename = sprintf('%s%d.mat', rows{i, 1}, rows{i, 2});
        entries(i).sha256 = rows{i, 3};
        entries(i).url = [base_url entries(i).filename];
    end

    if nargin == 0
        entry = entries;
        return;
    end

    dataset = lower(char(string(dataset)));
    mask = strcmp({entries.dataset}, dataset) & [entries.year] == year;
    entry = entries(mask);
end
