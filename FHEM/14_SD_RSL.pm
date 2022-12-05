#####################################################################
# $Id: 14_SD_RSL.pm 7779 2019-01-04 18:00:00Z v3.34-dev $
#
# The file is part of the SIGNALduino project.
# SIGNALduino RSL Modul. Modified version of FHEMduino Modul by Wzut
#
# 2019 - Ralf9 & Sidey79
# 2020..2021 Sidey79
#
# Supports following devices:
# - Conrad RSL (define Button2_CH2 SD_RSL RSL 505400_2_2)
# - RSL866T (define Button2 SD_RSL RSL866T EA6400_2)
#
#####################################################################

package main;

use strict;
use warnings;
use SetExtensions;
use Data::Dumper;

my %sets = (
    "on"  => sub {return $_[0]->{OnCode};},
    "off" => sub {return $_[0]->{OffCode};}
);

my %models = (
    "RSL"   => {
        # Kanal, Tastenpaar, Action
        0x81    => [1, 1, 0],       # I    1 / off
        0x8E    => [1, 1, 1],       # I    1 / on
        0xAE    => [1, 2, 0],       # I    2 / off
        0xA6    => [1, 2, 1],       # I    2 / on
        0x9E    => [1, 3, 0],       # I    3 / off
        0x96    => [1, 3, 1],       # I    3 / on
        0xB5    => [1, 4, 0],       # I    4 / off  - nicht auf 12 Kanal FB
        0xB9    => [1, 4, 1],       # I    4 / on   - nicht auf 12 Kanal FB

        0x8D    => [2, 1, 0],       # II   1 / off
        0x85    => [2, 1, 1],       # II   1 / on
        0xA5    => [2, 2, 0],       # II   2 / off
        0xA9    => [2, 2, 1],       # II   2 / on
        0x95    => [2, 3, 0],       # II   3 / off
        0x99    => [2, 3, 1],       # II   3 / on
        0xB8    => [2, 4, 0],       # II   4 / off - nicht auf 12 Kanal FB
        0xB0    => [2, 4, 1],       # II   4 / on  - nicht auf 12 Kanal FB

        0x84    => [3, 1, 0],       # III  1 / off
        0x88    => [3, 1, 1],       # III  1 / on
        0xA8    => [3, 2, 0],       # III  2 / off
        0xA0    => [3, 2, 1],       # III  2 / on
        0x99    => [3, 3, 0],       # III  3 / off
        0x90    => [3, 3, 1],       # III  3 / on
        0xB2    => [3, 4, 0],       # III  4 / off - nicht auf 12 Kanal FB
        0xBC    => [3, 4, 1],       # III  4 / on  - nicht auf 12 Kanal FB

        0x8A    => [4, 1, 0],       # IV   1 / off
        0x82    => [4, 1, 1],       # IV   1 / on
        0xA2    => [4, 2, 0],       # IV   2 / off
        0xAC    => [4, 2, 1],       # IV   2 / on
        0x92    => [4, 3, 0],       # IV   3 / off
        0x9C    => [4, 3, 1],       # IV   3 / on
        0xA3    => [4, 4, 0],       # IV   4 / off All
        0x93    => [4, 4, 1],       # IV   4 / on  All
    },

    "RSL866T"   => {
        # dummy, Tastenpaar, Action
        0x3E    => [0, 1, 0],       #  1 / off
        0x36    => [0, 1, 1],       #  1 / on

        0x01    => [0, 2, 0],       #  2 / off
        0x0E    => [0, 2, 1],       #  2 / on

        0x2E    => [0, 3, 0],       #  3 / off
        0x26    => [0, 3, 1],       #  3 / on

        0x1E    => [0, 4, 0],       #  4 / off
        0x16    => [0, 4, 1],       #  4 / on

        0x23    => [0, 5, 0],       #  G / off
        0x13    => [0, 5, 1]        #  G / on
    }
);

sub SD_RSL_Initialize($) {
    my ($hash) = @_;

    $hash->{Match} = "^P1#[A-Fa-f0-9]+";
    $hash->{SetFn} = "SD_RSL_Set";
    $hash->{DefFn} = "SD_RSL_Define";
    $hash->{UndefFn} = "SD_RSL_Undef";
    $hash->{AttrFn} = "SD_RSL_Attr";
    $hash->{ParseFn} = "SD_RSL_Parse";
    $hash->{AttrList} = "IODev RSLrepetition ignore:0,1 ".
                        #"model:".join(',', sort keys %models)." ".
                        $readingFnAttributes;

    $hash->{AutoCreate} =
        { "SD_RSL.*" => { GPLOT => "", FILTER => "%NAME", autocreateThreshold => "2:30" } };
}

