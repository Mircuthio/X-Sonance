function out=indexesForSubplotsWithLegend2(rows,cols)
      out=nan(1,rows*cols);
      
      out(1)=cols+1;
      count=0;
      for r=1:rows
          for c=1:cols
              count=count+1;
              if r==1 && c==1
                  r;
              else
                  out(count)=out(count-1)+1;
              end
          end
      end
%      1 =2
%      2 =3
%      3 =4
%      4 =5
%      
%      5 =7
%      6 =8
%      7 =9
%      8 =10
%      
%      9 =12
%      10=13
%      11=14
%      12=15