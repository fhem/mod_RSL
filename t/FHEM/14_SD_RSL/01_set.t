use strict;
use warnings;
use File::Basename;

use Test2::V0;
use Test2::Tools::Compare qw{ is array hash};

our %defs;
our %attr;
our %modules;

my $testSet;
my $tData;
my $testDataArray; 

InternalTimer(time()+1, sub {
	my $target = shift;
	my $targetHash = $defs{$target};
	# my $mock = Test2::Mock->new(
	# 	track => 1,
	# 	class => 'main'
	# );	 	
	# my $tracking = $mock->sub_tracking;

    my @mockData = (
		{
			testname	=>  'set ? command (1.0)',
			input		=>	'?',
			return 		=>  check_set ( match qr/^Unknown argument \?, choose one of.*/, match qr/on/, match qr/off/, match qr/toggle/ ),
			deviceHash 	=>  hash { 	},
		}, 
		{		
			testname	=>  'set without argument',
			input		=>	'',
			return		=>	match qr/needs at least one argument$/,
			deviceHash 	=>  hash {  }, 
		},
		{		
			testname	=>  'set on command',
			input		=>	'on',
			return		=>	undef,
			deviceHash 	=>  hash { field READINGS => hash 	
									{ field state => hash 
										{
											field VAL => 'on';
										} 
									}
								}
		},
		{		
			testname	=>  'set off command',
			input		=>	'off',
			return		=>	undef,
			deviceHash 	=>  hash { field READINGS => hash 	
									{ field state => hash 
										{
											field VAL => 'off';
										};
									};
								}
		},
		{		
			testname	=>  'set toggle command',
			input		=>	'toggle',
			check 		=>  array  {
								end();
							},
			return		=>	undef,
			deviceHash 	=>  hash { field READINGS => hash 	
									{ field state => hash 
										{
											field VAL => 'on';
										};
									};
								}
		}
	);

	plan (scalar @mockData);	
	my $todo=undef;
	
	foreach my $element (@mockData)
	{
		next if (!exists($element->{testname}));
		

		#Mock attr
		while (my ($key,$value) = each %{$element->{attr}} ) {
			defined $value 
				?	CommandAttr(undef,qq[$target $key $value])
				:	CommandAttr(undef,qq[-r $target $key])
		}
		$element->{pre_code}->($target) if (exists($element->{pre_code}));
		$todo=$element->{todo}->() if (exists($element->{todo}));
		
		subtest "checking $element->{testname};" => sub {
			plan (2);	
			
			my $ret = SD_RSL_Set($targetHash,$target,split(' ',$element->{input}));
			like($ret,$element->{return},'Verify return value');
			like($targetHash,$element->{deviceHash},'Verify expected hash element');
		};
		undef ($todo);
		$element->{post_code}->() if (exists($element->{post_code}));
	
	};

	exit(0);
},'RSL_411B11_0_0');

1;