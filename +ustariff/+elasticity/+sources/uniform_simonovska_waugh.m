function raw = uniform_simonovska_waugh()
%USTARIFF.ELASTICITY.SOURCES.UNIFORM_SIMONOVSKA_WAUGH  Uniform elasticity = 4.
%
%   raw = ustariff.elasticity.sources.uniform_simonovska_waugh()
%
%   Returns a struct with:
%     .value  - scalar elasticity value (4)
%
%   Source: Simonovska & Waugh (2014, JIE) "The Elasticity of Trade"
%   Uses the median estimate of epsilon = 4 across all sectors.
%
%   Classification: uniform (same value for all sectors)

    raw.value = 4;
end
