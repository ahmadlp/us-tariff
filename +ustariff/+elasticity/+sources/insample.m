function raw = insample()
%USTARIFF.ELASTICITY.SOURCES.INSAMPLE  In-sample trade elasticities.
%
%   raw = ustariff.elasticity.sources.insample()
%
%   Returns dataset-specific 16x1 epsilon vectors at WIOD-16 classification:
%     .epsilon_wiod  - from Lashkaripour (2021) SECTORAL_TRADE_ELASTICITY.csv
%     .epsilon_icio  - CP2014 trilateral gravity on pooled ICIO 2011-2022
%     .epsilon_itpd  - CP2014 trilateral gravity on pooled ITPD 2000-2019
%     .sectors       - 16x1 cell of WIOD-16 sector labels
%
%   The build pipeline selects the appropriate vector based on the target
%   dataset (wiod -> epsilon_wiod, icio -> epsilon_icio, itpd -> epsilon_itpd),
%   then chains through the concordance to the target sector classification.
%
%   Classification: insample (dataset-dependent, all vectors are WIOD-16)
%
%   See also: ustariff.elasticity.registry

    % WIOD: Lashkaripour (2021) Table values from SECTORAL_TRADE_ELASTICITY.csv
    raw.epsilon_wiod = [ ...
         0.67;  ... % 1  Agriculture, forestry, fishing
        13.53;  ... % 2  Mining and quarrying
         0.47;  ... % 3  Food products, beverages, tobacco
         3.33;  ... % 4  Textiles, wearing apparel, leather
         5.73;  ... % 5  Wood, paper, printing
         8.50;  ... % 6  Coke and refined petroleum
        14.94;  ... % 7  Chemicals and pharmaceuticals
         0.91;  ... % 8  Rubber, plastics, non-metallic minerals
         1.69;  ... % 9  Basic metals
         1.47;  ... % 10 Fabricated metals
         3.28;  ... % 11 Computer, electronic, optical
         3.44;  ... % 12 Electrical equipment
         3.63;  ... % 13 Machinery and equipment
         1.38;  ... % 14 Transport equipment
         1.64;  ... % 15 Other manufacturing; repair
         5.00]; ... % 16 Services (aggregate)

    % ICIO: CP2014 trilateral gravity on pooled ICIO 2011-2022, aggregated to WIOD-16
    % Pooled groups: {[1,2], [9,10], [11,12,13,14,15]}
    raw.epsilon_icio = [ ...
         7.6215;  ... % 1  Agriculture, forestry, fishing (pooled 1+2)
         7.6215;  ... % 2  Mining and quarrying (pooled 1+2)
         1.2925;  ... % 3  Food products, beverages, tobacco
         3.2191;  ... % 4  Textiles, wearing apparel, leather
         5.8568;  ... % 5  Wood, paper, printing
         6.3971;  ... % 6  Coke and refined petroleum
         7.7621;  ... % 7  Chemicals and pharmaceuticals
         3.0765;  ... % 8  Rubber, plastics, non-metallic minerals
         1.6119;  ... % 9  Basic metals (pooled 9+10)
         1.6119;  ... % 10 Fabricated metals (pooled 9+10)
         4.0000;  ... % 11 Computer, electronic, optical (pooled 11-15, fallback)
         4.0000;  ... % 12 Electrical equipment (pooled 11-15, fallback)
         4.0000;  ... % 13 Machinery and equipment (pooled 11-15, fallback)
         4.0000;  ... % 14 Transport equipment (pooled 11-15, fallback)
         4.0000;  ... % 15 Other manufacturing; repair (pooled 11-15, fallback)
         4.0000]; ... % 16 Services (aggregate, fallback)

    % ITPD: CP2014 trilateral gravity on pooled ITPD 2000-2019, aggregated to WIOD-16
    % Pooled group: {[1,2]}
    raw.epsilon_itpd = [ ...
         5.5110;  ... % 1  Agriculture, forestry, fishing (pooled 1+2)
         5.5110;  ... % 2  Mining and quarrying (pooled 1+2)
         1.5484;  ... % 3  Food products, beverages, tobacco
         5.1442;  ... % 4  Textiles, wearing apparel, leather
         5.0685;  ... % 5  Wood, paper, printing
         0.2174;  ... % 6  Coke and refined petroleum
         6.1666;  ... % 7  Chemicals and pharmaceuticals
         3.6567;  ... % 8  Rubber, plastics, non-metallic minerals
         3.7311;  ... % 9  Basic metals
         5.6125;  ... % 10 Fabricated metals
         5.6163;  ... % 11 Computer, electronic, optical
         4.0257;  ... % 12 Electrical equipment
         2.4432;  ... % 13 Machinery and equipment
         6.7538;  ... % 14 Transport equipment
         3.6975;  ... % 15 Other manufacturing; repair
         4.0000]; ... % 16 Services (aggregate, fallback)

    raw.sectors = { ...
        'Agriculture, forestry, fishing'; ...
        'Mining and quarrying'; ...
        'Food products, beverages, tobacco'; ...
        'Textiles, wearing apparel, leather'; ...
        'Wood, paper, printing'; ...
        'Coke and refined petroleum'; ...
        'Chemicals and pharmaceuticals'; ...
        'Rubber, plastics, non-metallic minerals'; ...
        'Basic metals'; ...
        'Fabricated metals'; ...
        'Computer, electronic, optical'; ...
        'Electrical equipment'; ...
        'Machinery and equipment n.e.c.'; ...
        'Transport equipment'; ...
        'Other manufacturing; repair'; ...
        'Services (aggregate)'};
end
