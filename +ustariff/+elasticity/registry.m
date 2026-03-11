function reg = registry()
%USTARIFF.ELASTICITY.REGISTRY  Master registry of all elasticity sources.
%
%   reg = ustariff.elasticity.registry()
%
%   Returns a struct array where each entry describes one elasticity source:
%     .name           - unique identifier for config
%     .abbrev         - short abbreviation for filenames
%     .label          - human-readable label
%     .paper          - paper reference
%     .native_sectors - number of sectors in the source classification
%     .classification - sector classification system used
%     .implemented    - true if values are fully encoded
%     .getter         - function handle returning raw elasticity values
%
%   See also: ustariff.pipeline.run

    reg = struct([]);
    idx = 0;

    idx = idx + 1;
    reg(idx).name           = 'in_sample';
    reg(idx).abbrev         = 'IS';
    reg(idx).label          = 'In-Sample (dataset-specific)';
    reg(idx).paper          = 'WIOD: Lashkaripour (2021); ICIO/ITPD: Caliendo-Parro triple difference estimator';
    reg(idx).native_sectors = 16;
    reg(idx).classification = 'insample';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.insample;

    idx = idx + 1;
    reg(idx).name           = 'uniform_4';
    reg(idx).abbrev         = 'U4';
    reg(idx).label          = 'Uniform = 4 (Simonovska-Waugh)';
    reg(idx).paper          = 'Simonovska & Waugh (2014, JIE)';
    reg(idx).native_sectors = 1;
    reg(idx).classification = 'uniform';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.uniform_simonovska_waugh;

    idx = idx + 1;
    reg(idx).name           = 'caliendo_parro_2015';
    reg(idx).abbrev         = 'CP';
    reg(idx).label          = 'Caliendo & Parro (2015, ReStud)';
    reg(idx).paper          = 'Caliendo & Parro (2015) "Trade and Welfare Effects of NAFTA"';
    reg(idx).native_sectors = 20;
    reg(idx).classification = 'isic_rev3';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.caliendo_parro_2015;

    idx = idx + 1;
    reg(idx).name           = 'bagwell_staiger_yurukoglu_2021';
    reg(idx).abbrev         = 'BSY';
    reg(idx).label          = 'Bagwell, Staiger, Yurukoglu (2021, Econometrica)';
    reg(idx).paper          = 'BSY (2021) "Multilateral Trade Bargaining"';
    reg(idx).native_sectors = 49;
    reg(idx).classification = 'sitc_rev2';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.bagwell_staiger_yurukoglu_2021;

    idx = idx + 1;
    reg(idx).name           = 'giri_yi_yilmazkuday_2021';
    reg(idx).abbrev         = 'GYY';
    reg(idx).label          = 'Giri, Yi, Yilmazkuday (2021, JIE)';
    reg(idx).paper          = 'GYY (2021) "Gains from Trade: Sectoral Heterogeneity"';
    reg(idx).native_sectors = 19;
    reg(idx).classification = 'isic_rev2';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.giri_yi_yilmazkuday_2021;

    idx = idx + 1;
    reg(idx).name           = 'shapiro_2016';
    reg(idx).abbrev         = 'Shap';
    reg(idx).label          = 'Shapiro (2016, AEJ)';
    reg(idx).paper          = 'Shapiro (2016) "Trade Costs, CO2, and the Environment"';
    reg(idx).native_sectors = 13;
    reg(idx).classification = 'shapiro_13';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.shapiro_2016;

    idx = idx + 1;
    reg(idx).name           = 'fontagne_2022';
    reg(idx).abbrev         = 'FGO';
    reg(idx).label          = 'Fontagne, Guimbard, Orefice (2022, JIE)';
    reg(idx).paper          = 'Fontagne et al. (2022) "Tariff-based Product-Level Elasticities"';
    reg(idx).native_sectors = 19;
    reg(idx).classification = 'tiva_19';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.fontagne_2022;

    idx = idx + 1;
    reg(idx).name           = 'lashkaripour_lugovskyy_2023';
    reg(idx).abbrev         = 'LL';
    reg(idx).label          = 'Lashkaripour & Lugovskyy (2023, AER)';
    reg(idx).paper          = 'LL (2023) "Profits, Scale Economies, Gains from Trade"';
    reg(idx).native_sectors = 14;
    reg(idx).classification = 'isic4_14';
    reg(idx).implemented    = true;
    reg(idx).getter         = @ustariff.elasticity.sources.lashkaripour_lugovskyy_2023;

end
