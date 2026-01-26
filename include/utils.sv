
static function int count_ones(int num);
    int count = 0;
    for (int i = 0; i < $bits(num); i++) begin
        count += num[i];
    end
    return count;
endfunction