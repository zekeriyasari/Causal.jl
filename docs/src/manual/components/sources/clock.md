# Clock

`Jusdl` is a *clocked* simulation environment. That is, model components are evolved in different time intervals, called as *sampling interval*. During the simulation, model components are triggered by these generated time pulses.  The `Clock` type is used to to generate those time pulses. The simulation time settings, the simulation start time, stop time, sampling interval are configured through the `Clock`s.

## Construction of Clock
Construction of `Clock` is done by specifying its start time and final time and the simulation sampling period. 
