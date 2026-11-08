function v=audit_windows()
  % Check guards independently on a model with multiple and overlapping Wood bands.
  % Input: none. Output: total retained-length errors for two synthetic windows.
  v=[];
  for delta=[.01,.23]
    ab=[.1,2];beta=.2;d=2*pi;
    [pieces,lines,bands]=wood_panels(ab,beta,d,1,delta);
    known=[.2,.8,1.2,1.8,2.2];
    expected_lines=known(known-delta<=ab(2) & known+delta>=ab(1));
    assert(isequal(size(lines),size(expected_lines)) && max(abs(lines-expected_lines))<2e-15);
    endpoints=unique([ab(:);bands(:);reshape(pieces(:,1:2),[],1)]);
    mids=(endpoints(1:end-1)+endpoints(2:end))/2;
    in=any(mids>=pieces(:,1).' & mids<=pieces(:,2).',2);
    expected=min(abs(mids-lines),[],2)>=delta;
    assert(isequal(in,expected));
    err=abs(sum(diff(pieces(:,1:2),1,2))-sum(diff(endpoints).*expected));
    assert(err<5e-15);v(end+1)=err;
  end
end
