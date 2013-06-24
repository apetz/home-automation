#!/usr/bin/perl

my %rainfall;
my @tableIndex = ("15 min.","30 min.","1 hr.","3 hr.","6 hr.","12 hr.","24 hr.","12 mon.","Additional Info","Gauge Status");

# fetch rainfall log for City of Austin
`wget --tries=10 --waitretry=10 http://www.ci.austin.tx.us/fews/rainfall.cfm`;

open F,"rainfall.cfm";
my @data = <F>;
close F;

parseRainfallData(@data);
logRainfallToDropbox();

# delete file
`rm rainfall.cfm`;

foreach my $key (sort keys %rainfall) {
    print "$key: $rainfall{$key}\n";
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
            $rainfall{$tableIndex[$indexer]} = $value;
            $indexer++;
        }
    }
}

sub logRainfallToDropbox {
    my $record = "$rainfall{date},$rainfall{time},$rainfall{\"24 hr.\"}";
    print "recording: $record\n";
    `echo \"$record\" >> ~/Dropbox/Public/db/rainfall.db`;
}
