#!/usr/bin/perl

my %rainfall;
my %weather;
my @rfTableIndex = ("15 min.","30 min.","1 hr.","3 hr.","6 hr.","12 hr.","24 hr.","12 mon.","Additional Info","Gauge Status");
my @wTableIndex = ("Eto (in.)","Max. Temp.","Min. Temp.","Min. RH (%)","Solar Rad. (MJ/m2)","Rainfall","Wind (mph) - 4am","Wind (mph) - 4pm");

# fetch rainfall log for City of Austin
`wget --tries=10 --waitretry=10 -O rainfall.cfm http://www.ci.austin.tx.us/fews/rainfall.cfm`;

open F,"rainfall.cfm";
my @data = <F>;
close F;
# delete file
`rm rainfall.cfm`;

parseRainfallData(@data);

foreach my $key (sort keys %rainfall) {
    print "$key: $rainfall{$key}\n";
}

# fetch weather station data from A&M Morris Williams site
`wget --tries=10 --waitretry=10 -O index.html http://texaset.tamu.edu/`;

open F,"index.html";
@data = <F>;
close F;
# delete file
`rm index.html`;

parseWeatherStationData(@data);


logDataToDropbox();

foreach my $key (sort keys %weather) {
    print "$key: $weather{$key}\n";
}

sub parseRainfallData {
    my $indexer = -1;
    foreach my $line (@_) {
        if (my ($date,$time) = $line =~ m/Last\s+updated:\s+([0-9]+\/[0-9]+\/[0-9]+)\s+([0-9]+:[0-9]+\s+[AM|PM]+)/) {
            $rainfall{date} = $date;
            $rainfall{time} = $time;
        }
        elsif ($line =~ m/3120\.jpg.+Koenig\s+Ln/) {
            $indexer++;
        } 
        elsif (($indexer >= 0 && $indexer < 10) && (my ($value) = $line =~ m/<td.*>(.*)<\/td>/)) {
            $rainfall{$rfTableIndex[$indexer]} = $value;
            $indexer++;
        }
    }
}

sub parseWeatherStationData {
    my $indexer = -1;
    foreach my $line (@_) {
        if ($line =~ m/class="Data">Austin \(Morris Williams\)/) {
            $indexer++;
        } 
        elsif (($indexer >= 0 && $indexer < $#wTableIndex+1) && (my ($value) = $line =~ m/<td.*>(.*)<\/td>/)) {
            $weather{$wTableIndex[$indexer]} = $value;
            $indexer++;
        }
    }
}

sub logDataToDropbox {
    my $record = "$rainfall{date},$rainfall{time},$rainfall{\"24 hr.\"},$rainfall{\"Additional Info\"},$rainfall{\"Gauge Status\"}";
    print "recording: $record\n";
    `echo \"$record\" >> ~/Dropbox/Public/db/rainfall.db`;
    `echo \"$record\" >> ~/www/home/db/rainfall.db`;
    $record = "";
    my $i=0;
    for ($i=0; $i<$#wTableIndex;$i++) {
        print "inserting $wTableIndex[$i] : $weather{$wTableIndex[$i]}\n";
        $record = $record . "$weather{$wTableIndex[$i]},";
    }
    print "inserting $wTableIndex[$i] : $weather{$wTableIndex[$i]}\n";
    $record = $record . "$weather{$wTableIndex[$i]}";
    `echo \"$record\" >> ~/Dropbox/Public/db/weather.db`;
    `echo \"$record\" >> ~/www/home/db/weather.db`;
}
