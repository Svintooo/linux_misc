# Kernel#`
value = `echo 'hi'`
value = `#{cmd}`
$?.exitstatus

# %x( cmd )
value = %x( echo 'hi' )
value = %x[ #{cmd} ]
$?.exitstatus

# Kernel#system
exitstatus = system( "echo 'hi'" )
exitstatus = system( cmd )

# Kernel#exec
#NOTE: Script terminates afterwards
exec( "echo 'hi'" )
exec( cmd )

# Process.spawn
pid = Process.spawn( "echo 'hi'" )
pid = Process.spawn( cmd )
Process.wait(pid)
