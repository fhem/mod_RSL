#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;
use File::Basename;

# Testtool which supports DMSG Tests from SIGNALDuino_tool
use Test2::FHEM::Command;
use Test2::Tools::Compare qw{is U validator array hash};
use Test2::Mock;

our %defs;
our $init_done;
our $mock;

my $module = basename (dirname(__FILE__));

# This is the testdata, which will speify what to test and what to check
@mockData = (
    {
        # Default mocking for every testrun in our loop
        defaults    => {
            mocking =>  sub { $mock->override ( IOWrite => sub { return @_ } );  } 
        },
    },
    {
        targetName      => 	q[RSL_411B11_0_0],
        testname        =>  q[set ? ],
        cmd             =>	q[set ?],

        returnCheck     => check_set( match qr/^Unknown argument \?, choose one of.*/, match qr/on/, match qr/off/, match qr/toggle/ ),
        subCheck        => hash { end(); }
    },	
    {
        targetName      => 	q[RSL_411B11_0_0],
        testname        =>  q[set without argument],
        cmd             =>	q[set ],

        returnCheck     => match qr/needs at least one argument$/,
        subCheck        => hash { end(); } ,
    },	
    {	
        targetName      => 	q[RSL_411B11_0_0],
		testname        =>  q[set on command],
        cmd	            =>	q[set on],
        returnCheck     => F(),    
        hashCheck       => hash { field READINGS => hash { field state => hash 	{ field VAL => 'on'; } 	}  },
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P1#0xB6411B11#R6' }; etc() } } } ,
    },
    {	
        targetName      => 	q[RSL_411B11_0_0],
		testname        =>  q[set off command],
        cmd	            =>	q[set off],
        returnCheck     => F(),    
        hashCheck       => hash { field READINGS => hash { field state => hash 	{ field VAL => 'off'; } 	}  },
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P1#0xBE411B11#R6' }; etc() } } } ,
    },
    {	
        targetName      => 	q[RSL_411B11_0_0],
		testname        =>  q[set toggle command],
        cmd	            =>	q[set toggle],
        returnCheck     => F(),    
        hashCheck       => hash { field READINGS => hash { field state => hash 	{ field VAL => 'on'; } 	}  },
        subCheck        => hash { field 'IOWrite' => array { item 0 => hash { field 'args' => array { item hash { etc(); } ; item 'sendMsg'; item 'P1#0xB6411B11#R6' }; etc() } } } ,
    },
);
        
sub runTest {
    Test2::FHEM::Command::commandCheck($module);

    done_testing();
	exit(0);
}

sub waitDone {

	if ($init_done) 
	{
		runTest(@_);
	} else {
		InternalTimer(time()+0.5, &waitDone,@_);			
	}

}

waitDone();

1;