#####################################

sub SD_RSL_Define($$) {
    my ($hash, $def) = @_;

    my @a = split("[ \t][ \t]*", $def);

    return "wrong syntax: define <name> SD_RSL <MODEL> <code (00000-FFFFFF)_(optional channel (1-4))_button (1-5)> <optional IODEV>" if (int(@a) < 4 || int(@a) > 6);

    my $name = $a[0];
    my $modelName = $a[2];
    my $device = "";
    my $channel = 0;
    my $button = undef;

    if($modelName eq "RSL") {
        ($device, $channel, $button) = split("_", $a[3]);

        if ($button eq "ALL") {
            $channel = 4;
            $button = 4;
        }

        return "wrong syntax: use channel 1 - 4" if (($channel > 4)); # || ($channel < 1 ));
        return "wrong syntax: use button 1 - 4" if (($button > 4));   # || ($button < 1));

    } elsif($modelName eq "RSL866T") {
        ($device, $button) = split("_", $a[3]);

        if ($button eq "ALL") {
            $button = 5;
        }

        return "wrong syntax: use button 1 - 5" if (($button > 5));   # || ($button < 1));
    }

    return "wrong syntax: use code 000000 - FFFFFF" if (length($device) != 6);
    return "wrong Device Code $device , please use 000000 - FFFFFF" if ((hex($device) < 0) || (hex($device) > 16777215));

    my $code = uc($a[3]);
    $hash->{DEF} = $modelName." ".$code;
    $hash->{MODEL} = $modelName;

    $modules{SD_RSL}{defptr}{$code} = $hash;
    $modules{SD_RSL}{defptr}{$code}{$name} = $hash;

    $hash->{OnCode} = sprintf('%02X', RSL_getActionCode($modelName, $channel, $button, 1));
    $hash->{OffCode} = sprintf('%02X', RSL_getActionCode($modelName, $channel, $button, 0));

    my $iodevice;
    $iodevice = $a[4] if ($a[4]);
    $iodevice = $modules{SD_RSL}{defptr}{ioname} if (exists $modules{SD_RSL}{defptr}{ioname} && not $iodevice);

    AssignIoPort($hash, $iodevice);

    return;
}

sub RSL_getActionCode($$) {
    my ($modelName, $channel, $button, $action) = @_;

    foreach my $code (keys %{$models{$modelName}}){
        my @devData = $models{$modelName}{$code};

        if($devData[0][0] == $channel
            && $devData[0][1] == $button
            && $devData[0][2] == $action
        ) {
            return $code;
        }
    }
}

##########################################################
sub SD_RSL_Set($@) {
    my ($hash, $name, @a) = @_;
    my $cmd = $a[0];
    return "\"set $name\" needs at least one argument" unless (defined($cmd));

    my $cmdList = join(" ", map {"$_:noArg"} sort keys %sets);
    if (exists($sets{$cmd})) {
        my $ioHash = $hash->{IODev};
        my $ioName = $ioHash->{NAME};
        my ($model, $device) = split(/ /, $hash->{DEF}, 2);

        $device = substr($device, 0, 6);
        my $c = $sets{$cmd}->($hash, @a);
        my $message = 'P1#0x'.$c.$device.'#R'.AttrVal($name, "RSLrepetition", 6);
        Log3 $name, 3, "$ioName RSL_set: $name $cmd -> sendMsg: $message";
        IOWrite($hash, 'sendMsg', $message);
        readingsSingleUpdate($hash, "state", $cmd, 1);
    }
    else {
        return SetExtensions($hash, $cmdList, $name, @a)
    }

    return;
}

