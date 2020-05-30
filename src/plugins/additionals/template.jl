# This file includes the template plugin

struct TemplatePlugin <: AbstractPlugin 
    process(plg::TemplatePlugin, x) = println("In the template plugin. Doing nothing")
end
