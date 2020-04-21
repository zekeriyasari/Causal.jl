# This file includes the package-wide defaults.

"""Number of taps of buffers used for interpolations"""
const numtaps = 3

"""DiscreteSystem default solver algorithm."""
const DiscreteAlg = FunctionMap()

"""ODESystem default algorithm."""
const ODEAlg = Tsit5()

"""DDESystem default solver algorithm."""
const DDEAlg = MethodOfSteps(Tsit5())

"""DAESystem default solver algorithm"""
const DAEAlg = IDA()

"""RODESystem default solver algorithm"""
const RODEAlg = RandomEM()

"""SDESysttem default solver algorithm"""
const SDEAlg = LambaEM{true}()

