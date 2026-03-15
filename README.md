# Distributed Network Propagation Simulator
This project was developed as part of COP5615 at the University of Florida, taught by Prof. Alin Dobra. Implemented in Gleam and executed on the Erlang VM, the simulator models distributed nodes across various network topologies and evaluates message propagation using Gossip and Push-Sum algorithms.

A distributed systems simulator that models how information propagates across a network of nodes using Gossip and Push-Sum algorithms. The simulator evaluates how different network topologies affect convergence time and message dissemination. This project uses the actor model for highly concurrent distributed simulations.

**Overview**

In distributed systems, information must propagate efficiently across many nodes. Algorithms like Gossip and Push-Sum are widely used for decentralized communication, fault tolerance, and distributed aggregation. This simulator creates a configurable network of nodes and analyzes how quickly information spreads depending on the network topology and algorithm used.

**Algorithms**

**Gossip Algorithm**

The gossip protocol spreads information through a network by randomly selecting neighbors and transmitting a message repeatedly until all nodes receive the rumor.

Use cases include:
- Distributed databases
- Peer-to-peer systems
- Blockchain networks

**Push-Sum Algorithm**

The push-sum protocol is used to compute the global average of values distributed across nodes in a decentralized system.

Each node maintains:
- s (sum)
- w (weight)

Nodes exchange partial values with neighbors until the ratio s / w converges to the global average.

**Network Topologies**

The simulator supports several network structures:
- Full Network : Every node connects to every other node.
- Line Network : Nodes are arranged sequentially where each node connects to its neighbors.
- 3D Grid : Nodes are organized in a 3-dimensional grid structure.
- Imperfect 3D Grid : A 3D grid with additional random connections to simulate real-world networks.
