function addSoftwareStamp(fig)
% ADDSOFTWARESTAMP  Small, unobtrusive attribution in the bottom-right
% margin of FIG, so a figure/frame pulled out of a paper, slide, or GIF
% later can still be traced back to the software that made it. Tagged so
% calling this again on the same figure (e.g. Export Figures clicked
% twice, or every frame of a movie) doesn't stack duplicate stamps.
% Wrapped in try/catch: annotation() property support varies across
% Octave/MATLAB versions, and a missing stamp is a cosmetic issue, not
% worth failing the whole figure export (or a running simulation) over.
%
% Usage:
%   addSoftwareStamp(gcf)
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
try
    if ~isempty(findall(fig, 'Tag', 'MIDAS_software_stamp'))
        return
    end
    annotation(fig, 'textbox', [0.5 0.003 0.48 0.03], ...
        'String', 'MIDAS - Stroh & Moulas (2026)', ...
        'Tag', 'MIDAS_software_stamp', ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
        'FontSize', 7, 'Color', [0.55 0.55 0.55], 'FitBoxToText', 'off');
catch
    % Cosmetic only - skip silently if this Octave/MATLAB version's
    % annotation() doesn't support one of the properties above.
end
end
