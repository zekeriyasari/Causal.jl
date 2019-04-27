# This file is used to print build messages.

msg = "To simulate a model and write downs all the simulation logs to log.txt file, \n"
msg *= "call the `simulate` functon with `logtofile=true`. \n"
msg *= "However is this funciton is called within Juno, then the global logger set by \n"
msg *= "the `simulate` function is wrapped and deactivated by Juno. \n"
msg *= "A possible workaround to write all the logger messages to file `log.txt` set by \n"
msg *= "the `simulate` function is to write the code in a script and execute that script  \n"
msg *= "from systems terminal. E.g. `julia --color=yes <path/to/script.jl>`"
@info msg
