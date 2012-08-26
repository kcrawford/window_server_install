Once in a while you run into a package or program that will only work properly with a user logged in.  This can ruin your day if you need to automated the deployment.

I found this method of automatically logging in a user (which is quite awesome).
http://www.brock-family.org/gavin/perl/kcpassword.html

Using that perl script along with a wrapper script can enable you to automate these can other cases where your only option is to have a user logged in.

I started writing a script to handle this, but it turned out I didn’t need it.  The script is unfinished, but it may give you a head start if you are considering something similar.

It depends on a modified version of the perl script that accepts a username and password.  Just swap out the user and password lines with these that accept arguments.

my $user = $ARGV[0];

my $pass = $ARGV[1];

and I comment out the line to automatically restarts the loginwindow.

\#system(‘killall’,'loginwindow’);