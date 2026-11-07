function result=fem_read(action,path,varargin)
  % FEM_READ Record explicit finite element scientific-input reads.
  % Input
  %   action: start, text or mat; path: ledger or supplied numerical input.
  % Output
  %   Unchanged fileread/load result and an append-only list of opened inputs.
  persistent ledger entries
  if strcmp(action,'start'),ledger=path;entries={};result=[];return;end
  assert(~isempty(ledger),'fem:Ledger','Initialize the scientific read ledger.');
  entries{end+1}=struct('operation',action,'path',char(path),'variables',{varargin});
  fid=fopen(ledger,'w');fwrite(fid,jsonencode(entries,PrettyPrint=true));fclose(fid);
  if strcmp(action,'text'),result=fileread(path);
  elseif strcmp(action,'mat'),result=load(path,varargin{:});
  else,error('fem:Read','Unknown scientific read operation.');end
end
