function result=library_tests(output_dir)
  % LIBRARY_TESTS Verify polynomial-model operations and elementary integrals.
  % Input
  %   output_dir: new small-output directory.
  % Output
  %   JSON records, including exactness diagnostics under excluded rounding.
  mkdir(output_dir);result=test_poly2();
  a=poly2('make',[1,0;0,.2],.001);b=poly2('make',[2;.1],.002);
  ad=poly2('add',a,b);mu=poly2('mul',a,b);tr=poly2('truncate',mu,1);
  result.add=struct('interval',poly2('square',ad),'known',12);
  result.multiply=struct('interval',poly2('square',mu),'known',8);
  result.truncate=struct('interval',poly2('square',tr),'known',8);
  for d=[-.001,.001]
    re=poly2('reciprocal',poly2('make',[1;.1],.001),12);iv=poly2('square',re);known=2*log((1+d+.1)/(1+d-.1))/.1;
    assert(iv(1)<=known&&known<=iv(2));
  end
  f=poly2('make',[.25,-.25;.25,-.25],0);rg=poly2('range',f);result.bernstein=struct('range',rg,'known',[0,1]);
  assert(rg(1)<=0&&rg(2)>=1);
  for name={'add','multiply','truncate'}
    v=result.(name{1});assert(v.interval(1)<=v.known&&v.known<=v.interval(2));
  end
  result.pass=true;f=fopen(fullfile(output_dir,'polynomial-tests.json'),'w');cl=onCleanup(@()fclose(f));fwrite(f,jsonencode(result,PrettyPrint=true));
end
