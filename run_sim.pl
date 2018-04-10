#!/usr/bin/perl
use strict; use warnings;
use Getopt::Long;

#Invariants
$ENV{"LD_LIBRARY_PATH"}= "$ENV{LD_LIBRARY_PATH}:/org/seg/tools/eda/novas/verdi/Verdi3-201403-3/share/PLI/IUS/LINUX64";
my $verdi_cmd = "Verdi -ssf waves.fsdb -f vlog_listfile -sv -top tb_top &";
mkdir "run" unless (-d "run");
chdir "run";
$ENV{RESULTSDIR} = "run";
my $default = {
    test => "test_base",
    debug => 0,
    run => 1,
    make => 1,
    verdi => 0
};
my $default_make_args = [
                        "-elaborate",
                        "-sv",
                        "-64bit",
                        "-uvm",
                        "-log compile.log",
                        "-top tb_top",
                        "-access r",
                        "-delay_trigger",
                        "-nonotifier",
                        "-timescale 1ns/10ps",
                        "-default_ext verilog",
                        "+define+UVM_REPORT_FILE_LINE",
                        "+libext+.v+.sv+.vlib+.vh+.svh",
                        "-nowarn LIBNOU",
                        "-no_tchk_msg",
                        "-delay_mode Zero"
                 ];

#---INPUT-----
my @input = @ARGV;

#---OUTPUT----
map  (&sys($_), &gen_cmd_list( &get_options($default, \@input),$default_make_args ) );

#---Function Definitions---
sub get_options{
    my ($default, $argv) = (shift,shift);
    @ARGV = @{$argv};
    GetOptions(
        "test=s", \$default->{test},
        "debug", \$default->{debug},
        "run!",\$default->{run},
        "make!",\$default->{make},
        "verdi!",\$default->{verdi}
    );
    print join "", map { "$_ : $default->{$_}\n" } keys %{$default};
    return $default;
}


sub gen_cmd_list{
    my ($opt,$make_args) = (shift,shift);
    return ( &gen_verdi_cmds($opt->{verdi}),  
             &gen_make_cmds($opt->{verdi},$opt->{make},$make_args), 
             &gen_run_cmds($opt->{verdi},$opt->{run},$opt->{test},$opt->{debug}) );
}
sub gen_verdi_cmds{
    my $verdi = shift;
    return ($verdi_cmd) if $verdi;
    return ();
}
sub gen_make_cmds{
    my ($verdi,$make,$make_args) = (shift,shift,shift);
    return (
            &gen_make_cmd($make_args),
            "make",
            &gen_cat_error("compile.log")
           ) if $make and not $verdi;
    return ();
}
sub gen_run_cmds{
    my ($verdi,$run,$test,$debug) = (shift,shift,shift,shift);
    return (
            &gen_run_cmd($test,$debug),
            &gen_cat_error("irun.log")
           ) if $run and not $verdi;
    return ();
}
sub gen_cat_error{
    return "cat ".(shift)." | grep '*E'";
}
sub gen_make_cmd{
    my $irun_args = shift;
    return  join("","makemodel -mf Makefile -cf ../sim.config.pl -DNO_UNIT_DELAYS -DSIMON -tool incisive",
                map( " -vcsargs '$_' ",
                    @{$irun_args}
                   ),
                )
}
sub gen_run_cmd{
    my ($test,$debug) = (shift,shift);
    return "irun -uvm +UVM_TESTNAME=$test -LICQUEUE -64bit -l irun.log -nclibdirname ./INCA_libs -r _sim -snapshot _sim".($debug ? " + UVM_VERBOSITY=UVM_DEBUG" : "");
}
sub sys{
    my $cmd = shift; print "$cmd\n";system($cmd);
}

