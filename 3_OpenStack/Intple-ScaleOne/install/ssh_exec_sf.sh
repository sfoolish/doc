#!/usr/bin/expect
set timeout -1
set host [lindex $argv 0]
set username [lindex $argv 1]
set password [lindex $argv 2]
set commond  [lindex $argv 3]

spawn ssh $username@$host $commond
expect {
        "(yes/no)?" { exp_send "yes\n" ; exp_continue }
        "(y/n)?" { exp_send "y\n" ; exp_continue }
        "Y/n" { exp_send "y\n" ; exp_continue }
        "y/N" { exp_send "y\n" ; exp_continue }
        "New password" { exp_send "intple\n" ; exp_continue }
        "Repeat password" { exp_send "intple\n" ; exp_continue }
        "Enter password*" { exp_send "\n" ; exp_continue }
        "*replace*" { exp_send "A\n" ; exp_continue }
        "*'s password: " { exp_send "$password\n" ; exp_continue }
        "Enter new UNIX password:" { exp_send "intple\n" ; exp_continue }
        "Retype new UNIX password" { exp_send "intple\n" ; exp_continue }
        "*Enter*" { exp_send "\n" ; exp_continue }
       }
expect "100%"
expect eof