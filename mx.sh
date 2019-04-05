#!/bin/sh -eu
#advanced bash stuff not needed
: >> lock #create a file if it doesn't exist
{
flock 3 #lock file by filedescriptor

echo $$ working with lock
sleep 2
echo $$ done with lock

} 3<lock
