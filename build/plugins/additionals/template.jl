# This file includes the template plugin

struct TemplatePlugin <: AbstractPlugin 
end
process(plg::TemplatePlugin, x) = println("In the template plugin. Doing nothing")
