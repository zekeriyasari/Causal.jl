---
title: 'Causal.jl: A Modeling and Simulation Framework for Causal Models'
tags:
  - Julia
  - system modeling 
  - causal modeling
  - system simulation 
  - dynamical systems 
authors:
  - name: Zekeriya Sarı^[Corresponding Author]
    orcid: 0000-0003-4070-9666
    affiliation: 1
  - name: Serkan Günel
    affiliation: 1
affiliations:
 - name: Department of Electrical and Electronics Engineering, Dokuz Eylül University, İzmir, Turkey
   index: 1
date: 07 September 2020
bibliography: paper.bib
---

# Summary 

Numerical simulations can be expressed as solving the mathematical equations derived from modeling physical systems and/or processing the data obtained from the solutions. Based on the properties of the system at hand and the level of abstraction in the modeling, mathematical equations may be ordinary, stochastic, delay differential or difference equations. High speed performance and ability to offer useful analysis tools are other typical features expected from an effective simulation environment.

Many simulation environments have been developed for numerical analysis of systems[@elmqvist1978structured; @nytsch2006advanced; @zimmer2008introducing; @mosterman2002hybrsim; @van2001variables; @giorgidze2009higher; @pfeiffer2012pysimulator; @simulink]. They are capable of allowing simulations that are represented by ordinary differential equations and differential equations, mostly. This is restrictive given the variety of mathematical equations that can be derived from the modeling [@rackauckas2017differentialequations]. In addition, many of the existing simulation environments lack modern computational methods such as parallel computing techniques.

In this study, Causal.jl which is a modeling and simulation framework for causal models is introduced [@causal]. The aim is to easily model large scale complex system networks and to provide fast and effective simulations. For this purpose, Julia, an open source, high level, general purpose dynamical programming language designed for high performance numerical analysis and computational science, has been used. Although Julia  is a dynamical language, owing to its Just-in-Time(JIT) compiler developed on Low Level Virtual Machine(LLVM), it can reach the high speed performance of static languages such as C[@bezanson2017julia; @julialang]. It supports various parallel computing techniques at thread and process levels. In addition to Julia's standard library, numerous specialized packages developed for different fields such as data science, scientific computing, are also available. Julia's high speed performance and parallel computing support are important in meeting the need to design a  fast and effective simulation environment. Julia's syntax can be enlarged purposefully using its metaprogramming support. The analyzes scope of the simulation framework can be extended with new plugins that can be easily defined. It is possible to analyze discrete or continuous time, static or dynamical systems. In particular, it is possible to simulate dynamical systems modeled by ordinary, random ordinary, stochastic, delay differential, differential algebraic and/or discrete difference equations, simultaneously. Unlike its counterparts, the models do not evolve at once for the whole simulation duration. Instead, the model components evolve between sampling time intervals, individually. While individual evolution of the components enables the simulation of systems consisting of components represented by different mathematical models, parallel evolution of components increases the simulation performance.


# Acknowledgements
This work was supported by Scientific Research Projects Funding Program of Dokuz Eylül University (project no: 2020.KB.FEN.007).

# References
