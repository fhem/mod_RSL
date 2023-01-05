#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Compare qw{is U isnt hash};
use File::Basename;
use Test2::Todo;

our %defs;
our $init_done;

my $module = basename (dirname(__FILE__));

$module =~ s/[0-9][0-9]_//x;

sub runTest {
	my $ioName = shift; 
	my $ioHash = $defs{$ioName};
	
    my $sensorname=q[RSL_Test_ALL];
	my $command=q[74A400_ALL];
	subtest qq[define $sensorname $module $command (incomplete define)] => sub {		
		plan(4);
		
        my $sensorname=q[RSL_74A400_ALL];
        my $ret=CommandDefine(undef,qq[$sensorname SD_RSL 74A400_ALL]); 
		is ($ret,U(),q[verify return from Define]);
        is(IsDevice($sensorname), 1, "check sensor created with define");
		is(InternalVal($sensorname,q[OnCode],undef),q[93],'verify OnCode');
		is(InternalVal($sensorname,q[OffCode],undef),q[A3],'verify OffCode');
	};

    $sensorname=q[RSL_Test_1];
	$command=q[74A400_4_1];
	subtest qq[define $sensorname $module $command (incomplete define)] => sub {		
		plan(4);
        
        my $ret= CommandDefine(undef,qq[$sensorname SD_RSL 74A400_4_1]); 
        #is ($ret,match(qr/^wrong syntax:.*/),q[verify return error from Define]);
		is ($ret,U(),q[verify return from Define]);
		is(IsDevice($sensorname), 1, "check sensor created with define");
		is(InternalVal($sensorname,q[OnCode],undef),q[82],'verify OnCode');
		is(InternalVal($sensorname,q[OffCode],undef),q[8A],'verify OffCode');
	};

    $sensorname=q[RSL_Test_2];
	$command=q[74A400_4];
	subtest qq[define $sensorname $module $command (incomplete define)] => sub {
		plan(2);
		
		my $todo = Test2::Todo->new(reason => 'Test needs fix');

        my $ret= CommandDefine(undef,qq[$sensorname $module $command]); 
        is ($ret,match(qr/^wrong syntax:.*/),q[verify return error from Define]);
		isnt(IsDevice($sensorname), 1, "check sensor created with define");

		$todo->end;
	};

    $sensorname=q[RSL_Test_2];
	$command=q[74A400];
	subtest qq[define $sensorname $module $command (incomplete define)] => sub {
		plan(2);
		
		my $todo = Test2::Todo->new(reason => 'Test needs fix');

        my $ret= CommandDefine(undef,qq[$sensorname $module $command]); 
        is ($ret,match(qr/^wrong syntax:.*/),q[verify return error from Define]);
		isnt(IsDevice($sensorname), 1, "check sensor created with define");
	};

    $sensorname=q[RSL_Test_2];
	$command=q[74BDA400];
	subtest qq[define $sensorname $module $command (wrong devicecode)] => sub {
		plan(2);

		my $todo = Test2::Todo->new(reason => 'Test needs fix');
		
        my $ret= CommandDefine(undef,qq[$sensorname $module $command]); 
        is ($ret,match(qr/^wrong syntax:.*/),q[verify return error from Define]);
		isnt(IsDevice($sensorname), 1, "check sensor created with define");
	};

    $sensorname=q[RSL_Test_2];
	$command=q[74A400_8_1];
	subtest qq[define $sensorname $module $command (wrong channelcode)] => sub {
		plan(2);

		my $todo = Test2::Todo->new(reason => 'Test needs fix');
		
        my $ret= CommandDefine(undef,qq[$sensorname $module $command]); 
        is ($ret,match(qr/^wrong syntax:.*/),q[verify return error from Define]);
		isnt(IsDevice($sensorname), 1, "check sensor created with define");
	};


    $sensorname=q[RSL_Test_2];
	$command=q[74A400_4_7];
	subtest qq[define $sensorname $module $command (wrong buttoncode)] => sub {
		plan(2);
		
		my $todo = Test2::Todo->new(reason => 'Test needs fix');

        my $ret= CommandDefine(undef,qq[$sensorname $module $command]); 
        is ($ret,match(qr/^wrong syntax:.*/),q[verify return error from Define]);
		isnt(IsDevice($sensorname), 1, "check sensor created with define");
	};

    $sensorname=q[RSL_Test_3];
	$command=q[74A400_4_1 dummyDuino];
	subtest qq[define $sensorname $module $command (with IODev)] => sub {
		plan(5);
		
        my $ret= CommandDefine(undef,qq[$sensorname $module $command]); 
		is ($ret,U(),q[verify return from Define]);
		is(IsDevice($sensorname), 1, "check sensor created with define");
		is(InternalVal($sensorname,q[OnCode],undef),q[82],'verify OnCode');
		is(InternalVal($sensorname,q[OffCode],undef),q[8A],'verify OffCode');
		is(InternalVal($sensorname,q[IODev],undef),hash { field NAME => 'dummyDuino'; etc(); },'verify IODev');
	};

	done_testing();
	exit(0);
}

sub waitDone {

	if ($init_done) 
	{
		runTest(@_);
	} else {
		InternalTimer(time()+0.3, &waitDone,@_);			
	}

}

waitDone();

1;