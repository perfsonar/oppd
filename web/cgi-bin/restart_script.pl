#!/usr/bin/perl

use warnings;
use strict;
use English;

my $restart_command = "/etc/init.d/oppd restart";

$ENV{PATH} = "";

$UID = 0;
die "Cannot set UID: $!\n" if $!;
$EUID = 0;
die "Cannot set EUID: $!\n" if $!;
$GID = 0;
die "Cannot set GID: $!\n" if $!;
$EGID = 0;
die "Cannot set EGID: $!\n" if $!;

exec($restart_command);

die "Could not exec '$restart_command': $!";
