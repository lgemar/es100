
flag1 = 0; 
prompt = 'Place the colored object at the origin. Enter "1" if you are finished: ';
while(flag1 ~= 1)
    flag1 = input(prompt);
    if(flag1==1)
        disp('Great. Lets move on!')
    else
        disp('Please follow the directions...')
    end
end


    