###################################################################
sub RSL_getButtonCode($$) {
    my ($hash, $msg) = @_;

    my $name = $hash->{NAME};
    my $DeviceCode = "undef";
    my $buttonCode = "";
    my $receivedButtonCode = "undef";
    my $parsedButtonCode = "undef";
    my $action = "undef";
    my $model = "unknown";
    my $button = -1;
    my $channel = -1;

    ## Groupcode
    $DeviceCode = substr($msg, 2, 6);
    $receivedButtonCode = substr($msg, 0, 2);
    Log3 $hash, 4, "$name: SD_RSL_getButtonCode Message Devicecode: $DeviceCode Buttoncode: $receivedButtonCode";

    #if ((hex($receivedButtonCode) & 0xc0) != 0x80) {
    #  Log3 $hash, 4, "$name: SD_RSL_getButtonCode Message Error: received Buttoncode $receivedButtonCode begins not with bin 10";
    #  return "";
    #}

    $parsedButtonCode = hex($receivedButtonCode);
    Log3 $hash, 5, "$name: SD_RSL_getButtonCode Message parsed Devicecode: $DeviceCode Buttoncode: $parsedButtonCode";

    foreach my $model_name (keys %models) {
        Log3 $hash, 5, "$name: SD_RSL_getButtonCode test Model: $model_name";
        next if !$models{$model_name}{$parsedButtonCode};

        my @tmp_button = $models{$model_name}{$parsedButtonCode};
        $model = $model_name;
        $channel = $tmp_button[0][0];
        $button = $tmp_button[0][1];
        $action = $tmp_button[0][2];

        $buttonCode = $model." ".$DeviceCode."_";

        if($model eq 'RSL') {
            if($channel == 4 && $button == 4) {
                $buttonCode .=  "ALL";
            } else {
                $buttonCode .= $channel."_".$button;
            }

        } elsif($model eq 'RSL866T') {
            if($button == 5) {
                $buttonCode .= "ALL";
            } else {
                $buttonCode .= $button;
            }

        } else {
            Log3 $hash, 1, "$name: SD_RSL_getButtonCode Model: $model not implemented";
            return "";
        }

        $buttonCode .= " ".$action;
    }

    Log3 $hash, 4, "$name: SD_RSL_getButtonCode button return/result: ID: $DeviceCode $receivedButtonCode DEVICE: $DeviceCode $channel $button ACTION: $action";

    return $buttonCode;
}

########################################################
sub SD_RSL_Parse($$) {
    my ($hash, $msg) = @_;
    my $name = $hash->{NAME};
    my (undef, $rawData) = split("#", $msg);

    Log3 $hash, 4, "$name: SD_RSL_Parse - Message: $rawData";

    my $buttonCode = RSL_getButtonCode($hash, $rawData);

    if ($buttonCode ne "") {
        Log3 $hash, 4, "$name: SD_RSL_Parse - ButtonCode: $buttonCode";

        my ($model, $deviceCode, $action) = split m/ /, $buttonCode, 3;

        Log3 $hash, 4, "$name: SD_RSL_Parse - Device: $deviceCode  Action: $action";

        $modules{SD_RSL}{defptr}{ioname} = $name;
        my $def = $modules{SD_RSL}{defptr}{$hash->{NAME}.".".$deviceCode};

        $def = $modules{SD_RSL}{defptr}{$deviceCode} if (!$def);

        if (!$def) {
            Log3 $hash, 3, "$name: SD_RSL_Parse UNDEFINED Remotebutton send to define: $model $deviceCode";
            return "UNDEFINED SD_RSL_$deviceCode SD_RSL $model $deviceCode";
        }

        $hash = $def;

        my $name = $hash->{NAME};
        return "" if (IsIgnored($name));

        Log3 $name, 5, "$name: SD_RSL_Parse - actioncode: $action";

        if($action == 1) {
            readingsSingleUpdate($hash, "state", "on", 1);
        } else {
            readingsSingleUpdate($hash, "state", "off", 1);
        }

        return $name;
    }
    return "";
}

########################################################
sub SD_RSL_Undef($$) {
    my ($hash, $name) = @_;
    SetExtensionsCancel($hash);
    delete($modules{SD_RSL}{defptr}{$hash->{DEF}}) if ($hash && $hash->{DEF});
    return;
}

########################################################
sub SD_RSL_Attr(@) {
    my @a = @_;

    # Make possible to use the same code for different logical devices when they
    # are received through different physical devices.
    return if ($a[0] ne "set" || $a[2] ne "IODev");
    my $hash = $defs{$a[1]};
    my $iohash = $defs{$a[3]};
    my $cde = $hash->{DEF};
    delete($modules{SD_RSL}{defptr}{$cde});
    $modules{SD_RSL}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
    return;
}

1;

=pod
=item summary devices communicating using the Conrad RSL protocol
=item summary_DE Anbindung von Conrad RSL Ger&auml;ten

=begin html

<a name="SD_RSL"></a>
<h3>SD_RSL</h3>
The SD_RSL module decrypts and creates Conrad RSL messages sent / received by a SIGNALduino device.<br>
If autocreate is used, a device &quot;&lt;code&gt;_ALL&quot; like RSL_74A400_ALLis created instead of channel and button = 4.<br>

