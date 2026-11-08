"""Monitor serial MATLAB diagnostics: RSS means resident set size.
Input: output directory followed by the MATLAB batch expression.
Output: run.log, resource.csv, monitor.json; stop on memory/time/disk limits.
"""
import csv,json,os,signal,subprocess,sys,time
from pathlib import Path

def disk_size(root):
  return sum((Path(d)/f).lstat().st_size for d,ds,fs in os.walk(root,followlinks=False) for f in fs if f!='.git')

def run(out,expression,soft=1800,hard=2400,matlab_path="/Applications/MATLAB_R2023b.app/bin/matlab"):
  out=Path(out); out.mkdir(parents=True,exist_ok=True)
  command=expression if isinstance(expression,list) else [matlab_path,'-batch',expression]
  (out/'command.json').write_text(json.dumps({'command':command,'soft_seconds':soft,'hard_seconds':hard,'rss_limit_gib':2},indent=2))
  worktree_start=disk_size(Path.cwd()); before=disk_size(out); peak=0; peaks={}; peak_disk=before; reason='completed'; start=time.monotonic()
  with (out/'run.log').open('w') as log,(out/'resource.csv').open('w') as rsslog:
    writer=csv.writer(rsslog); writer.writerow(['elapsed_seconds','process_tree_rss_kib','part'])
    p=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
    while p.poll() is None:
      rows=subprocess.check_output(['ps','-axo','pid=,ppid=,rss=,comm='],text=True)
      procs={int(a[0]):(int(a[1]),int(a[2])) for row in rows.splitlines() if len(a:=row.split(None,3))==4}
      tree={p.pid}
      while True:
        more={pid for pid,(ppid,rss) in procs.items() if ppid in tree}
        if more<=tree: break
        tree|=more
      rss=sum(procs[pid][1] for pid in tree if pid in procs)*1024
      peak=max(peak,rss); elapsed=time.monotonic()-start
      used=disk_size(Path(__file__).parent); peak_disk=max(peak_disk,used)
      part=(out/'part.txt').read_text().strip() if (out/'part.txt').exists() else 'startup'
      peaks[part]=max(peaks.get(part,0),rss/2**30)
      writer.writerow([elapsed,rss/1024,part]); rsslog.flush()
      if rss>2*2**30: reason='RSS_LIMIT'
      elif elapsed>hard: reason='HARD_LIMIT'
      elif elapsed>soft: reason='SOFT_LIMIT'
      elif used>50_000_000: reason='EXPERIMENT_DISK_LIMIT'
      elif disk_size(Path.cwd())-worktree_start>700_000_000: reason='WORKTREE_DISK_LIMIT'
      if reason!='completed':
        os.killpg(p.pid,signal.SIGTERM)
        try: p.wait(timeout=5)
        except subprocess.TimeoutExpired: os.killpg(p.pid,signal.SIGKILL)
        break
      time.sleep(1)
    code=p.wait()
  result={'returncode':code,'reason':reason,'wall_seconds':time.monotonic()-start,'peak_process_tree_rss_gib':peak/2**30,'peak_experiment_disk_mb':peak_disk/1e6,'output_disk_mb':disk_size(out)/1e6,'peak_by_part_gib':peaks}
  (out/'monitor.json').write_text(json.dumps(result,indent=2)); print(json.dumps(result),flush=True)
  return result

if __name__=='__main__':
  result=run(sys.argv[1],sys.argv[2])
  sys.exit(0 if result['returncode']==0 and result['reason']=='completed' else 1)
