{
    ofn = outfile (NR % thread_cnt);
    print $0 > ofn;
}
