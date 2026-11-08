function [p,counts]=shared_proxy(action,key,make)
  % Reuse exactly equal proxy fits between the two grids at one fixed phase.
  % Input: action, full binary64 fit key (frequency first), construction function.
  % Output: unchanged proxy data and the number of cached/fresh lookups.
  persistent phase freqs values hits misses
  p=[];counts=[];
  if isempty(hits),hits=0;misses=0;end
  if strcmp(action,'counts'),counts=[hits,misses];return;end
  if ~isequal(phase,key(2:end))
    phase=key(2:end);freqs=[];values={};
  end
  j=find(freqs==key(1),1);
  if isempty(j)
    p=make();misses=misses+1;
    if numel(freqs)>=768,freqs(1:128)=[];values(1:128)=[];end
    freqs(end+1)=key(1);values{end+1}=p;
  else,p=values{j};hits=hits+1;end
end
