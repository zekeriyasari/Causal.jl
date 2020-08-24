# This file includes the type symbols of the fields to be added to the user defined components. 

# NOTE: This is one-time defines to avoid name name conflicts with the user defined type names. 

# `trigger` field  type symbol. Common to all AbstractComponent
const TRIGGER_TYPE_SYMBOL = gensym() 

# `handshake` field type symbol. Commona to all AbstractComponent.
const HANDSHAKE_TYPE_SYMBOL = gensym() 

# `callbacks` field type symbol. Commone to all AbstractComponent
const CALLBACKS_TYPE_SYMBOL = gensym() 

# `id` field type symbol. Common to all AbstractComponent. 
const ID_TYPE_SYMBOL = gensym() 

# `modelargs` field type symbol. Common to all AbstractDynamicalSystem 
const MODEL_ARGS_TYPE_SYMBOL = gensym() 

# `modelkwargs` field type symbol. Common to all AbstractDynamicalSystem
const MODEL_KWARGS_TYPE_SYMBOL = gensym() 

# `solverargs` field type symbol. Common to all AbstractDynamicalSystem
const SOLVER_ARGS_TYPE_SYMBOL = gensym() 

# `solverkwargs` field type symbol. Common to all AbstractDynamicalSystem
const SOLVER_KWARGS_TYPE_SYMBOL = gensym() 

# `alg` field type symbol. Common to all AbstractDynamicalSystem
const ALG_TYPE_SYMBOL = gensym() 

# `integrator` field type symbol. Common to all AbstractDynamicalSystem
const INTEGRATOR_TYPE_SYMBOL = gensym() 

# `input` field type symbol. Common to all AbstractSink 
const INPUT_TYPE_SYMBOL = gensym() 

# `plugin` field type symbol. Common to all AbstractSink 
const PLUGIN_TYPE_SYMBOL = gensym() 

# `timebuf` field type symbol. Common to all AbstractSink 
const TIMEBUF_TYPE_SYMBOL = gensym() 

# `databuf` field type symbol. Common to all AbstractSink 
const DATABUF_TYPE_SYMBOL = gensym() 

# `sinkcallback` field type symbol. Common to all AbstractSink 
const SINK_CALLBACK_TYPE_SYMBOL = gensym() 