<br>
<a name="SD_RSL_Define"></a>
<b>Define</b>
<ul>
	<p><code>define &lt;name&gt; SD_RSL &lt;model&gt; &lt;code&gt;_&lt;channel&gt;[_&lt;button&gt;] &lt;optional IODEV&gt;</code>
	<br>
	<br>
	<code>&lt;name&gt;</code> is any name assigned to the device.
	
	For a better overview it is recommended to use a name in the form &quot;RSL_B1A800_1_2&quot;
	<br /><br />
	<code>&lt;code&gt;</code> The code is 00000-FFFFFF
	<br /><br />
	<code>&lt;model&gt;</code> Model is RSL or RSL866T
	<br /><br />
	<code>&lt;channel&gt;</code> The channel is 1-4 or ALL
	<br /><br />
	<code>&lt;button&gt;</code> The button is 1-4
	<br /><br />
</ul>   
<a name="SD_RSL_Set"></a>
<b>Set</b>
<ul>
  <code>set <name> &lt;[on|off|toggle]&gt;</code><br>
  Switches the device on or off.<br><br>
  <code>set <name> &lt;[on-for-timer|off-for-timer|on-till|off-till|blink|intervals]&gt;</code><br>
  Switches the socket for a specified duration. For Details see <a href="#setExtensions">set extensions</a>.<br><br>
  <br /><br />
</ul>
<a name="SD_RSL_Get"></a>
<b>Get</b>
<ul>
	N/A
</ul><br>
<a name="SD_RSL_Attr"></a>
<b>Attribute</b>
<ul>
    <li><a href="#IODev">IODev</a></li>
	<li><a href="#do_not_notify">do_not_notify</a></li>
	<li><a href="#eventMap">eventMap</a></li>
	<li><a href="#ignore">ignore</a></li>
	<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
	<a name="RSLrepetition"></a>
	<li>RSLrepetition<br>
	Set the repeats for sending signal. 
	</li>
</ul>
=end html

=begin html_DE

<a name="SD_RSL"></a>
<h3>SD_RSL</h3>
Das SD_RSL-Modul decodiert und erstellt Conrad-RSL-Nachrichten, die vom SIGNALduino gesendet bzw. empfangen werden.<br>
Beim Verwendung von Autocreate wird bei der Taste All anstatt channel und button = 4 &quot;&lt;code&gt;_ALL&quot; angelegt, z.B. RSL_74A400_ALL<br>
<br>
<a name="SD_RSL_Define"></a>
<b>Define</b>
<ul>
	<p><code>define &lt;name&gt; SD_RSL &lt;model&gt; &lt;code&gt;_&lt;channel&gt;[_&lt;button&gt;] &lt;optional IODEV&gt;</code>
	<br>
	<br>
	<code>&lt;name&gt;</code> ist ein Name, der dem Ger&auml;t zugewiesen ist.
	Zur besseren &Uuml;bersicht wird empfohlen, einen Namen in dieser Form zu verwenden &quot;RSL_B1A800_1_2&quot;
	<br /><br />
	<code>&lt;code&gt;</code> Der Code ist 00000-FFFFFF
	<br /><br />
	<code>&lt;model&gt;</code> Model ist RSL oder RSL866T
	<br /><br />
	<code>&lt;channel&gt;</code> Der Kanal ist 1-4 oder ALL (entfällt bei RSL866T)
	<br /><br />
	<code>&lt;button&gt;</code> Der Knopf ist 1-4 (-5 bei RSL866T)
	<br /><br />
</ul>
<a name="SD_RSL_Set"></a>
<b>Set</b>
<ul>
  <code>set <name> &lt;[on|off|toggle]&gt;</code><br
  Schaltet das Ger&auml;t ein oder aus.<br><br>
  <code>set <name> &lt;[on-for-timer|off-for-timer|on-till|off-till|blink|intervals]&gt;</code><br>
  Schaltet das Ger&auml;t f&uuml;r einen bestimmten Zeitraum. Weitere Infos hierzu unter <a href="#setExtensions">set extensions</a>.<br><br>
  <br /><br />
</ul>
<a name="SD_RSL_Get"></a>
<b>Get</b>
<ul>
	N/A
</ul><br>
<a name="SD_RSL_Attr"></a>
<b>Attribute</b>
<ul>
	<li><a href="#IODev">IODev</a></li>
	<li><a href="#do_not_notify">do_not_notify</a></li>
	<li><a href="#eventMap">eventMap</a></li>
	<li><a href="#ignore">ignore</a></li>
	<li><a href="#readingFnAttributes">readingFnAttributes</a></li>
	<a name="RSLrepetition"></a>
	<li>RSLrepetition<br>
	Stellen Sie die Wiederholungen f&uumlr das Senden des Signals ein. 
	</li>
</ul>
=end html_DE

=cut
