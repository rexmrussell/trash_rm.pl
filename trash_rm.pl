#!/usr/bin/perl
use strict;
use warnings;
use File::Copy qw(move);
use File::Basename;
use File::Path qw(make_path remove_tree);
use Getopt::Long;
use Time::Piece;

# Configuration
my $trash_dir = "$ENV{HOME}/.trash";  # Trash directory
my $expiration_time = 7 * 24 * 60 * 60; # 7 days

# Create the trash directory if it doesn't exist
make_path($trash_dir) unless -d $trash_dir;

# Command line options
my $empty_trash = 0;
my $restore_file;
my $restore = 0;
GetOptions(
    'empty'   => \$empty_trash,
    'restore=s' => \$restore_file,
);

# Empty trash if --empty flag is set
if ($empty_trash) {
    remove_tree($trash_dir);
    print "Trash has been emptied.\n";
    exit 0;
}

# Restore file if --restore flag is set
if ($restore) {
    my $trash_file = "$trash_dir/" . basename($restore_file);
    if (-e $trash_file) {
        move($trash_file, $restore_file) or die "Failed to restore $restore_file: $!\n";
        print "$restore_file has been restored.\n";
    } else {
        die "No such file in trash: $restore_file\n";
    }
    exit 0;
}

# Move files to trash
foreach my $file (@ARGV) {
    if (-e $file) {
        my $timestamp = localtime->epoch;
        my $trash_file = "$trash_dir/$file.$timestamp";
        move($file, $trash_file) or die "Failed to move $file to trash: $!\n";
        print "$file has been moved to trash.\n";
    } else {
        print "No such file: $file\n";
    }
}

# Automatically delete old files from trash
opendir(my $dh, $trash_dir) or die "Cannot open $trash_dir: $!\n";
while (my $entry = readdir $dh) {
    next if $entry =~ /^\./;
    my $file_path = "$trash_dir/$entry";
    if ((stat($file_path))[9] + $expiration_time < time) {
        unlink($file_path) or warn "Failed to delete $file_path: $!\n";
    }
}
closedir $dh;

__END__

=head1 NAME

trash_rm.pl - A safe delete command with trash can functionality.

=head1 SYNOPSIS

trash_rm.pl [options] [file ...]

Options:

    --empty           Empty the trash can.
    --restore FILE    Restore a file from the trash can.

=head1 DESCRIPTION

This script mimics the behavior of the 'rm' command but instead moves
files to a trash directory. Files in the trash directory are
automatically deleted after a certain period of time. The script
includes options to empty the trash can or restore files from it.

=cut
