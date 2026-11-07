function r=wood_trace(q,c,out)
  % Follow two paths away from the initial diagonal; save each real-axis diagnostic.
  % Input: seed beta at k-beta=.012. Output: last point and update history per detuning.
  paths={.1,[.01,.001,.0001,-.0001,-.001,-.01,-.1]};table={};
  for i=1:2
    seed=q.start;old=.012;
    for goal=paths{i}
      grid=linspace(old,goal,ceil(abs(goal-old)/.004)+1);grid=grid(2:end);hist={};ok=true;
      for delta=grid
        if delta==0,continue;end
        z=q;z.action='local';z.diagonal=true;z.offset=delta;z.start=seed;
        v=diagnose(z,c,out);a=v.roots{1};a.newton_history=v.rows;hist{end+1}=a;
        if ~strcmp(a.status,'GAP') || a.beta<0 || a.beta>pi || a.ratio>1e-7
          ok=false;break
        end
        seed=a.beta;
      end
      table{end+1}=struct('offset',goal,'finished',ok,'last',a,'steps',{hist});
      f=fopen(fullfile(out,'trace.json'),'w');fwrite(f,jsonencode(table));fclose(f);
      if ~ok,break;end
      old=goal;
    end
  end
  r=struct('status','MEASURED','targets',{table});
end
